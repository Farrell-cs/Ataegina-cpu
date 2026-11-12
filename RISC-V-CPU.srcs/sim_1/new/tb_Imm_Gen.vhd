library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity tb_Imm_Gen is
end entity tb_Imm_Gen;

architecture sim of tb_Imm_Gen is
    signal instruction : std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal imm_out     : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    uut: entity work.Imm_Gen
        port map(
            instruction => instruction,
            imm_out     => imm_out
        );

    stim_proc: process
    begin
        instruction <= X"FFC00093";
        wait for 5 ns;
        assert imm_out = X"FFFFFFFC" report "I-type mismatch" severity error;

        instruction <= X"0020A423";
        wait for 5 ns;
        assert imm_out = X"00000008" report "S-type mismatch" severity error;

        instruction <= X"FE208CE3";
        wait for 5 ns;
        assert imm_out = X"FFFFFFF8" report "B-type mismatch" severity error;

        instruction <= X"123452B7";
        wait for 5 ns;
        assert imm_out = X"12345000" report "U-type mismatch" severity error;

        report "tb_Imm_Gen passed successfully." severity note;
        wait;
    end process;

end architecture sim;
