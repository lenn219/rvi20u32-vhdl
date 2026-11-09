#!/usr/bin/env bash
# Compile + Unicorn-ref a small RV32I arch-test subset (no trap suite).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ARCH_TEST="${ARCH_TEST_ROOT:-/tmp/riscv-arch-test-legacy}"
SRC="$ARCH_TEST/riscv-test-suite/rv32i_m/I/src"
TESTS=(addi-01 add-01 lui-01 auipc-01 xor-01 beq-01)

mkdir -p "$ROOT/compliance/work"
pass=0; fail=0
for t in "${TESTS[@]}"; do
  echo "=== $t ==="
  if ! "$ROOT/compliance/scripts/compile_one.sh" "$SRC/$t.S" "$ROOT/compliance/work/$t"; then
    echo "COMPILE FAIL $t"; fail=$((fail+1)); continue
  fi
  if ! python3 "$ROOT/compliance/scripts/run_unicorn_sig.py" \
      "$ROOT/compliance/work/$t/test.elf" "$ROOT/compliance/work/$t/ref.signature"; then
    echo "UNICORN FAIL $t"; fail=$((fail+1)); continue
  fi
  echo "OK $t"; pass=$((pass+1))
done
echo "subset compile+ref: pass=$pass fail=$fail"
