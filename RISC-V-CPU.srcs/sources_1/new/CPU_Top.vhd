library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity CPU_Top is
    generic(
        IMEM_WORDS : integer := 1024;
        DMEM_WORDS : integer := 1024
    );
    port(
        clk           : in  std_logic;
        rst           : in  std_logic;
        btn           : in  std_logic_vector(2 downto 0) := "000";
        uart_rx       : in  std_logic := '1';
        led           : out std_logic_vector(3 downto 0);
        hdmi_clk_p    : out std_logic;
        hdmi_clk_n    : out std_logic;
        hdmi_data_p   : out std_logic_vector(2 downto 0);
        hdmi_data_n   : out std_logic_vector(2 downto 0);
        -- AXI4 Master port for DDR3 access (0x10000000 - 0x1FFFFFFF)
        cpu_clk_o     : out std_logic;
        cpu_rst_o     : out std_logic;
        m_axi_awaddr  : out std_logic_vector(31 downto 0);
        m_axi_awlen   : out std_logic_vector(7 downto 0);
        m_axi_awsize  : out std_logic_vector(2 downto 0);
        m_axi_awburst : out std_logic_vector(1 downto 0);
        m_axi_awvalid : out std_logic;
        m_axi_awready : in  std_logic := '0';
        m_axi_wdata   : out std_logic_vector(31 downto 0);
        m_axi_wstrb   : out std_logic_vector(3 downto 0);
        m_axi_wlast   : out std_logic;
        m_axi_wvalid  : out std_logic;
        m_axi_wready  : in  std_logic := '0';
        m_axi_bresp   : in  std_logic_vector(1 downto 0) := "00";
        m_axi_bvalid  : in  std_logic := '0';
        m_axi_bready  : out std_logic;
        m_axi_araddr  : out std_logic_vector(31 downto 0);
        m_axi_arlen   : out std_logic_vector(7 downto 0);
        m_axi_arsize  : out std_logic_vector(2 downto 0);
        m_axi_arburst : out std_logic_vector(1 downto 0);
        m_axi_arvalid : out std_logic;
        m_axi_arready : in  std_logic := '0';
        m_axi_rdata   : in  std_logic_vector(31 downto 0) := (others => '0');
        m_axi_rresp   : in  std_logic_vector(1 downto 0) := "00";
        m_axi_rlast   : in  std_logic := '1';
        m_axi_rvalid  : in  std_logic := '0';
        m_axi_rready  : out std_logic
    );
end entity CPU_Top;

architecture Structural of CPU_Top is

    signal cpu_clk       : std_logic;
    signal pll_locked    : std_logic;
    signal cpu_rst       : std_logic;
    signal rst_sync      : std_logic_vector(1 downto 0) := "11";

    signal pc_in         : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal pc_out        : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal pc_plus_4     : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal const_four    : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal imem_instr    : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal instruction   : std_logic_vector(WORD_WIDTH - 1 downto 0);

    signal opcode        : std_logic_vector(6 downto 0);
    signal read_reg_1    : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal read_reg_2    : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal write_reg     : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    signal funct3        : std_logic_vector(2 downto 0);
    signal funct7_b5     : std_logic;
    signal funct7_b0     : std_logic;

    signal branch        : std_logic;
    signal mem_read      : std_logic;
    signal mem_to_reg    : std_logic;
    signal alu_op        : std_logic_vector(2 downto 0);
    signal mem_write     : std_logic;
    signal alu_src       : std_logic;
    signal reg_write     : std_logic;
    signal reg_write_eff : std_logic;
    signal pc_en         : std_logic;
    signal jump          : std_logic;
    signal jalr          : std_logic;
    signal auipc         : std_logic;

    signal read_data_1   : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal read_data_2   : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal imm_out       : std_logic_vector(WORD_WIDTH - 1 downto 0);

    signal alu_in_1      : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal alu_in_2      : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal alu_ctrl      : std_logic_vector(4 downto 0);
    signal alu_result    : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal div_result    : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal exec_result   : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal is_div_op     : std_logic;
    signal div_stall     : std_logic;
    signal axi_stall     : std_logic;
    signal cpu_stall     : std_logic;
    signal pc_in_ddr     : std_logic;
    signal dmem_in_ddr   : std_logic;
    signal axi_ifetch_req: std_logic;
    signal axi_dmem_req  : std_logic;
    signal axi_ifetch_data : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal axi_dmem_rdata  : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal zero          : std_logic;

    signal jump_base     : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal branch_target : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal pc_src        : std_logic;

    signal dmem_write     : std_logic;
    signal dmem_read      : std_logic;
    signal dmem_read_data : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal read_data      : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal mem_or_alu     : std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal write_data     : std_logic_vector(WORD_WIDTH - 1 downto 0);

    signal vram_we       : std_logic;
    signal ms_prescaler  : integer range 0 to 36874 := 0;
    signal ms_counter    : unsigned(31 downto 0) := (others => '0');
    signal vram_addr     : std_logic_vector(15 downto 0);
    signal vram_din      : std_logic_vector(7 downto 0);
    signal vram_dout     : std_logic_vector(7 downto 0);

    signal btn_meta      : std_logic_vector(2 downto 0) := "000";
    signal btn_sync      : std_logic_vector(2 downto 0) := "000";

    signal loader_active : std_logic := '0';
    signal loader_we     : std_logic := '0';
    signal loader_addr   : std_logic_vector(31 downto 0) := (others => '0');
    signal loader_wdata  : std_logic_vector(31 downto 0) := (others => '0');
    signal heartbeat_cnt : unsigned(25 downto 0) := (others => '0');

