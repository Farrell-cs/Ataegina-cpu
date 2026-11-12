.section .text.init
.globl _start

_start:
    # Initialize stack pointer to top of Data Memory (4 KB)
    la   sp, _stack_top

    # Jump to C main()
    call main

_hang:
    j _hang
