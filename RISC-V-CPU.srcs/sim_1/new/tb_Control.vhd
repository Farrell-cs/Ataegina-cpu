library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity tb_Control is
end entity tb_Control;

architecture sim of tb_Control is
    signal opcode     : std_logic_vector(6 downto 0) := (others => '0');
    signal branch     : std_logic;
    signal mem_read   : std_logic;
    signal mem_to_reg : std_logic;
    signal alu_op     : std_logic_vector(2 downto 0);
    signal mem_write  : std_logic;
    signal alu_src    : std_logic;
    signal reg_write  : std_logic;
    signal jump       : std_logic;
    signal jalr       : std_logic;
    signal auipc      : std_logic;
begin

    uut: entity work.Control
        port map(
            opcode     => opcode,
            branch     => branch,
            mem_read   => mem_read,
            mem_to_reg => mem_to_reg,
            alu_op     => alu_op,
            mem_write  => mem_write,
            alu_src    => alu_src,
            reg_write  => reg_write,
            jump       => jump,
            jalr       => jalr,
            auipc      => auipc
        );

    stim_proc: process
    begin
        opcode <= OP_REG;
        wait for 5 ns;
        assert reg_write = '1' and alu_src = '0' and alu_op = ALUOP_R_TYPE
            report "OP_REG control failed" severity error;

        opcode <= OP_LOAD;
        wait for 5 ns;
        assert reg_write = '1' and mem_read = '1' and mem_to_reg = '1' and alu_src = '1'
            report "OP_LOAD control failed" severity error;

        opcode <= OP_STORE;
        wait for 5 ns;
        assert mem_write = '1' and reg_write = '0' and alu_src = '1'
            report "OP_STORE control failed" severity error;

        opcode <= OP_BRANCH;
        wait for 5 ns;
        assert branch = '1' and alu_op = ALUOP_BRANCH
            report "OP_BRANCH control failed" severity error;

        report "tb_Control passed successfully." severity note;
        wait;
    end process;

end architecture sim;
