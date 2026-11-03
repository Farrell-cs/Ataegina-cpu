library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity CPU_Top is
    generic(
        IMEM_WORDS : integer := 1024;
        DMEM_WORDS : integer := 1024
    );
    port(
        clk             : in  std_logic;
        rst             : in  std_logic;
        pc_out_dbg      : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        instruction_dbg : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        alu_result_dbg  : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        write_data_dbg  : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity CPU_Top;

architecture Structural of CPU_Top is

    -- Fetch wires
    signal pc_in         : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal pc_out        : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal pc_plus_4     : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal const_four    : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal instruction   : std_logic_vector(WORD_WIDTH - 1 downto 0);

    -- Sliced instruction fields (Figure 4.17 black bus splits)
    signal opcode        : std_logic_vector(6 downto 0);
    signal read_reg_1    : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal read_reg_2    : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal write_reg     : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal funct3        : std_logic_vector(2 downto 0);
    signal funct7_b5     : std_logic;

    -- Control lines (Figure 4.17 blue lines)
    signal branch        : std_logic;
    signal mem_read      : std_logic;
    signal mem_to_reg    : std_logic;
    signal alu_op        : std_logic_vector(2 downto 0);
    signal mem_write     : std_logic;
    signal alu_src       : std_logic;
    signal reg_write     : std_logic;
    signal jump          : std_logic;
    signal jalr          : std_logic;
    signal auipc         : std_logic;

    -- Register File & Immediate Generator wires
    signal read_data_1   : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal read_data_2   : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal imm_out       : std_logic_vector(WORD_WIDTH - 1 downto 0);

    -- ALU & ALU Control wires
    signal alu_in_1      : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal alu_in_2      : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal alu_ctrl      : std_logic_vector(3 downto 0);
    signal alu_result    : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal zero          : std_logic;

    -- Branch / Jump Target Adder & PCSrc Mux wires
    signal jump_base     : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal branch_target : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal pc_src        : std_logic;

    -- Data Memory & Writeback Mux wires
    signal read_data     : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal mem_or_alu    : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal write_data    : std_logic_vector(WORD_WIDTH - 1 downto 0);

begin

    -- 1. PC Register
    u_pc: entity work.PC
        port map(
            clk    => clk,
            rst    => rst,
            pc_in  => pc_in,
            pc_out => pc_out
        );

    -- 2. Add (PC + 4)
    u_add_pc_4: entity work.Adder
        port map(
            in_a => pc_out,
            in_b => const_four,
            sum  => pc_plus_4
        );

    -- 3. Instruction Memory
    u_imem: entity work.Instruction_Memory
        generic map(
            IMEM_WORDS => IMEM_WORDS
        )
        port map(
            read_address => pc_out,
            instruction  => instruction
        );

    -- 4. Instruction Bus Slicer (Instruction[6:0], [19:15], [24:20], [11:7], [30,14:12])
    u_slicer: entity work.Instruction_Slicer
        port map(
            instruction => instruction,
            opcode      => opcode,
            read_reg_1  => read_reg_1,
            read_reg_2  => read_reg_2,
            write_reg   => write_reg,
            funct3      => funct3,
            funct7_b5   => funct7_b5,
            const_four  => const_four
        );

    -- 5. Control Unit
    u_control: entity work.Control
        port map(
            opcode     => opcode,
            branch     => branch,
            mem_read   => mem_read,
            mem_to_reg => mem_to_reg,
            alu_op     => alu_op,
            mem_write  => mem_write,
            alu_src    => alu_src,
            reg_write  => reg_write,
            jump       => jump,
            jalr       => jalr,
            auipc      => auipc
        );

    -- 6. Registers
    u_registers: entity work.Registers
        port map(
            clk         => clk,
            rst         => rst,
            reg_write   => reg_write,
            read_reg_1  => read_reg_1,
            read_reg_2  => read_reg_2,
            write_reg   => write_reg,
            write_data  => write_data,
            read_data_1 => read_data_1,
            read_data_2 => read_data_2
        );

    -- 7. Immediate Generator (Imm Gen)
    u_imm_gen: entity work.Imm_Gen
        port map(
            instruction => instruction,
            imm_out     => imm_out
        );

    -- 8. ALU Input Muxes (ALUSrc Mux from Fig 4.17 + AUIPC support)
    u_mux_alu_a: entity work.Mux2
        port map(
            in_0    => read_data_1,
            in_1    => pc_out,
            sel     => auipc,
            mux_out => alu_in_1
        );

    u_mux_alu_src: entity work.Mux2
        port map(
            in_0    => read_data_2,
            in_1    => imm_out,
            sel     => alu_src,
            mux_out => alu_in_2
        );

    -- 9. ALU Control
    u_alu_control: entity work.ALU_Control
        port map(
            alu_op    => alu_op,
            funct3    => funct3,
            funct7_b5 => funct7_b5,
            alu_ctrl  => alu_ctrl
        );

    -- 10. ALU
    u_alu: entity work.ALU
        port map(
            in_1       => alu_in_1,
            in_2       => alu_in_2,
            alu_ctrl   => alu_ctrl,
            zero       => zero,
            alu_result => alu_result
        );

    -- 11. Branch / Jump Target Adder & AND Gate + PCSrc Mux
    u_mux_jump_base: entity work.Mux2
        port map(
            in_0    => pc_out,
            in_1    => read_data_1,
            sel     => jalr,
            mux_out => jump_base
        );

    u_add_branch: entity work.Adder
        port map(
            in_a => jump_base,
            in_b => imm_out,
            sum  => branch_target
        );

    u_branch_and: entity work.Branch_And
        port map(
            branch => branch,
            jump   => jump,
            funct3 => funct3,
            zero   => zero,
            pc_src => pc_src
        );

    u_mux_pc_src: entity work.Mux2
        port map(
            in_0    => pc_plus_4,
            in_1    => branch_target,
            sel     => pc_src,
            mux_out => pc_in
        );

    -- 12. Data Memory
    u_dmem: entity work.Data_Memory
        generic map(
            DMEM_WORDS => DMEM_WORDS
        )
        port map(
            clk        => clk,
            rst        => rst,
            mem_read   => mem_read,
            mem_write  => mem_write,
            funct3     => funct3,
            address    => alu_result,
            write_data => read_data_2,
            read_data  => read_data
        );

    -- 13. MemtoReg Writeback Muxes
    u_mux_mem_to_reg: entity work.Mux2
        port map(
            in_0    => alu_result,
            in_1    => read_data,
            sel     => mem_to_reg,
            mux_out => mem_or_alu
        );

    u_mux_wb_jump: entity work.Mux2
        port map(
            in_0    => mem_or_alu,
            in_1    => pc_plus_4,
            sel     => jump,
            mux_out => write_data
        );

    -- Simulation debug probes
    pc_out_dbg      <= pc_out;
    instruction_dbg <= instruction;
    alu_result_dbg  <= alu_result;
    write_data_dbg  <= write_data;

end architecture Structural;
