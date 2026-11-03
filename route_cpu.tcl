# Recreate CPU Block Design matching Patterson & Hennessy Figure 4.17
remove_files -quiet [get_files *CPU.bd]
create_bd_design "CPU"
current_bd_design [get_bd_designs CPU]

# External Clock (100 MHz) and Active-High Reset
create_bd_port -dir I -type clk -freq_hz 100000000 clk
create_bd_port -dir I -type rst rst
set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports rst]

# Instantiate Figure 4.17 Blocks
create_bd_cell -type module -reference PC                 PC_0
create_bd_cell -type module -reference Adder              Add_PC_4
create_bd_cell -type module -reference Instruction_Memory Instruction_Memory_0
create_bd_cell -type module -reference Instruction_Slicer Instruction_Slicer_0
create_bd_cell -type module -reference Control            Control_0
create_bd_cell -type module -reference Registers          Registers_0
create_bd_cell -type module -reference Imm_Gen            Imm_Gen_0
create_bd_cell -type module -reference ALU_Control        ALU_Control_0
create_bd_cell -type module -reference ALU                ALU_0
create_bd_cell -type module -reference Adder              Add_Branch
create_bd_cell -type module -reference Branch_And         Branch_And_0
create_bd_cell -type module -reference Data_Memory        Data_Memory_0

# Multiplexers (Figure 4.17 ovals + RV32I JAL/JALR/AUIPC support)
create_bd_cell -type module -reference Mux2               Mux_ALUSrc_A
create_bd_cell -type module -reference Mux2               Mux_ALUSrc
create_bd_cell -type module -reference Mux2               Mux_Jump_Base
create_bd_cell -type module -reference Mux2               Mux_PCSrc
create_bd_cell -type module -reference Mux2               Mux_MemtoReg
create_bd_cell -type module -reference Mux2               Mux_WB_Jump

# Clock & Reset Routing
connect_bd_net [get_bd_ports clk] [get_bd_pins PC_0/clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins Registers_0/clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins Data_Memory_0/clk]

connect_bd_net [get_bd_ports rst] [get_bd_pins PC_0/rst]
connect_bd_net [get_bd_ports rst] [get_bd_pins Registers_0/rst]
connect_bd_net [get_bd_ports rst] [get_bd_pins Data_Memory_0/rst]

# 1. PC -> Instruction Memory & Adders
connect_bd_net [get_bd_pins PC_0/pc_out] [get_bd_pins Instruction_Memory_0/read_address]
connect_bd_net [get_bd_pins PC_0/pc_out] [get_bd_pins Add_PC_4/in_a]
connect_bd_net [get_bd_pins PC_0/pc_out] [get_bd_pins Mux_ALUSrc_A/in_1]
connect_bd_net [get_bd_pins PC_0/pc_out] [get_bd_pins Mux_Jump_Base/in_0]

connect_bd_net [get_bd_pins Instruction_Slicer_0/const_four] [get_bd_pins Add_PC_4/in_b]
connect_bd_net [get_bd_pins Add_PC_4/sum] [get_bd_pins Mux_PCSrc/in_0]
connect_bd_net [get_bd_pins Add_PC_4/sum] [get_bd_pins Mux_WB_Jump/in_1]

# 2. Instruction Memory -> Slicer & Imm_Gen
connect_bd_net [get_bd_pins Instruction_Memory_0/instruction] [get_bd_pins Instruction_Slicer_0/instruction]
connect_bd_net [get_bd_pins Instruction_Memory_0/instruction] [get_bd_pins Imm_Gen_0/instruction]

# 3. Slicer -> Control, Registers, ALU_Control, Branch_And, Data_Memory
connect_bd_net [get_bd_pins Instruction_Slicer_0/opcode]     [get_bd_pins Control_0/opcode]
connect_bd_net [get_bd_pins Instruction_Slicer_0/read_reg_1] [get_bd_pins Registers_0/read_reg_1]
connect_bd_net [get_bd_pins Instruction_Slicer_0/read_reg_2] [get_bd_pins Registers_0/read_reg_2]
connect_bd_net [get_bd_pins Instruction_Slicer_0/write_reg]  [get_bd_pins Registers_0/write_reg]
connect_bd_net [get_bd_pins Instruction_Slicer_0/funct3]     [get_bd_pins ALU_Control_0/funct3]
connect_bd_net [get_bd_pins Instruction_Slicer_0/funct3]     [get_bd_pins Branch_And_0/funct3]
connect_bd_net [get_bd_pins Instruction_Slicer_0/funct3]     [get_bd_pins Data_Memory_0/funct3]
connect_bd_net [get_bd_pins Instruction_Slicer_0/funct7_b5]  [get_bd_pins ALU_Control_0/funct7_b5]

