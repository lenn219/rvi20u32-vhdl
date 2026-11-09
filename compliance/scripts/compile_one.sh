#!/usr/bin/env bash
# Compile one riscv-arch-test (legacy) assembly file for this DUT / Spike.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COMP="$ROOT/compliance"
ARCH_TEST="${ARCH_TEST_ROOT:-/tmp/riscv-arch-test-legacy}"
GCC="${RISCV_GCC:-riscv64-linux-gnu-gcc}"
OBJCOPY="${RISCV_OBJCOPY:-riscv64-linux-gnu-objcopy}"
OBJDUMP="${RISCV_OBJDUMP:-riscv64-linux-gnu-objdump}"

TEST_SRC="${1:?usage: compile_one.sh path/to/test.S [outdir]}"
OUT_DIR="${2:-$COMP/work/$(basename "$TEST_SRC" .S)}"
mkdir -p "$OUT_DIR"

"$GCC" -march=rv32i -mabi=ilp32 -static -mcmodel=medany \
  -fvisibility=hidden -nostdlib -nostartfiles \
  -DXLEN=32 -DTEST_CASE_1=True \
  -T "$COMP/env/link.ld" \
  -I "$COMP/env" \
  -I "$ARCH_TEST/riscv-test-suite/env" \
  "$TEST_SRC" -o "$OUT_DIR/test.elf"

"$OBJCOPY" -O binary "$OUT_DIR/test.elf" "$OUT_DIR/test.bin"
"$OBJDUMP" -d "$OUT_DIR/test.elf" > "$OUT_DIR/test.dis" || true
python3 "$COMP/scripts/elf_to_memhex.py" "$OUT_DIR/test.elf" "$OUT_DIR"
echo "Built $OUT_DIR/test.elf"
