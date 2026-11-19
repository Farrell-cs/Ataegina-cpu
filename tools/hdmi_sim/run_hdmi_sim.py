import argparse
import os
import shutil
import struct
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = REPO_ROOT / "RISC-V-CPU.srcs" / "sources_1" / "new"
SIM_DIR = Path(__file__).resolve().parent
BUILD_DIR = SIM_DIR / "build"
SIM_FW_DIR = SIM_DIR / "sim_fw"
FW_DIR = REPO_ROOT / "firmware"
MSYS_BIN = Path(r"C:\msys64\ucrt64\bin")
VITIS_RV_BIN = Path(r"C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin")

UNISIM_FILES = [
    SIM_DIR / "unisim" / "unisim_vcomponents.vhd",
    SIM_DIR / "unisim" / "unisim_primitives.vhd",
]

RTL_FILES = [
    SRC_DIR / "Constants.vhd",
    SRC_DIR / "ALU.vhd",
    SRC_DIR / "ALU_Control.vhd",
    SRC_DIR / "Div_Unit.vhd",
    SRC_DIR / "Adder.vhd",
    SRC_DIR / "Branch_And.vhd",
    SRC_DIR / "UART_Program_Loader.vhd",
    SRC_DIR / "PC.vhd",
    SRC_DIR / "Instruction_Memory.vhd",
    SRC_DIR / "Control.vhd",
    SRC_DIR / "Registers.vhd",
    SRC_DIR / "Imm_Gen.vhd",
    SRC_DIR / "Mux2.vhd",
    SRC_DIR / "Data_Memory.vhd",
    SRC_DIR / "AXI4_Master.vhd",
    SRC_DIR / "clock_gen.vhd",
    SRC_DIR / "timing_generator.vhd",
    SRC_DIR / "Framebuffer_RAM.vhd",
    SRC_DIR / "SyncAsync.vhd",
    SRC_DIR / "SyncAsyncReset.vhd",
    SRC_DIR / "ClockGen.vhd",
    SRC_DIR / "OutputSERDES.vhd",
    SRC_DIR / "DVI_Constants.vhd",
    SRC_DIR / "tmds_encoder.vhd",
    SRC_DIR / "rgb2dvi.vhd",
    SRC_DIR / "HDMI_Controller.vhd",
    SRC_DIR / "CPU_Top.vhd",
]

TB_FILES = [
    SIM_DIR / "tmds_receiver.vhd",
    SIM_DIR / "tb_hdmi_dvi.vhd",
    SIM_DIR / "tb_cpu_hdmi.vhd",
]

TARGETS = {
    "hdmi": "tb_hdmi_dvi",
    "cpu": "tb_cpu_hdmi",
}


def build_env():
    env = os.environ.copy()
    if MSYS_BIN.exists():
        env["PATH"] = str(MSYS_BIN) + os.pathsep + env.get("PATH", "")
    return env


def run_cmd(cmd, cwd, env, creationflags=0):
    print("+", " ".join(str(c) for c in cmd))
    res = subprocess.run([str(c) for c in cmd], cwd=str(cwd), env=env, creationflags=creationflags)
    if res.returncode != 0:
        sys.exit(res.returncode)


def bin_to_mem(bin_path, mem_path, min_words=1):
    data = bin_path.read_bytes() if bin_path.exists() else b""
    while len(data) % 4 != 0:
        data += b"\x00"
    words = [f"{struct.unpack('<I', data[i:i + 4])[0]:08X}" for i in range(0, len(data), 4)]
    while len(words) < min_words:
        words.append("00000000")
    mem_path.write_text("\n".join(words) + "\n", encoding="ascii")
    return len(words)


