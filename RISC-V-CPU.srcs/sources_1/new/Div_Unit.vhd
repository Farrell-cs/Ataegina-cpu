library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Div_Unit is
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        alu_ctrl   : in  std_logic_vector(4 downto 0);
        in_1       : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        in_2       : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        is_div_op  : out std_logic;
        stall      : out std_logic;
        div_result : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Div_Unit;

architecture Behavioral of Div_Unit is
    type state_t is (IDLE, RUN, DONE_S);
    signal state : state_t := IDLE;

    signal is_div_s    : std_logic;
    signal is_signed   : std_logic;
    signal is_rem      : std_logic;
    signal div_by_zero : std_logic;
    signal ovf_case    : std_logic;
    signal edge_case   : std_logic;

    signal cnt         : unsigned(4 downto 0) := (others => '0');
    signal quot_reg    : unsigned(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal rem_reg     : unsigned(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal div_reg     : unsigned(WORD_WIDTH - 1 downto 0) := (others => '0');
    signal quot_neg_r  : std_logic := '0';
    signal rem_neg_r   : std_logic := '0';
begin

    is_div_s <= '1' when (alu_ctrl = ALU_DIV  or alu_ctrl = ALU_DIVU or
                          alu_ctrl = ALU_REM  or alu_ctrl = ALU_REMU) else '0';
    is_signed <= '1' when (alu_ctrl = ALU_DIV or alu_ctrl = ALU_REM) else '0';
    is_rem    <= '1' when (alu_ctrl = ALU_REM or alu_ctrl = ALU_REMU) else '0';

    div_by_zero <= '1' when in_2 = X"00000000" else '0';
    ovf_case    <= '1' when (is_signed = '1' and in_1 = X"80000000" and in_2 = X"FFFFFFFF") else '0';
    edge_case   <= div_by_zero or ovf_case;

    is_div_op <= is_div_s;
    stall     <= '1' when (is_div_s = '1' and edge_case = '0' and state /= DONE_S) else '0';

    process(clk)
        variable abs_a    : unsigned(WORD_WIDTH - 1 downto 0);
        variable abs_b    : unsigned(WORD_WIDTH - 1 downto 0);
        variable rem_next : unsigned(WORD_WIDTH downto 0);
        variable div_ext  : unsigned(WORD_WIDTH downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state      <= IDLE;
                cnt        <= (others => '0');
                quot_reg   <= (others => '0');
                rem_reg    <= (others => '0');
                div_reg    <= (others => '0');
                quot_neg_r <= '0';
                rem_neg_r  <= '0';
            else
                case state is
                    when IDLE =>
                        if is_div_s = '1' and edge_case = '0' then
                            if is_signed = '1' and in_1(WORD_WIDTH - 1) = '1' then
                                abs_a := unsigned(-signed(in_1));
                            else
                                abs_a := unsigned(in_1);
                            end if;

                            if is_signed = '1' and in_2(WORD_WIDTH - 1) = '1' then
                                abs_b := unsigned(-signed(in_2));
                            else
                                abs_b := unsigned(in_2);
                            end if;

                            quot_reg   <= abs_a;
                            rem_reg    <= (others => '0');
                            div_reg    <= abs_b;
                            quot_neg_r <= is_signed and (in_1(WORD_WIDTH - 1) xor in_2(WORD_WIDTH - 1));
                            rem_neg_r  <= is_signed and in_1(WORD_WIDTH - 1);
                            cnt        <= to_unsigned(WORD_WIDTH - 1, 5);
                            state      <= RUN;
                        end if;

                    when RUN =>
                        rem_next := rem_reg & quot_reg(WORD_WIDTH - 1);
                        div_ext  := '0' & div_reg;
                        if rem_next >= div_ext then
                            rem_reg  <= resize(rem_next - div_ext, WORD_WIDTH);
                            quot_reg <= quot_reg(WORD_WIDTH - 2 downto 0) & '1';
                        else
                            rem_reg  <= rem_next(WORD_WIDTH - 1 downto 0);
                            quot_reg <= quot_reg(WORD_WIDTH - 2 downto 0) & '0';
                        end if;

                        if cnt = 0 then
                            state <= DONE_S;
                        else
                            cnt <= cnt - 1;
                        end if;

                    when DONE_S =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    process(is_rem, div_by_zero, ovf_case, in_1, quot_reg, rem_reg, quot_neg_r, rem_neg_r)
    begin
        if div_by_zero = '1' then
            if is_rem = '1' then
                div_result <= in_1;
            else
                div_result <= X"FFFFFFFF";
            end if;
        elsif ovf_case = '1' then
            if is_rem = '1' then
                div_result <= (others => '0');
            else
                div_result <= X"80000000";
            end if;
        else
            if is_rem = '1' then
                if rem_neg_r = '1' then
                    div_result <= std_logic_vector(-signed(rem_reg));
                else
                    div_result <= std_logic_vector(rem_reg);
                end if;
            else
                if quot_neg_r = '1' then
                    div_result <= std_logic_vector(-signed(quot_reg));
                else
                    div_result <= std_logic_vector(quot_reg);
                end if;
            end if;
        end if;
    end process;

end Behavioral;
