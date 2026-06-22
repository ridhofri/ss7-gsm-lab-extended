#!/usr/bin/env bash
set -euo pipefail

echo "== Checking binaries =="
for b in osmo-stp osmo-hlr osmo-mgw osmo-msc; do
  if command -v "$b" >/dev/null 2>&1; then
    echo "  ✔ $b: $($b -V | head -n1)"
  else
    echo "  ✖ $b not found in PATH"
  fi
done

echo "== Checking ports (localhost) =="
ports=(2906 4222 2427 4254 4255)
for p in "${ports[@]}"; do
  if ss -ltn | awk '{print $4}' | grep -q ":$p$"; then
    echo "  ✔ TCP port $p is listening"
  else
    echo "  ! Port $p not listening (yet)"
  fi
done
