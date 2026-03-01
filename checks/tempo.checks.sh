#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/lib/load_env.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/discord.sh"

tempo_run_checks() {
  local failed=0

  # 1) Service health
  status="$(systemctl is-active "${TEMPO_SERVICE}" 2>/dev/null || echo "unknown")"
  if [[ "$status" != "active" ]]; then
    discord_send "🚨 Tempo Service Down" \
      "Service: **${TEMPO_SERVICE}**\nStatus: **${status}**" \
      "critical"
    failed=1
  fi

  # 2) RPC reachable
  if ! curl -sS "${TEMPO_RPC}/status" >/dev/null 2>&1; then
    discord_send "🚨 Tempo RPC Unreachable" \
      "RPC: **${TEMPO_RPC}**" \
      "critical"
    failed=1
  fi

  return $failed
}