# 4. Control Signals
connect_bd_net [get_bd_pins Control_0/branch]     [get_bd_pins Branch_And_0/branch]
connect_bd_net [get_bd_pins Control_0/jump]       [get_bd_pins Branch_And_0/jump]
connect_bd_net [get_bd_pins Control_0/jump]       [get_bd_pins Mux_WB_Jump/sel]
connect_bd_net [get_bd_pins Control_0/jalr]       [get_bd_pins Mux_Jump_Base/sel]
connect_bd_net [get_bd_pins Control_0/auipc]      [get_bd_pins Mux_ALUSrc_A/sel]
connect_bd_net [get_bd_pins Control_0/mem_read]   [get_bd_pins Data_Memory_0/mem_read]
connect_bd_net [get_bd_pins Control_0/mem_to_reg] [get_bd_pins Mux_MemtoReg/sel]
connect_bd_net [get_bd_pins Control_0/alu_op]     [get_bd_pins ALU_Control_0/alu_op]
connect_bd_net [get_bd_pins Control_0/mem_write]  [get_bd_pins Data_Memory_0/mem_write]
connect_bd_net [get_bd_pins Control_0/alu_src]    [get_bd_pins Mux_ALUSrc/sel]
connect_bd_net [get_bd_pins Control_0/reg_write]  [get_bd_pins Registers_0/reg_write]

# 5. Registers & Imm_Gen -> ALU Input Muxes & Data_Memory
connect_bd_net [get_bd_pins Registers_0/read_data_1] [get_bd_pins Mux_ALUSrc_A/in_0]
connect_bd_net [get_bd_pins Registers_0/read_data_1] [get_bd_pins Mux_Jump_Base/in_1]
connect_bd_net [get_bd_pins Registers_0/read_data_2] [get_bd_pins Mux_ALUSrc/in_0]
connect_bd_net [get_bd_pins Registers_0/read_data_2] [get_bd_pins Data_Memory_0/write_data]

connect_bd_net [get_bd_pins Imm_Gen_0/imm_out] [get_bd_pins Mux_ALUSrc/in_1]
connect_bd_net [get_bd_pins Imm_Gen_0/imm_out] [get_bd_pins Add_Branch/in_b]

# 6. ALU_Control & Muxes -> ALU
connect_bd_net [get_bd_pins Mux_ALUSrc_A/mux_out]   [get_bd_pins ALU_0/in_1]
connect_bd_net [get_bd_pins Mux_ALUSrc/mux_out]     [get_bd_pins ALU_0/in_2]
connect_bd_net [get_bd_pins ALU_Control_0/alu_ctrl] [get_bd_pins ALU_0/alu_ctrl]

# 7. ALU -> Data_Memory, MemtoReg Mux, and Branch_And
connect_bd_net [get_bd_pins ALU_0/alu_result] [get_bd_pins Data_Memory_0/address]
connect_bd_net [get_bd_pins ALU_0/alu_result] [get_bd_pins Mux_MemtoReg/in_0]
connect_bd_net [get_bd_pins ALU_0/zero]       [get_bd_pins Branch_And_0/zero]

# 8. Branch / Jump Target Adder & PCSrc Mux -> PC
connect_bd_net [get_bd_pins Mux_Jump_Base/mux_out] [get_bd_pins Add_Branch/in_a]
connect_bd_net [get_bd_pins Add_Branch/sum]        [get_bd_pins Mux_PCSrc/in_1]
connect_bd_net [get_bd_pins Branch_And_0/pc_src]   [get_bd_pins Mux_PCSrc/sel]
connect_bd_net [get_bd_pins Mux_PCSrc/mux_out]     [get_bd_pins PC_0/pc_in]

# 9. Data_Memory & MemtoReg / Jump Writeback Muxes -> Registers
connect_bd_net [get_bd_pins Data_Memory_0/read_data] [get_bd_pins Mux_MemtoReg/in_1]
connect_bd_net [get_bd_pins Mux_MemtoReg/mux_out]    [get_bd_pins Mux_WB_Jump/in_0]
connect_bd_net [get_bd_pins Mux_WB_Jump/mux_out]     [get_bd_pins Registers_0/write_data]

regenerate_bd_layout
validate_bd_design
save_bd_design
puts "=== Figure 4.17 Block Design Created, Validated, and Saved! ==="
