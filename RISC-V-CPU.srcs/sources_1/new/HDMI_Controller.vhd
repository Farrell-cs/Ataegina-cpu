library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity HDMI_Controller is
    generic (
        SERIES6 : boolean := false
    );
    port(
        clk_125mhz  : in  std_logic;
        rst         : in  std_logic;
        clk_cpu_o   : out std_logic;
        pll_locked  : out std_logic;
        vram_we     : in  std_logic;
        vram_addr   : in  std_logic_vector(15 downto 0);
        vram_din    : in  std_logic_vector(7 downto 0);
        vram_dout   : out std_logic_vector(7 downto 0);
        clk_p       : out std_logic;
        clk_n       : out std_logic;
        data_p      : out std_logic_vector(2 downto 0);
        data_n      : out std_logic_vector(2 downto 0)
    );
end HDMI_Controller;

architecture rtl of HDMI_Controller is

    signal pixclk, serclk, cpuclk : std_logic;
    signal locked_s               : std_logic;
    signal hdmi_rst               : std_logic;

    signal raw_active, raw_hsync, raw_vsync : std_logic := '0';
    signal fb_active, fb_hsync, fb_vsync    : std_logic := '0';
    signal video_data                       : std_logic_vector(23 downto 0);
    signal digilent_vid_data                : std_logic_vector(23 downto 0);
    signal pixel_x, pixel_y                 : std_logic_vector(15 downto 0);

begin

    clk_cpu_o  <= cpuclk;
    pll_locked <= locked_s;
    hdmi_rst   <= rst or (not locked_s);

    clock: entity work.clock_gen(rtl)
        generic map (
            CLKIN_PERIOD => 8.000,
            CLK_MULTIPLY => 59,
            CLK_DIVIDE   => 5,
            CLKOUT0_DIV  => 4,
            CLKOUT1_DIV  => 20,
            CLKOUT2_DIV  => 40
        )
        port map (
            clk_i    => clk_125mhz,
            clk0_o   => serclk,
            clk1_o   => pixclk,
            clk2_o   => cpuclk,
            locked_o => locked_s
        );

    timing: entity work.timing_generator(rtl)
        generic map (
            GEN_PIX_LOC => true,
            OBJECT_SIZE => 16
        )
        port map (
            clk          => pixclk,
            hsync        => raw_hsync,
            vsync        => raw_vsync,
            video_active => raw_active,
            pixel_x      => pixel_x,
            pixel_y      => pixel_y
        );

    fb_inst: entity work.Framebuffer_RAM
        generic map (
            VRAM_WIDTH  => 320,
            VRAM_HEIGHT => 180,
            VRAM_SIZE   => 57600
        )
        port map (
            clk_cpu        => cpuclk,
            cpu_we         => vram_we,
            cpu_addr       => vram_addr,
            cpu_din        => vram_din,
            cpu_dout       => vram_dout,
            clk_hdmi       => pixclk,
            video_active_i => raw_active,
            hsync_i        => raw_hsync,
            vsync_i        => raw_vsync,
            pixel_x        => pixel_x,
            pixel_y        => pixel_y,
            video_active_o => fb_active,
            hsync_o        => fb_hsync,
            vsync_o        => fb_vsync,
            rgb_out        => video_data
        );

    -- Digilent rgb2dvi expects:
    --   vid_pData(23 downto 16) = Red
    --   vid_pData(15 downto 8)  = Blue
    --   vid_pData(7 downto 0)   = Green
    -- Framebuffer_RAM produces video_data as: Red(23 downto 16) & Green(15 downto 8) & Blue(7 downto 0).
    digilent_vid_data <= video_data(23 downto 16) & video_data(7 downto 0) & video_data(15 downto 8);

    u_rgb2dvi: entity work.rgb2dvi
        generic map (
            kGenerateSerialClk => false,
            kClkPrimitive      => "PLL",
            kRstActiveHigh     => true
        )
        port map (
            TMDS_Clk_p  => clk_p,
            TMDS_Clk_n  => clk_n,
            TMDS_Data_p => data_p,
            TMDS_Data_n => data_n,
            aRst        => hdmi_rst,
            aRst_n      => '1',
            vid_pData   => digilent_vid_data,
            vid_pVDE    => fb_active,
            vid_pHSync  => fb_hsync,
            vid_pVSync  => fb_vsync,
            PixelClk    => pixclk,
            SerialClk   => serclk
        );

end rtl;
