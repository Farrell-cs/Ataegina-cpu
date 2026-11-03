library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity Mux2 is
    port(
        in_0    : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        in_1    : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        sel     : in  std_logic;
        mux_out : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Mux2;

architecture Behavioral of Mux2 is
begin
    mux_out <= in_1 when sel = '1' else in_0;
end Behavioral;
