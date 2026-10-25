library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_Constants is
end entity tb_Constants;

architecture sim of tb_Constants is
begin
    process
    begin
        assert WORD_WIDTH = 32
            report "WORD_WIDTH must be 32 for RV32I" severity failure;
        assert REG_ADDR_WIDTH = 5
            report "REG_ADDR_WIDTH must be 5 for 32 registers" severity failure;
        assert OP_IMM = "0010011"
            report "OP_IMM mismatch" severity failure;
        assert OP_REG = "0110011"
            report "OP_REG mismatch" severity failure;
        assert OP_LOAD = "0000011"
            report "OP_LOAD mismatch" severity failure;
        assert OP_STORE = "0100011"
            report "OP_STORE mismatch" severity failure;
        assert OP_BRANCH = "1100011"
            report "OP_BRANCH mismatch" severity failure;

        report "tb_Constants passed successfully." severity note;
        wait;
    end process;
end architecture sim;