def compile_sim_firmware(env, src_file="main.c"):
    rv_gcc = VITIS_RV_BIN / "riscv64-unknown-elf-gcc.exe"
    rv_objcopy = VITIS_RV_BIN / "riscv64-unknown-elf-objcopy.exe"
    if not rv_gcc.exists() or not rv_objcopy.exists():
        sys.exit(f"Error: Vitis RISC-V toolchain not found in {VITIS_RV_BIN}")

    SIM_FW_DIR.mkdir(parents=True, exist_ok=True)
    # Use space-free relative paths from FW_DIR because AMD's gcc wrapper splits spaces in args.
    rel_sim_fw = Path("..") / "tools" / "hdmi_sim" / "sim_fw"
    elf_rel = rel_sim_fw / "pong_sim.elf"
    imem_bin = SIM_FW_DIR / "imem.bin"
    dmem_bin = SIM_FW_DIR / "dmem.bin"

    run_cmd(
        [
            rv_gcc,
            "-march=rv32im",
            "-mabi=ilp32",
            "-O2",
            "-DSIM_FAST",
            "-nostdlib",
            "-Wl,--build-id=none",
            "-T",
            "linker.ld",
            "crt0.s",
            src_file,
            "-o",
            elf_rel,
        ],
        cwd=FW_DIR,
        env=env,
    )
    run_cmd([rv_objcopy, "-O", "binary", "--only-section=.text", "pong_sim.elf", "imem.bin"], cwd=SIM_FW_DIR, env=env)
    run_cmd([rv_objcopy, "-O", "binary", "--only-section=.data", "pong_sim.elf", "dmem.bin"], cwd=SIM_FW_DIR, env=env)

    imem_words = bin_to_mem(imem_bin, SIM_FW_DIR / "imem.mem", min_words=1)
    dmem_words = bin_to_mem(dmem_bin, SIM_FW_DIR / "dmem.mem", min_words=1)
    print(f"[hdmi_sim] Built sim firmware (-DSIM_FAST): imem={imem_words} words, dmem={dmem_words} words")


def compile_all(target_entity, env, build_dir, native_res=False, fast_rgb=False):
    build_dir.mkdir(parents=True, exist_ok=True)
    ghdl = MSYS_BIN / "ghdl.exe" if (MSYS_BIN / "ghdl.exe").exists() else shutil.which("ghdl", path=env["PATH"])
    gcc = MSYS_BIN / "gcc.exe" if (MSYS_BIN / "gcc.exe").exists() else shutil.which("gcc", path=env["PATH"])

    if not ghdl:
        sys.exit("Error: ghdl not found. Ensure mingw-w64-ucrt-x86_64-ghdl-llvm is installed.")
    if not gcc:
        sys.exit("Error: gcc not found.")

    sdl_inc = Path(r"C:\msys64\ucrt64\include\SDL2")
    sdl_lib = Path(r"C:\msys64\ucrt64\lib")
    mon_c = SIM_DIR / "hdmi_monitor.c"
    mon_o = build_dir / "hdmi_monitor.o"

    run_cmd(
        [gcc, "-O3", "-march=native", "-Wall", "-Wextra", f"-I{sdl_inc}", "-c", mon_c, "-o", mon_o],
        cwd=build_dir,
        env=env,
    )

    ghdl_flags = ["--std=08", "-fsynopsys", "-frelaxed", "-O3", f"--workdir={build_dir}"]

    for f in UNISIM_FILES:
        run_cmd([ghdl, "-a", *ghdl_flags, "--work=unisim", f], cwd=build_dir, env=env)

    overrides = {}
    if native_res:
        overrides["timing_generator.vhd"] = SIM_DIR / "native_res" / "timing_generator.vhd"
    if fast_rgb:
        overrides["clock_gen.vhd"] = SIM_DIR / "fast_rgb" / "clock_gen.vhd"
        overrides["rgb2dvi.vhd"] = SIM_DIR / "fast_rgb" / "rgb2dvi.vhd"
        overrides["tmds_receiver.vhd"] = SIM_DIR / "fast_rgb" / "tmds_receiver.vhd"

    files_to_analyze = [overrides.get(f.name, f) for f in (RTL_FILES + TB_FILES)]

    for f in files_to_analyze:
        run_cmd([ghdl, "-a", *ghdl_flags, "--work=work", f], cwd=build_dir, env=env)

    exe_path = build_dir / f"{target_entity}.exe"
    run_cmd(
        [
            ghdl,
            "-e",
            *ghdl_flags,
            f"-Wl,{mon_o}",
            f"-Wl,-L{sdl_lib}",
            "-Wl,-lSDL2",
            "-o",
            exe_path,
            target_entity,
        ],
        cwd=build_dir,
        env=env,
    )
    return exe_path


