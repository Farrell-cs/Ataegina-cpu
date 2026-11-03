library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Adder is
    port(
        in_a : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        in_b : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        sum  : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Adder;

architecture Behavioral of Adder is
begin
    sum <= std_logic_vector(unsigned(in_a) + unsigned(in_b));
end Behavioral;
