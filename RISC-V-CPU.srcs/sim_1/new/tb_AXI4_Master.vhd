library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity tb_AXI4_Master is
end entity tb_AXI4_Master;

architecture sim of tb_AXI4_Master is
    constant CLK_PERIOD : time := 10 ns;

    signal clk           : std_logic := '0';
    signal rst           : std_logic := '1';
    signal ifetch_req    : std_logic := '0';
    signal ifetch_addr   : std_logic_vector(31 downto 0) := (others => '0');
    signal ifetch_data   : std_logic_vector(31 downto 0);
    signal dmem_req      : std_logic := '0';
    signal dmem_we       : std_logic := '0';
    signal dmem_funct3   : std_logic_vector(2 downto 0) := F3_WORD;
    signal dmem_addr     : std_logic_vector(31 downto 0) := (others => '0');
    signal dmem_wdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal dmem_rdata    : std_logic_vector(31 downto 0);
    signal stall         : std_logic;

    signal awaddr        : std_logic_vector(31 downto 0);
    signal awlen         : std_logic_vector(7 downto 0);
    signal awsize        : std_logic_vector(2 downto 0);
    signal awburst       : std_logic_vector(1 downto 0);
    signal awvalid       : std_logic;
    signal awready       : std_logic := '0';
    signal wdata         : std_logic_vector(31 downto 0);
    signal wstrb         : std_logic_vector(3 downto 0);
    signal wlast         : std_logic;
    signal wvalid        : std_logic;
    signal wready        : std_logic := '0';
    signal bresp         : std_logic_vector(1 downto 0) := "00";
    signal bvalid        : std_logic := '0';
    signal bready        : std_logic;
    signal araddr        : std_logic_vector(31 downto 0);
    signal arlen         : std_logic_vector(7 downto 0);
    signal arsize        : std_logic_vector(2 downto 0);
    signal arburst       : std_logic_vector(1 downto 0);
    signal arvalid       : std_logic;
    signal arready       : std_logic := '0';
    signal rdata         : std_logic_vector(31 downto 0) := (others => '0');
    signal rresp         : std_logic_vector(1 downto 0) := "00";
    signal rlast         : std_logic := '1';
    signal rvalid        : std_logic := '0';
    signal rready        : std_logic;

    -- Simple 16-word AXI slave memory model
    type mem_t is array (0 to 15) of std_logic_vector(31 downto 0);
    signal slave_mem : mem_t := (others => (others => '0'));
