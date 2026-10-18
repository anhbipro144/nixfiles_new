"""Live CLI/MCP checks in disposable repositories; never indexes user projects.

Usage: python3 tests/test_codegraph_mcp.py /nix/store/.../bin/codegraph [old-binary]
"""

import json
import os
from pathlib import Path
import queue
import sqlite3
import subprocess
import sys
import tempfile
import threading
import time


def command(binary, args, env, cwd):
    result = subprocess.run(
        [str(binary), *args], cwd=cwd, env=env,
        input="", text=True, capture_output=True, timeout=120,
    )
    assert result.returncode == 0, (args, result.stdout[-2000:], result.stderr[-2000:])
    return result.stdout


class McpClient:
    def __init__(self, binary, cwd, env, roots):
        self.roots = roots
        self.messages = queue.Queue()
        self.sequence = 0
        self.stderr = tempfile.TemporaryFile(mode="w+")
        self.process = subprocess.Popen(
            [str(binary), "serve", "--mcp", "--no-watch"], cwd=cwd, env=env,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.stderr,
            text=True, bufsize=1,
        )
        self.reader = threading.Thread(target=self.read_messages, daemon=True)
        self.reader.start()

    def read_messages(self):
        for line in self.process.stdout:
            self.messages.put(json.loads(line))

    def send(self, message):
        self.process.stdin.write(json.dumps({"jsonrpc": "2.0", **message}) + "\n")
        self.process.stdin.flush()

    def request(self, method, params):
        self.sequence += 1
        request_id = self.sequence
        self.send({"id": request_id, "method": method, "params": params})
        deadline = time.monotonic() + 60
        while True:
            try:
                message = self.messages.get(timeout=max(0, deadline - time.monotonic()))
            except queue.Empty:
                self.stderr.seek(0)
                raise AssertionError((method, "MCP timeout", self.stderr.read()[-3000:]))
            if message.get("method") == "roots/list":
                self.send({"id": message["id"], "result": {"roots": self.roots}})
            elif message.get("id") == request_id and "method" not in message:
                assert "error" not in message, message
                return message["result"]

    def close(self):
        self.process.stdin.close()
        try:
            self.process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.process.terminate()
            self.process.wait(timeout=10)
        self.reader.join(timeout=2)
        self.process.stdout.close()
        self.stderr.close()


def main():
    binary = Path(sys.argv[1]).resolve()
    old_binary = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else binary
    with tempfile.TemporaryDirectory(prefix="codegraph-check-") as directory:
        root = Path(directory).resolve()
        home = root / "home"
        home.mkdir()
        workspace = root / "workspace"
        workspace.mkdir()
        env = {
            **os.environ, "HOME": str(home), "CODEGRAPH_TELEMETRY": "0",
            "CODEGRAPH_NO_UPDATE_CHECK": "1", "CODEGRAPH_DAEMON_IDLE_TIMEOUT_MS": "1000",
        }
        repos = [workspace / "invoice", workspace / "shipping"]
        symbols = ["calculateInvoiceTotal", "calculateShippingCost"]
        for repo, symbol in zip(repos, symbols):
            repo.mkdir()
            (repo / ".gitignore").write_text(".codegraph/\n")
            (repo / "app.ts").write_text(
                f"export function {symbol}(amount: number): number {{ return amount * 3; }}\n"
                f"export function useResult(amount: number): number {{ return {symbol}(amount); }}\n"
            )
            command("git", ["init", "--quiet", str(repo)], env, root)
            output = command(old_binary if repo == repos[0] else binary, ["init", str(repo)], env, root)
            assert (repo / ".codegraph/codegraph.db").exists(), output

        database = repos[0] / ".codegraph/codegraph.db"
        backup = root / "before-upgrade.sqlite3"
        with sqlite3.connect(database) as source:
            before_version = source.execute("SELECT MAX(version) FROM schema_versions").fetchone()[0]
            before_files = source.execute("SELECT COUNT(*) FROM files").fetchone()[0]
            with sqlite3.connect(backup) as target:
                source.backup(target)
        command(binary, ["status", str(repos[0])], env, root)

        # Start outside any indexed repository and let MCP roots resolve the project.
        client = McpClient(binary, root, env, [{"uri": repos[0].as_uri(), "name": "invoice"}])
        try:
            initialized = client.request("initialize", {
                "protocolVersion": "2024-11-05", "capabilities": {"roots": {"listChanged": True}},
                "clientInfo": {"name": "codegraph-nix-check", "version": "1"},
            })
            assert initialized["serverInfo"]["version"] == "1.6.2", initialized
            assert initialized.get("instructions"), "MCP server must supply usage guidance"
            client.send({"method": "notifications/initialized"})
            tools = client.request("tools/list", {})["tools"]
            assert "codegraph_explore" in {tool["name"] for tool in tools}, tools
            for index, (repo, symbol) in enumerate(zip(repos, symbols)):
                args = {"query": symbol}
                if index:
                    args["projectPath"] = str(repo)
                result = client.request("tools/call", {"name": "codegraph_explore", "arguments": args})
                content = "\n".join(item.get("text", "") for item in result.get("content", []))
                assert not result.get("isError"), result
                assert f"function {symbol}" in content, content
            print(f"PASS: MCP handshake, {len(tools)} tools, roots-based default, two-project explore")
        finally:
            client.close()
            # Allow the test daemon to honor its shortened idle timeout before cleanup.
            time.sleep(2)

        with sqlite3.connect(database) as db:
            after_version = db.execute("SELECT MAX(version) FROM schema_versions").fetchone()[0]
            assert after_version == 11, after_version
            assert db.execute("SELECT COUNT(*) FROM files").fetchone()[0] == before_files
            assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
        with sqlite3.connect(backup) as db:
            assert db.execute("SELECT MAX(version) FROM schema_versions").fetchone()[0] == before_version
            assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
        assert not (home / ".codegraph/codegraph.db").exists(), "Home must never be indexed"
        assert not (root / ".codegraph").exists(), "MCP must not index its working directory"
        print(f"PASS: schema {before_version} -> {after_version}, file rows preserved, intact SQLite backup")
        print("PASS: no home/workspace indexing; all fixture state isolated in a temporary directory")


if __name__ == "__main__":
    main()
