library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_CPU_Top is
end entity tb_CPU_Top;

architecture sim of tb_CPU_Top is
    constant CLK_PERIOD : time := 10 ns;

    signal clk             : std_logic := '0';
    signal rst             : std_logic := '1';
    signal pc_out_dbg      : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal instruction_dbg : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal alu_result_dbg  : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal write_data_dbg  : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.CPU_Top
        generic map(
            IMEM_WORDS => 256,
            DMEM_WORDS => 256
        )
        port map(
            clk             => clk,
            rst             => rst,
            pc_out_dbg      => pc_out_dbg,
            instruction_dbg => instruction_dbg,
            alu_result_dbg  => alu_result_dbg,
            write_data_dbg  => write_data_dbg
        );

    clk_proc: process
    begin
        while now < 300 ns loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        rst <= '1';
        wait for CLK_PERIOD * 3;
        wait until falling_edge(clk);
        assert pc_out_dbg = X"00000000" report "Reset failed to hold PC at 0x00" severity error;
        rst <= '0';

        -- Cycle 1 (PC = 0x00): addi x1, x0, 10
        assert pc_out_dbg = X"00000000" report "Cycle 1 PC mismatch" severity error;
        assert write_data_dbg = std_logic_vector(to_unsigned(10, 32))
            report "Cycle 1: addi x1 writeback mismatch" severity error;

        -- Cycle 2 (PC = 0x04): addi x2, x0, 20
        wait until falling_edge(clk);
        assert pc_out_dbg = X"00000004" report "Cycle 2 PC mismatch" severity error;
        assert write_data_dbg = std_logic_vector(to_unsigned(20, 32))
            report "Cycle 2: addi x2 writeback mismatch" severity error;

        -- Cycle 3 (PC = 0x08): add x3, x1, x2 (10 + 20 = 30)
        wait until falling_edge(clk);
        assert pc_out_dbg = X"00000008" report "Cycle 3 PC mismatch" severity error;
        assert write_data_dbg = std_logic_vector(to_unsigned(30, 32))
            report "Cycle 3: add x3 writeback mismatch" severity error;

        -- Cycle 4 (PC = 0x0C): sw x3, 16(x0)
        wait until falling_edge(clk);
        assert pc_out_dbg = X"0000000C" report "Cycle 4 PC mismatch" severity error;
        assert alu_result_dbg = X"00000010"
            report "Cycle 4: sw address mismatch" severity error;

        -- Cycle 5 (PC = 0x10): lw x4, 16(x0) -> loads 30 from Data_Memory
        wait until falling_edge(clk);
        assert pc_out_dbg = X"00000010" report "Cycle 5 PC mismatch" severity error;
        assert write_data_dbg = std_logic_vector(to_unsigned(30, 32))
            report "Cycle 5: lw x4 writeback mismatch" severity error;

        -- Cycle 6 (PC = 0x14): beq x3, x4, +8 (30 == 30 -> Zero='1', PCSrc='1')
        wait until falling_edge(clk);
        assert pc_out_dbg = X"00000014" report "Cycle 6 PC mismatch" severity error;

        -- Cycle 7 (PC = 0x1C): addi x5, x0, 42 (branch skipped 0x18!)
        wait until falling_edge(clk);
        assert pc_out_dbg = X"0000001C" report "Cycle 7: Branch did not skip 0x18 to 0x1C" severity error;
        assert write_data_dbg = std_logic_vector(to_unsigned(42, 32))
            report "Cycle 7: addi x5 writeback mismatch" severity error;

        report "ALL TESTS PASSED: Figure 4.17 RISC-V Datapath executes end-to-end!" severity note;
        wait;
    end process;

end architecture sim;
