library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_ALU is
end entity tb_ALU;

architecture sim of tb_ALU is
    signal A       : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal B       : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal opcode  : std_logic_vector(3 downto 0) := ALU_ADD;
    signal zero    : std_logic;
    signal ALU_Out : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.ALU
        port map(
            A       => A,
            B       => B,
            opcode  => opcode,
            zero    => zero,
            ALU_Out => ALU_Out
        );

    stim_proc: process
    begin
        -- Addition: 15 + 27 = 42
        A      <= std_logic_vector(to_unsigned(15, 32));
        B      <= std_logic_vector(to_unsigned(27, 32));
        opcode <= ALU_ADD;
        wait for 10 ns;
        assert ALU_Out = std_logic_vector(to_unsigned(42, 32))
            report "ALU_ADD failed" severity error;
        assert zero = '0'
            report "ALU zero flag should be 0" severity error;

        -- Subtraction: 20 - 20 = 0
        A      <= std_logic_vector(to_unsigned(20, 32));
        B      <= std_logic_vector(to_unsigned(20, 32));
        opcode <= ALU_SUB;
        wait for 10 ns;
        assert ALU_Out = X"00000000"
            report "ALU_SUB failed" severity error;
        assert zero = '1'
            report "ALU zero flag should be 1" severity error;

        -- Signed Less Than: -5 < 3 => 1
        A      <= std_logic_vector(to_signed(-5, 32));
        B      <= std_logic_vector(to_signed(3, 32));
        opcode <= ALU_SLT;
        wait for 10 ns;
        assert ALU_Out = X"00000001"
            report "ALU_SLT failed for signed negative" severity error;

        -- Unsigned Less Than: 0xFFFFFFFB < 3 => 0
        opcode <= ALU_SLTU;
        wait for 10 ns;
        assert ALU_Out = X"00000000"
            report "ALU_SLTU failed for unsigned comparison" severity error;

        -- Shifts: SLL, SRL, SRA
        A      <= X"F0000008";
        B      <= std_logic_vector(to_unsigned(2, 32));
        opcode <= ALU_SLL;
        wait for 10 ns;
        assert ALU_Out = X"C0000020"
            report "ALU_SLL failed" severity error;

        opcode <= ALU_SRL;
        wait for 10 ns;
        assert ALU_Out = X"3C000002"
            report "ALU_SRL failed" severity error;

        opcode <= ALU_SRA;
        wait for 10 ns;
        assert ALU_Out = X"FC000002"
            report "ALU_SRA failed" severity error;

        -- Bitwise AND, OR, XOR
        A      <= X"FF00FF00";
        B      <= X"0F0F0F0F";
        opcode <= ALU_AND;
        wait for 10 ns;
        assert ALU_Out = X"0F000F00"
            report "ALU_AND failed" severity error;

        opcode <= ALU_OR;
        wait for 10 ns;
        assert ALU_Out = X"FF0FFF0F"
            report "ALU_OR failed" severity error;

        opcode <= ALU_XOR;
        wait for 10 ns;
        assert ALU_Out = X"F00FF00F"
            report "ALU_XOR failed" severity error;

        report "tb_ALU passed successfully." severity note;
        wait;
    end process;

end architecture sim;
