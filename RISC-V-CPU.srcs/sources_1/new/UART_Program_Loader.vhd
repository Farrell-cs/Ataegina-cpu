library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_Program_Loader is
    generic(
        CLK_FREQ_HZ : integer := 36875000;
        BAUD_RATE   : integer := 115200
    );
    port(
        clk           : in  std_logic;
        rst           : in  std_logic;
        rx            : in  std_logic;
        loader_active : out std_logic;
        imem_we       : out std_logic;
        imem_addr     : out std_logic_vector(31 downto 0);
        imem_wdata    : out std_logic_vector(31 downto 0)
    );
end entity UART_Program_Loader;

architecture Behavioral of UART_Program_Loader is

    constant CLKS_PER_BIT : integer := CLK_FREQ_HZ / BAUD_RATE;
    constant HALF_BIT     : integer := CLKS_PER_BIT / 2;

    -- 2-stage synchronizer
    signal rx_sync_0 : std_logic := '1';
    signal rx_sync_1 : std_logic := '1';

    -- UART RX states
    type rx_state_t is (RX_IDLE, RX_START, RX_DATA, RX_STOP);
    signal rx_state     : rx_state_t := RX_IDLE;
    signal rx_clk_cnt   : integer range 0 to CLKS_PER_BIT := 0;
    signal rx_bit_idx   : integer range 0 to 7 := 0;
    signal rx_byte_reg  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid     : std_logic := '0';

    -- Loader FSM signals
    signal active_reg   : std_logic := '0';
    signal word_buf     : std_logic_vector(31 downto 0) := (others => '0');
    signal byte_idx     : integer range 0 to 3 := 0;
    signal word_addr    : unsigned(31 downto 0) := (others => '0');
    signal ff_count     : integer range 0 to 4 := 0;

begin

    loader_active <= active_reg;

    -- UART Receiver Process
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rx_sync_0  <= '1';
                rx_sync_1  <= '1';
                rx_state   <= RX_IDLE;
                rx_clk_cnt <= 0;
                rx_bit_idx <= 0;
                rx_valid   <= '0';
            else
                rx_sync_0 <= rx;
                rx_sync_1 <= rx_sync_0;
                rx_valid  <= '0';

                case rx_state is
                    when RX_IDLE =>
                        rx_clk_cnt <= 0;
                        rx_bit_idx <= 0;
                        if rx_sync_1 = '0' then
                            rx_state <= RX_START;
                        end if;

                    when RX_START =>
                        if rx_clk_cnt = HALF_BIT then
                            if rx_sync_1 = '0' then
                                rx_clk_cnt <= 0;
                                rx_state   <= RX_DATA;
                            else
                                rx_state   <= RX_IDLE;
                            end if;
                        else
                            rx_clk_cnt <= rx_clk_cnt + 1;
                        end if;

                    when RX_DATA =>
                        if rx_clk_cnt = CLKS_PER_BIT - 1 then
                            rx_clk_cnt <= 0;
                            rx_byte_reg(rx_bit_idx) <= rx_sync_1;
                            if rx_bit_idx = 7 then
                                rx_bit_idx <= 0;
                                rx_state   <= RX_STOP;
                            else
                                rx_bit_idx <= rx_bit_idx + 1;
                            end if;
                        else
                            rx_clk_cnt <= rx_clk_cnt + 1;
                        end if;

                    when RX_STOP =>
                        if rx_clk_cnt = CLKS_PER_BIT - 1 then
                            rx_clk_cnt <= 0;
                            rx_valid   <= '1';
                            rx_state   <= RX_IDLE;
                        else
                            rx_clk_cnt <= rx_clk_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- Program Loader FSM
    process(clk)
    begin
        if rising_edge(clk) then
            imem_we <= '0';

            if rst = '1' then
                active_reg <= '0';
                byte_idx   <= 0;
                word_addr  <= (others => '0');
                word_buf   <= (others => '0');
                ff_count   <= 0;
            elsif rx_valid = '1' then
                -- Any incoming byte activates the loader (holds CPU in reset)
                active_reg <= '1';

                if rx_byte_reg = X"FF" then
                    if ff_count >= 3 then
                        -- Received 4 consecutive 0xFF bytes: end sequence!
                        active_reg <= '0';  -- Release CPU from reset
                        byte_idx   <= 0;
                        word_addr  <= (others => '0');
                        ff_count   <= 0;
                    else
                        ff_count <= ff_count + 1;
                    end if;
                else
                    ff_count <= 0;
                end if;

                -- Assemble 32-bit word (little-endian)
                case byte_idx is
                    when 0 =>
                        word_buf(7 downto 0) <= rx_byte_reg;
                        byte_idx <= 1;
                    when 1 =>
                        word_buf(15 downto 8) <= rx_byte_reg;
                        byte_idx <= 2;
                    when 2 =>
                        word_buf(23 downto 16) <= rx_byte_reg;
                        byte_idx <= 3;
                    when 3 =>
                        word_buf(31 downto 24) <= rx_byte_reg;
                        byte_idx <= 0;

                        -- Pulse write enable to Instruction Memory
                        imem_we    <= '1';
                        imem_addr  <= std_logic_vector(word_addr);
                        imem_wdata <= rx_byte_reg & word_buf(23 downto 0);
                        word_addr  <= word_addr + 4;
                end case;
            end if;
        end if;
    end process;

end architecture Behavioral;
