# ISA scope

## In scope
- Full **RV32I** base
- **RV32M** (`mul`/`mulh`/`mulhsu`/`mulhu`/`div`/`divu`/`rem`/`remu`)
- **Zicsr** (CSRRW/CSRRS/CSRRC + immediate forms) for the M-mode CSR subset below
- **M-mode traps**: `ECALL`, `EBREAK`, illegal, misaligned load/store; `mret`
- `FENCE`, `FENCE.I` as **NOP**

### CSRs implemented
`mstatus`, `misa` (RO), `mie`, `mtvec` (direct), `mscratch`, `mepc`, `mcause`, `mtval`, `mip`, `mhartid` (RO).  
Other CSR addresses: read-0 / ignore-write stubs (bring-up; avoids trap storms).

### Halt convention
If `mtvec == 0`, `ECALL`/`EBREAK`/illegal **halt** the core (smoke / bare-metal without a handler).  
Once software programs `mtvec`, exceptions vector normally.

## Out of scope (for now)
- A, F, D, C, V
- S/U privilege, MMU, interrupts as a product feature
- Full RVI20U32 certification claim (needs more suite coverage + Zifencei semantics)
