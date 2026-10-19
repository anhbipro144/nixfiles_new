---
name: hindsight-uv-cache-prune
description: Reclaim disk space from the uv cache used by the Hindsight daemon (torch/CUDA duplicates, 20G+ growth). Stops only the Hindsight daemon, runs `uv cache prune`, and restarts it offline. Use when the disk is full or nearly full, `df` shows little free space, or `~/.cache/uv` is unexpectedly large.
---

# Prune the uv cache for Hindsight

## Why this exists

The Hindsight daemon (`uvx hindsight-embed` → `hindsight-api`) pulls in `sentence_transformers`,
which pulls in PyTorch with CUDA libraries (about 3–4G per copy). The daemon runs with
`--idle-timeout 0` and `embedVersion` defaults to `latest`, so every upstream release adds another
copy to `~/.cache/uv/archive-v0`. uv never removes old copies on its own.

`uv cache prune` removes only unreferenced entries, so it frees the old copies and keeps the
active environment. It needs the cache lock, and the running daemon holds that lock, so the daemon
must be stopped first.

Memory data is **not** in the uv cache. It lives in `~/.pg0` (Postgres) and must not be touched.

## Steps

### 1. Measure first

```bash
df -h / | tail -1
du -sh ~/.cache/uv
```

If free space is comfortable and the cache is small (under about 10G), stop here.

### 2. Identify the lock holders

```bash
for p in $(fuser ~/.cache/uv/.lock 2>/dev/null | tr -s ' ' '\n' | grep -E '^[0-9]+$'); do
  echo "$p $(ps -o cmd= -p $p | cut -c1-140)"
done
```

Only Hindsight processes may be stopped. Their command lines contain `hindsight`. If any holder is
**not** a Hindsight process, stop and report it to the user. Do not kill it.

The `node .../hindsight/coding-agents/dist/mcp-server.js` processes do **not** hold the uv lock, so
leave them running.

### 3. Stop the Hindsight daemon

Use `kill` with the explicit PIDs from step 2 only. Never use `pkill` or `killall`.

```bash
kill <pid> [<pid> ...]
for i in $(seq 1 30); do fuser ~/.cache/uv/.lock >/dev/null 2>&1 || break; sleep 1; done
fuser ~/.cache/uv/.lock 2>/dev/null && echo "lock still held, aborting" || echo "lock free"
```

If the lock is still held after 30 seconds, stop and report. Do not use `--force`.

### 4. Prune

```bash
timeout 280 uv cache prune
du -sh ~/.cache/uv
df -h / | tail -1
```

Use `uv cache prune`, not `uv cache clean`. `clean` deletes the whole cache, which forces a full
multi-GB re-download on the next start.

### 5. Restart the daemon offline

```bash
cd ~/.hindsight/coding-agents/dist && HF_HUB_OFFLINE=1 node daemon-start.js --harness coding-agent
for i in $(seq 1 24); do
  c=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://127.0.0.1:9077/health)
  [ "$c" = "200" ] && { echo "UP"; break; }; sleep 5
done
echo "health: $c"
```

`HF_HUB_OFFLINE=1` is required. Without it, the daemon checks HuggingFace on startup, and that
check fails SSL certificate verification on this machine. The cached models (about 217M in
`~/.cache/huggingface`) are used instead.

If health is not 200 after 2 minutes, check `~/.hindsight/profiles/coding-agent.log` and
`~/.hindsight/coding-agents-logs/diag.jsonl`, and report what you find.

## Notes

- The plugin's own auto-start does **not** set `HF_HUB_OFFLINE`. If the daemon is down at the start
  of a session, it may fail with the same SSL error. Tell the user rather than retrying blindly.
- Expect the cache to refill over time. This skill should be re-run when the disk gets tight again.
- Do not delete `~/.pg0`, `~/.chroma_data`, or `~/.hindsight/` contents while doing this.