begin

    clk <= not clk after CLK_PERIOD / 2;

    uut: entity work.AXI4_Master
        port map(
            clk           => clk,
            rst           => rst,
            ifetch_req    => ifetch_req,
            ifetch_addr   => ifetch_addr,
            ifetch_data   => ifetch_data,
            dmem_req      => dmem_req,
            dmem_we       => dmem_we,
            dmem_funct3   => dmem_funct3,
            dmem_addr     => dmem_addr,
            dmem_wdata    => dmem_wdata,
            dmem_rdata    => dmem_rdata,
            stall         => stall,
            m_axi_awaddr  => awaddr,
            m_axi_awlen   => awlen,
            m_axi_awsize  => awsize,
            m_axi_awburst => awburst,
            m_axi_awvalid => awvalid,
            m_axi_awready => awready,
            m_axi_wdata   => wdata,
            m_axi_wstrb   => wstrb,
            m_axi_wlast   => wlast,
            m_axi_wvalid  => wvalid,
            m_axi_wready  => wready,
            m_axi_bresp   => bresp,
            m_axi_bvalid  => bvalid,
            m_axi_bready  => bready,
            m_axi_araddr  => araddr,
            m_axi_arlen   => arlen,
            m_axi_arsize  => arsize,
            m_axi_arburst => arburst,
            m_axi_arvalid => arvalid,
            m_axi_arready => arready,
            m_axi_rdata   => rdata,
            m_axi_rresp   => rresp,
            m_axi_rlast   => rlast,
            m_axi_rvalid  => rvalid,
            m_axi_rready  => rready
        );

    -- AXI4 slave BFM with staggered ready/valid delays
    axi_slave: process
        variable idx      : integer;
        variable got_aw   : boolean;
        variable got_w    : boolean;
        variable aw_a_lat : std_logic_vector(31 downto 0);
        variable w_d_lat  : std_logic_vector(31 downto 0);
        variable w_s_lat  : std_logic_vector(3 downto 0);
        variable tmp      : std_logic_vector(31 downto 0);
    begin
        wait until rst = '0';
        loop
            wait until rising_edge(clk);
            awready <= '0';
            wready  <= '0';
            bvalid  <= '0';
            arready <= '0';
            rvalid  <= '0';

            if arvalid = '1' then
                wait until rising_edge(clk);
                arready <= '1';
                idx := to_integer(unsigned(araddr(5 downto 2)));
                wait until rising_edge(clk);
                arready <= '0';
                wait until rising_edge(clk);
                rdata  <= slave_mem(idx);
                rvalid <= '1';
                rlast  <= '1';
                loop
                    wait until rising_edge(clk);
                    exit when rready = '1';
                end loop;
                rvalid <= '0';
            elsif awvalid = '1' or wvalid = '1' then
                got_aw := false;
                got_w  := false;
                -- Staggered: accept W first, then AW 1 cycle later
                while not (got_aw and got_w) loop
                    wait until rising_edge(clk);
                    if not got_w and wvalid = '1' then
                        wready  <= '1';
                        w_d_lat := wdata;
                        w_s_lat := wstrb;
                        got_w   := true;
                    else
                        wready <= '0';
                    end if;
                    if got_w and not got_aw and awvalid = '1' then
                        awready  <= '1';
                        aw_a_lat := awaddr;
                        got_aw   := true;
                    else
                        awready <= '0';
                    end if;
                end loop;
                wait until rising_edge(clk);
                awready <= '0';
                wready  <= '0';

                idx := to_integer(unsigned(aw_a_lat(5 downto 2)));
                tmp := slave_mem(idx);
                if w_s_lat(0) = '1' then tmp(7 downto 0)   := w_d_lat(7 downto 0);   end if;
                if w_s_lat(1) = '1' then tmp(15 downto 8)  := w_d_lat(15 downto 8);  end if;
                if w_s_lat(2) = '1' then tmp(23 downto 16) := w_d_lat(23 downto 16); end if;
                if w_s_lat(3) = '1' then tmp(31 downto 24) := w_d_lat(31 downto 24); end if;
                slave_mem(idx) <= tmp;

                bvalid <= '1';
                loop
                    wait until rising_edge(clk);
                    exit when bready = '1';
                end loop;
                bvalid <= '0';
            end if;
        end loop;
    end process;

    stim: process
    begin
        rst <= '1';
        wait for CLK_PERIOD * 3;
        rst <= '0';
        wait until rising_edge(clk);

        -- 1. Word write (SW) to 0x10000004
        dmem_req    <= '1';
        dmem_we     <= '1';
        dmem_funct3 <= F3_WORD;
        dmem_addr   <= X"10000004";
        dmem_wdata  <= X"CAFEBABE";
        wait for 1 ns;
        while stall = '1' loop
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        wait until rising_edge(clk);
        dmem_req <= '0';
        wait until rising_edge(clk);

        -- 2. Byte write (SB) 0x80 at 0x10000006 (byte 2)
        dmem_req    <= '1';
        dmem_we     <= '1';
        dmem_funct3 <= F3_BYTE;
        dmem_addr   <= X"10000006";
        dmem_wdata  <= X"00000080";
        wait for 1 ns;
        while stall = '1' loop
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        wait until rising_edge(clk);
        dmem_req <= '0';
        wait until rising_edge(clk);

        -- 3. Signed byte read (LB) at 0x10000006 -> 0xFFFFFF80
        dmem_req    <= '1';
        dmem_we     <= '0';
        dmem_funct3 <= F3_BYTE;
        dmem_addr   <= X"10000006";
        wait for 1 ns;
        while stall = '1' loop
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        assert dmem_rdata = X"FFFFFF80" report "LB sign-extension failed" severity error;
        wait until rising_edge(clk);
        dmem_req <= '0';
        wait until rising_edge(clk);

        -- 4. Instruction fetch (0x10000004) + Data Load (0x10000004) on same cycle
        ifetch_req  <= '1';
        ifetch_addr <= X"10000004";
        dmem_req    <= '1';
        dmem_we     <= '0';
        dmem_funct3 <= F3_WORD;
        dmem_addr   <= X"10000004";
        wait for 1 ns;
        while stall = '1' loop
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;
        assert ifetch_data = X"CA80BABE" report "ifetch data mismatch" severity error;
        assert dmem_rdata  = X"CA80BABE" report "dmem word read mismatch" severity error;

        report "tb_AXI4_Master passed successfully." severity note;
        std.env.stop;
        wait;
    end process;

end architecture sim;
