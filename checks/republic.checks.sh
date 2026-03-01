#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load shared modules
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/load_env.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/discord.sh"

republic_run_checks() {

  local failed=0

  # ----------------------------
  # 1️⃣ Service Health Check
  # ----------------------------
  status="$(systemctl is-active "${REPUBLIC_SERVICE}" 2>/dev/null || echo "unknown")"

  if [[ "$status" != "active" ]]; then
    discord_send "🚨 Republic Service Down" \
      "Service: **${REPUBLIC_SERVICE}**\nStatus: **${status}**" \
      "critical"
    failed=1
  fi

  # ----------------------------
  # 2️⃣ RPC Reachability Check
  # ----------------------------
  if ! curl -sS "${REPUBLIC_RPC}/status" >/dev/null 2>&1; then
    discord_send "🚨 Republic RPC Unreachable" \
      "RPC: **${REPUBLIC_RPC}**" \
      "critical"
    failed=1
  fi

  # ----------------------------
  # 3️⃣ Jailed Status Check
  # ----------------------------
  need_cmd jq

  jailed_output="$("${REPUBLIC_CHAIN_BINARY}" query staking validator "${REPUBLIC_VALOPER}" \
    --node "${REPUBLIC_RPC}" \
    --chain-id "${REPUBLIC_CHAIN_ID}" \
    -o json 2>/dev/null || true)"

  if [[ -z "$jailed_output" ]]; then
    discord_send "⚠️ Republic Jailed Check Failed" \
      "Could not query validator info.\nVALOPER: **${REPUBLIC_VALOPER}**" \
      "warn"
    failed=1
  else
    jailed="$(echo "$jailed_output" | jq -r '.jailed' 2>/dev/null || echo "null")"

    if [[ "$jailed" == "true" ]]; then
      discord_send "🚨 Republic VALIDATOR JAILED" \
        "VALOPER: **${REPUBLIC_VALOPER}**" \
        "critical"
      failed=1
    fi
  fi

  return $failed
}