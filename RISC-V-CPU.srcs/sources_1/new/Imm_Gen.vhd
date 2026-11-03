library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Imm_Gen is
    port(
        instruction : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        imm_out     : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Imm_Gen;

architecture Behavioral of Imm_Gen is
begin

    process(instruction)
        variable op : std_logic_vector(6 downto 0);
    begin
        op := instruction(6 downto 0);

        case op is
            when OP_IMM | OP_LOAD | OP_JALR =>
                imm_out <= std_logic_vector(resize(signed(instruction(31 downto 20)), 32));

            when OP_STORE =>
                imm_out <= std_logic_vector(resize(signed(instruction(31 downto 25) & instruction(11 downto 7)), 32));

            when OP_BRANCH =>
                imm_out <= std_logic_vector(resize(signed(instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0'), 32));

            when OP_LUI | OP_AUIPC =>
                imm_out <= instruction(31 downto 12) & X"000";

            when OP_JAL =>
                imm_out <= std_logic_vector(resize(signed(instruction(31) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21) & '0'), 32));

            when others =>
                imm_out <= (others => '0');
        end case;
    end process;

end Behavioral;
