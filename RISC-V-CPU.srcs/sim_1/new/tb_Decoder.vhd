library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_Decoder is
end entity tb_Decoder;

architecture sim of tb_Decoder is
    signal instruction : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal opcode      : std_logic_vector(6 downto 0);
    signal rd          : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal funct3      : std_logic_vector(2 downto 0);
    signal rs1         : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal rs2         : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal funct7      : std_logic_vector(6 downto 0);
    signal imm_out     : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal alu_op      : std_logic_vector(3 downto 0);
    signal alu_src_imm : std_logic;
    signal reg_write   : std_logic;
    signal mem_read    : std_logic;
    signal mem_write   : std_logic;
    signal branch      : std_logic;
    signal jump        : std_logic;
begin

    uut: entity work.Decoder
        port map(
            instruction => instruction,
            opcode      => opcode,
            rd          => rd,
            funct3      => funct3,
            rs1         => rs1,
            rs2         => rs2,
            funct7      => funct7,
            imm_out     => imm_out,
            alu_op      => alu_op,
            alu_src_imm => alu_src_imm,
            reg_write   => reg_write,
            mem_read    => mem_read,
            mem_write   => mem_write,
            branch      => branch,
            jump        => jump
        );

    stim_proc: process
    begin
        -- I-Type: addi x1, x0, -4 (0xFFC00093)
        instruction <= X"FFC00093";
        wait for 10 ns;
        assert opcode = OP_IMM report "ADDI opcode mismatch" severity error;
        assert rd = "00001" report "ADDI rd mismatch" severity error;
        assert rs1 = "00000" report "ADDI rs1 mismatch" severity error;
        assert imm_out = X"FFFFFFFC" report "ADDI sign-extended imm mismatch" severity error;
        assert alu_op = ALU_ADD and alu_src_imm = '1' and reg_write = '1'
            report "ADDI control signals mismatch" severity error;

        -- R-Type: sub x3, x1, x2 (0x402081B3)
        instruction <= X"402081B3";
        wait for 10 ns;
        assert opcode = OP_REG report "SUB opcode mismatch" severity error;
        assert rd = "00011" and rs1 = "00001" and rs2 = "00010"
            report "SUB register fields mismatch" severity error;
        assert alu_op = ALU_SUB and alu_src_imm = '0' and reg_write = '1'
            report "SUB control signals mismatch" severity error;

        -- S-Type: sw x2, 8(x1) (0x0020A423)
        instruction <= X"0020A423";
        wait for 10 ns;
        assert opcode = OP_STORE report "SW opcode mismatch" severity error;
        assert imm_out = X"00000008" report "SW immediate mismatch" severity error;
        assert mem_write = '1' and reg_write = '0'
            report "SW control signals mismatch" severity error;

        -- B-Type: beq x1, x2, -8 (0xFE208CE3)
        instruction <= X"FE208CE3";
        wait for 10 ns;
        assert opcode = OP_BRANCH report "BEQ opcode mismatch" severity error;
        assert imm_out = X"FFFFFFF8" report "BEQ immediate mismatch" severity error;
        assert branch = '1' report "BEQ branch flag mismatch" severity error;

        -- U-Type: lui x5, 0x12345 (0x123452B7)
        instruction <= X"123452B7";
        wait for 10 ns;
        assert opcode = OP_LUI report "LUI opcode mismatch" severity error;
        assert imm_out = X"12345000" report "LUI immediate mismatch" severity error;
        assert alu_op = ALU_PASS_B and reg_write = '1'
            report "LUI control signals mismatch" severity error;

        report "tb_Decoder passed successfully." severity note;
        wait;
    end process;

end architecture sim;
