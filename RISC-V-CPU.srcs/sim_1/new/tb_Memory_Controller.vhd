library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_Memory_Controller is
end entity tb_Memory_Controller;

architecture sim of tb_Memory_Controller is
    constant CLK_PERIOD : time := 10 ns;

    signal clk       : std_logic := '0';
    signal inst_addr : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal inst_out  : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal mem_read  : std_logic := '0';
    signal mem_write : std_logic := '0';
    signal funct3    : std_logic_vector(2 downto 0) := F3_WORD;
    signal data_addr : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal data_in   : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal data_out  : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.Memory_Controller
        generic map(
            MEM_WORDS => 256
        )
        port map(
            clk       => clk,
            inst_addr => inst_addr,
            inst_out  => inst_out,
            mem_read  => mem_read,
            mem_write => mem_write,
            funct3    => funct3,
            data_addr => data_addr,
            data_in   => data_in,
            data_out  => data_out
        );

    clk_process: process
    begin
        while now < 100 ns loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        -- Store Word (SW) at 0x00000010
        data_addr <= X"00000010";
        data_in   <= X"DEADBEEF";
        funct3    <= F3_WORD;
        mem_write <= '1';
        wait for CLK_PERIOD;
        mem_write <= '0';

        -- Load Word (LW) from 0x00000010
        mem_read <= '1';
        wait for 1 ns;
        assert data_out = X"DEADBEEF"
            report "LW failed" severity error;

        -- Load Signed Byte (LB) at offset +3 (0xDE -> 0xFFFFFFDE)
        data_addr <= X"00000013";
        funct3    <= F3_BYTE;
        wait for 1 ns;
        assert data_out = X"FFFFFFDE"
            report "LB sign extension failed" severity error;

        -- Load Unsigned Byte (LBU) at offset +3 (0xDE -> 0x000000DE)
        funct3 <= F3_BYTE_U;
        wait for 1 ns;
        assert data_out = X"000000DE"
            report "LBU zero extension failed" severity error;

        -- Store Byte (SB) at 0x00000010
        data_addr <= X"00000010";
        data_in   <= X"00000042";
        funct3    <= F3_BYTE;
        mem_write <= '1';
        wait for CLK_PERIOD;
        mem_write <= '0';

        funct3 <= F3_WORD;
        wait for 1 ns;
        assert data_out = X"DEADBE42"
            report "SB byte update failed" severity error;

        report "tb_Memory_Controller passed successfully." severity note;
        wait;
    end process;

end architecture sim;
