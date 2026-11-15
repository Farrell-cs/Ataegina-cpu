library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_Div_Unit is
end entity tb_Div_Unit;

architecture sim of tb_Div_Unit is
    constant CLK_PERIOD : time := 10 ns;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal alu_ctrl   : std_logic_vector(4 downto 0) := ALU_ADD;
    signal in_1       : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal in_2       : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal is_div_op  : std_logic;
    signal stall      : std_logic;
    signal div_result : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.Div_Unit
        port map(
            clk        => clk,
            rst        => rst,
            alu_ctrl   => alu_ctrl,
            in_1       => in_1,
            in_2       => in_2,
            is_div_op  => is_div_op,
            stall      => stall,
            div_result => div_result
        );

    clk_proc: process
    begin
        while true loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stim_proc: process
        procedure run_div(
            op      : std_logic_vector(4 downto 0);
            a       : std_logic_vector(31 downto 0);
            b       : std_logic_vector(31 downto 0);
            exp     : std_logic_vector(31 downto 0);
            msg     : string
        ) is
        begin
            alu_ctrl <= op;
            in_1     <= a;
            in_2     <= b;
            wait for 1 ns;
            while stall = '1' loop
                wait until rising_edge(clk);
                wait for 1 ns;
            end loop;
            assert div_result = exp report msg severity error;
            wait until rising_edge(clk);
            alu_ctrl <= ALU_ADD;
            wait for 1 ns;
        end procedure;
    begin
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait until rising_edge(clk);

        -- Normal signed DIV / REM
        run_div(ALU_DIV,  std_logic_vector(to_signed(-100, 32)), std_logic_vector(to_signed(7, 32)),
                std_logic_vector(to_signed(-14, 32)), "DIV -100 / 7 failed");
        run_div(ALU_REM,  std_logic_vector(to_signed(-100, 32)), std_logic_vector(to_signed(7, 32)),
                std_logic_vector(to_signed(-2, 32)), "REM -100 % 7 failed");

        -- Normal unsigned DIVU / REMU
        run_div(ALU_DIVU, X"80000005", X"00000002", X"40000002", "DIVU failed");
        run_div(ALU_REMU, X"80000005", X"00000002", X"00000001", "REMU failed");

        -- Divide by zero (spec: quotient = -1, remainder = dividend)
        run_div(ALU_DIV,  X"12345678", X"00000000", X"FFFFFFFF", "DIV by zero failed");
        run_div(ALU_REM,  X"12345678", X"00000000", X"12345678", "REM by zero failed");
        run_div(ALU_DIVU, X"12345678", X"00000000", X"FFFFFFFF", "DIVU by zero failed");
        run_div(ALU_REMU, X"12345678", X"00000000", X"12345678", "REMU by zero failed");

        -- Signed overflow (-2^31 / -1 -> -2^31, rem -> 0)
        run_div(ALU_DIV,  X"80000000", X"FFFFFFFF", X"80000000", "DIV overflow failed");
        run_div(ALU_REM,  X"80000000", X"FFFFFFFF", X"00000000", "REM overflow failed");

        report "tb_Div_Unit passed successfully." severity note;
        std.env.stop;
        wait;
    end process;

end architecture sim;
