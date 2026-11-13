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
from pathlib import Path

DEFAULT_IMEM = Path(__file__).resolve().parents[1] / "RISC-V-CPU.srcs" / "sources_1" / "new" / "imem.mem"

def load_file(filepath):
    path = Path(filepath)
    if not path.is_file():
        print(f"Error: File not found: {path}")
        sys.exit(1)
    words = []
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("//") or line.startswith("#"):
                continue
            words.append(int(line, 16))
    return words

def print_available_ports(list_ports):
    ports = sorted(list_ports.comports(), key=lambda p: p.device)
    if not ports:
        print("No COM ports detected on this PC.")
        return
    print("Available COM ports:")
    for p in ports:
        desc = p.description or "Unknown device"
        hwid = f" [{p.hwid}]" if p.hwid else ""
        print(f"  {p.device}: {desc}{hwid}")


def main():
    parser = argparse.ArgumentParser(description="Upload RISC-V binary to Zybo Z7 over UART")
    parser.add_argument(
        "file",
        nargs="?",
        default=str(DEFAULT_IMEM),
        help="Path to .mem or .hex instruction file (default: %(default)s)",
    )
    parser.add_argument("--port", default="COM3", help="Serial port (default: COM3)")
    parser.add_argument("--baud", default=115200, type=int, help="Baud rate (default: 115200)")
    parser.add_argument("--delay", default=0.001, type=float, help="Inter-word delay (default: 0.001s)")
    parser.add_argument("--list", action="store_true", help="List available COM ports and exit")
    args = parser.parse_args()

    try:
        import serial
        from serial.tools import list_ports
    except ImportError:
        print("Error: pyserial is required. Install via: pip install pyserial")
        sys.exit(1)

    if args.list:
        print_available_ports(list_ports)
        return

    words = load_file(args.file)
    print(f"Loaded {len(words)} instructions ({len(words)*4} bytes) from '{args.file}'")

    try:
        with serial.Serial(args.port, args.baud, timeout=2, rtscts=False, dsrdtr=False) as ser:
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
        print("Check your COM port setting, ensure the USB-UART adapter is connected, and note uart_rx is on Pmod JC Pin 1 (V15).")
        print_available_ports(list_ports)
        sys.exit(1)

if __name__ == "__main__":
    main()
