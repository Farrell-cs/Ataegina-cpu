library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity Branch_And is
    port(
        branch : in  std_logic;
        jump   : in  std_logic;
        funct3 : in  std_logic_vector(2 downto 0);
        zero   : in  std_logic;
        pc_src : out std_logic
    );
end entity Branch_And;

architecture Behavioral of Branch_And is
    signal branch_taken : std_logic;
begin

    process(funct3, zero)
    begin
        case funct3 is
            when F3_BEQ  => branch_taken <= zero;
            when F3_BNE  => branch_taken <= not zero;
            when F3_BLT  => branch_taken <= not zero;
            when F3_BGE  => branch_taken <= zero;
            when F3_BLTU => branch_taken <= not zero;
            when F3_BGEU => branch_taken <= zero;
            when others  => branch_taken <= '0';
        end case;
    end process;

    pc_src <= (branch and branch_taken) or jump;

end Behavioral;
