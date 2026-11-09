# ISA scope (v1)

## In scope
- Full **RV32I** base
- `FENCE`, `FENCE.I` as **NOP**
- `ECALL` / `EBREAK` → halt + sticky flag

## Out of scope
- M, A, F, D, C
- **Zicsr** (CSR ops → illegal/halt)
- Privilege modes / trap vectoring
