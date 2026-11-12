library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use work.Constants.ALL;

entity tb_CPU_Top is
end entity tb_CPU_Top;

architecture sim of tb_CPU_Top is
    constant CLK_PERIOD : time := 8 ns;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal btn         : std_logic_vector(2 downto 0) := "000";
    signal hdmi_clk_p  : std_logic;
    signal hdmi_clk_n  : std_logic;
    signal hdmi_data_p : std_logic_vector(2 downto 0);
    signal hdmi_data_n : std_logic_vector(2 downto 0);

    type shadow_vram_t is array (0 to 14399) of std_logic_vector(7 downto 0);
    signal shadow_vram : shadow_vram_t := (others => X"00");
    signal vram_writes : integer := 0;

begin

    uut: entity work.CPU_Top
        generic map(
            IMEM_WORDS => 1024,
            DMEM_WORDS => 1024
        )
        port map(
            clk         => clk,
            rst         => rst,
            btn         => btn,
            hdmi_clk_p  => hdmi_clk_p,
            hdmi_clk_n  => hdmi_clk_n,
            hdmi_data_p => hdmi_data_p,
            hdmi_data_n => hdmi_data_n
        );

    clk_proc: process
    begin
        while now < 2 ms loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    process
        alias c_clk  is << signal .tb_CPU_Top.uut.cpu_clk   : std_logic >>;
        alias v_we   is << signal .tb_CPU_Top.uut.vram_we   : std_logic >>;
        alias v_addr is << signal .tb_CPU_Top.uut.vram_addr : std_logic_vector(15 downto 0) >>;
        alias v_din  is << signal .tb_CPU_Top.uut.vram_din  : std_logic_vector(7 downto 0) >>;
        variable a_int : integer;
    begin
        wait until rising_edge(c_clk);
        if v_we = '1' then
            a_int := to_integer(unsigned(v_addr));
            if a_int < 14400 then
                shadow_vram(a_int) <= v_din;
                if v_din /= X"00" then
                    report "NON-ZERO VRAM WRITE: addr=" & integer'image(a_int) & " data=" & to_hstring(v_din) severity note;
                end if;
                vram_writes <= vram_writes + 1;
            end if;
        end if;
    end process;

    stim_proc: process
        alias c_clk is << signal .tb_CPU_Top.uut.cpu_clk : std_logic >>;
        file out_file     : text;
        variable out_line : line;
        variable r_val, g_val, b_val : integer;
        variable b_byte   : std_logic_vector(7 downto 0);
    begin
        rst <= '1';
        wait for CLK_PERIOD * 20;
        rst <= '0';

        for i in 1 to 55000 loop
            wait until rising_edge(c_clk);
        end loop;

        report "REAL VHDL CPU FINISHED 55,000 CYCLES. Total VRAM writes: " & integer'image(vram_writes) severity note;

        file_open(out_file, "vhdl_cpu_pong_frame.ppm", write_mode);
        write(out_line, string'("P3")); writeline(out_file, out_line);
        write(out_line, string'("160 90")); writeline(out_file, out_line);
        write(out_line, string'("255")); writeline(out_file, out_line);

        for y in 0 to 89 loop
            for x in 0 to 159 loop
                b_byte := shadow_vram(y * 160 + x);
                r_val := to_integer(unsigned(b_byte(7 downto 5))) * 36;
                g_val := to_integer(unsigned(b_byte(4 downto 2))) * 36;
                b_val := to_integer(unsigned(b_byte(1 downto 0))) * 85;
                write(out_line, integer'image(r_val) & " " & integer'image(g_val) & " " & integer'image(b_val) & " ");
            end loop;
            writeline(out_file, out_line);
        end loop;

        file_close(out_file);
        report "SUCCESS: vhdl_cpu_pong_frame.ppm dumped from real VHDL CPU!" severity note;
        wait;
    end process;

end architecture sim;
