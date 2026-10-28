library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_Registers is
end entity tb_Registers;

architecture sim of tb_Registers is
    constant CLK_PERIOD : time := 10 ns;

    signal clk       : std_logic := '0';
    signal reg_write : std_logic := '0';
    signal rd_addr   : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal din       : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal rs1_addr  : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal rs2_addr  : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal out_a     : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal out_b     : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.Registers
        port map(
            clk       => clk,
            reg_write => reg_write,
            rd_addr   => rd_addr,
            din       => din,
            rs1_addr  => rs1_addr,
            rs2_addr  => rs2_addr,
            out_a     => out_a,
            out_b     => out_b
        );

    clk_proc: process
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
        -- Test 1: Initial read from x0 and x1 should be 0
        rs1_addr <= "00000";
        rs2_addr <= "00001";
        wait for CLK_PERIOD;
        assert out_a = X"00000000" report "x0 should read 0" severity error;
        assert out_b = X"00000000" report "Unwritten x1 should read 0" severity error;

        -- Test 2: Write 0x12345678 into register x1
        rd_addr   <= "00001";
        din       <= X"12345678";
        reg_write <= '1';
        wait for CLK_PERIOD;
        reg_write <= '0';

        -- Verify x1 read
        rs1_addr <= "00001";
        wait for 1 ns;
        assert out_a = X"12345678" report "x1 write/read mismatch" severity error;

        -- Test 3: Attempt write to x0 (must remain 0)
        rd_addr   <= "00000";
        din       <= X"DEADBEEF";
        reg_write <= '1';
        wait for CLK_PERIOD;
        reg_write <= '0';

        rs1_addr <= "00000";
        wait for 1 ns;
        assert out_a = X"00000000" report "x0 must ALWAYS stay 0" severity error;

        -- Test 4: Dual read test (x1 and x2)
        rd_addr   <= "00010";
        din       <= X"CAFEBABE";
        reg_write <= '1';
        wait for CLK_PERIOD;
        reg_write <= '0';

        rs1_addr <= "00001";
        rs2_addr <= "00010";
        wait for 1 ns;
        assert out_a = X"12345678" report "Dual read port A mismatch" severity error;
        assert out_b = X"CAFEBABE" report "Dual read port B mismatch" severity error;

        report "tb_Registers passed successfully." severity note;
        wait;
    end process;

end architecture sim;
