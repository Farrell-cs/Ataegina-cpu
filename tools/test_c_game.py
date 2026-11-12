import sys
import os

def run_simulation(mem_path, max_cycles=300000):
    if not os.path.exists(mem_path):
        print(f"Error: {mem_path} not found.")
        return

    # Load instruction memory (ROM)
    imem = []
    with open(mem_path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                imem.append(int(line, 16))

    # Memory maps
    # Data Memory: 4096 bytes (0x00000000 - 0x00000FFF)
    dmem = bytearray(4096)
    # Framebuffer VRAM: 240 x 135 bytes (0x80000000 - 0x80007E8F)
    vram = bytearray(240 * 135)

    regs = [0] * 32
    pc = 0
    cycle = 0
    vram_writes = 0

    print(f"Running simulation on {len(imem)} instructions...")

    while cycle < max_cycles:
        word_addr = pc >> 2
        if word_addr >= len(imem):
            break

        inst = imem[word_addr]
        cycle += 1

        opcode = inst & 0x7F
        rd     = (inst >> 7) & 0x1F
        funct3 = (inst >> 12) & 0x07
        rs1    = (inst >> 15) & 0x1F
        rs2    = (inst >> 20) & 0x1F
        funct7 = (inst >> 25) & 0x7F

        def sign_ext(val, bits):
            if val & (1 << (bits - 1)):
                return val - (1 << bits)
            return val

        imm_i = sign_ext(inst >> 20, 12)
        imm_s = sign_ext(((inst >> 25) << 5) | ((inst >> 7) & 0x1F), 12)
        imm_b = sign_ext(((inst >> 31) << 12) | (((inst >> 7) & 1) << 11) | (((inst >> 25) & 0x3F) << 5) | (((inst >> 8) & 0x0F) << 1), 13)
        imm_u = (inst & 0xFFFFF000)
        imm_j = sign_ext(((inst >> 31) << 20) | (((inst >> 12) & 0xFF) << 12) | (((inst >> 20) & 1) << 11) | (((inst >> 21) & 0x3FF) << 1), 21)

        def u32(val):
            return val & 0xFFFFFFFF

        def s32(val):
            val = val & 0xFFFFFFFF
            if val & 0x80000000:
                return val - 0x100000000
            return val

        next_pc = pc + 4

        # Read memory helper
        def mem_read(addr, width, unsigned=False):
            addr = u32(addr)
            if addr == 0x80010000:
                return 0 # Buttons
            elif 0x80000000 <= addr < (0x80000000 + len(vram)):
                offset = addr - 0x80000000
                return vram[offset]
            elif addr < len(dmem):
                if width == 1:
                    val = dmem[addr]
                    return val if unsigned else sign_ext(val, 8)
                elif width == 2:
                    val = dmem[addr] | (dmem[addr+1] << 8)
                    return val if unsigned else sign_ext(val, 16)
                elif width == 4:
                    val = dmem[addr] | (dmem[addr+1] << 8) | (dmem[addr+2] << 16) | (dmem[addr+3] << 24)
                    return u32(val)
            return 0

        # Write memory helper
        def mem_write(addr, val, width):
            nonlocal vram_writes
            addr = u32(addr)
            if 0x80000000 <= addr < (0x80000000 + len(vram)):
                offset = addr - 0x80000000
                vram[offset] = val & 0xFF
                vram_writes += 1
            elif addr < len(dmem):
                if width == 1:
                    dmem[addr] = val & 0xFF
                elif width == 2:
                    dmem[addr]   = val & 0xFF
                    dmem[addr+1] = (val >> 8) & 0xFF
                elif width == 4:
                    dmem[addr]   = val & 0xFF
                    dmem[addr+1] = (val >> 8) & 0xFF
                    dmem[addr+2] = (val >> 16) & 0xFF
                    dmem[addr+3] = (val >> 24) & 0xFF

        # Execute Instruction
        if opcode == 0x37: # LUI
            if rd != 0: regs[rd] = u32(imm_u)
        elif opcode == 0x17: # AUIPC
            if rd != 0: regs[rd] = u32(pc + imm_u)
        elif opcode == 0x6F: # JAL
            if rd != 0: regs[rd] = next_pc
            next_pc = pc + imm_j
        elif opcode == 0x67: # JALR
            target = (regs[rs1] + imm_i) & ~1
            if rd != 0: regs[rd] = next_pc
            next_pc = target
        elif opcode == 0x63: # BRANCH
            cond = False
            if funct3 == 0:   cond = (regs[rs1] == regs[rs2])           # BEQ
            elif funct3 == 1: cond = (regs[rs1] != regs[rs2])           # BNE
            elif funct3 == 4: cond = (s32(regs[rs1]) < s32(regs[rs2]))  # BLT
            elif funct3 == 5: cond = (s32(regs[rs1]) >= s32(regs[rs2])) # BGE
            elif funct3 == 6: cond = (u32(regs[rs1]) < u32(regs[rs2]))  # BLTU
            elif funct3 == 7: cond = (u32(regs[rs1]) >= u32(regs[rs2])) # BGEU
            if cond:
                next_pc = pc + imm_b
        elif opcode == 0x03: # LOAD
            val = 0
            if funct3 == 0:   val = mem_read(regs[rs1] + imm_i, 1, False) # LB
            elif funct3 == 1: val = mem_read(regs[rs1] + imm_i, 2, False) # LH
            elif funct3 == 2: val = mem_read(regs[rs1] + imm_i, 4, True)  # LW
            elif funct3 == 4: val = mem_read(regs[rs1] + imm_i, 1, True)  # LBU
            elif funct3 == 5: val = mem_read(regs[rs1] + imm_i, 2, True)  # LHU
            if rd != 0: regs[rd] = u32(val)
        elif opcode == 0x23: # STORE
            if funct3 == 0:   mem_write(regs[rs1] + imm_s, regs[rs2], 1) # SB
            elif funct3 == 1: mem_write(regs[rs1] + imm_s, regs[rs2], 2) # SH
            elif funct3 == 2: mem_write(regs[rs1] + imm_s, regs[rs2], 4) # SW
        elif opcode == 0x13: # OP-IMM
            shamt = (inst >> 20) & 0x1F
            res = 0
            if funct3 == 0:   res = s32(regs[rs1]) + imm_i                  # ADDI
            elif funct3 == 2: res = 1 if s32(regs[rs1]) < imm_i else 0       # SLTI
            elif funct3 == 3: res = 1 if u32(regs[rs1]) < u32(imm_i) else 0 # SLTIU
            elif funct3 == 4: res = regs[rs1] ^ imm_i                       # XORI
            elif funct3 == 6: res = regs[rs1] | imm_i                       # ORI
            elif funct3 == 7: res = regs[rs1] & imm_i                       # ANDI
            elif funct3 == 1: res = regs[rs1] << shamt                      # SLLI
            elif funct3 == 5:
                if (inst >> 30) & 1: res = s32(regs[rs1]) >> shamt          # SRAI
                else:                res = u32(regs[rs1]) >> shamt          # SRLI
            if rd != 0: regs[rd] = u32(res)
        elif opcode == 0x33: # OP-REG
            shamt = regs[rs2] & 0x1F
            res = 0
            if funct3 == 0:
                if funct7 == 0x20: res = s32(regs[rs1]) - s32(regs[rs2])    # SUB
                else:              res = s32(regs[rs1]) + s32(regs[rs2])    # ADD
            elif funct3 == 1: res = regs[rs1] << shamt                      # SLL
            elif funct3 == 2: res = 1 if s32(regs[rs1]) < s32(regs[rs2]) else 0 # SLT
            elif funct3 == 3: res = 1 if u32(regs[rs1]) < u32(regs[rs2]) else 0 # SLTU
            elif funct3 == 4: res = regs[rs1] ^ regs[rs2]                   # XOR
            elif funct3 == 5:
                if funct7 == 0x20: res = s32(regs[rs1]) >> shamt            # SRA
                else:              res = u32(regs[rs1]) >> shamt            # SRL
            elif funct3 == 6: res = regs[rs1] | regs[rs2]                   # OR
            elif funct3 == 7: res = regs[rs1] & regs[rs2]                   # AND
            if rd != 0: regs[rd] = u32(res)

        pc = next_pc

        # Break after one full frame has been rendered and drawn
        if vram_writes > 33000:
            break

    print(f"Simulation completed {cycle} cycles. Total VRAM pixel writes: {vram_writes}")

    # 1. Output PPM and BMP Image (Viewable in Windows Paint / any viewer)
    ppm_path = "pong_frame.ppm"
    with open(ppm_path, "w") as f:
        f.write("P3\n240 135\n255\n")
        for byte in vram:
            r = ((byte >> 5) & 0x07) * 36
            g = ((byte >> 2) & 0x07) * 36
            b = (byte & 0x03) * 85
            f.write(f"{r} {g} {b} ")
        f.write("\n")
    print(f"-> Generated image: {ppm_path}")

    try:
        from ppm_to_bmp import ppm_to_bmp
        ppm_to_bmp(ppm_path, "pong_frame.bmp")
    except Exception:
        pass

    # 2. Output ASCII terminal view of the Pong court
    print("\n=== PONG FRAME BUFFER TERMINAL PREVIEW ===")
    step_x = 4
    step_y = 5
    for y in range(0, 135, step_y):
        row = ""
        for x in range(0, 240, step_x):
            b = vram[y * 240 + x]
            if b == 0x1C:    row += "|"  # Green AI paddle
            elif b == 0xE0:  row += "|"  # Red Player paddle
            elif b == 0xFF:  row += "O"  # White Ball
            elif b == 0x49:  row += ":"  # Center net
            else:            row += " "  # Black background
        print(row)
    print("==========================================\n")

if __name__ == "__main__":
    mem_file = sys.argv[1] if len(sys.argv) > 1 else "imem.mem"
    run_simulation(mem_file)
