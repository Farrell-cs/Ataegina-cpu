library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package Constants is

    constant WORD_WIDTH     : integer := 32;
    constant REG_ADDR_WIDTH : integer := 5;
    constant NUM_REGISTERS  : integer := 32;

    function clog2(n : positive) return natural;

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

    constant ALUOP_LOAD_STORE : std_logic_vector(2 downto 0) := "000";
    constant ALUOP_BRANCH     : std_logic_vector(2 downto 0) := "001";
    constant ALUOP_R_TYPE     : std_logic_vector(2 downto 0) := "010";
    constant ALUOP_I_TYPE     : std_logic_vector(2 downto 0) := "011";
    constant ALUOP_LUI        : std_logic_vector(2 downto 0) := "100";

    constant F3_ADD_SUB : std_logic_vector(2 downto 0) := "000";
    constant F3_SLL     : std_logic_vector(2 downto 0) := "001";
    constant F3_SLT     : std_logic_vector(2 downto 0) := "010";
    constant F3_SLTU    : std_logic_vector(2 downto 0) := "011";
    constant F3_XOR     : std_logic_vector(2 downto 0) := "100";
    constant F3_SRL_SRA : std_logic_vector(2 downto 0) := "101";
    constant F3_OR      : std_logic_vector(2 downto 0) := "110";
    constant F3_AND     : std_logic_vector(2 downto 0) := "111";

    constant F3_BEQ  : std_logic_vector(2 downto 0) := "000";
    constant F3_BNE  : std_logic_vector(2 downto 0) := "001";
    constant F3_BLT  : std_logic_vector(2 downto 0) := "100";
    constant F3_BGE  : std_logic_vector(2 downto 0) := "101";
    constant F3_BLTU : std_logic_vector(2 downto 0) := "110";
    constant F3_BGEU : std_logic_vector(2 downto 0) := "111";

    constant F3_BYTE   : std_logic_vector(2 downto 0) := "000";
    constant F3_HALF   : std_logic_vector(2 downto 0) := "001";
    constant F3_WORD   : std_logic_vector(2 downto 0) := "010";
    constant F3_BYTE_U : std_logic_vector(2 downto 0) := "100";
    constant F3_HALF_U : std_logic_vector(2 downto 0) := "101";

    constant F3_MUL    : std_logic_vector(2 downto 0) := "000";
    constant F3_MULH   : std_logic_vector(2 downto 0) := "001";
    constant F3_MULHSU : std_logic_vector(2 downto 0) := "010";
    constant F3_MULHU  : std_logic_vector(2 downto 0) := "011";
    constant F3_DIV    : std_logic_vector(2 downto 0) := "100";
    constant F3_DIVU   : std_logic_vector(2 downto 0) := "101";
    constant F3_REM    : std_logic_vector(2 downto 0) := "110";
    constant F3_REMU   : std_logic_vector(2 downto 0) := "111";

    constant ALU_AND    : std_logic_vector(4 downto 0) := "00000";
    constant ALU_OR     : std_logic_vector(4 downto 0) := "00001";
    constant ALU_ADD    : std_logic_vector(4 downto 0) := "00010";
    constant ALU_SLL    : std_logic_vector(4 downto 0) := "00011";
    constant ALU_SLT    : std_logic_vector(4 downto 0) := "00100";
    constant ALU_SLTU   : std_logic_vector(4 downto 0) := "00101";
    constant ALU_SUB    : std_logic_vector(4 downto 0) := "00110";
    constant ALU_XOR    : std_logic_vector(4 downto 0) := "00111";
    constant ALU_SRL    : std_logic_vector(4 downto 0) := "01000";
    constant ALU_SRA    : std_logic_vector(4 downto 0) := "01001";
    constant ALU_PASS_B : std_logic_vector(4 downto 0) := "01010";
    constant ALU_MUL    : std_logic_vector(4 downto 0) := "01011";
    constant ALU_MULH   : std_logic_vector(4 downto 0) := "01100";
    constant ALU_MULHSU : std_logic_vector(4 downto 0) := "01101";
    constant ALU_MULHU  : std_logic_vector(4 downto 0) := "01110";
    constant ALU_DIV    : std_logic_vector(4 downto 0) := "01111";
    constant ALU_DIVU   : std_logic_vector(4 downto 0) := "10000";
    constant ALU_REM    : std_logic_vector(4 downto 0) := "10001";
    constant ALU_REMU   : std_logic_vector(4 downto 0) := "10010";

end package Constants;

package body Constants is

    function clog2(n : positive) return natural is
        variable res : natural := 0;
        variable val : natural := n - 1;
    begin
        while val > 0 loop
            val := val / 2;
            res := res + 1;
        end loop;
        return res;
    end function clog2;

end package body Constants;
