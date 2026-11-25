#!/usr/bin/env bash
# FlowPilot installer. Run from the repo folder as the user who will run Claude Code:
#   ./install.sh
# It installs the skills into ~/.claude/skills and the systemd units (with sudo).
set -euo pipefail

FLOWPILOT_HOME="$(cd "$(dirname "$0")" && pwd)"
USER_NAME="$(id -un)"

[[ -f "$FLOWPILOT_HOME/.env" ]] || { echo "Copy .env.example to .env and fill it in first."; exit 1; }
command -v tmux >/dev/null || { echo "Install tmux first (sudo apt install tmux)."; exit 1; }
command -v claude >/dev/null || echo "Warning: 'claude' not on PATH. Install Claude Code and log in before starting the service."

chmod +x "$FLOWPILOT_HOME"/scripts/*.sh "$FLOWPILOT_HOME"/scripts/*.py

mkdir -p "$HOME/.claude/skills"
for s in flowpilot agent-ticket; do
  rm -rf "$HOME/.claude/skills/$s"
  cp -r "$FLOWPILOT_HOME/skills/$s" "$HOME/.claude/skills/$s"
  echo "Installed skill: $s"
done

for unit in "$FLOWPILOT_HOME"/systemd/*; do
  sed -e "s#__USER__#$USER_NAME#g" -e "s#__HOME__#$HOME#g" -e "s#__FLOWPILOT_HOME__#$FLOWPILOT_HOME#g" \
    "$unit" | sudo tee "/etc/systemd/system/$(basename "$unit")" >/dev/null
  echo "Installed unit: $(basename "$unit")"
done

sudo systemctl daemon-reload
sudo systemctl enable flowpilot.service flowpilot-daily-restart.timer
echo
echo "Done. Start it with:  sudo systemctl start flowpilot && sudo systemctl start flowpilot-daily-restart.timer"
echo "Watch it with:        tmux attach -t flowpilot   (detach: Ctrl+B then D)"