begin

    -- Hold CPU in reset until PLL locks and rst button is released
    process(cpu_clk, pll_locked, rst)
    begin
        if pll_locked = '0' or rst = '1' then
            rst_sync <= "11";
        elsif rising_edge(cpu_clk) then
            rst_sync <= rst_sync(0) & '0';
        end if;
    end process;
    cpu_rst <= rst_sync(1) or loader_active;

    u_uart_loader: entity work.UART_Program_Loader
        generic map(
            CLK_FREQ_HZ => 36875000,
            BAUD_RATE   => 115200
        )
        port map(
            clk           => cpu_clk,
            rst           => rst,
            rx            => uart_rx,
            loader_active => loader_active,
            imem_we       => loader_we,
            imem_addr     => loader_addr,
            imem_wdata    => loader_wdata
        );

    cpu_clk_o     <= cpu_clk;
    cpu_rst_o     <= cpu_rst;
    cpu_stall     <= div_stall or axi_stall;
    pc_en         <= not cpu_stall;
    reg_write_eff <= reg_write and (not cpu_stall);

    u_pc: entity work.PC
        port map(
            clk    => cpu_clk,
            rst    => cpu_rst,
            en     => pc_en,
            pc_in  => pc_in,
            pc_out => pc_out
        );

    u_add_pc_4: entity work.Adder
        port map(
            in_a => pc_out,
            in_b => const_four,
            sum  => pc_plus_4
        );

    u_imem: entity work.Instruction_Memory
        generic map(
            IMEM_WORDS => IMEM_WORDS
        )
        port map(
            clk           => cpu_clk,
            write_en      => loader_we,
            write_address => loader_addr,
            write_data    => loader_wdata,
            read_address  => pc_out,
            instruction   => imem_instr
        );

    pc_in_ddr      <= '1' when pc_out(31 downto 28) = "0001" else '0';
    axi_ifetch_req <= pc_in_ddr and (not cpu_rst);
    instruction    <= axi_ifetch_data when pc_in_ddr = '1' else imem_instr;

    opcode     <= instruction(6 downto 0);
    write_reg  <= instruction(11 downto 7);
    funct3     <= instruction(14 downto 12);
    read_reg_1 <= instruction(19 downto 15);
    read_reg_2 <= instruction(24 downto 20);
    funct7_b5  <= instruction(30);
    funct7_b0  <= instruction(25);
    const_four <= X"00000004";

    u_control: entity work.Control
        port map(
            opcode     => opcode,
            branch     => branch,
            mem_read   => mem_read,
            mem_to_reg => mem_to_reg,
            alu_op     => alu_op,
            mem_write  => mem_write,
            alu_src    => alu_src,
            reg_write  => reg_write,
            jump       => jump,
            jalr       => jalr,
            auipc      => auipc
        );

    u_registers: entity work.Registers
        port map(
            clk         => cpu_clk,
            rst         => cpu_rst,
            reg_write   => reg_write_eff,
            read_reg_1  => read_reg_1,
            read_reg_2  => read_reg_2,
            write_reg   => write_reg,
            write_data  => write_data,
            read_data_1 => read_data_1,
            read_data_2 => read_data_2
        );

    u_imm_gen: entity work.Imm_Gen
        port map(
            instruction => instruction,
            imm_out     => imm_out
        );

    u_mux_alu_a: entity work.Mux2
        port map(
            in_0    => read_data_1,
            in_1    => pc_out,
            sel     => auipc,
            mux_out => alu_in_1
        );

    u_mux_alu_src: entity work.Mux2
        port map(
            in_0    => read_data_2,
            in_1    => imm_out,
            sel     => alu_src,
            mux_out => alu_in_2
        );

    u_alu_control: entity work.ALU_Control
        port map(
            alu_op    => alu_op,
            funct3    => funct3,
            funct7_b5 => funct7_b5,
            funct7_b0 => funct7_b0,
            alu_ctrl  => alu_ctrl
        );

    u_alu: entity work.ALU
        port map(
            in_1       => alu_in_1,
            in_2       => alu_in_2,
            alu_ctrl   => alu_ctrl,
            zero       => zero,
            alu_result => alu_result
        );

    u_div_unit: entity work.Div_Unit
        port map(
            clk        => cpu_clk,
            rst        => cpu_rst,
            alu_ctrl   => alu_ctrl,
            in_1       => alu_in_1,
            in_2       => alu_in_2,
            is_div_op  => is_div_op,
            stall      => div_stall,
            div_result => div_result
        );

    exec_result <= div_result when is_div_op = '1' else alu_result;

    u_mux_jump_base: entity work.Mux2
        port map(
            in_0    => pc_out,
            in_1    => read_data_1,
            sel     => jalr,
            mux_out => jump_base
        );

    u_add_branch: entity work.Adder
        port map(
            in_a => jump_base,
            in_b => imm_out,
            sum  => branch_target
        );

    u_branch_and: entity work.Branch_And
        port map(
            branch => branch,
            jump   => jump,
            funct3 => funct3,
            zero   => zero,
            pc_src => pc_src
        );

    u_mux_pc_src: entity work.Mux2
        port map(
            in_0    => pc_plus_4,
            in_1    => branch_target,
            sel     => pc_src,
            mux_out => pc_in
        );

    dmem_in_ddr  <= '1' when alu_result(31 downto 28) = "0001" else '0';
    axi_dmem_req <= dmem_in_ddr and (mem_read or mem_write) and (not cpu_rst);

    dmem_write <= mem_write when (alu_result(31) = '0' and dmem_in_ddr = '0' and cpu_stall = '0') else '0';
    dmem_read  <= mem_read  when (alu_result(31) = '0' and dmem_in_ddr = '0') else '0';

    vram_we   <= mem_write when (alu_result(31) = '1' and alu_result(16) = '0' and cpu_rst = '0' and cpu_stall = '0') else '0';
    vram_addr <= alu_result(15 downto 0);
    vram_din  <= read_data_2(7 downto 0);

    process(cpu_clk)
    begin
        if rising_edge(cpu_clk) then
            btn_meta <= btn;
            btn_sync <= btn_meta;
            if cpu_rst = '1' then
                ms_prescaler <= 0;
                ms_counter   <= (others => '0');
            elsif ms_prescaler = 36874 then
                ms_prescaler <= 0;
                ms_counter   <= ms_counter + 1;
            else
                ms_prescaler <= ms_prescaler + 1;
            end if;
        end if;
    end process;

    process(alu_result, dmem_read_data, vram_dout, btn_sync, ms_counter, dmem_in_ddr, axi_dmem_rdata)
    begin
        if alu_result(31) = '1' then
            if alu_result(16) = '1' then
                if alu_result(2) = '1' then
                    read_data <= std_logic_vector(ms_counter);
                else
                    read_data <= X"0000000" & '0' & btn_sync;
                end if;
            else
                read_data <= X"000000" & vram_dout;
            end if;
        elsif dmem_in_ddr = '1' then
            read_data <= axi_dmem_rdata;
        else
            read_data <= dmem_read_data;
        end if;
    end process;

    u_axi_master: entity work.AXI4_Master
        port map(
            clk           => cpu_clk,
            rst           => cpu_rst,
            ifetch_req    => axi_ifetch_req,
            ifetch_addr   => pc_out,
            ifetch_data   => axi_ifetch_data,
            dmem_req      => axi_dmem_req,
            dmem_we       => mem_write,
            dmem_funct3   => funct3,
            dmem_addr     => alu_result,
            dmem_wdata    => read_data_2,
            dmem_rdata    => axi_dmem_rdata,
            stall         => axi_stall,
            m_axi_awaddr  => m_axi_awaddr,
            m_axi_awlen   => m_axi_awlen,
            m_axi_awsize  => m_axi_awsize,
            m_axi_awburst => m_axi_awburst,
            m_axi_awvalid => m_axi_awvalid,
            m_axi_awready => m_axi_awready,
            m_axi_wdata   => m_axi_wdata,
            m_axi_wstrb   => m_axi_wstrb,
            m_axi_wlast   => m_axi_wlast,
            m_axi_wvalid  => m_axi_wvalid,
            m_axi_wready  => m_axi_wready,
            m_axi_bresp   => m_axi_bresp,
            m_axi_bvalid  => m_axi_bvalid,
            m_axi_bready  => m_axi_bready,
            m_axi_araddr  => m_axi_araddr,
            m_axi_arlen   => m_axi_arlen,
            m_axi_arsize  => m_axi_arsize,
            m_axi_arburst => m_axi_arburst,
            m_axi_arvalid => m_axi_arvalid,
            m_axi_arready => m_axi_arready,
            m_axi_rdata   => m_axi_rdata,
            m_axi_rresp   => m_axi_rresp,
            m_axi_rlast   => m_axi_rlast,
            m_axi_rvalid  => m_axi_rvalid,
            m_axi_rready  => m_axi_rready
        );

    u_dmem: entity work.Data_Memory
        generic map(
            DMEM_WORDS => DMEM_WORDS
        )
        port map(
            clk        => cpu_clk,
            rst        => cpu_rst,
            mem_read   => dmem_read,
            mem_write  => dmem_write,
            funct3     => funct3,
            address    => alu_result,
            write_data => read_data_2,
            read_data  => dmem_read_data
        );

    u_hdmi: entity work.HDMI_Controller
        generic map(
            SERIES6 => false
        )
        port map(
            clk_125mhz => clk,
            rst        => rst,
            clk_cpu_o  => cpu_clk,
            pll_locked => pll_locked,
            vram_we    => vram_we,
            vram_addr  => vram_addr,
            vram_din   => vram_din,
            vram_dout  => vram_dout,
            clk_p      => hdmi_clk_p,
            clk_n      => hdmi_clk_n,
            data_p     => hdmi_data_p,
            data_n     => hdmi_data_n
        );

    u_mux_mem_to_reg: entity work.Mux2
        port map(
            in_0    => exec_result,
            in_1    => read_data,
            sel     => mem_to_reg,
            mux_out => mem_or_alu
        );

    u_mux_wb_jump: entity work.Mux2
        port map(
            in_0    => mem_or_alu,
            in_1    => pc_plus_4,
            sel     => jump,
            mux_out => write_data
        );

    process(cpu_clk)
    begin
        if rising_edge(cpu_clk) then
            heartbeat_cnt <= heartbeat_cnt + 1;
        end if;
    end process;

    led(0) <= pll_locked;
    led(1) <= heartbeat_cnt(24);
    led(2) <= vram_we;
    led(3) <= btn_sync(0) or btn_sync(1) or btn_sync(2);

end architecture Structural;
