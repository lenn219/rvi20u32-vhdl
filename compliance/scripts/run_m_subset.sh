#!/usr/bin/env bash
# Compile + Unicorn golden signatures for RV32IM arch-tests (legacy 3.9.1).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ARCH_TEST="${ARCH_TEST_ROOT:-/tmp/riscv-arch-test-legacy}"
export RISCV_MARCH=rv32im

TESTS=(mul mulh mulhsu mulhu div divu rem remu)

for t in "${TESTS[@]}"; do
  src="$ARCH_TEST/riscv-test-suite/rv32i_m/M/src/${t}-01.S"
  echo "=== $t-01 ==="
  "$ROOT/compliance/scripts/compile_one.sh" "$src"
  python3 "$ROOT/compliance/scripts/run_unicorn_sig.py" \
    "$ROOT/compliance/work/${t}-01/test.elf" \
    "$ROOT/compliance/work/${t}-01/ref.signature"
done
echo "M-subset compile+ref done."
