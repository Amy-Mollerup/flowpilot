#!/usr/bin/env python3
"""
Run FlowPilot under systemd.

- Kills any existing flowpilot tmux session
- Starts Claude Code with the Discord channel plugin inside a fresh tmux session
- Sends /flowpilot once. The skill then schedules itself (see SKILL.md, Dynamic Loop Timing)
- Watches the session and exits non-zero if it dies, so systemd restarts it

Attach to watch it live:  tmux attach -t flowpilot
"""
import os
import subprocess
import sys
import time

SESSION = os.environ.get("FLOWPILOT_TMUX_SESSION", "flowpilot")
CLAUDE_CMD = (
    'export PATH="$HOME/.bun/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"; '
    "claude --channels plugin:discord@claude-plugins-official --dangerously-skip-permissions"
)
STARTUP_WAIT = int(os.environ.get("FLOWPILOT_STARTUP_WAIT", "15"))


def tmux(*args):
    return subprocess.run(["tmux", *args], capture_output=True)


tmux("kill-session", "-t", SESSION)
time.sleep(2)

tmux("new-session", "-d", "-s", SESSION, "-x", "220", "-y", "50")
tmux("send-keys", "-t", SESSION, CLAUDE_CMD, "Enter")

# Give Claude Code time to start (and dismiss any first-run prompt)
time.sleep(STARTUP_WAIT)
tmux("send-keys", "-t", SESSION, "", "Enter")
time.sleep(5)

tmux("send-keys", "-t", SESSION, "/flowpilot", "Enter")
print(f"FlowPilot started in tmux session '{SESSION}'. Attach with: tmux attach -t {SESSION}", flush=True)

while True:
    if tmux("has-session", "-t", SESSION).returncode != 0:
        print("tmux session died, exiting so systemd can restart it", flush=True)
        sys.exit(1)
    time.sleep(10)
