library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Lightweight receiver stub for --fast-rgb: initializes hdmi_monitor.c and
-- forwards keyboard btn_out updates without serial bit decoding.
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

    impure function c_hdmi_init(width : integer; height : integer) return integer;
    attribute foreign of c_hdmi_init : function is "VHPIDIRECT c_hdmi_init";

    impure function c_hdmi_init(width : integer; height : integer) return integer is
    begin
        report "VHPIDIRECT c_hdmi_init not bound" severity failure;
        return -1;
    end function;

begin

    process
        variable init_rc : integer;
    begin
        init_rc := c_hdmi_init(FRAME_WIDTH, FRAME_HEIGHT);
        if init_rc /= 0 then
            report "c_hdmi_init failed" severity failure;
        end if;

        loop
            wait until tmds_clk_p'event;
            btn_out <= tmds_data_p;
        end loop;
    end process;

end architecture sim;
