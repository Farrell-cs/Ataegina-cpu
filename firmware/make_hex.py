import subprocess
import struct
import shutil
import os

GCC = r"C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin\riscv64-unknown-elf-gcc.exe"
OBJCOPY = r"C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin\riscv64-unknown-elf-objcopy.exe"

def bin_to_mem(bin_path, mem_path, min_words=1):
    data = b""
    if os.path.exists(bin_path):
        with open(bin_path, "rb") as f:
            data = f.read()

    while len(data) % 4 != 0:
        data += b"\x00"

    words = []
    for i in range(0, len(data), 4):
        val = struct.unpack("<I", data[i:i+4])[0]
        words.append(f"{val:08X}")

    while len(words) < min_words:
        words.append("00000000")

    with open(mem_path, "w") as f:
        for w in words:
            f.write(w + "\n")
    return len(words)

def build():
    print("1. Compiling C code with Vitis RISC-V GCC...")
    subprocess.check_call([
        GCC, "-march=rv32i", "-mabi=ilp32", "-O2",
        "-nostdlib", "-Wl,--build-id=none", "-T", "linker.ld",
        "crt0.s", "main.c", "-o", "pong.elf"
    ])

    print("2. Extracting .text (Instruction ROM) and .data (Data RAM)...")
    subprocess.check_call([OBJCOPY, "-O", "binary", "--only-section=.text", "pong.elf", "imem.bin"])
    subprocess.check_call([OBJCOPY, "-O", "binary", "--only-section=.data", "pong.elf", "dmem.bin"])

    imem_words = bin_to_mem("imem.bin", "imem.mem", min_words=1)
    dmem_words = bin_to_mem("dmem.bin", "dmem.mem", min_words=1)

    shutil.copyfile("imem.mem", "../imem.mem")
    shutil.copyfile("dmem.mem", "../dmem.mem")
    shutil.copyfile("imem.mem", "../RISC-V-CPU.srcs/sources_1/new/imem.mem")
    shutil.copyfile("dmem.mem", "../RISC-V-CPU.srcs/sources_1/new/dmem.mem")

    print(f"SUCCESS! imem.mem ({imem_words} words) and dmem.mem ({dmem_words} words) generated and synced.")

if __name__ == "__main__":
    build()
