library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Zybo_Top is
    port(
        -- Zynq PS Fixed I/O & DDR (auto-constrained by Vivado)
        DDR_addr          : inout std_logic_vector(14 downto 0);
        DDR_ba            : inout std_logic_vector(2 downto 0);
        DDR_cas_n         : inout std_logic;
        DDR_ck_n          : inout std_logic;
        DDR_ck_p          : inout std_logic;
        DDR_cke           : inout std_logic;
        DDR_cs_n          : inout std_logic;
        DDR_dm            : inout std_logic_vector(3 downto 0);
        DDR_dq            : inout std_logic_vector(31 downto 0);
        DDR_dqs_n         : inout std_logic_vector(3 downto 0);
        DDR_dqs_p         : inout std_logic_vector(3 downto 0);
        DDR_odt           : inout std_logic;
        DDR_ras_n         : inout std_logic;
        DDR_reset_n       : inout std_logic;
        DDR_we_n          : inout std_logic;
        FIXED_IO_ddr_vrn  : inout std_logic;
        FIXED_IO_ddr_vrp  : inout std_logic;
        FIXED_IO_mio      : inout std_logic_vector(53 downto 0);
        FIXED_IO_ps_clk   : inout std_logic;
        FIXED_IO_ps_porb  : inout std_logic;
        FIXED_IO_ps_srstb : inout std_logic;
        -- PL Board I/O (matched to zybo_z7.xdc)
        clk               : in    std_logic;
        rst               : in    std_logic;
        btn               : in    std_logic_vector(2 downto 0);
        uart_rx           : in    std_logic;
        led               : out   std_logic_vector(3 downto 0);
        hdmi_clk_p        : out   std_logic;
        hdmi_clk_n        : out   std_logic;
        hdmi_data_p       : out   std_logic_vector(2 downto 0);
        hdmi_data_n       : out   std_logic_vector(2 downto 0)
    );
end entity Zybo_Top;

