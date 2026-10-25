library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity ALU is
    port(
        A        : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        B        : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        opcode   : in  std_logic_vector(3 downto 0);
        zero     : out std_logic;
        ALU_Out  : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity ALU;

architecture Behavioral of ALU is
    signal alu_result : std_logic_vector(WORD_WIDTH - 1 downto 0);
begin

    process(A, B, opcode)
        variable shift_amt : natural range 0 to 31;
    begin
        shift_amt := to_integer(unsigned(B(4 downto 0)));

        case opcode is
            when ALU_ADD =>
                alu_result <= std_logic_vector(unsigned(A) + unsigned(B));

            when ALU_SUB =>
                alu_result <= std_logic_vector(unsigned(A) - unsigned(B));

            when ALU_SLL =>
                alu_result <= std_logic_vector(shift_left(unsigned(A), shift_amt));

            when ALU_SLT =>
                if signed(A) < signed(B) then
                    alu_result <= (0 => '1', others => '0');
                else
                    alu_result <= (others => '0');
                end if;

            when ALU_SLTU =>
                if unsigned(A) < unsigned(B) then
                    alu_result <= (0 => '1', others => '0');
                else
                    alu_result <= (others => '0');
                end if;

            when ALU_XOR =>
                alu_result <= A xor B;

            when ALU_SRL =>
                alu_result <= std_logic_vector(shift_right(unsigned(A), shift_amt));

            when ALU_SRA =>
                alu_result <= std_logic_vector(shift_right(signed(A), shift_amt));

            when ALU_OR =>
                alu_result <= A or B;

            when ALU_AND =>
                alu_result <= A and B;

            when ALU_EQ =>
                if A = B then
                    alu_result <= (0 => '1', others => '0');
                else
                    alu_result <= (others => '0');
                end if;

            when ALU_PASS_B =>
                alu_result <= B;

            when others =>
                alu_result <= (others => '0');
        end case;
    end process;

    zero    <= '1' when alu_result = X"00000000" else '0';
    ALU_Out <= alu_result;

end Behavioral;
