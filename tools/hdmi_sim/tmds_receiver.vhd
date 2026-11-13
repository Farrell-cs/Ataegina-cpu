library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.all;

entity tmds_receiver is
    generic (
        FRAME_WIDTH  : integer := 1280;
        FRAME_HEIGHT : integer := 720
    );
    port (
        tmds_clk_p  : in  std_logic;
        tmds_clk_n  : in  std_logic;
        tmds_data_p : in  std_logic_vector(2 downto 0);
        tmds_data_n : in  std_logic_vector(2 downto 0);
        btn_out     : out std_logic_vector(2 downto 0) := "000";
        done        : out std_logic := '0'
    );
end entity tmds_receiver;

architecture sim of tmds_receiver is

    constant CTL0 : std_logic_vector(9 downto 0) := "1101010100";
    constant CTL1 : std_logic_vector(9 downto 0) := "0010101011";
    constant CTL2 : std_logic_vector(9 downto 0) := "0101010100";
    constant CTL3 : std_logic_vector(9 downto 0) := "1010101011";

    impure function c_hdmi_init(width : integer; height : integer) return integer;
    attribute foreign of c_hdmi_init : function is "VHPIDIRECT c_hdmi_init";

    impure function c_hdmi_tick(vde : integer; hsync : integer; vsync : integer; r : integer; g : integer; b : integer) return integer;
    attribute foreign of c_hdmi_tick : function is "VHPIDIRECT c_hdmi_tick";

    impure function c_hdmi_finish return integer;
    attribute foreign of c_hdmi_finish : function is "VHPIDIRECT c_hdmi_finish";

    impure function c_hdmi_init(width : integer; height : integer) return integer is
    begin
        report "VHPIDIRECT c_hdmi_init not bound" severity failure;
        return -1;
    end function;

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

    function is_ctl_token(s : std_logic_vector(9 downto 0)) return boolean is
    begin
        return (s = CTL0) or (s = CTL1) or (s = CTL2) or (s = CTL3);
    end function;

    procedure decode_tmds(
        sym : in  std_logic_vector(9 downto 0);
        vde : out std_logic;
        c0  : out std_logic;
        c1  : out std_logic;
        dat : out std_logic_vector(7 downto 0)
    ) is
        variable q_m : std_logic_vector(7 downto 0);
        variable d   : std_logic_vector(7 downto 0);
    begin
        if sym = CTL0 then
            vde := '0'; c1 := '0'; c0 := '0'; dat := (others => '0');
        elsif sym = CTL1 then
            vde := '0'; c1 := '0'; c0 := '1'; dat := (others => '0');
        elsif sym = CTL2 then
            vde := '0'; c1 := '1'; c0 := '0'; dat := (others => '0');
        elsif sym = CTL3 then
            vde := '0'; c1 := '1'; c0 := '1'; dat := (others => '0');
        else
            vde := '1';
            c1  := '0';
            c0  := '0';
            if sym(9) = '1' then
                q_m := not sym(7 downto 0);
            else
                q_m := sym(7 downto 0);
            end if;
            d(0) := q_m(0);
            if sym(8) = '1' then
                for i in 1 to 7 loop
                    d(i) := q_m(i) xor q_m(i - 1);
                end loop;
            else
                for i in 1 to 7 loop
                    d(i) := q_m(i) xnor q_m(i - 1);
                end loop;
            end if;
            dat := d;
        end if;
    end procedure;

    type win_arr_t is array (0 to 2) of std_logic_vector(19 downto 0);
    type slip_arr_t is array (0 to 2) of integer range 0 to 9;
    type cnt_arr_t is array (0 to 2) of integer;

