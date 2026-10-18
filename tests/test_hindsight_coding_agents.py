"""Exercise official hooks and MCP against a local HTTP fixture, not a real memory backend.

Usage: python3 tests/test_hindsight_coding_agents.py /nix/store/...-hindsight-coding-agents-...
"""

import json
import os
from pathlib import Path
import queue
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlparse


FACT = "The harmless Hindsight integration test mascot is a lavender paper otter."
requests = []


class BackendFixture(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def handle_request(self):
        path = unquote(urlparse(self.path).path)
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        assert self.headers.get("Authorization") == "Bearer fixture-token"
        requests.append((self.command, path, body))
        bank = path.split("/banks/", 1)[-1].split("/", 1)[0]
        retained = [
            item.get("content", "")
            for method, route, payload in requests
            if method == "POST" and route == f"/v1/default/banks/{bank}/memories"
            for item in payload.get("items", [])
        ]
        if path.endswith("/reflect"):
            response = {"text": FACT if any(FACT in text for text in retained) else "No relevant memory."}
        elif path.endswith("/version"):
            response = {"version": "0.11.0"}
        elif path.endswith("/memories") and self.command == "POST":
            response = {"operation_id": body.get("operation_id", "fixture-operation")}
        elif "/operations/" in path:
            response = {"status": "completed"}
        elif path.endswith("/knowledge-base/tree"):
            response = {"roots": []}
        else:
            response = {"items": [], "results": [], "total": 0, "status": "completed"}
        encoded = json.dumps(response).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    do_GET = do_POST = do_PUT = do_PATCH = handle_request


def run(binary, args, env, cwd, payload=None):
    result = subprocess.run(
        [str(binary), *args], input=json.dumps(payload) if payload is not None else "",
        env=env, cwd=cwd, capture_output=True, text=True, timeout=30,
    )
    assert result.returncode == 0, (args, result.stdout[-1500:], result.stderr[-2000:])
    return result.stdout


def mcp_check(runtime, env, cwd):
    messages = queue.Queue()
    with tempfile.TemporaryFile(mode="w+") as errors:
        process = subprocess.Popen(
            [str(runtime / "bin/hindsight-mcp-server")], env=env, cwd=cwd,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=errors,
            text=True, bufsize=1,
        )
        def read():
            for line in process.stdout:
                messages.put(json.loads(line))
        reader = threading.Thread(target=read, daemon=True)
        reader.start()
        def send(message):
            process.stdin.write(json.dumps({"jsonrpc": "2.0", **message}) + "\n")
            process.stdin.flush()
        def request(number, method, params):
            send({"id": number, "method": method, "params": params})
            while True:
                try:
                    message = messages.get(timeout=15)
                except queue.Empty:
                    errors.seek(0)
                    raise AssertionError((method, errors.read()[-2000:]))
                if message.get("id") == number:
                    assert "error" not in message, message
                    return message["result"]
        try:
            request(1, "initialize", {
                "protocolVersion": "2024-11-05", "capabilities": {},
                "clientInfo": {"name": "hindsight-nix-check", "version": "1"},
            })
            send({"method": "notifications/initialized"})
            tools = request(2, "tools/list", {})["tools"]
            names = [tool["name"] for tool in tools]
            assert any("reflect" in name for name in names), names
            assert any("ingest_document" in name for name in names), names
            assert any("knowledge_page" in name for name in names), names
            print("PASS: official MCP handshake and tool discovery:", ", ".join(names))
            reflected = request(3, "tools/call", {
                "name": "hindsight_reflect", "arguments": {"query": "What is the project test mascot?"},
            })
            assert not reflected.get("isError") and FACT in json.dumps(reflected), reflected
            ingested = request(4, "tools/call", {
                "name": "hindsight_ingest_document",
                "arguments": {"title": "Nix integration fixture", "content": "Harmless MCP ingestion fixture."},
            })
            assert not ingested.get("isError"), ingested
            assert any(
                method == "POST" and path == "/v1/default/banks/coding-agent::repo-one/memories"
                and "Harmless MCP ingestion fixture." in json.dumps(body)
                and "harness:codex" in json.dumps(body)
                for method, path, body in requests
            ), "MCP ingestion must use this repository's bank and Codex attribution"
            print("PASS: official MCP reflection and document ingestion against the local fixture")
        finally:
            process.stdin.close()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=5)
            reader.join(timeout=2)
            process.stdout.close()


