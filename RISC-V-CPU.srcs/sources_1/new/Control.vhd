library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity Control is
    port(
        opcode     : in  std_logic_vector(6 downto 0);
        branch     : out std_logic;
        mem_read   : out std_logic;
        mem_to_reg : out std_logic;
        alu_op     : out std_logic_vector(2 downto 0);
        mem_write  : out std_logic;
        alu_src    : out std_logic;
        reg_write  : out std_logic;
        jump       : out std_logic;
        jalr       : out std_logic;
        auipc      : out std_logic
    );
end entity Control;

architecture Behavioral of Control is
begin

    process(opcode)
    begin
        branch     <= '0';
        mem_read   <= '0';
        mem_to_reg <= '0';
        alu_op     <= ALUOP_LOAD_STORE;
        mem_write  <= '0';
        alu_src    <= '0';
        reg_write  <= '0';
        jump       <= '0';
        jalr       <= '0';
        auipc      <= '0';

        case opcode is
            when OP_REG =>
                reg_write <= '1';
                alu_src   <= '0';
                alu_op    <= ALUOP_R_TYPE;

            when OP_IMM =>
                reg_write <= '1';
                alu_src   <= '1';
                alu_op    <= ALUOP_I_TYPE;

            when OP_LOAD =>
                reg_write  <= '1';
                mem_read   <= '1';
                mem_to_reg <= '1';
                alu_src    <= '1';
                alu_op     <= ALUOP_LOAD_STORE;

            when OP_STORE =>
                mem_write <= '1';
                alu_src   <= '1';
                alu_op    <= ALUOP_LOAD_STORE;

            when OP_BRANCH =>
                branch  <= '1';
                alu_src <= '0';
                alu_op  <= ALUOP_BRANCH;

            when OP_LUI =>
                reg_write <= '1';
                alu_src   <= '1';
                alu_op    <= ALUOP_LUI;

            when OP_AUIPC =>
                reg_write <= '1';
                alu_src   <= '1';
                auipc     <= '1';
                alu_op    <= ALUOP_LOAD_STORE;

            when OP_JAL =>
                reg_write <= '1';
                jump      <= '1';

            when OP_JALR =>
                reg_write <= '1';
                jump      <= '1';
                jalr      <= '1';
                alu_src   <= '1';
                alu_op    <= ALUOP_LOAD_STORE;

            when others =>
                null;
        end case;
    end process;

end Behavioral;