begin

    process
        variable init_rc     : integer;
        variable tick_rc     : integer;
        variable fin_rc      : integer;
        variable last_rise   : time := 0 ns;
        variable clk_period  : time := 0 ns;
        variable bit_time    : time := 0 ns;
        variable have_period : boolean := false;

        variable cap0, cap1, cap2 : std_logic_vector(9 downto 0);
        variable win         : win_arr_t := (others => (others => '0'));
        variable slip        : slip_arr_t := (others => 0);
        variable lock_cnt    : cnt_arr_t := (others => 0);
        variable ch_locked   : std_logic_vector(2 downto 0) := "000";
        variable all_locked  : boolean := false;

        variable sym0, sym1, sym2 : std_logic_vector(9 downto 0);
        variable vde0, vde1, vde2 : std_logic;
        variable c0_0, c1_0, c0_x, c1_x : std_logic;
        variable d_b, d_g, d_r    : std_logic_vector(7 downto 0);
        variable vde_i, hs_i, vs_i : integer;
        variable r_i, g_i, b_i     : integer;
        variable btn_v             : std_logic_vector(2 downto 0);
    begin
        init_rc := c_hdmi_init(FRAME_WIDTH, FRAME_HEIGHT);
        if init_rc /= 0 then
            report "c_hdmi_init failed" severity failure;
        end if;

        loop
            wait until rising_edge(tmds_clk_p);
            assert tmds_clk_n = not tmds_clk_p
                report "TMDS differential clock polarity mismatch" severity error;

            if last_rise > 0 ns then
                clk_period := now - last_rise;
                if clk_period > 1 ns and clk_period < 100 ns then
                    bit_time := clk_period / 10;
                    have_period := true;
                end if;
            end if;
            last_rise := now;

            if have_period then
                wait for bit_time / 2;
                for b in 0 to 9 loop
                    assert tmds_data_p(0) = not tmds_data_n(0) report "TMDS ch0 polarity error" severity error;
                    assert tmds_data_p(1) = not tmds_data_n(1) report "TMDS ch1 polarity error" severity error;
                    assert tmds_data_p(2) = not tmds_data_n(2) report "TMDS ch2 polarity error" severity error;
                    cap0(b) := to_X01(tmds_data_p(0));
                    cap1(b) := to_X01(tmds_data_p(1));
                    cap2(b) := to_X01(tmds_data_p(2));
                    if b < 9 then
                        wait for bit_time;
                    end if;
                end loop;

                win(0) := cap0 & win(0)(19 downto 10);
                win(1) := cap1 & win(1)(19 downto 10);
                win(2) := cap2 & win(2)(19 downto 10);

                if not all_locked then
                    for ch in 0 to 2 loop
                        if ch_locked(ch) = '0' then
                            if is_ctl_token(win(ch)(slip(ch) + 9 downto slip(ch))) then
                                lock_cnt(ch) := lock_cnt(ch) + 1;
                                if lock_cnt(ch) >= 16 then
                                    ch_locked(ch) := '1';
                                    report "TMDS channel " & integer'image(ch) & " locked at slip=" & integer'image(slip(ch)) severity note;
                                end if;
                            else
                                lock_cnt(ch) := 0;
                                for s in 0 to 9 loop
                                    if is_ctl_token(win(ch)(s + 9 downto s)) then
                                        slip(ch) := s;
                                        lock_cnt(ch) := 1;
                                        exit;
                                    end if;
                                end loop;
                            end if;
                        end if;
                    end loop;
                    if ch_locked = "111" then
                        all_locked := true;
                        report "TMDS all 3 channels word-locked." severity note;
                    end if;
                else
                    sym0 := win(0)(slip(0) + 9 downto slip(0));
                    sym1 := win(1)(slip(1) + 9 downto slip(1));
                    sym2 := win(2)(slip(2) + 9 downto slip(2));

                    decode_tmds(sym0, vde0, c0_0, c1_0, d_b);
                    decode_tmds(sym1, vde1, c0_x, c1_x, d_g);
                    decode_tmds(sym2, vde2, c0_x, c1_x, d_r);

                    if vde0 = '1' then vde_i := 1; else vde_i := 0; end if;
                    if c0_0 = '1' then hs_i  := 1; else hs_i  := 0; end if;
                    if c1_0 = '1' then vs_i  := 1; else vs_i  := 0; end if;

                    if vde0 = '1' then
                        r_i := to_integer(unsigned(d_r));
                        g_i := to_integer(unsigned(d_g));
                        b_i := to_integer(unsigned(d_b));
                    else
                        r_i := 0; g_i := 0; b_i := 0;
                    end if;

                    tick_rc := c_hdmi_tick(vde_i, hs_i, vs_i, r_i, g_i, b_i);
                    if tick_rc < 0 then
                        fin_rc := c_hdmi_finish;
                        done <= '1';
                        if fin_rc /= 0 then
                            report "HDMI verification FAILED" severity failure;
                        end if;
                        stop(0);
                    else
                        btn_v := std_logic_vector(to_unsigned(tick_rc, 3));
                        btn_out <= btn_v;
                    end if;
                end if;
            end if;
        end loop;
    end process;

end architecture sim;
