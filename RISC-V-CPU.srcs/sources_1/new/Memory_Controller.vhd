library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Memory_Controller is
    generic(
        MEM_WORDS : integer := 1024
    );
    port(
        clk        : in  std_logic;
        inst_addr  : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        inst_out   : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        funct3     : in  std_logic_vector(2 downto 0);
        data_addr  : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        data_in    : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        data_out   : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Memory_Controller;

architecture Behavioral of Memory_Controller is

begin

    -- TODO:
    -- 1. Declare a RAM array of MEM_WORDS x 32-bit words
    -- 2. Fetch 32-bit instruction word using inst_addr(11 downto 2)
    -- 3. Implement synchronous store (SB, SH, SW) using mem_write, funct3, and data_addr(1 downto 0)
    -- 4. Implement load (LB, LH, LW, LBU, LHU) with sign/zero extension based on funct3

end Behavioral;
