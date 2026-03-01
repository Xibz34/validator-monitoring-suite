#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Shared loader (brings need_cmd etc.)
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/load_env.sh"
source "$ROOT_DIR/checks/tempo.checks.sh"
source "$ROOT_DIR/checks/shelby.checks.sh"
# Load project modules
# shellcheck disable=SC1091
source "$ROOT_DIR/checks/republic.checks.sh"
source "$ROOT_DIR/checks/tempo.checks.sh"
source "$ROOT_DIR/checks/shelby.checks.sh"
main() {
  need_cmd curl
  need_cmd systemctl

  failed=0

  echo "[runner] starting checks..."

  if declare -F republic_run_checks >/dev/null; then
    echo "[runner] republic checks..."
    republic_run_checks || failed=1
  fi
  
  if declare -F tempo_run_checks >/dev/null; then
    echo "[runner] tempo checks..."
    tempo_run_checks || failed=1
  fi

  if declare -F shelby_run_checks >/dev/null; then
    echo "[runner] shelby checks..."
    shelby_run_checks || failed=1
  fi

  echo "[runner] done."
  exit $failed
}

main "$@"