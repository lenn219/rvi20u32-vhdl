OUTPUT_ARCH("riscv")
ENTRY(rvtest_entry_point)

/* Spike-friendly contiguous map; compliance_soc mirrors this. */
MEMORY
{
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 1M
}

SECTIONS
{
  .text.init ORIGIN(RAM) :
  {
    KEEP(*(.text.init))
  } > RAM

  .text : ALIGN(4)
  {
    *(.text) *(.text.*)
  } > RAM

  .data : ALIGN(4)
  {
    *(.data) *(.data.*)
    *(.sdata) *(.sdata.*)
    *(.rodata) *(.rodata.*)
  } > RAM

  .tohost : ALIGN(8)
  {
    *(.tohost)
  } > RAM

  .bss : ALIGN(4)
  {
    *(.sbss) *(.sbss.*)
    *(.bss) *(.bss.*)
    *(COMMON)
  } > RAM

  /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }
}
