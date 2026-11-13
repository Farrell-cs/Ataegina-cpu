library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_hdmi_dvi is
    generic (
        FRAME_WIDTH  : integer := 1280;
        FRAME_HEIGHT : integer := 720
    );
end entity tb_hdmi_dvi;

architecture sim of tb_hdmi_dvi is
    constant CLK_PERIOD : time := 8 ns;

    signal clk_125mhz  : std_logic := '0';
    signal rst         : std_logic := '1';
    signal clk_cpu_o   : std_logic;
    signal pll_locked  : std_logic;
    signal vram_we     : std_logic := '0';
    signal vram_addr   : std_logic_vector(15 downto 0) := (others => '0');
    signal vram_din    : std_logic_vector(7 downto 0) := (others => '0');
    signal vram_dout   : std_logic_vector(7 downto 0);
    signal clk_p       : std_logic;
    signal clk_n       : std_logic;
    signal data_p      : std_logic_vector(2 downto 0);
    signal data_n      : std_logic_vector(2 downto 0);
    signal btn_unused  : std_logic_vector(2 downto 0);
    signal rx_done     : std_logic;

    function color_for_xy(x : integer; y : integer) return std_logic_vector is
        variable bar : integer;
    begin
        if x = 0 or x = 159 or y = 0 or y = 89 then
            return X"FF"; -- White 1px border (8px on 720p)
        elsif y < 45 then
            bar := (x * 8) / 160;
            case bar is
                when 0 => return X"FF"; -- White
                when 1 => return X"FC"; -- Yellow
                when 2 => return X"1F"; -- Cyan
                when 3 => return X"1C"; -- Green
                when 4 => return X"E3"; -- Magenta
                when 5 => return X"E0"; -- Red
                when 6 => return X"03"; -- Blue
                when others => return X"00"; -- Black
            end case;
        else
            if x < 53 then
                return X"E0"; -- Pure Red block
            elsif x < 106 then
                return X"1C"; -- Pure Green block
            else
                return X"03"; -- Pure Blue block
            end if;
        end if;
    end function;
begin

    clk_125mhz <= not clk_125mhz after CLK_PERIOD / 2;

    dut: entity work.HDMI_Controller
        generic map (
            SERIES6 => false
        )
        port map (
            clk_125mhz => clk_125mhz,
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

    rx: entity work.tmds_receiver
        generic map (
            FRAME_WIDTH  => FRAME_WIDTH,
            FRAME_HEIGHT => FRAME_HEIGHT
        )
        port map (
            tmds_clk_p  => clk_p,
            tmds_clk_n  => clk_n,
            tmds_data_p => data_p,
            tmds_data_n => data_n,
            btn_out     => btn_unused,
            done        => rx_done
        );

    stim: process
    begin
        rst <= '1';
        wait for CLK_PERIOD * 20;
        rst <= '0';
        if pll_locked /= '1' then
            wait until pll_locked = '1';
        end if;

        for y in 0 to 89 loop
            for x in 0 to 159 loop
                wait until falling_edge(clk_cpu_o);
                vram_we   <= '1';
                vram_addr <= std_logic_vector(to_unsigned(y * 160 + x, 16));
                vram_din  <= color_for_xy(x, y);
            end loop;
        end loop;

        wait until falling_edge(clk_cpu_o);
        vram_we <= '0';
        wait;
    end process;

end architecture sim;
