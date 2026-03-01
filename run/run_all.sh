#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Shared loader + alerting
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/load_env.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/discord.sh"

# Load project modules
# shellcheck disable=SC1091
source "$ROOT_DIR/checks/republic.checks.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/checks/tempo.checks.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/checks/shelby.checks.sh"

run_one() {
  local name="$1"
  local fn="$2"

  if ! declare -F "$fn" >/dev/null; then
    echo "[runner] missing function: $fn"
    echo "$name: ⚠️ SKIP (missing function)"
    return 0
  fi

  if "$fn"; then
    echo "$name: ✅ OK"
    return 0
  else
    echo "$name: ❌ FAIL"
    return 1
  fi
}

main() {
  need_cmd curl
  need_cmd systemctl

  echo "[runner] starting checks..."

  results=""
  failed=0

  line="$(run_one "Republic" republic_run_checks)" || failed=1
  results+="${line}\n"

  line="$(run_one "Tempo" tempo_run_checks)" || failed=1
  results+="${line}\n"

  line="$(run_one "Shelby" shelby_run_checks)" || failed=1
  results+="${line}\n"

  echo -e "$results"

  # Send ONE summary alert only when there is a failure
  if [[ "$failed" -ne 0 ]]; then
    discord_send_summary "🚨 Validator Monitoring Summary" "$(echo -e "$results")" "critical"
  fi

  echo "[runner] done."
  exit $failed
}

main "$@"