library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity tb_Instruction_Memory is
end entity tb_Instruction_Memory;

architecture sim of tb_Instruction_Memory is
    signal read_address : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal instruction  : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.Instruction_Memory
        generic map(IMEM_WORDS => 256)
        port map(
            read_address => read_address,
            instruction  => instruction
        );

    stim_proc: process
    begin
        read_address <= X"00000000";
        wait for 5 ns;
        assert instruction = X"00A00093" report "IMEM[0] mismatch" severity error;

        read_address <= X"00000004";
        wait for 5 ns;
        assert instruction = X"01400113" report "IMEM[1] mismatch" severity error;

        report "tb_Instruction_Memory passed successfully." severity note;
        wait;
    end process;

end architecture sim;
