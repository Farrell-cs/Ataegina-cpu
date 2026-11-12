library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_HDMI_Controller is
end tb_HDMI_Controller;

architecture rtl of tb_HDMI_Controller is

    constant clk_period  : time    := 8 ns;
    constant reset_time  : time    := 20 * clk_period;
    constant sim_window  : time    := 2000 * clk_period;

    signal clk           : std_logic := '0';
    signal rst           : std_logic := '1';
    signal clk_cpu_o     : std_logic;
    signal pll_locked    : std_logic;
    signal vram_we       : std_logic := '0';
    signal vram_addr     : std_logic_vector(15 downto 0) := (others => '0');
    signal vram_din      : std_logic_vector(7 downto 0) := (others => '0');
    signal vram_dout     : std_logic_vector(7 downto 0);
    signal clk_p, clk_n  : std_logic;
    signal data_p, data_n: std_logic_vector(2 downto 0);

begin

    uut0: entity work.HDMI_Controller
        generic map(
            SERIES6 => false
        )
        port map(
            clk_125mhz => clk,
            rst        => rst,
            clk_cpu_o  => clk_cpu_o,
            pll_locked => pll_locked,
            vram_we    => vram_we,
            vram_addr  => vram_addr,
            vram_din   => vram_din,
            vram_dout  => vram_dout,
            clk_p      => clk_p,
            clk_n      => clk_n,
            data_p     => data_p,
            data_n     => data_n
        );

    clk_proc: process
    begin
        while now < (reset_time + sim_window) loop
            clk <= '0'; wait for clk_period / 2;
            clk <= '1'; wait for clk_period / 2;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        rst <= '1';
        wait for reset_time;
        rst <= '0';
        wait for sim_window;

        assert pll_locked = '1'
            report "PLL failed to lock" severity error;
        assert (clk_p = '0' or clk_p = '1') and (clk_n = not clk_p)
            report "Clock output error" severity error;

        report "tb_HDMI_Controller passed successfully." severity note;
        wait;
    end process;

end rtl;
