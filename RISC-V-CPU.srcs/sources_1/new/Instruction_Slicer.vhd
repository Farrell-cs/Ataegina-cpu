library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity Instruction_Slicer is
    port(
        instruction : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        opcode      : out std_logic_vector(6 downto 0);
        read_reg_1  : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        read_reg_2  : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        write_reg   : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        funct3      : out std_logic_vector(2 downto 0);
        funct7_b5   : out std_logic;
        const_four  : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Instruction_Slicer;

architecture Behavioral of Instruction_Slicer is
begin
    opcode     <= instruction(6 downto 0);
    write_reg  <= instruction(11 downto 7);
    funct3     <= instruction(14 downto 12);
    read_reg_1 <= instruction(19 downto 15);
    read_reg_2 <= instruction(24 downto 20);
    funct7_b5  <= instruction(30);
    const_four <= X"00000004";
end Behavioral;
