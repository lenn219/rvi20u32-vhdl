# RISC-V architecture tests (compliance)

Official suite: **[riscv-non-isa/riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test)**  
(legacy tag **3.9.1** still has the RISCOF-style `riscv-test-suite/rv32i_m/I` tests used here).

Current ACT default branch (`act4`) needs Sail + UDB/mise; we use the legacy suite for a practical RV32I bring-up.

## What this DUT can / cannot claim

| Area | Status |
|------|--------|
| Pure RV32I ALU / branch / load-store (aligned) | Targeted by `rv32i_m/I` |
| **Zicsr** | **Not implemented** (locked). Trap-enabled tests need CSRs |
| Privilege / interrupts / misaligned traps | Out of scope until Zicsr + trap path |
| Full RVI20U32 profile certification | Needs Zicsr (+ Zifencei); not claimed |

Basic `I/*.S` tests that do **not** define `rvtest_mtrap_routine` avoid CSR trap prologues and are the right first slice.

## Layout in this repo

```
compliance/
  env/model_test.h   # RVMODEL_* for this DUT
  env/link.ld        # RAM @ 0x80000000 (Spike-compatible)
  scripts/           # compile + unicorn signature + helpers
  work/              # build outputs (gitignored)
rtl/core/compliance_soc.vhd   # unified-RAM SoC for arch-tests
rtl/mem/unified_ram.vhd
```

## Quick start

```bash
# One-time: suite + tools
git clone --depth 1 -b 3.9.1 https://github.com/riscv-non-isa/riscv-arch-test.git /tmp/riscv-arch-test-legacy
sudo apt-get install -y gcc-riscv64-linux-gnu
pip install --user pyelftools unicorn vunit-hdl

export ARCH_TEST_ROOT=/tmp/riscv-arch-test-legacy

# Build one test + golden signature (Unicorn RV32 reference)
./compliance/scripts/compile_one.sh $ARCH_TEST_ROOT/riscv-test-suite/rv32i_m/I/src/addi-01.S
python3 compliance/scripts/run_unicorn_sig.py compliance/work/addi-01/test.elf \
  compliance/work/addi-01/ref.signature

# Run on VHDL DUT (VUnit)
python3 sim/run.py "lib.tb_arch_addi.*"
```

Reference signatures are generated with **Unicorn** (RV32) because this Spike build does not expose a working `--signature` plusarg path for bare-metal dumps. Spike remains useful to confirm the ELF halts via `tohost`.

## Next steps toward stronger compliance

1. Add minimal **Zicsr** + M-mode trap vector so misalign/ECALL tests can use official handlers  
2. Wire a full **RISCOF** plugin (`compliance/plugin/`) against Spike/Sail  
3. Sweep all `rv32i_m/I` tests in CI  