def main():
    parser = argparse.ArgumentParser(description="Build and run GHDL DVI/HDMI video simulation.")
    parser.add_argument("target", choices=["hdmi", "cpu"], help="'hdmi' tests HDMI_Controller; 'cpu' tests full CPU_Top.")
    parser.add_argument("--mode", choices=["verify", "live"], default="verify", help="Headless timing+BMP check or live SDL2 window.")
    parser.add_argument("--frames", type=int, default=None, help="Frames to capture before stopping (default: auto in verify, 0=unlimited in live).")
    parser.add_argument("--out", type=str, default=None, help="Output BMP path (default: <target>_*_frame.bmp in verify mode).")
    parser.add_argument("--native-res", action="store_true", help="Simulate at native 160x90 framebuffer resolution (~62x fewer pixels/frame).")
    parser.add_argument("--fast-rgb", action="store_true", help="Bypass 368.75 MHz 10:1 DDR SERDES/TMDS and sample pixel-rate RGB directly.")
    parser.add_argument("--fast-fw", action="store_true", help="Use -DSIM_FAST firmware (shorter Pong delay loop) in tools/hdmi_sim/sim_fw/.")
    parser.add_argument("--fw", type=str, default="main.c", help="Firmware C source to compile when --fast-fw is used (default: main.c).")
    parser.add_argument("--fast", action="store_true", help="Preset: enables --fast-rgb at 720p (uses root imem.mem/dmem.mem).")
    parser.add_argument("--no-build", action="store_true", help="Skip recompiling if executable already exists.")
    args = parser.parse_args()

    native_res = args.native_res
    fast_rgb = args.fast_rgb or args.fast
    fast_fw = args.fast_fw

    env = build_env()
    target_entity = TARGETS[args.target]

    if native_res and fast_rgb:
        build_dir = SIM_DIR / "build_fast_native"
    elif fast_rgb:
        build_dir = SIM_DIR / "build_fast_rgb"
    elif native_res:
        build_dir = SIM_DIR / "build_native"
    else:
        build_dir = BUILD_DIR

    exe_path = build_dir / f"{target_entity}.exe"

    if not args.no_build or not exe_path.exists():
        exe_path = compile_all(target_entity, env, build_dir, native_res=native_res, fast_rgb=fast_rgb)

    if fast_fw:
        compile_sim_firmware(env, src_file=args.fw)

    env["HDMI_SIM_MODE"] = args.mode
    if args.frames is not None:
        env["HDMI_SIM_FRAMES"] = str(args.frames)
    elif args.mode == "verify":
        if native_res:
            env["HDMI_SIM_FRAMES"] = "12" if args.target == "cpu" else "3"
        else:
            env["HDMI_SIM_FRAMES"] = "1"
    else:
        env["HDMI_SIM_FRAMES"] = "0"

    if args.out is not None:
        env["HDMI_SIM_OUT"] = str(Path(args.out).resolve())
    elif args.mode == "verify":
        suffix = "native_frame.bmp" if native_res else "dvi_frame.bmp"
        env["HDMI_SIM_OUT"] = str((REPO_ROOT / f"{args.target}_{suffix}").resolve())
    else:
        env.pop("HDMI_SIM_OUT", None)

    sim_cmd = [exe_path, "--ieee-asserts=disable"]
    if native_res:
        sim_cmd.extend(["-gFRAME_WIDTH=160", "-gFRAME_HEIGHT=90"])

    sim_cwd = SIM_FW_DIR if fast_fw else REPO_ROOT
    flags = getattr(subprocess, "HIGH_PRIORITY_CLASS", 0) if sys.platform == "win32" else 0
    run_cmd(sim_cmd, cwd=sim_cwd, env=env, creationflags=flags)


if __name__ == "__main__":
    main()
