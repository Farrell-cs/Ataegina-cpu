library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HDMI_Controller is
    generic(
        H_ACTIVE : integer := 640;
        H_FP     : integer := 16;
        H_SYNC   : integer := 96;
        H_BP     : integer := 48;
        V_ACTIVE : integer := 480;
        V_FP     : integer := 10;
        V_SYNC   : integer := 2;
        V_BP     : integer := 33
    );
    port(
        pixel_clk    : in  std_logic;
        rst          : in  std_logic;
        rgb_in       : in  std_logic_vector(23 downto 0);
        hsync        : out std_logic;
        vsync        : out std_logic;
        video_active : out std_logic;
        pixel_x      : out std_logic_vector(9 downto 0);
        pixel_y      : out std_logic_vector(9 downto 0);
        rgb_out      : out std_logic_vector(23 downto 0)
    );
end entity HDMI_Controller;

architecture Behavioral of HDMI_Controller is

begin

    -- TODO:
    -- 1. Create horizontal (0 to H_TOTAL-1) and vertical (0 to V_TOTAL-1) pixel counters
    -- 2. Drive video_active high when inside the active display region (H_ACTIVE x V_ACTIVE)
    -- 3. Generate negative-polarity hsync and vsync pulses during their sync intervals
    -- 4. Output pixel_x, pixel_y, and blank rgb_out to 0x000000 when video_active = '0'

end Behavioral;
