#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/load_env.sh"

# Get latest height from a tendermint RPC endpoint
rpc_height() {
  local rpc="$1"
  # returns height or empty
  curl -sS "$rpc/status" 2>/dev/null | jq -r '.result.sync_info.latest_block_height // empty' 2>/dev/null || true
}

# Compare node against a reference RPC and fail if lag > threshold
check_height_lag() {
  local name="$1"
  local node_rpc="$2"
  local ref_rpc="$3"
  local max_lag="$4"

  if [[ -z "$ref_rpc" ]]; then
    echo "$name: height-lag SKIP (no reference RPC)"
    return 0
  fi

  local h_node h_ref
  h_node="$(rpc_height "$node_rpc")"
  h_ref="$(rpc_height "$ref_rpc")"

  if [[ -z "$h_node" || -z "$h_ref" ]]; then
    echo "$name: height-lag FAIL (could not read height)"
    return 1
  fi

  # numeric compare
  if ! [[ "$h_node" =~ ^[0-9]+$ && "$h_ref" =~ ^[0-9]+$ ]]; then
    echo "$name: height-lag FAIL (non-numeric height)"
    return 1
  fi

  local lag=$(( h_ref - h_node ))
  if (( lag < 0 )); then lag=0; fi

  if (( lag > max_lag )); then
    echo "$name: height-lag FAIL (node=$h_node ref=$h_ref lag=$lag > $max_lag)"
    return 1
  fi

  echo "$name: height-lag OK (lag=$lag <= $max_lag)"
  return 0
}

# Disk usage check for a mountpoint (default: /)
check_disk_usage() {
  local name="$1"
  local mountpoint="$2"
  local max_pct="$3"

  local used
  used="$(df -P "$mountpoint" 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}')"

  if [[ -z "$used" || ! "$used" =~ ^[0-9]+$ ]]; then
    echo "$name: disk FAIL (could not read df for $mountpoint)"
    return 1
  fi

  if (( used >= max_pct )); then
    echo "$name: disk FAIL (used=${used}% >= ${max_pct}% on $mountpoint)"
    return 1
  fi

  echo "$name: disk OK (used=${used}% < ${max_pct}% on $mountpoint)"
  return 0
}