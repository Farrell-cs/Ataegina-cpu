library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity AXI4_Master is
    port(
        clk           : in  std_logic;
        rst           : in  std_logic;
        -- CPU Instruction Fetch interface (0x1xxxxxxx)
        ifetch_req    : in  std_logic;
        ifetch_addr   : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        ifetch_data   : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        -- CPU Data Load/Store interface (0x1xxxxxxx)
        dmem_req      : in  std_logic;
        dmem_we       : in  std_logic;
        dmem_funct3   : in  std_logic_vector(2 downto 0);
        dmem_addr     : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        dmem_wdata    : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        dmem_rdata    : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        -- Global CPU stall while AXI transaction is in progress
        stall         : out std_logic;
        -- AXI4 Master Interface
        m_axi_awaddr  : out std_logic_vector(31 downto 0);
        m_axi_awlen   : out std_logic_vector(7 downto 0);
        m_axi_awsize  : out std_logic_vector(2 downto 0);
        m_axi_awburst : out std_logic_vector(1 downto 0);
        m_axi_awvalid : out std_logic;
        m_axi_awready : in  std_logic;
        m_axi_wdata   : out std_logic_vector(31 downto 0);
        m_axi_wstrb   : out std_logic_vector(3 downto 0);
        m_axi_wlast   : out std_logic;
        m_axi_wvalid  : out std_logic;
        m_axi_wready  : in  std_logic;
        m_axi_bresp   : in  std_logic_vector(1 downto 0);
        m_axi_bvalid  : in  std_logic;
        m_axi_bready  : out std_logic;
        m_axi_araddr  : out std_logic_vector(31 downto 0);
        m_axi_arlen   : out std_logic_vector(7 downto 0);
        m_axi_arsize  : out std_logic_vector(2 downto 0);
        m_axi_arburst : out std_logic_vector(1 downto 0);
        m_axi_arvalid : out std_logic;
        m_axi_arready : in  std_logic;
        m_axi_rdata   : in  std_logic_vector(31 downto 0);
        m_axi_rresp   : in  std_logic_vector(1 downto 0);
        m_axi_rlast   : in  std_logic;
        m_axi_rvalid  : in  std_logic;
        m_axi_rready  : out std_logic
    );
end entity AXI4_Master;

architecture Behavioral of AXI4_Master is
    type state_t is (IDLE, READ_AR, READ_R, WRITE_AW_W, WRITE_B);
    signal state : state_t := IDLE;

    signal ifetch_done     : std_logic := '0';
    signal dmem_done       : std_logic := '0';
    signal active_is_if    : std_logic := '0';
    signal stall_s         : std_logic;

    signal ifetch_data_reg : std_logic_vector(31 downto 0) := X"00000013";
    signal dmem_rdata_reg  : std_logic_vector(31 downto 0) := (others => '0');

    signal awaddr_reg      : std_logic_vector(31 downto 0) := (others => '0');
    signal awvalid_reg     : std_logic := '0';
    signal wdata_reg       : std_logic_vector(31 downto 0) := (others => '0');
    signal wstrb_reg       : std_logic_vector(3 downto 0)  := (others => '0');
    signal wvalid_reg      : std_logic := '0';
    signal bready_reg      : std_logic := '0';
    signal araddr_reg      : std_logic_vector(31 downto 0) := (others => '0');
    signal arvalid_reg     : std_logic := '0';
    signal rready_reg      : std_logic := '0';