architecture Structural of Zybo_Top is

    component CPU_wrapper is
        port(
            DDR_ACLK          : in    std_logic;
            DDR_ARESETN       : in    std_logic;
            DDR_addr          : inout std_logic_vector(14 downto 0);
            DDR_ba            : inout std_logic_vector(2 downto 0);
            DDR_cas_n         : inout std_logic;
            DDR_ck_n          : inout std_logic;
            DDR_ck_p          : inout std_logic;
            DDR_cke           : inout std_logic;
            DDR_cs_n          : inout std_logic;
            DDR_dm            : inout std_logic_vector(3 downto 0);
            DDR_dq            : inout std_logic_vector(31 downto 0);
            DDR_dqs_n         : inout std_logic_vector(3 downto 0);
            DDR_dqs_p         : inout std_logic_vector(3 downto 0);
            DDR_odt           : inout std_logic;
            DDR_ras_n         : inout std_logic;
            DDR_reset_n       : inout std_logic;
            DDR_we_n          : inout std_logic;
            FIXED_IO_ddr_vrn  : inout std_logic;
            FIXED_IO_ddr_vrp  : inout std_logic;
            FIXED_IO_mio      : inout std_logic_vector(53 downto 0);
            FIXED_IO_ps_clk   : inout std_logic;
            FIXED_IO_ps_porb  : inout std_logic;
            FIXED_IO_ps_srstb : inout std_logic;
            S_AXI_DDR_araddr  : in    std_logic_vector(31 downto 0);
            S_AXI_DDR_arburst : in    std_logic_vector(1 downto 0);
            S_AXI_DDR_arcache : in    std_logic_vector(3 downto 0);
            S_AXI_DDR_arlen   : in    std_logic_vector(7 downto 0);
            S_AXI_DDR_arlock  : in    std_logic_vector(0 downto 0);
            S_AXI_DDR_arprot  : in    std_logic_vector(2 downto 0);
            S_AXI_DDR_arqos   : in    std_logic_vector(3 downto 0);
            S_AXI_DDR_arready : out   std_logic;
            S_AXI_DDR_arsize  : in    std_logic_vector(2 downto 0);
            S_AXI_DDR_arvalid : in    std_logic;
            S_AXI_DDR_awaddr  : in    std_logic_vector(31 downto 0);
            S_AXI_DDR_awburst : in    std_logic_vector(1 downto 0);
            S_AXI_DDR_awcache : in    std_logic_vector(3 downto 0);
            S_AXI_DDR_awlen   : in    std_logic_vector(7 downto 0);
            S_AXI_DDR_awlock  : in    std_logic_vector(0 downto 0);
            S_AXI_DDR_awprot  : in    std_logic_vector(2 downto 0);
            S_AXI_DDR_awqos   : in    std_logic_vector(3 downto 0);
            S_AXI_DDR_awready : out   std_logic;
            S_AXI_DDR_awsize  : in    std_logic_vector(2 downto 0);
            S_AXI_DDR_awvalid : in    std_logic;
            S_AXI_DDR_bready  : in    std_logic;
            S_AXI_DDR_bresp   : out   std_logic_vector(1 downto 0);
            S_AXI_DDR_bvalid  : out   std_logic;
            S_AXI_DDR_rdata   : out   std_logic_vector(31 downto 0);
            S_AXI_DDR_rlast   : out   std_logic;
            S_AXI_DDR_rready  : in    std_logic;
            S_AXI_DDR_rresp   : out   std_logic_vector(1 downto 0);
            S_AXI_DDR_rvalid  : out   std_logic;
            S_AXI_DDR_wdata   : in    std_logic_vector(31 downto 0);
            S_AXI_DDR_wlast   : in    std_logic;
            S_AXI_DDR_wready  : out   std_logic;
            S_AXI_DDR_wstrb   : in    std_logic_vector(3 downto 0);
            S_AXI_DDR_wvalid  : in    std_logic
        );
    end component CPU_wrapper;

    signal cpu_clk_s       : std_logic;
    signal cpu_rst_s       : std_logic;
    signal cpu_aresetn_s   : std_logic;

    signal m_axi_awaddr_s  : std_logic_vector(31 downto 0);
    signal m_axi_awlen_s   : std_logic_vector(7 downto 0);
    signal m_axi_awsize_s  : std_logic_vector(2 downto 0);
    signal m_axi_awburst_s : std_logic_vector(1 downto 0);
    signal m_axi_awvalid_s : std_logic;
    signal m_axi_awready_s : std_logic;
    signal m_axi_wdata_s   : std_logic_vector(31 downto 0);
    signal m_axi_wstrb_s   : std_logic_vector(3 downto 0);
    signal m_axi_wlast_s   : std_logic;
    signal m_axi_wvalid_s  : std_logic;
    signal m_axi_wready_s  : std_logic;
    signal m_axi_bresp_s   : std_logic_vector(1 downto 0);
    signal m_axi_bvalid_s  : std_logic;
    signal m_axi_bready_s  : std_logic;
    signal m_axi_araddr_s  : std_logic_vector(31 downto 0);
    signal m_axi_arlen_s   : std_logic_vector(7 downto 0);
    signal m_axi_arsize_s  : std_logic_vector(2 downto 0);
    signal m_axi_arburst_s : std_logic_vector(1 downto 0);
    signal m_axi_arvalid_s : std_logic;
    signal m_axi_arready_s : std_logic;
    signal m_axi_rdata_s   : std_logic_vector(31 downto 0);
    signal m_axi_rresp_s   : std_logic_vector(1 downto 0);
    signal m_axi_rlast_s   : std_logic;
    signal m_axi_rvalid_s  : std_logic;
    signal m_axi_rready_s  : std_logic;

