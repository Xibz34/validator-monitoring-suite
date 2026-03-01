#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/lib/load_env.sh"
source "$ROOT_DIR/lib/health.sh"

republic_run_checks() {
  local failed=0

  # 1️⃣ Service Check
  status="$(systemctl is-active "$REPUBLIC_SERVICE" 2>/dev/null || echo "unknown")"

  if [[ "$status" != "active" ]]; then
    echo "Republic: service NOT active ($status)"
    failed=1
  fi

  # 2️⃣ RPC Check
  if ! curl -sS "$REPUBLIC_RPC/status" >/dev/null 2>&1; then
    echo "Republic: RPC unreachable"
    failed=1
  fi

  # 4️⃣ Height lag vs reference (optional)
  check_height_lag "Republic" "$REPUBLIC_RPC" "${REPUBLIC_REF_RPC:-}" "${MAX_HEIGHT_LAG:-30}" || failed=1

  # 5️⃣ Disk usage
  check_disk_usage "Republic" "${DISK_MOUNTPOINT:-/}" "${DISK_WARN_PCT:-85}" || failed=1

  # 3️⃣ Jailed Check
  need_cmd jq

  jailed_output="$("$REPUBLIC_CHAIN_BINARY" query staking validator "$REPUBLIC_VALOPER" \
    --node "$REPUBLIC_RPC" \
    --chain-id "$REPUBLIC_CHAIN_ID" \
    -o json 2>/dev/null || true)"

  if [[ -z "$jailed_output" ]]; then
    echo "Republic: jailed check failed (no response)"
    failed=1
  else
    jailed="$(echo "$jailed_output" | jq -r '.jailed' 2>/dev/null || echo "null")"
    if [[ "$jailed" == "true" ]]; then
      echo "Republic: VALIDATOR JAILED"
      failed=1
    fi
  fi

  return $failed
}