begin

    stall_s <= '1' when ((ifetch_req = '1' and ifetch_done = '0') or
                         (dmem_req = '1'   and dmem_done = '0')) else '0';
    stall   <= stall_s;

    ifetch_data <= ifetch_data_reg;

    m_axi_awaddr  <= awaddr_reg;
    m_axi_awlen   <= "00000000"; -- 1 beat
    m_axi_awsize  <= "010";      -- 4 bytes
    m_axi_awburst <= "01";       -- INCR
    m_axi_awvalid <= awvalid_reg;

    m_axi_wdata   <= wdata_reg;
    m_axi_wstrb   <= wstrb_reg;
    m_axi_wlast   <= '1';
    m_axi_wvalid  <= wvalid_reg;
    m_axi_bready  <= bready_reg;

    m_axi_araddr  <= araddr_reg;
    m_axi_arlen   <= "00000000"; -- 1 beat
    m_axi_arsize  <= "010";      -- 4 bytes
    m_axi_arburst <= "01";       -- INCR
    m_axi_arvalid <= arvalid_reg;
    m_axi_rready  <= rready_reg;

    process(clk)
        variable aw_done_next : std_logic;
        variable w_done_next  : std_logic;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state           <= IDLE;
                ifetch_done     <= '0';
                dmem_done       <= '0';
                active_is_if    <= '0';
                ifetch_data_reg <= X"00000013";
                dmem_rdata_reg  <= (others => '0');
                awaddr_reg      <= (others => '0');
                awvalid_reg     <= '0';
                wdata_reg       <= (others => '0');
                wstrb_reg       <= (others => '0');
                wvalid_reg      <= '0';
                bready_reg      <= '0';
                araddr_reg      <= (others => '0');
                arvalid_reg     <= '0';
                rready_reg      <= '0';
            else
                case state is
                    when IDLE =>
                        if stall_s = '0' then
                            -- Instruction is retiring this edge; clear completion flags for next cycle
                            ifetch_done <= '0';
                            dmem_done   <= '0';
                        elsif ifetch_req = '1' and ifetch_done = '0' then
                            active_is_if <= '1';
                            araddr_reg   <= ifetch_addr(31 downto 2) & "00";
                            arvalid_reg  <= '1';
                            state        <= READ_AR;
                        elsif dmem_req = '1' and dmem_done = '0' then
                            active_is_if <= '0';
                            if dmem_we = '1' then
                                awaddr_reg  <= dmem_addr(31 downto 2) & "00";
                                awvalid_reg <= '1';
                                wvalid_reg  <= '1';
                                case dmem_funct3 is
                                    when F3_BYTE =>
                                        wdata_reg <= dmem_wdata(7 downto 0) & dmem_wdata(7 downto 0) &
                                                     dmem_wdata(7 downto 0) & dmem_wdata(7 downto 0);
                                        case dmem_addr(1 downto 0) is
                                            when "00"   => wstrb_reg <= "0001";
                                            when "01"   => wstrb_reg <= "0010";
                                            when "10"   => wstrb_reg <= "0100";
                                            when others => wstrb_reg <= "1000";
                                        end case;
                                    when F3_HALF =>
                                        wdata_reg <= dmem_wdata(15 downto 0) & dmem_wdata(15 downto 0);
                                        if dmem_addr(1) = '0' then
                                            wstrb_reg <= "0011";
                                        else
                                            wstrb_reg <= "1100";
                                        end if;
                                    when others =>
                                        wdata_reg <= dmem_wdata;
                                        wstrb_reg <= "1111";
                                end case;
                                state <= WRITE_AW_W;
                            else
                                araddr_reg  <= dmem_addr(31 downto 2) & "00";
                                arvalid_reg <= '1';
                                state       <= READ_AR;
                            end if;
                        end if;

                    when READ_AR =>
                        if m_axi_arready = '1' then
                            arvalid_reg <= '0';
                            rready_reg  <= '1';
                            state       <= READ_R;
                        end if;

                    when READ_R =>
                        if m_axi_rvalid = '1' then
                            rready_reg <= '0';
                            if active_is_if = '1' then
                                ifetch_data_reg <= m_axi_rdata;
                                ifetch_done     <= '1';
                            else
                                dmem_rdata_reg <= m_axi_rdata;
                                dmem_done      <= '1';
                            end if;
                            state <= IDLE;
                        end if;

                    when WRITE_AW_W =>
                        aw_done_next := not awvalid_reg;
                        w_done_next  := not wvalid_reg;

                        if awvalid_reg = '1' and m_axi_awready = '1' then
                            awvalid_reg  <= '0';
                            aw_done_next := '1';
                        end if;

                        if wvalid_reg = '1' and m_axi_wready = '1' then
                            wvalid_reg  <= '0';
                            w_done_next := '1';
                        end if;

                        if aw_done_next = '1' and w_done_next = '1' then
                            bready_reg <= '1';
                            state      <= WRITE_B;
                        end if;

                    when WRITE_B =>
                        if m_axi_bvalid = '1' then
                            bready_reg <= '0';
                            dmem_done  <= '1';
                            state      <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- Byte/halfword read alignment and sign/zero extension for DDR3 loads
    process(dmem_rdata_reg, dmem_funct3, dmem_addr)
        variable target_byte : std_logic_vector(7 downto 0);
        variable target_half : std_logic_vector(15 downto 0);
    begin
        case dmem_addr(1 downto 0) is
            when "00"   => target_byte := dmem_rdata_reg(7 downto 0);
            when "01"   => target_byte := dmem_rdata_reg(15 downto 8);
            when "10"   => target_byte := dmem_rdata_reg(23 downto 16);
            when others => target_byte := dmem_rdata_reg(31 downto 24);
        end case;

        if dmem_addr(1) = '0' then
            target_half := dmem_rdata_reg(15 downto 0);
        else
            target_half := dmem_rdata_reg(31 downto 16);
        end if;

        case dmem_funct3 is
            when F3_BYTE   => dmem_rdata <= std_logic_vector(resize(signed(target_byte), 32));
            when F3_BYTE_U => dmem_rdata <= std_logic_vector(resize(unsigned(target_byte), 32));
            when F3_HALF   => dmem_rdata <= std_logic_vector(resize(signed(target_half), 32));
            when F3_HALF_U => dmem_rdata <= std_logic_vector(resize(unsigned(target_half), 32));
            when others    => dmem_rdata <= dmem_rdata_reg;
        end case;
    end process;

end Behavioral;
