library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Constants is

    constant WORD_WIDTH     : integer := 32;
    constant REG_ADDR_WIDTH : integer := 5;
    constant NUM_REGISTERS  : integer := 32;

    -- Program Counter Control Codes
    constant PC_OP_HALT   : std_logic_vector(1 downto 0) := "00";
    constant PC_OP_INC    : std_logic_vector(1 downto 0) := "01";
    constant PC_OP_ASSIGN : std_logic_vector(1 downto 0) := "10";
    constant PC_OP_RESET  : std_logic_vector(1 downto 0) := "11";

    -- RV32I Base Major Opcodes (inst[6:0])
    constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
    constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";
    constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
    constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
    constant OP_BRANCH : std_logic_vector(6 downto 0) := "1100011";
    constant OP_LOAD   : std_logic_vector(6 downto 0) := "0000011";
    constant OP_STORE  : std_logic_vector(6 downto 0) := "0100011";
    constant OP_IMM    : std_logic_vector(6 downto 0) := "0010011";
    constant OP_REG    : std_logic_vector(6 downto 0) := "0110011";
    constant OP_FENCE  : std_logic_vector(6 downto 0) := "0001111";
    constant OP_SYSTEM : std_logic_vector(6 downto 0) := "1110011";

    -- RV32I ALU / Integer funct3 Codes (inst[14:12])
    constant F3_ADD_SUB : std_logic_vector(2 downto 0) := "000";
    constant F3_SLL     : std_logic_vector(2 downto 0) := "001";
    constant F3_SLT     : std_logic_vector(2 downto 0) := "010";
    constant F3_SLTU    : std_logic_vector(2 downto 0) := "011";
    constant F3_XOR     : std_logic_vector(2 downto 0) := "100";
    constant F3_SRL_SRA : std_logic_vector(2 downto 0) := "101";
    constant F3_OR      : std_logic_vector(2 downto 0) := "110";
    constant F3_AND     : std_logic_vector(2 downto 0) := "111";

    -- RV32I Branch funct3 Codes
    constant F3_BEQ  : std_logic_vector(2 downto 0) := "000";
    constant F3_BNE  : std_logic_vector(2 downto 0) := "001";
    constant F3_BLT  : std_logic_vector(2 downto 0) := "100";
    constant F3_BGE  : std_logic_vector(2 downto 0) := "101";
    constant F3_BLTU : std_logic_vector(2 downto 0) := "110";
    constant F3_BGEU : std_logic_vector(2 downto 0) := "111";

    -- RV32I Load / Store Width funct3 Codes
    constant F3_BYTE   : std_logic_vector(2 downto 0) := "000";
    constant F3_HALF   : std_logic_vector(2 downto 0) := "001";
    constant F3_WORD   : std_logic_vector(2 downto 0) := "010";
    constant F3_BYTE_U : std_logic_vector(2 downto 0) := "100";
    constant F3_HALF_U : std_logic_vector(2 downto 0) := "101";

    -- RV32I funct7 Codes (inst[31:25])
    constant F7_DEFAULT : std_logic_vector(6 downto 0) := "0000000";
    constant F7_ALT     : std_logic_vector(6 downto 0) := "0100000";

    -- Internal 4-bit ALU Operation Select Codes
    constant ALU_ADD    : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB    : std_logic_vector(3 downto 0) := "0001";
    constant ALU_SLL    : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SLT    : std_logic_vector(3 downto 0) := "0011";
    constant ALU_SLTU   : std_logic_vector(3 downto 0) := "0100";
    constant ALU_XOR    : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SRL    : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SRA    : std_logic_vector(3 downto 0) := "0111";
    constant ALU_OR     : std_logic_vector(3 downto 0) := "1000";
    constant ALU_AND    : std_logic_vector(3 downto 0) := "1001";
    constant ALU_EQ     : std_logic_vector(3 downto 0) := "1010";
    constant ALU_PASS_B : std_logic_vector(3 downto 0) := "1011";

end package Constants;

package body Constants is
end package body Constants;
