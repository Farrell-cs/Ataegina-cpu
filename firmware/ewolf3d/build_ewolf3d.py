import os
import subprocess
import sys
from pathlib import Path

DIR = Path(__file__).resolve().parent
RV_GCC = r"C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin\riscv64-unknown-elf-gcc.exe"
RV_OBJCOPY = r"C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin\riscv64-unknown-elf-objcopy.exe"
HOST_GCC = r"C:\msys64\ucrt64\bin\gcc.exe"

REQUIRED_WL1 = ["gamemaps.wl1", "maphead.wl1", "vgahead.wl1", "vswap.wl1"]

BUILD_TOOLS = [
    ("build_tables", "tables.c"),
    ("build_pagemap", "pagemap.c"),
    ("build_grstarts", "grstarts.c"),
    ("build_pal4bit", "pal4bit.c"),
    ("build_sprites", "sprites.c"),
    ("build_walls", "walls.c"),
    ("build_mapdata", "mapdata.c"),
    ("build_mapheaders", "mapheaders.c"),
]

GAME_SRCS = [
    "crt0_ddr.s", "objs.c", "misc.c", "id_ca.c", "id_vh.c", "id_us.c",
    "wl_act1.c", "wl_act2.c", "wl_act3.c", "wl_agent.c", "wl_game.c",
    "wl_inter.c", "wl_menu.c", "wl_play.c", "wl_state.c", "wl_main.c",
    "wl_debug.c", "wl_draw.c", "vi_comm.c", "vi_riscv.c", "arm_support.c",
    "tables.c", "pagemap.c", "grstarts.c", "pal4bit.c",
    "sprites.c", "walls.c", "mapdata.c",
]


def run(cmd):
    print("+", " ".join(str(c) for c in cmd))
    subprocess.check_call([str(c) for c in cmd], cwd=str(DIR))


def main():
    missing = [f for f in REQUIRED_WL1 if not (DIR / f).exists()]
    if missing:
        print("ERROR: Missing Wolfenstein 3D Shareware (.wl1) files in firmware/ewolf3d/:")
        for m in missing:
            print(f"  - {m}")
        print("\nCopy those 4 files into firmware/ewolf3d/ and re-run this script.")
        sys.exit(1)

    print("[1/3] Packing Wolfenstein 3D Shareware assets into C arrays...")
    for tool, out_c in BUILD_TOOLS:
        exe = DIR / f"{tool}.exe"
        run([HOST_GCC, "-DHOST", "-O2", f"{tool}.c", "-o", exe])
        with open(DIR / out_c, "w", encoding="ascii") as out_f:
            subprocess.check_call([str(exe)], cwd=str(DIR), stdout=out_f)

    print("[2/3] Compiling ewolf3d for RV32IM DDR3 (0x10000000)...")
    run([
        RV_GCC, "-march=rv32im", "-mabi=ilp32", "-Os",
        "-fno-common", "-ffunction-sections", "-fdata-sections",
        "-nostdlib", "-Wl,--gc-sections", "-Wl,--build-id=none",
        "-T", "linker_ddr.ld",
        *GAME_SRCS, "-lgcc", "-o", "ewolf3d.elf",
    ])

    print("[3/3] Extracting ewolf3d.bin...")
    run([RV_OBJCOPY, "-O", "binary", "ewolf3d.elf", "ewolf3d.bin"])
    size_kb = (DIR / "ewolf3d.bin").stat().st_size / 1024.0
    print(f"\nSUCCESS! Built firmware/ewolf3d/ewolf3d.bin ({size_kb:.1f} KB)")
    print("Load via xsdb: dow -data firmware/ewolf3d/ewolf3d.bin 0x10000000")


if __name__ == "__main__":
    main()
