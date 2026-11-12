#!/usr/bin/env python3
"""
RISC-V UART Program Loader for Digilent Zybo Z7
Sends a .mem or .hex file over UART to the hardware UART_Program_Loader.

Usage:
    python tools/load_program.py firmware/imem.mem --port COM3
    python tools/load_program.py firmware/imem.mem --port COM3 --baud 115200
"""

import sys
import time
import argparse

try:
    import serial
except ImportError:
    print("Error: pyserial is required. Install via: pip install pyserial")
    sys.exit(1)

def load_file(filepath):
    words = []
    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("//") or line.startswith("#"):
                continue
            words.append(int(line, 16))
    return words

def main():
    parser = argparse.ArgumentParser(description="Upload RISC-V binary to Zybo Z7 over UART")
    parser.add_argument("file", help="Path to .mem or .hex file")
    parser.add_argument("--port", default="COM3", help="Serial port (default: COM3)")
    parser.add_argument("--baud", default=115200, type=int, help="Baud rate (default: 115200)")
    parser.add_argument("--delay", default=0.001, type=float, help="Inter-word delay (default: 0.001s)")
    args = parser.parse_args()

    words = load_file(args.file)
    print(f"Loaded {len(words)} instructions ({len(words)*4} bytes) from '{args.file}'")

    try:
        with serial.Serial(args.port, args.baud, timeout=2) as ser:
            print(f"Connected to {args.port} at {args.baud} baud.")
            print("Streaming program to FPGA...")

            for i, word in enumerate(words):
                # Little-endian 4-byte transfer
                data = word.to_bytes(4, byteorder='little')
                ser.write(data)
                if args.delay > 0:
                    time.sleep(args.delay)

                pct = (i + 1) / len(words) * 100
                bar = '#' * int(pct / 2) + '-' * (50 - int(pct / 2))
                print(f"\r[{bar}] {pct:.1f}% ({i+1}/{len(words)} words)", end='', flush=True)

            print()

            # End-of-program trigger sequence (4x 0xFF)
            print("Sending launch token (0xFF 0xFF 0xFF 0xFF)...")
            ser.write(bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
            time.sleep(0.05)

            print("SUCCESS: Program loaded! CPU reset released, executing immediately on HDMI display.")

    except serial.SerialException as e:
        print(f"\nSerial error: {e}")
        print(f"Check your COM port setting and ensure Zybo UART cable is connected.")
        sys.exit(1)

if __name__ == "__main__":
    main()
