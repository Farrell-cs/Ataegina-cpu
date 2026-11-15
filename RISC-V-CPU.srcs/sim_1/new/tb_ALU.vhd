library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_ALU is
end entity tb_ALU;

architecture sim of tb_ALU is
    signal in_1       : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal in_2       : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal alu_ctrl   : std_logic_vector(4 downto 0) := ALU_ADD;
    signal zero       : std_logic;
    signal alu_result : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.ALU
        port map(
            in_1       => in_1,
            in_2       => in_2,
            alu_ctrl   => alu_ctrl,
            zero       => zero,
            alu_result => alu_result
        );

    stim_proc: process
    begin
        in_1     <= std_logic_vector(to_unsigned(15, 32));
        in_2     <= std_logic_vector(to_unsigned(27, 32));
        alu_ctrl <= ALU_ADD;
        wait for 10 ns;
        assert alu_result = std_logic_vector(to_unsigned(42, 32)) report "ALU_ADD failed" severity error;
        assert zero = '0' report "Zero flag mismatch" severity error;

        in_1     <= std_logic_vector(to_unsigned(20, 32));
        in_2     <= std_logic_vector(to_unsigned(20, 32));
        alu_ctrl <= ALU_SUB;
        wait for 10 ns;
        assert alu_result = X"00000000" and zero = '1' report "ALU_SUB / Zero failed" severity error;

        in_1     <= std_logic_vector(to_signed(-5, 32));
        in_2     <= std_logic_vector(to_signed(3, 32));
        alu_ctrl <= ALU_SLT;
        wait for 10 ns;
        assert alu_result = X"00000001" report "ALU_SLT failed" severity error;

        alu_ctrl <= ALU_SLTU;
        wait for 10 ns;
        assert alu_result = X"00000000" report "ALU_SLTU failed" severity error;

        in_1     <= std_logic_vector(to_signed(-7, 32));
        in_2     <= std_logic_vector(to_signed(6, 32));
        alu_ctrl <= ALU_MUL;
        wait for 10 ns;
        assert alu_result = std_logic_vector(to_signed(-42, 32)) report "ALU_MUL failed" severity error;

        alu_ctrl <= ALU_MULH;
        wait for 10 ns;
        assert alu_result = X"FFFFFFFF" report "ALU_MULH failed" severity error;

        in_1     <= X"80000000";
        in_2     <= X"00000002";
        alu_ctrl <= ALU_MULHSU;
        wait for 10 ns;
        assert alu_result = X"FFFFFFFF" report "ALU_MULHSU failed" severity error;

        alu_ctrl <= ALU_MULHU;
        wait for 10 ns;
        assert alu_result = X"00000001" report "ALU_MULHU failed" severity error;

        report "tb_ALU passed successfully." severity note;
        wait;
    end process;

end architecture sim;
