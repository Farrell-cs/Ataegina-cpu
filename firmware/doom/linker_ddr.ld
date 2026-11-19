ENTRY(_start)

MEMORY
{
    DDR (rwx) : ORIGIN = 0x10000000, LENGTH = 16M
}

SECTIONS
{
    .text : ALIGN(4) {
        KEEP(*(.text.init))
        *(.text*)
    } > DDR

    .rodata : ALIGN(4) {
        *(.rodata*)
        *(.srodata*)
    } > DDR

    .data : ALIGN(4) {
        *(.data*)
        *(.sdata*)
    } > DDR

    .bss (NOLOAD) : ALIGN(4) {
        _bss_start = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > DDR

    . = ALIGN(16);
    _end = .;
    end = .;

    _stack_top = ORIGIN(DDR) + LENGTH(DDR) - 16;

    /DISCARD/ : {
        *(.note*)
        *(.comment)
        *(.riscv.attributes)
    }
}
