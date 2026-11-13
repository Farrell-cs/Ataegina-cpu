library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cpu_hdmi is
    generic (
        FRAME_WIDTH  : integer := 1280;
        FRAME_HEIGHT : integer := 720
    );
end entity tb_cpu_hdmi;

architecture sim of tb_cpu_hdmi is
    constant CLK_PERIOD : time := 8 ns;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal btn         : std_logic_vector(2 downto 0) := "000";
    signal uart_rx     : std_logic := '1';
    signal led         : std_logic_vector(3 downto 0);
    signal hdmi_clk_p  : std_logic;
    signal hdmi_clk_n  : std_logic;
    signal hdmi_data_p : std_logic_vector(2 downto 0);
    signal hdmi_data_n : std_logic_vector(2 downto 0);
    signal rx_done     : std_logic;
begin

    clk <= not clk after CLK_PERIOD / 2;

    dut: entity work.CPU_Top
        generic map (
            IMEM_WORDS => 1024,
            DMEM_WORDS => 1024
        )
        port map (
            clk         => clk,
            rst         => rst,
            btn         => btn,
            uart_rx     => uart_rx,
            led         => led,
            hdmi_clk_p  => hdmi_clk_p,
            hdmi_clk_n  => hdmi_clk_n,
            hdmi_data_p => hdmi_data_p,
            hdmi_data_n => hdmi_data_n
        );

    rx: entity work.tmds_receiver
        generic map (
            FRAME_WIDTH  => FRAME_WIDTH,
            FRAME_HEIGHT => FRAME_HEIGHT
        )
        port map (
            tmds_clk_p  => hdmi_clk_p,
            tmds_clk_n  => hdmi_clk_n,
            tmds_data_p => hdmi_data_p,
            tmds_data_n => hdmi_data_n,
            btn_out     => btn,
            done        => rx_done
        );

    stim: process
    begin
        rst <= '1';
        wait for CLK_PERIOD * 20;
        rst <= '0';
        wait;
    end process;

end architecture sim;
