library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity ALU is
    port(
        in_1       : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        in_2       : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        alu_ctrl   : in  std_logic_vector(4 downto 0);
        zero       : out std_logic;
        alu_result : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity ALU;

architecture Behavioral of ALU is
    signal result_s : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal mul_a    : signed(WORD_WIDTH downto 0);
    signal mul_b    : signed(WORD_WIDTH downto 0);
    signal mul_prod : std_logic_vector(2 * WORD_WIDTH + 1 downto 0);
begin

    -- Shared 33x33 signed multiplier covers signed*signed, signed*unsigned, and unsigned*unsigned
    mul_a <= signed('0' & in_1) when alu_ctrl = ALU_MULHU else
             signed(in_1(WORD_WIDTH - 1) & in_1);

    mul_b <= signed('0' & in_2) when (alu_ctrl = ALU_MULHSU or alu_ctrl = ALU_MULHU) else
             signed(in_2(WORD_WIDTH - 1) & in_2);

    mul_prod <= std_logic_vector(mul_a * mul_b);

    process(in_1, in_2, alu_ctrl, mul_prod)
        variable shift_amt : natural range 0 to 31;
    begin
        shift_amt := to_integer(unsigned(in_2(4 downto 0)));

        case alu_ctrl is
            when ALU_AND =>
                result_s <= in_1 and in_2;

            when ALU_OR =>
                result_s <= in_1 or in_2;

            when ALU_ADD =>
                result_s <= std_logic_vector(unsigned(in_1) + unsigned(in_2));

            when ALU_SUB =>
                result_s <= std_logic_vector(unsigned(in_1) - unsigned(in_2));

            when ALU_SLL =>
                result_s <= std_logic_vector(shift_left(unsigned(in_1), shift_amt));

            when ALU_SLT =>
                if signed(in_1) < signed(in_2) then
                    result_s <= (0 => '1', others => '0');
                else
                    result_s <= (others => '0');
                end if;

            when ALU_SLTU =>
                if unsigned(in_1) < unsigned(in_2) then
                    result_s <= (0 => '1', others => '0');
                else
                    result_s <= (others => '0');
                end if;

            when ALU_XOR =>
                result_s <= in_1 xor in_2;

            when ALU_SRL =>
                result_s <= std_logic_vector(shift_right(unsigned(in_1), shift_amt));

            when ALU_SRA =>
                result_s <= std_logic_vector(shift_right(signed(in_1), shift_amt));

            when ALU_PASS_B =>
                result_s <= in_2;

            when ALU_MUL =>
                result_s <= mul_prod(WORD_WIDTH - 1 downto 0);

            when ALU_MULH | ALU_MULHSU | ALU_MULHU =>
                result_s <= mul_prod(2 * WORD_WIDTH - 1 downto WORD_WIDTH);

            when others =>
                result_s <= (others => '0');
        end case;
    end process;

    zero       <= '1' when result_s = X"00000000" else '0';
    alu_result <= result_s;

end Behavioral;
