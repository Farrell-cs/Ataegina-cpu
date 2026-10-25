library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_PC_Unit is
end entity tb_PC_Unit;

architecture sim of tb_PC_Unit is
    constant CLK_PERIOD : time := 10 ns;

    signal clk    : std_logic := '0';
    signal opcode : std_logic_vector(1 downto 0) := PC_OP_RESET;
    signal PC_In  : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal PC_Out : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.PC_Unit
        port map(
            clk    => clk,
            opcode => opcode,
            PC_In  => PC_In,
            PC_Out => PC_Out
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
        -- Reset PC
        opcode <= PC_OP_RESET;
        wait for CLK_PERIOD;
        assert PC_Out = X"00000000"
            report "PC Reset failed" severity error;

        -- Increment PC twice (+4 each cycle)
        opcode <= PC_OP_INC;
        wait for CLK_PERIOD;
        assert PC_Out = X"00000004"
            report "PC Increment 1 failed" severity error;

        wait for CLK_PERIOD;
        assert PC_Out = X"00000008"
            report "PC Increment 2 failed" severity error;

        -- Halt PC
        opcode <= PC_OP_HALT;
        wait for CLK_PERIOD;
        assert PC_Out = X"00000008"
            report "PC Halt failed" severity error;

        -- Branch / Jump target assignment
        PC_In  <= X"00000040";
        opcode <= PC_OP_ASSIGN;
        wait for CLK_PERIOD;
        assert PC_Out = X"00000040"
            report "PC Assign failed" severity error;

        report "tb_PC_Unit passed successfully." severity note;
        wait;
    end process;

end architecture sim;
