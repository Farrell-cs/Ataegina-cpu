library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Framebuffer_RAM is
    generic(
        VRAM_WIDTH  : integer := 160;
        VRAM_HEIGHT : integer := 90;
        VRAM_SIZE   : integer := 14400
    );
    port(
        clk_cpu        : in  std_logic;
        cpu_we         : in  std_logic;
        cpu_addr       : in  std_logic_vector(15 downto 0);
        cpu_din        : in  std_logic_vector(7 downto 0);
        cpu_dout       : out std_logic_vector(7 downto 0);
        clk_hdmi       : in  std_logic;
        video_active_i : in  std_logic;
        hsync_i        : in  std_logic;
        vsync_i        : in  std_logic;
        pixel_x        : in  std_logic_vector(15 downto 0);
        pixel_y        : in  std_logic_vector(15 downto 0);
        video_active_o : out std_logic;
        hsync_o        : out std_logic;
        vsync_o        : out std_logic;
        rgb_out        : out std_logic_vector(23 downto 0)
    );
end entity Framebuffer_RAM;

architecture rtl of Framebuffer_RAM is

    type vram_array is array (0 to 16383) of std_logic_vector(7 downto 0);
    signal ram : vram_array := (others => X"00");

    signal read_addr_s1 : unsigned(13 downto 0) := (others => '0');
    signal active_s1    : std_logic := '0';
    signal hsync_s1     : std_logic := '0';
    signal vsync_s1     : std_logic := '0';

    signal bram_dout_s2 : std_logic_vector(7 downto 0) := X"00";
    signal active_s2    : std_logic := '0';
    signal hsync_s2     : std_logic := '0';
    signal vsync_s2     : std_logic := '0';

    signal pixel_reg_s3 : std_logic_vector(7 downto 0) := X"00";
    signal active_s3    : std_logic := '0';
    signal hsync_s3     : std_logic := '0';
    signal vsync_s3     : std_logic := '0';

begin

    process(clk_cpu)
        variable a_idx : integer range 0 to 16383;
    begin
        if rising_edge(clk_cpu) then
            a_idx := to_integer(unsigned(cpu_addr(13 downto 0)));
            if cpu_we = '1' then
                ram(a_idx) <= cpu_din;
            end if;
            cpu_dout <= ram(a_idx);
        end if;
    end process;

    process(clk_hdmi)
        variable vx : unsigned(13 downto 0);
        variable vy : unsigned(13 downto 0);
    begin
        if rising_edge(clk_hdmi) then
            vx := resize(unsigned(pixel_x(10 downto 3)), 14);
            vy := resize(unsigned(pixel_y(9 downto 3)), 14);

            -- Stage 1: Compute address (vy * 160 + vx = (vy << 7) + (vy << 5) + vx)
            read_addr_s1 <= shift_left(vy, 7) + shift_left(vy, 5) + vx;
            active_s1    <= video_active_i;
            hsync_s1     <= hsync_i;
            vsync_s1     <= vsync_i;

            -- Stage 2: BRAM array read
            bram_dout_s2 <= ram(to_integer(read_addr_s1));
            active_s2    <= active_s1;
            hsync_s2     <= hsync_s1;
            vsync_s2     <= vsync_s1;

            -- Stage 3: BRAM output register (merged into RAMB36E1 DOB_REG)
            pixel_reg_s3 <= bram_dout_s2;
            active_s3    <= active_s2;
            hsync_s3     <= hsync_s2;
            vsync_s3     <= vsync_s2;
        end if;
    end process;

    video_active_o <= active_s3;
    hsync_o        <= hsync_s3;
    vsync_o        <= vsync_s3;

    rgb_out(23 downto 16) <= pixel_reg_s3(7 downto 5) & pixel_reg_s3(7 downto 5) & pixel_reg_s3(7 downto 6) when active_s3 = '1' else X"00";
    rgb_out(15 downto 8)  <= pixel_reg_s3(4 downto 2) & pixel_reg_s3(4 downto 2) & pixel_reg_s3(4 downto 3) when active_s3 = '1' else X"00";
    rgb_out(7 downto 0)   <= pixel_reg_s3(1 downto 0) & pixel_reg_s3(1 downto 0) & pixel_reg_s3(1 downto 0) & pixel_reg_s3(1 downto 0) when active_s3 = '1' else X"00";

end architecture rtl;
