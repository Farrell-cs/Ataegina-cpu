library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_HDMI_Controller is
end entity tb_HDMI_Controller;

architecture sim of tb_HDMI_Controller is
    constant CLK_PERIOD : time := 40 ns;

    signal pixel_clk    : std_logic := '0';
    signal rst          : std_logic := '1';
    signal rgb_in       : std_logic_vector(23 downto 0) := X"FF8800";
    signal hsync        : std_logic;
    signal vsync        : std_logic;
    signal video_active : std_logic;
    signal pixel_x      : std_logic_vector(9 downto 0);
    signal pixel_y      : std_logic_vector(9 downto 0);
    signal rgb_out      : std_logic_vector(23 downto 0);
begin

    uut: entity work.HDMI_Controller
        generic map(
            H_ACTIVE => 8,
            H_FP     => 2,
            H_SYNC   => 2,
            H_BP     => 2,
            V_ACTIVE => 4,
            V_FP     => 1,
            V_SYNC   => 1,
            V_BP     => 1
        )
        port map(
            pixel_clk    => pixel_clk,
            rst          => rst,
            rgb_in       => rgb_in,
            hsync        => hsync,
            vsync        => vsync,
            video_active => video_active,
            pixel_x      => pixel_x,
            pixel_y      => pixel_y,
            rgb_out      => rgb_out
        );

    clk_process: process
    begin
        while now < 1000 ns loop
            pixel_clk <= '0';
            wait for CLK_PERIOD / 2;
            pixel_clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_proc: process
    begin
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for 1 ns;

        assert video_active = '1'
            report "Active video should be high at (0,0)" severity error;
        assert rgb_out = X"FF8800"
            report "RGB output should match rgb_in during active video" severity error;

        -- Advance to horizontal sync region (8 active + 2 front porch = 10 cycles)
        wait for 10 * CLK_PERIOD;
        assert video_active = '0'
            report "Active video should be low during blanking" severity error;
        assert hsync = '0'
            report "HSYNC should pulse low during sync interval" severity error;
        assert rgb_out = X"000000"
            report "RGB output should be blanked to 0" severity error;

        report "tb_HDMI_Controller passed successfully." severity note;
        wait;
    end process;

end architecture sim;
