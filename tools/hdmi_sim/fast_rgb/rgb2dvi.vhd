library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.all;

-- Simulation-only parallel-RGB bypass for --fast-rgb: samples pixel-rate RGB + sync
-- directly into hdmi_monitor.c instead of simulating 737.5 Mbps 10:1 DDR TMDS lanes.
entity rgb2dvi is
   Generic (
      kGenerateSerialClk : boolean := true;
      kClkPrimitive      : string := "PLL";
      kClkRange          : natural := 1;
      kRstActiveHigh     : boolean := true;
      kD0Swap            : boolean := false;
      kD1Swap            : boolean := false;
      kD2Swap            : boolean := false;
      kClkSwap           : boolean := false);
   Port (
      TMDS_Clk_p  : out std_logic := '0';
      TMDS_Clk_n  : out std_logic := '1';
      TMDS_Data_p : out std_logic_vector(2 downto 0) := "000";
      TMDS_Data_n : out std_logic_vector(2 downto 0) := "111";
      aRst        : in std_logic;
      aRst_n      : in std_logic;
      vid_pData   : in std_logic_vector(23 downto 0);
      vid_pVDE    : in std_logic;
      vid_pHSync  : in std_logic;
      vid_pVSync  : in std_logic;
      PixelClk    : in std_logic;
      SerialClk   : in std_logic);
end rgb2dvi;

architecture Behavioral of rgb2dvi is

    impure function c_hdmi_tick(vde : integer; hsync : integer; vsync : integer; r : integer; g : integer; b : integer) return integer;
    attribute foreign of c_hdmi_tick : function is "VHPIDIRECT c_hdmi_tick";

    impure function c_hdmi_finish return integer;
    attribute foreign of c_hdmi_finish : function is "VHPIDIRECT c_hdmi_finish";

    impure function c_hdmi_tick(vde : integer; hsync : integer; vsync : integer; r : integer; g : integer; b : integer) return integer is
    begin
        report "VHPIDIRECT c_hdmi_tick not bound" severity failure;
        return -1;
    end function;

    impure function c_hdmi_finish return integer is
    begin
        report "VHPIDIRECT c_hdmi_finish not bound" severity failure;
        return -1;
    end function;

begin

    process(PixelClk)
        variable rst_active : boolean;
        variable vde_i, hs_i, vs_i : integer;
        variable r_i, g_i, b_i     : integer;
        variable tick_rc           : integer;
        variable fin_rc            : integer;
        variable prev_btn          : integer := -1;
        variable clk_tog           : std_logic := '0';
        variable btn_v             : std_logic_vector(2 downto 0);
    begin
        if rising_edge(PixelClk) then
            rst_active := (kRstActiveHigh and aRst = '1') or ((not kRstActiveHigh) and aRst_n = '0');
            if not rst_active then
                if vid_pVDE = '1' then vde_i := 1; else vde_i := 0; end if;
                if vid_pHSync = '1' then hs_i := 1; else hs_i := 0; end if;
                if vid_pVSync = '1' then vs_i := 1; else vs_i := 0; end if;

                if vid_pVDE = '1' then
                    -- Digilent rgb2dvi packs R(23..16), B(15..8), G(7..0)
                    r_i := to_integer(unsigned(vid_pData(23 downto 16)));
                    b_i := to_integer(unsigned(vid_pData(15 downto 8)));
                    g_i := to_integer(unsigned(vid_pData(7 downto 0)));
                else
                    r_i := 0; g_i := 0; b_i := 0;
                end if;

                tick_rc := c_hdmi_tick(vde_i, hs_i, vs_i, r_i, g_i, b_i);
                if tick_rc < 0 then
                    fin_rc := c_hdmi_finish;
                    if fin_rc /= 0 then
                        report "HDMI verification FAILED" severity failure;
                    end if;
                    stop(0);
                elsif tick_rc /= prev_btn then
                    prev_btn := tick_rc;
                    btn_v := std_logic_vector(to_unsigned(tick_rc, 3));
                    TMDS_Data_p <= btn_v;
                    TMDS_Data_n <= not btn_v;
                    clk_tog := not clk_tog;
                    TMDS_Clk_p <= clk_tog;
                    TMDS_Clk_n <= not clk_tog;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
