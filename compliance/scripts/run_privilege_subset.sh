#!/usr/bin/env bash
# Compile + Spike golden for privilege/trap slice (needs Zicsr + mtrap).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ARCH_TEST="${ARCH_TEST_ROOT:-/tmp/riscv-arch-test-legacy}"
export RISCV_MARCH=rv32i_zicsr
export EXTRA_DEFS="-Drvtest_mtrap_routine"
export SPIKE_ISA=rv32izicsr

TESTS=(ecall ebreak)

for t in "${TESTS[@]}"; do
  src="$ARCH_TEST/riscv-test-suite/rv32i_m/privilege/src/${t}.S"
  echo "=== $t ==="
  "$ROOT/compliance/scripts/compile_one.sh" "$src" "$ROOT/compliance/work/${t}"
  "$ROOT/compliance/scripts/run_spike_sig.sh" \
    "$ROOT/compliance/work/${t}/test.elf" \
    "$ROOT/compliance/work/${t}/ref.signature"
done
echo "Privilege subset compile+Spike ref done."
