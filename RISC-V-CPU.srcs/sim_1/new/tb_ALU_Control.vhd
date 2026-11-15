library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity tb_ALU_Control is
end entity tb_ALU_Control;

architecture sim of tb_ALU_Control is
    signal alu_op    : std_logic_vector(2 downto 0) := ALUOP_LOAD_STORE;
    signal funct3    : std_logic_vector(2 downto 0) := "000";
    signal funct7_b5 : std_logic := '0';
    signal funct7_b0 : std_logic := '0';
    signal alu_ctrl  : std_logic_vector(4 downto 0);
begin

    uut: entity work.ALU_Control
        port map(
            alu_op    => alu_op,
            funct3    => funct3,
            funct7_b5 => funct7_b5,
            funct7_b0 => funct7_b0,
            alu_ctrl  => alu_ctrl
        );

    stim_proc: process
    begin
        alu_op <= ALUOP_LOAD_STORE;
        wait for 5 ns;
        assert alu_ctrl = ALU_ADD report "Load/Store should select ALU_ADD" severity error;

        alu_op    <= ALUOP_R_TYPE;
        funct3    <= F3_ADD_SUB;
        funct7_b5 <= '1';
        wait for 5 ns;
        assert alu_ctrl = ALU_SUB report "R-type SUB failed" severity error;

        funct7_b5 <= '0';
        funct3    <= F3_AND;
        wait for 5 ns;
        assert alu_ctrl = ALU_AND report "R-type AND failed" severity error;

        alu_op <= ALUOP_BRANCH;
        funct3 <= F3_BEQ;
        wait for 5 ns;
        assert alu_ctrl = ALU_SUB report "BEQ should select ALU_SUB" severity error;

        alu_op    <= ALUOP_R_TYPE;
        funct7_b5 <= '0';
        funct7_b0 <= '1';
        funct3    <= F3_MUL;
        wait for 5 ns;
        assert alu_ctrl = ALU_MUL report "M-ext MUL failed" severity error;

        funct3 <= F3_DIV;
        wait for 5 ns;
        assert alu_ctrl = ALU_DIV report "M-ext DIV failed" severity error;

        funct3 <= F3_REMU;
        wait for 5 ns;
        assert alu_ctrl = ALU_REMU report "M-ext REMU failed" severity error;

        report "tb_ALU_Control passed successfully." severity note;
        wait;
    end process;

end architecture sim;
