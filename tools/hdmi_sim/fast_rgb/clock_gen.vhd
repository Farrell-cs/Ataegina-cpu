library ieee;
use ieee.std_logic_1164.all;

-- Simulation-only clock_gen for --fast-rgb: skips 368.75 MHz SerialClk (clk0_o)
-- while keeping exact PixelClk (73.75 MHz) and CPU clock (36.875 MHz).
entity clock_gen is
    generic (
        CLKIN_PERIOD : real    := 8.000;
        CLK_MULTIPLY : integer := 59;
        CLK_DIVIDE   : integer := 5;
        CLKOUT0_DIV  : integer := 4;
        CLKOUT1_DIV  : integer := 20;
        CLKOUT2_DIV  : integer := 40
    );
    port(
        clk_i    : in  std_logic;
        clk0_o   : out std_logic;
        clk1_o   : out std_logic;
        clk2_o   : out std_logic;
        locked_o : out std_logic
    );
end clock_gen;

architecture rtl of clock_gen is
    constant PIX_HALF_FS : time := integer((CLKIN_PERIOD * 1.0e6 * real(CLK_DIVIDE) * real(CLKOUT1_DIV)) / (2.0 * real(CLK_MULTIPLY))) * 1 fs;
    signal locked_s : std_logic := '0';
    signal c1       : std_logic := '0';
    signal c2       : std_logic := '0';
begin

    process
        variable cycles : integer := 0;
    begin
        locked_s <= '0';
        cycles := 0;
        while cycles < 4 loop
            wait until rising_edge(clk_i);
            cycles := cycles + 1;
        end loop;
        locked_s <= '1';
        wait;
    end process;

    process
        variable cnt2 : integer := 0;
    begin
        if locked_s = '0' then
            c1 <= '0';
            c2 <= '0';
            cnt2 := 0;
            wait until locked_s = '1';
        else
            wait for PIX_HALF_FS;
            c1 <= not c1;
            cnt2 := cnt2 + CLKOUT1_DIV;
            if cnt2 >= CLKOUT2_DIV then
                cnt2 := 0;
                c2 <= not c2;
            end if;
        end if;
    end process;

    clk0_o   <= '0';
    clk1_o   <= c1;
    clk2_o   <= c2;
    locked_o <= locked_s;

end rtl;
