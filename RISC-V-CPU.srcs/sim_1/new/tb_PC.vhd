library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_PC is
end entity tb_PC;

architecture sim of tb_PC is
    constant CLK_PERIOD : time := 10 ns;
    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    signal pc_in  : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal pc_out : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.PC
        port map(
            clk    => clk,
            rst    => rst,
            pc_in  => pc_in,
            pc_out => pc_out
        );

    clk_proc: process
    begin
        while now < 80 ns loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        rst   <= '1';
        pc_in <= X"00000010";
        wait for CLK_PERIOD;
        assert pc_out = X"00000000" report "PC Reset failed" severity error;

        rst   <= '0';
        pc_in <= X"00000004";
        wait for CLK_PERIOD;
        assert pc_out = X"00000004" report "PC latch +4 failed" severity error;

        pc_in <= X"00000041"; -- LSB must be masked to 0
        wait for CLK_PERIOD;
        assert pc_out = X"00000040" report "PC alignment mask failed" severity error;

        report "tb_PC passed successfully." severity note;
        wait;
    end process;

end architecture sim;
