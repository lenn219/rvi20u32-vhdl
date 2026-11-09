#!/usr/bin/env bash
# Run ELF on Spike; dump signature via plusargs (RISCOF-style).
set -euo pipefail

ELF="${1:?elf}"
OUT_SIG="${2:?out.signature}"
SPIKE="${SPIKE:-$HOME/.local/bin/spike}"

"$SPIKE" --isa=rv32i -m0x80000000:0x100000 \
  "$ELF" \
  +signature="$OUT_SIG" \
  +signature-granularity=4 \
  2>"${OUT_SIG}.spike.log"

echo "Wrote $OUT_SIG ($(wc -l < "$OUT_SIG") lines)"