begin

    cpu_aresetn_s <= not cpu_rst_s;

    u_ps: component CPU_wrapper
        port map(
            DDR_ACLK          => cpu_clk_s,
            DDR_ARESETN       => cpu_aresetn_s,
            DDR_addr          => DDR_addr,
            DDR_ba            => DDR_ba,
            DDR_cas_n         => DDR_cas_n,
            DDR_ck_n          => DDR_ck_n,
            DDR_ck_p          => DDR_ck_p,
            DDR_cke           => DDR_cke,
            DDR_cs_n          => DDR_cs_n,
            DDR_dm            => DDR_dm,
            DDR_dq            => DDR_dq,
            DDR_dqs_n         => DDR_dqs_n,
            DDR_dqs_p         => DDR_dqs_p,
            DDR_odt           => DDR_odt,
            DDR_ras_n         => DDR_ras_n,
            DDR_reset_n       => DDR_reset_n,
            DDR_we_n          => DDR_we_n,
            FIXED_IO_ddr_vrn  => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp  => FIXED_IO_ddr_vrp,
            FIXED_IO_mio      => FIXED_IO_mio,
            FIXED_IO_ps_clk   => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb  => FIXED_IO_ps_porb,
            FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
            S_AXI_DDR_araddr  => m_axi_araddr_s,
            S_AXI_DDR_arburst => m_axi_arburst_s,
            S_AXI_DDR_arcache => "0011",
            S_AXI_DDR_arlen   => m_axi_arlen_s,
            S_AXI_DDR_arlock  => "0",
            S_AXI_DDR_arprot  => "000",
            S_AXI_DDR_arqos   => "0000",
            S_AXI_DDR_arready => m_axi_arready_s,
            S_AXI_DDR_arsize  => m_axi_arsize_s,
            S_AXI_DDR_arvalid => m_axi_arvalid_s,
            S_AXI_DDR_awaddr  => m_axi_awaddr_s,
            S_AXI_DDR_awburst => m_axi_awburst_s,
            S_AXI_DDR_awcache => "0011",
            S_AXI_DDR_awlen   => m_axi_awlen_s,
            S_AXI_DDR_awlock  => "0",
            S_AXI_DDR_awprot  => "000",
            S_AXI_DDR_awqos   => "0000",
            S_AXI_DDR_awready => m_axi_awready_s,
            S_AXI_DDR_awsize  => m_axi_awsize_s,
            S_AXI_DDR_awvalid => m_axi_awvalid_s,
            S_AXI_DDR_bready  => m_axi_bready_s,
            S_AXI_DDR_bresp   => m_axi_bresp_s,
            S_AXI_DDR_bvalid  => m_axi_bvalid_s,
            S_AXI_DDR_rdata   => m_axi_rdata_s,
            S_AXI_DDR_rlast   => m_axi_rlast_s,
            S_AXI_DDR_rready  => m_axi_rready_s,
            S_AXI_DDR_rresp   => m_axi_rresp_s,
            S_AXI_DDR_rvalid  => m_axi_rvalid_s,
            S_AXI_DDR_wdata   => m_axi_wdata_s,
            S_AXI_DDR_wlast   => m_axi_wlast_s,
            S_AXI_DDR_wready  => m_axi_wready_s,
            S_AXI_DDR_wstrb   => m_axi_wstrb_s,
            S_AXI_DDR_wvalid  => m_axi_wvalid_s
        );

    u_cpu: entity work.CPU_Top
        generic map(
            IMEM_WORDS => 1024,
            DMEM_WORDS => 1024
        )
        port map(
            clk           => clk,
            rst           => rst,
            btn           => btn,
            uart_rx       => uart_rx,
            led           => led,
            hdmi_clk_p    => hdmi_clk_p,
            hdmi_clk_n    => hdmi_clk_n,
            hdmi_data_p   => hdmi_data_p,
            hdmi_data_n   => hdmi_data_n,
            cpu_clk_o     => cpu_clk_s,
            cpu_rst_o     => cpu_rst_s,
            m_axi_awaddr  => m_axi_awaddr_s,
            m_axi_awlen   => m_axi_awlen_s,
            m_axi_awsize  => m_axi_awsize_s,
            m_axi_awburst => m_axi_awburst_s,
            m_axi_awvalid => m_axi_awvalid_s,
            m_axi_awready => m_axi_awready_s,
            m_axi_wdata   => m_axi_wdata_s,
            m_axi_wstrb   => m_axi_wstrb_s,
            m_axi_wlast   => m_axi_wlast_s,
            m_axi_wvalid  => m_axi_wvalid_s,
            m_axi_wready  => m_axi_wready_s,
            m_axi_bresp   => m_axi_bresp_s,
            m_axi_bvalid  => m_axi_bvalid_s,
            m_axi_bready  => m_axi_bready_s,
            m_axi_araddr  => m_axi_araddr_s,
            m_axi_arlen   => m_axi_arlen_s,
            m_axi_arsize  => m_axi_arsize_s,
            m_axi_arburst => m_axi_arburst_s,
            m_axi_arvalid => m_axi_arvalid_s,
            m_axi_arready => m_axi_arready_s,
            m_axi_rdata   => m_axi_rdata_s,
            m_axi_rresp   => m_axi_rresp_s,
            m_axi_rlast   => m_axi_rlast_s,
            m_axi_rvalid  => m_axi_rvalid_s,
            m_axi_rready  => m_axi_rready_s
        );

end architecture Structural;