def main():
    runtime = Path(sys.argv[1]).resolve()
    server = ThreadingHTTPServer(("127.0.0.1", 0), BackendFixture)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        with tempfile.TemporaryDirectory(prefix="hindsight-check-") as directory:
            root = Path(directory).resolve()
            home = root / "home"
            home.mkdir()
            temporary_state = root / "tmp"
            temporary_state.mkdir()
            shared_skill = home / ".agents/skills/hindsight-coding-agent/SKILL.md"
            shared_skill.parent.mkdir(parents=True)
            shared_skill.write_text("Existing shared skill fixture; do not overwrite.\n")
            config = root / "coding-agent.json"
            config.write_text(json.dumps({
                "serverMode": "self-hosted", "apiUrl": f"http://127.0.0.1:{server.server_port}",
                "apiToken": "fixture-token", "autoUpdate": True, "autoSeed": False,
                "codebaseSurvey": False, "gitIngest": "none", "manageBankConfig": False,
            }))
            os.chmod(config, 0o600)
            env = {key: value for key, value in os.environ.items() if not key.startswith("HINDSIGHT_")}
            env.update({
                "HOME": str(home), "CODEX_HOME": str(home / "custom-codex"),
                "HINDSIGHT_CONFIG": str(config), "HINDSIGHT_MCP_HARNESS": "codex",
                "TMPDIR": str(temporary_state), "TMP": str(temporary_state), "TEMP": str(temporary_state),
            })
            first, second, worktree = root / "repo-one", root / "repo-two", root / "linked-worktree"
            for repo in (first, second):
                repo.mkdir()
                run("git", ["init", "--quiet", str(repo)], env, root)
            # An unborn branch can have a linked worktree without creating any commits.
            run("git", ["-C", str(first), "worktree", "add", "--orphan", "-b", "fixture-worktree", str(worktree)], env, root)

            def hook(name, cwd, session, **extra):
                return run(runtime / f"bin/hindsight-{name}", [], env, cwd, {
                    "session_id": session, "cwd": str(cwd), **extra,
                })
            hook("codex-sessionstart-hook", first, "session-one", source="startup")
            transcript = root / "rollout.jsonl"
            transcript.write_text("\n".join(json.dumps({
                "type": "response_item", "payload": {"type": "message", "role": role,
                "content": [{"type": kind, "text": text}]},
            }) for role, kind, text in [
                ("user", "input_text", FACT), ("assistant", "output_text", "I will remember that project-specific test fact."),
            ]) + "\n")
            hook("codex-stop-hook", first, "session-one", transcript_path=str(transcript))
            retained = [(path, body) for method, path, body in requests if method == "POST" and path.endswith("/memories")]
            assert any(FACT in json.dumps(body) for _, body in retained), requests
            def fact_documents():
                return {
                    item["document_id"]
                    for method, path, body in requests
                    if method == "POST" and path.endswith("/memories")
                    for item in body.get("items", []) if FACT in item.get("content", "")
                }
            documents = fact_documents()
            hook("codex-stop-hook", first, "session-one", transcript_path=str(transcript))
            assert fact_documents() == documents, "Repeat Stop must reuse the same document identity"
            hook("codex-sessionstart-hook", first, "session-two", source="startup")
            output = hook("codex-hook", first, "session-two", prompt="What is the project test mascot?")
            assert FACT in output, output
            json.loads(output)
            other_output = hook("codex-hook", second, "session-other", prompt="What is the project test mascot?")
            assert FACT not in other_output, "Another repository must not receive the first bank's fact"
            worktree_output = hook("codex-hook", worktree, "session-worktree", prompt="What is the project test mascot?")
            assert FACT in worktree_output, "A linked worktree must reuse the main repository's memory"
            reflected = [path for method, path, _ in requests if method == "POST" and path.endswith("/reflect")]
            assert any("coding-agent::repo-one" in path for path in reflected), reflected
            assert any("coding-agent::repo-two" in path for path in reflected), reflected
            assert not any("coding-agent::linked-worktree" in path for path in reflected), reflected
            assert json.loads(config.read_text())["autoUpdate"] is True, "Existing private config must not be rewritten"
            assert shared_skill.read_text() == "Existing shared skill fixture; do not overwrite.\n"
            mcp_check(runtime, env, first)
            before = len(requests)
            unconfigured = {**env, "HINDSIGHT_CONFIG": str(root / "missing-config.json")}
            for entry in ("codex-sessionstart-hook", "codex-hook", "codex-stop-hook"):
                run(runtime / f"bin/hindsight-{entry}", [], unconfigured, first, {
                    "session_id": "unconfigured", "cwd": str(first), "prompt": "Do not choose a backend.",
                    "transcript_path": str(transcript),
                })
            assert len(requests) == before, "Unconfigured hooks must not contact a backend"
            print("PASS: all three official hooks, Stop retention/dedup, new-session prompt context injection")
            print("PASS: isolated repository banks, linked-worktree bank reuse, custom CODEX_HOME, private config preserved")
            print("PASS: missing configuration stays inactive; shared legacy skill is unchanged")
            print("LIMIT: local HTTP fixture only; real backend memory persistence and Codex hook trust still require live validation")
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main()
