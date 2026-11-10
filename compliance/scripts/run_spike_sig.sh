#!/usr/bin/env bash
# Run ELF on Spike; dump begin_signature..end_signature via plusargs.
set -euo pipefail

ELF="${1:?elf}"
OUT_SIG="${2:?out.signature}"
SPIKE="${SPIKE:-$HOME/.local/bin/spike}"
ISA="${SPIKE_ISA:-rv32izicsr}"

"$SPIKE" --isa="$ISA" -m0x80000000:0x100000 \
  +signature="$OUT_SIG" \
  +signature-granularity=4 \
  "$ELF"

echo "Wrote $OUT_SIG ($(wc -l < "$OUT_SIG") lines)"
