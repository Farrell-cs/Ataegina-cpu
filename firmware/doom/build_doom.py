import subprocess
import sys
from pathlib import Path

DIR = Path(__file__).resolve().parent
RV_GCC = r"C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin\riscv64-unknown-elf-gcc.exe"
RV_OBJCOPY = r"C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin\riscv64-unknown-elf-objcopy.exe"

EXCLUDE_PREFIXES = ("doomgeneric_", "i_allegromusic", "i_allegrosound", "i_sdlmusic", "i_sdlsound")

def main():
    c_files = sorted(
        f.name for f in DIR.glob("*.c")
        if not f.name.startswith(EXCLUDE_PREFIXES) or f.name == "doomgeneric_riscv.c"
    )
    print(f"[1/2] Compiling {len(c_files)} DOOM source files for RV32IM DDR3 (0x10000000)...")
    cmd = [
        RV_GCC, "-march=rv32im", "-mabi=ilp32", "-O2",
        "-DDOOMGENERIC_RESX=320", "-DDOOMGENERIC_RESY=200",
        "-DFORCE_SOFTWARE_RENDERER",
        "-ffunction-sections", "-fdata-sections",
        "-nostartfiles", "-Wl,--gc-sections", "-Wl,--build-id=none",
        "-T", "linker_ddr.ld",
        "crt0_ddr.s", *c_files,
        "-lc", "-lm", "-lgcc",
        "-o", "doom.elf",
    ]
    subprocess.check_call(cmd, cwd=str(DIR))

    print("[2/2] Extracting doom.bin...")
    subprocess.check_call([RV_OBJCOPY, "-O", "binary", "doom.elf", "doom.bin"], cwd=str(DIR))
    size_kb = (DIR / "doom.bin").stat().st_size / 1024.0
    print(f"\nSUCCESS! Built firmware/doom/doom.bin ({size_kb:.1f} KB)")
    print("Load via xsdb:")
    print("  dow -data firmware/doom/doom.bin  0x10000000")
    print("  dow -data firmware/doom/doom1.wad 0x11000000")

if __name__ == "__main__":
    main()
