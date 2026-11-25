#!/usr/bin/env bash
# Send a Discord message straight through the bot API. Works even when Claude isn't running,
# which is why systemd uses it for crash alerts.
# Usage: discord-notify.sh "message text"
# Needs DISCORD_BOT_TOKEN (from the Discord channel plugin's .env) and DISCORD_ALERT_CHANNEL_ID.

set -euo pipefail

PLUGIN_ENV="${DISCORD_PLUGIN_ENV:-$HOME/.claude/channels/discord/.env}"
FP_ENV="${FLOWPILOT_ENV:-${FLOWPILOT_HOME:-$HOME/flowpilot}/.env}"

for f in "$PLUGIN_ENV" "$FP_ENV"; do
  # shellcheck disable=SC1090
  [[ -f "$f" ]] && set -a && source "$f" && set +a
done

: "${DISCORD_BOT_TOKEN:?DISCORD_BOT_TOKEN not set}"
: "${DISCORD_ALERT_CHANNEL_ID:?DISCORD_ALERT_CHANNEL_ID not set}"

MESSAGE="${1:-No message provided}"
PAYLOAD=$(python3 -c 'import json,sys; print(json.dumps({"content": sys.argv[1]}))' "$MESSAGE")

curl -sf -X POST \
  "https://discord.com/api/v10/channels/${DISCORD_ALERT_CHANNEL_ID}/messages" \
  -H "Authorization: Bot ${DISCORD_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" > /dev/null
