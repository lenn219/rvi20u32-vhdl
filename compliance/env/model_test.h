#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

/*
 * DUT / Spike model macros for rvi20u32-vhdl + riscv-arch-test (tag 3.9.1).
 *
 * Memory map:
 *   IMEM  0x00000000  (code)
 *   DMEM  0x10000000  (data + signatures + tohost)
 */

#define RVMODEL_DATA_SECTION \
  .pushsection .tohost,"aw",@progbits; \
  .align 4; .global tohost; tohost: .word 0; \
  .align 4; .global fromhost; fromhost: .word 0; \
  .popsection;

#define RVMODEL_HALT \
  li t1, 1; \
  la t0, tohost; \
  sw t1, 0(t0); \
1: j 1b;

#define RVMODEL_BOOT

#define RVMODEL_DATA_BEGIN \
  RVMODEL_DATA_SECTION \
  .align 4; \
  .global begin_signature; begin_signature:

#define RVMODEL_DATA_END \
  .align 4; \
  .global end_signature; end_signature:

#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_R, _STR)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#define RVMODEL_SET_MSW_INT
#define RVMODEL_CLEAR_MSW_INT
#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

#define RVMODEL_FENCEI nop

#endif
