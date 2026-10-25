library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Decoder is
    port(
        instruction : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        opcode      : out std_logic_vector(6 downto 0);
        rd          : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        funct3      : out std_logic_vector(2 downto 0);
        rs1         : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        rs2         : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        funct7      : out std_logic_vector(6 downto 0);
        imm_out     : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        alu_op      : out std_logic_vector(3 downto 0);
        alu_src_imm : out std_logic;
        reg_write   : out std_logic;
        mem_read    : out std_logic;
        mem_write   : out std_logic;
        branch      : out std_logic;
        jump        : out std_logic
    );
end entity Decoder;

architecture Behavioral of Decoder is

begin

    -- TODO:
    -- 1. Slice the 32-bit instruction into opcode, rd, funct3, rs1, rs2, and funct7
    -- 2. Reconstruct and sign-extend immediates for I, S, B, U, and J formats
    -- 3. Drive control signals (alu_op, alu_src_imm, reg_write, mem_read, mem_write, branch, jump)

end Behavioral;
