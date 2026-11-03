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
        -- I-Type: addi x1, x0, -4 (0xFFC00093)
        instruction <= X"FFC00093";
        wait for 5 ns;
        assert imm_out = X"FFFFFFFC" report "I-type imm failed" severity error;

        -- S-Type: sw x2, 8(x1) (0x0020A423)
        instruction <= X"0020A423";
        wait for 5 ns;
        assert imm_out = X"00000008" report "S-type imm failed" severity error;

        -- B-Type: beq x1, x2, -8 (0xFE208CE3)
        instruction <= X"FE208CE3";
        wait for 5 ns;
        assert imm_out = X"FFFFFFF8" report "B-type imm failed" severity error;

        -- U-Type: lui x5, 0x12345 (0x123452B7)
        instruction <= X"123452B7";
        wait for 5 ns;
        assert imm_out = X"12345000" report "U-type imm failed" severity error;

        report "tb_Imm_Gen passed successfully." severity note;
        wait;
    end process;

end architecture sim;
