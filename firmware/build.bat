@echo off
set GCC=C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin\riscv64-unknown-elf-gcc.exe
set OBJCOPY=C:\AMDDesignTools\2026.1\gnu\riscv\nt\bin\riscv64-unknown-elf-objcopy.exe

echo [1/3] Compiling C code with Vitis RISC-V GCC...
"%GCC%" -march=rv32i -mabi=ilp32 -O2 -nostdlib -Wl,--build-id=none -T linker.ld crt0.s main.c -o pong.elf
if errorlevel 1 goto error

echo [2/3] Extracting binary with objcopy...
"%OBJCOPY%" -O binary pong.elf pong.bin
if errorlevel 1 goto error

echo [3/3] Generating imem.mem...
python make_hex.py
if errorlevel 1 goto error

echo.
echo === BUILD SUCCESSFUL: imem.mem is ready! ===
goto end

:error
echo.
echo [ERROR] Build failed!

:end
pause
