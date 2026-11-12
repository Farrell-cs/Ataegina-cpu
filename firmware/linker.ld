MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x00001000, LENGTH = 4K
}

SECTIONS
{
    .text : ALIGN(4) {
        *(.text.init)
        *(.text*)
    } > ROM

    .data : ALIGN(4) {
        *(.rodata*)
        *(.srodata*)
        *(.data*)
        *(.sdata*)
    } > RAM

    .bss : ALIGN(4) {
        *(.sbss*)
        *(.bss*)
        *(COMMON)
    } > RAM

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /DISCARD/ : {
        *(.note*)
        *(.comment)
        *(.riscv.attributes)
    }
}
