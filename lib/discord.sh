#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/load_env.sh"

need_cmd curl
need_cmd jq

discord_send() {
  local title="$1"
  local message="$2"
  local level="${3:-info}" # info|warn|critical

  [[ -z "${DISCORD_WEBHOOK_URL:-}" ]] && { echo "DISCORD_WEBHOOK_URL missing"; return 0; }

  local payload
  payload="$(jq -n \
    --arg title "$title" \
    --arg desc "$message" \
    --arg footer "${ALERT_NAME:-Xibz-Infra} • $(ts_utc)" \
    '{
      "embeds":[
        {
          "title": $title,
          "description": $desc,
          "footer": {"text": $footer}
        }
      ]
    }')"

  curl -sS -X POST -H "Content-Type: application/json" -d "$payload" "$DISCORD_WEBHOOK_URL" >/dev/null
}
discord_send_summary() {
  local title="$1"
  local summary="$2"
  local level="${3:-info}" # info|warn|critical

  # Use same sender for now
  discord_send "$title" "$summary" "$level"
}