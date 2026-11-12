library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_Data_Memory is
end entity tb_Data_Memory;

architecture sim of tb_Data_Memory is
    constant CLK_PERIOD : time := 10 ns;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal mem_read   : std_logic := '0';
    signal mem_write  : std_logic := '0';
    signal funct3     : std_logic_vector(2 downto 0) := F3_WORD;
    signal address    : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal write_data : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal read_data  : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.Data_Memory
        generic map(DMEM_WORDS => 256)
        port map(
            clk        => clk,
            rst        => rst,
            mem_read   => mem_read,
            mem_write  => mem_write,
            funct3     => funct3,
            address    => address,
            write_data => write_data,
            read_data  => read_data
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
        address    <= X"00000010";
        write_data <= X"DEADBEEF";
        funct3     <= F3_WORD;
        mem_write  <= '1';
        wait for CLK_PERIOD;
        mem_write  <= '0';

        mem_read <= '1';
        wait for 1 ns;
        assert read_data = X"DEADBEEF" report "LW mismatch" severity error;

        address <= X"00000013";
        funct3  <= F3_BYTE;
        wait for 1 ns;
        assert read_data = X"FFFFFFDE" report "LB mismatch" severity error;

        funct3 <= F3_BYTE_U;
        wait for 1 ns;
        assert read_data = X"000000DE" report "LBU mismatch" severity error;

        report "tb_Data_Memory passed successfully." severity note;
        wait;
    end process;

end architecture sim;
