library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity clock_gen is
    generic (
        CLKIN_PERIOD : real    := 8.000;
        CLK_MULTIPLY : integer := 59;
        CLK_DIVIDE   : integer := 5;
        CLKOUT0_DIV  : integer := 4;  -- 368.75 MHz (5x serial DDR clock for 720p)
        CLKOUT1_DIV  : integer := 20; -- 73.75 MHz  (1x pixel clock for 720p)
        CLKOUT2_DIV  : integer := 40  -- 36.875 MHz (Single-cycle CPU clock)
    );
    port(
        clk_i      : in  std_logic;
        clk0_o     : out std_logic;
        clk1_o     : out std_logic;
        clk2_o     : out std_logic;
        locked_o   : out std_logic
    );
end clock_gen;

architecture rtl of clock_gen is
    signal pllclk0, pllclk1, pllclk2 : std_logic;
    signal clkfbout                  : std_logic;
begin

    clk0buf: BUFG port map (I => pllclk0, O => clk0_o);
    clk1buf: BUFG port map (I => pllclk1, O => clk1_o);
    clk2buf: BUFG port map (I => pllclk2, O => clk2_o);

    clock: PLLE2_BASE
        generic map (
            clkin1_period  => CLKIN_PERIOD,
            clkfbout_mult  => CLK_MULTIPLY,
            clkout0_divide => CLKOUT0_DIV,
            clkout1_divide => CLKOUT1_DIV,
            clkout2_divide => CLKOUT2_DIV,
            divclk_divide  => CLK_DIVIDE
        )
        port map(
            rst      => '0',
            pwrdwn   => '0',
            clkin1   => clk_i,
            clkfbin  => clkfbout,
            clkfbout => clkfbout,
            clkout0  => pllclk0,
            clkout1  => pllclk1,
            clkout2  => pllclk2,
            locked   => locked_o
        );

end rtl;
