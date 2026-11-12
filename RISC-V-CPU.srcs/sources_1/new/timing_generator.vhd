library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timing_generator is
    generic (
        GEN_PIX_LOC : boolean := true;
        OBJECT_SIZE : natural := 16
    );
    port(
        clk          : in  std_logic;
        hsync, vsync : out std_logic;
        video_active : out std_logic;
        pixel_x      : out std_logic_vector(OBJECT_SIZE - 1 downto 0);
        pixel_y      : out std_logic_vector(OBJECT_SIZE - 1 downto 0)
    );
end timing_generator;

architecture rtl of timing_generator is

    constant H_VIDEO : integer := 1280;
    constant H_FP    : integer := 72;
    constant H_SYNC  : integer := 80;
    constant H_BP    : integer := 216;
    constant H_TOTAL : integer := 1648;

    constant V_VIDEO : integer := 720;
    constant V_FP    : integer := 3;
    constant V_SYNC  : integer := 5;
    constant V_BP    : integer := 22;
    constant V_TOTAL : integer := 750;

    constant H_POL   : std_logic := '1';
    constant V_POL   : std_logic := '1';

    signal hcount : unsigned(OBJECT_SIZE - 1 downto 0) := (others => '0');
    signal vcount : unsigned(OBJECT_SIZE - 1 downto 0) := (others => '0');

begin

    process (clk) is
    begin
        if rising_edge(clk) then
            if (hcount = H_TOTAL - 1) then
                hcount <= (others => '0');
                if (vcount = V_TOTAL - 1) then
                    vcount <= (others => '0');
                else
                    vcount <= vcount + 1;
                end if;
            else
                hcount <= hcount + 1;
            end if;
        end if;
    end process;

    video_active <= '1' when (hcount < H_VIDEO) and (vcount < V_VIDEO) else '0';
    hsync        <= H_POL when (hcount >= H_VIDEO + H_FP) and (hcount < H_TOTAL - H_BP) else not H_POL;
    vsync        <= V_POL when (vcount >= V_VIDEO + V_FP) and (vcount < V_TOTAL - V_BP) else not V_POL;

    g0: if GEN_PIX_LOC = true generate
    begin
        pixel_x <= std_logic_vector(hcount) when hcount < H_VIDEO else (others => '0');
        pixel_y <= std_logic_vector(vcount) when vcount < V_VIDEO else (others => '0');
    end generate;

    g1: if GEN_PIX_LOC = false generate
    begin
        pixel_x <= (others => '0');
        pixel_y <= (others => '0');
    end generate;

end rtl;
