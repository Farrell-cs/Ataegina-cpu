library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_Registers is
end entity tb_Registers;

architecture sim of tb_Registers is
    constant CLK_PERIOD : time := 10 ns;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal reg_write   : std_logic := '0';
    signal read_reg_1  : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal read_reg_2  : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal write_reg   : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal write_data  : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal read_data_1 : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal read_data_2 : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.Registers
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

    clk_proc: process
    begin
        while now < 100 ns loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        read_reg_1 <= "00000";
        read_reg_2 <= "00001";
        wait for CLK_PERIOD;
        assert read_data_1 = X"00000000" report "x0 should read 0" severity error;

        write_reg  <= "00001";
        write_data <= X"12345678";
        reg_write  <= '1';
        wait for CLK_PERIOD;
        reg_write  <= '0';

        read_reg_1 <= "00001";
        wait for 1 ns;
        assert read_data_1 = X"12345678" report "x1 write/read mismatch" severity error;

        write_reg  <= "00000";
        write_data <= X"DEADBEEF";
        reg_write  <= '1';
        wait for CLK_PERIOD;
        reg_write  <= '0';

        read_reg_1 <= "00000";
        wait for 1 ns;
        assert read_data_1 = X"00000000" report "x0 must stay 0" severity error;

        report "tb_Registers passed successfully." severity note;
        wait;
    end process;

end architecture sim;
