.section .text.init
.globl _start

_start:
    # Jump straight to DDR3 entry point (0x10000000)
    lui  t0, 0x10000
    jalr zero, 0(t0)
