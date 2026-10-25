library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity PC_Unit is
    port(
        clk    : in  std_logic;
        opcode : in  std_logic_vector(1 downto 0);
        PC_In  : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        PC_Out : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity PC_Unit;

architecture Behavioral of PC_Unit is
    signal current_pc : std_logic_vector(WORD_WIDTH - 1 downto 0) := X"00000000";
begin

    process(clk)
    begin
        if rising_edge(clk) then
            case opcode is
                when PC_OP_HALT =>
                    null;
                when PC_OP_INC =>
                    current_pc <= std_logic_vector(unsigned(current_pc) + 4);
                when PC_OP_ASSIGN =>
                    current_pc <= PC_In(31 downto 1) & '0';
                when PC_OP_RESET =>
                    current_pc <= X"00000000";
                when others =>
                    null;
            end case;
        end if;
    end process;

    PC_Out <= current_pc;

end Behavioral;
