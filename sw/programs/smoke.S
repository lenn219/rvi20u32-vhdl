# smoke: sum 1..5 -> x10; store DMEM+LEDs; ecall
    .section .text
    .globl _start
_start:
    addi x10, x0, 0
    addi x11, x0, 1
    addi x12, x0, 6
1:
    add  x10, x10, x11
    addi x11, x11, 1
    blt  x11, x12, 1b
    lui  x13, 0x10000
    sw   x10, 0(x13)
    lui  x14, 0x20000
    sw   x10, 0(x14)
    ecall
