library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BUFG is
    port (
        O : out std_ulogic;
        I : in  std_ulogic
    );
end entity BUFG;

architecture sim of BUFG is
begin
    O <= I;
end architecture sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BUFIO is
    port (
        O : out std_ulogic;
        I : in  std_ulogic
    );
end entity BUFIO;

architecture sim of BUFIO is
begin
    O <= I;
end architecture sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BUFR is
    generic (
        BUFR_DIVIDE : string := "BYPASS";
        SIM_DEVICE  : string := "7SERIES"
    );
    port (
        O   : out std_ulogic;
        CE  : in  std_ulogic := '1';
        CLR : in  std_ulogic := '0';
        I   : in  std_ulogic
    );
end entity BUFR;

architecture sim of BUFR is
begin
    O <= I;
end architecture sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OBUFDS is
    generic (
        CAPACITANCE : string := "DONT_CARE";
        IOSTANDARD  : string := "DEFAULT";
        SLEW        : string := "SLOW"
    );
    port (
        O  : out std_ulogic;
        OB : out std_ulogic;
        I  : in  std_ulogic
    );
end entity OBUFDS;

architecture sim of OBUFDS is
begin
    O  <= to_X01(I);
    OB <= not to_X01(I);
end architecture sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PLLE2_BASE is
    generic (
        BANDWIDTH          : string  := "OPTIMIZED";
        CLKFBOUT_MULT      : integer := 5;
        CLKFBOUT_PHASE     : real    := 0.000;
        CLKIN1_PERIOD      : real    := 8.000;
        CLKOUT0_DIVIDE     : integer := 1;
        CLKOUT0_DUTY_CYCLE : real    := 0.500;
        CLKOUT0_PHASE      : real    := 0.000;
        CLKOUT1_DIVIDE     : integer := 1;
        CLKOUT1_DUTY_CYCLE : real    := 0.500;
        CLKOUT1_PHASE      : real    := 0.000;
        CLKOUT2_DIVIDE     : integer := 1;
        CLKOUT2_DUTY_CYCLE : real    := 0.500;
        CLKOUT2_PHASE      : real    := 0.000;
        CLKOUT3_DIVIDE     : integer := 1;
        CLKOUT3_DUTY_CYCLE : real    := 0.500;
        CLKOUT3_PHASE      : real    := 0.000;
        CLKOUT4_DIVIDE     : integer := 1;
        CLKOUT4_DUTY_CYCLE : real    := 0.500;
        CLKOUT4_PHASE      : real    := 0.000;
        CLKOUT5_DIVIDE     : integer := 1;
        CLKOUT5_DUTY_CYCLE : real    := 0.500;
        CLKOUT5_PHASE      : real    := 0.000;
        DIVCLK_DIVIDE      : integer := 1;
        REF_JITTER1        : real    := 0.010;
        STARTUP_WAIT       : string  := "FALSE"
    );
    port (
        CLKFBOUT : out std_ulogic := '0';
        CLKOUT0  : out std_ulogic := '0';
        CLKOUT1  : out std_ulogic := '0';
        CLKOUT2  : out std_ulogic := '0';
        CLKOUT3  : out std_ulogic := '0';
        CLKOUT4  : out std_ulogic := '0';
        CLKOUT5  : out std_ulogic := '0';
        LOCKED   : out std_ulogic := '0';
        CLKFBIN  : in  std_ulogic;
        CLKIN1   : in  std_ulogic;
        PWRDWN   : in  std_ulogic;
        RST      : in  std_ulogic
    );
end entity PLLE2_BASE;

architecture sim of PLLE2_BASE is
    function gcd2(a, b : integer) return integer is
        variable x : integer := a;
        variable y : integer := b;
        variable t : integer;
    begin
        while y /= 0 loop
            t := x mod y;
            x := y;
            y := t;
        end loop;
        if x < 1 then
            return 1;
        end if;
        return x;
    end function;

    function compute_step_div return integer is
        variable g : integer := 0;
        variable divs : integer_vector(0 to 5) := (
            CLKOUT0_DIVIDE, CLKOUT1_DIVIDE, CLKOUT2_DIVIDE,
            CLKOUT3_DIVIDE, CLKOUT4_DIVIDE, CLKOUT5_DIVIDE
        );
    begin
        for i in 0 to 5 loop
            if divs(i) > 1 then
                if g = 0 then
                    g := divs(i);
                else
                    g := gcd2(g, divs(i));
                end if;
            end if;
        end loop;
        if g = 0 then
            return 1;
        end if;
        return g;
    end function;

    constant VCO_HALF_FS  : time := integer((CLKIN1_PERIOD * 1.0e6 * real(DIVCLK_DIVIDE)) / (2.0 * real(CLKFBOUT_MULT))) * 1 fs;
    constant STEP_DIV     : integer := compute_step_div;
    constant STEP_HALF_FS : time := VCO_HALF_FS * STEP_DIV;
    signal lock_int  : std_ulogic := '0';
    signal c0, c1, c2, c3, c4, c5 : std_ulogic := '0';
begin
    process
        variable clkin_cycles : integer := 0;
    begin
        lock_int <= '0';
        clkin_cycles := 0;
        while clkin_cycles < 4 loop
            wait until rising_edge(CLKIN1) or RST = '1' or PWRDWN = '1';
            if RST = '1' or PWRDWN = '1' then
                lock_int <= '0';
                clkin_cycles := 0;
                wait until RST = '0' and PWRDWN = '0';
            else
                clkin_cycles := clkin_cycles + 1;
            end if;
        end loop;
        lock_int <= '1';
        wait until RST = '1' or PWRDWN = '1';
    end process;

    -- Step directly at the GCD of active dividers (e.g. 4 * VCO_HALF_FS instead of 1.475 GHz VCO)
    -- to eliminate redundant simulator events while keeping identical output clock edges.
    process
        variable cnt0, cnt1, cnt2, cnt3, cnt4, cnt5 : integer := 0;
    begin
        if RST = '1' or PWRDWN = '1' or lock_int = '0' then
            cnt0 := 0; cnt1 := 0; cnt2 := 0; cnt3 := 0; cnt4 := 0; cnt5 := 0;
            c0 <= '0'; c1 <= '0'; c2 <= '0'; c3 <= '0'; c4 <= '0'; c5 <= '0';
            wait until lock_int = '1' and RST = '0' and PWRDWN = '0';
        else
            wait for STEP_HALF_FS;
            if RST = '0' and PWRDWN = '0' and lock_int = '1' then
                if CLKOUT0_DIVIDE > 1 or STEP_DIV = 1 then
                    cnt0 := cnt0 + STEP_DIV;
                    if cnt0 >= CLKOUT0_DIVIDE then
                        cnt0 := 0;
                        c0 <= not c0;
                    end if;
                end if;
                if CLKOUT1_DIVIDE > 1 or STEP_DIV = 1 then
                    cnt1 := cnt1 + STEP_DIV;
                    if cnt1 >= CLKOUT1_DIVIDE then
                        cnt1 := 0;
                        c1 <= not c1;
                    end if;
                end if;
                if CLKOUT2_DIVIDE > 1 or STEP_DIV = 1 then
                    cnt2 := cnt2 + STEP_DIV;
                    if cnt2 >= CLKOUT2_DIVIDE then
                        cnt2 := 0;
                        c2 <= not c2;
                    end if;
                end if;
                if CLKOUT3_DIVIDE > 1 or STEP_DIV = 1 then
                    cnt3 := cnt3 + STEP_DIV;
                    if cnt3 >= CLKOUT3_DIVIDE then
                        cnt3 := 0;
                        c3 <= not c3;
                    end if;
                end if;
                if CLKOUT4_DIVIDE > 1 or STEP_DIV = 1 then
                    cnt4 := cnt4 + STEP_DIV;
                    if cnt4 >= CLKOUT4_DIVIDE then
                        cnt4 := 0;
                        c4 <= not c4;
                    end if;
                end if;
                if CLKOUT5_DIVIDE > 1 or STEP_DIV = 1 then
                    cnt5 := cnt5 + STEP_DIV;
                    if cnt5 >= CLKOUT5_DIVIDE then
                        cnt5 := 0;
                        c5 <= not c5;
                    end if;
                end if;
            end if;
        end if;
    end process;

    CLKOUT0  <= c0;
    CLKOUT1  <= c1;
    CLKOUT2  <= c2;
    CLKOUT3  <= c3;
    CLKOUT4  <= c4;
    CLKOUT5  <= c5;
    CLKFBOUT <= CLKIN1;
    LOCKED   <= lock_int;
end architecture sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PLLE2_ADV is
    generic (
        BANDWIDTH          : string  := "OPTIMIZED";
        COMPENSATION       : string  := "ZHOLD";
        STARTUP_WAIT       : string  := "FALSE";
        DIVCLK_DIVIDE      : integer := 1;
        CLKFBOUT_MULT      : integer := 5;
        CLKFBOUT_PHASE     : real    := 0.000;
        CLKOUT0_DIVIDE     : integer := 1;
        CLKOUT0_PHASE      : real    := 0.000;
        CLKOUT0_DUTY_CYCLE : real    := 0.500;
        CLKOUT1_DIVIDE     : integer := 1;
        CLKOUT1_PHASE      : real    := 0.000;
        CLKOUT1_DUTY_CYCLE : real    := 0.500;
        CLKOUT2_DIVIDE     : integer := 1;
        CLKOUT2_PHASE      : real    := 0.000;
        CLKOUT2_DUTY_CYCLE : real    := 0.500;
        CLKOUT3_DIVIDE     : integer := 1;
        CLKOUT3_PHASE      : real    := 0.000;
        CLKOUT3_DUTY_CYCLE : real    := 0.500;
        CLKOUT4_DIVIDE     : integer := 1;
        CLKOUT4_PHASE      : real    := 0.000;
        CLKOUT4_DUTY_CYCLE : real    := 0.500;
        CLKOUT5_DIVIDE     : integer := 1;
        CLKOUT5_PHASE      : real    := 0.000;
        CLKOUT5_DUTY_CYCLE : real    := 0.500;
        CLKIN1_PERIOD      : real    := 0.000;
        CLKIN2_PERIOD      : real    := 0.000;
        REF_JITTER1        : real    := 0.010;
        REF_JITTER2        : real    := 0.010
    );
    port (
        CLKFBOUT : out std_ulogic := '0';
        CLKOUT0  : out std_ulogic := '0';
        CLKOUT1  : out std_ulogic := '0';
        CLKOUT2  : out std_ulogic := '0';
        CLKOUT3  : out std_ulogic := '0';
        CLKOUT4  : out std_ulogic := '0';
        CLKOUT5  : out std_ulogic := '0';
        DO       : out std_logic_vector(15 downto 0) := (others => '0');
        DRDY     : out std_ulogic := '0';
        LOCKED   : out std_ulogic := '0';
        CLKFBIN  : in  std_ulogic;
        CLKIN1   : in  std_ulogic;
        CLKIN2   : in  std_ulogic := '0';
        CLKINSEL : in  std_ulogic := '1';
        DADDR    : in  std_logic_vector(6 downto 0) := (others => '0');
        DCLK     : in  std_ulogic := '0';
        DEN      : in  std_ulogic := '0';
        DI       : in  std_logic_vector(15 downto 0) := (others => '0');
        DWE      : in  std_ulogic := '0';
        PWRDWN   : in  std_ulogic := '0';
        RST      : in  std_ulogic := '0'
    );
end entity PLLE2_ADV;

architecture sim of PLLE2_ADV is
begin
    LOCKED <= not RST;
end architecture sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MMCME2_ADV is
    generic (
        BANDWIDTH            : string  := "OPTIMIZED";
        CLKFBOUT_MULT_F      : real    := 5.000;
        CLKFBOUT_PHASE       : real    := 0.000;
        CLKFBOUT_USE_FINE_PS : boolean := false;
        CLKIN1_PERIOD        : real    := 0.000;
        CLKIN2_PERIOD        : real    := 0.000;
        CLKOUT0_DIVIDE_F     : real    := 1.000;
        CLKOUT0_DUTY_CYCLE   : real    := 0.500;
        CLKOUT0_PHASE        : real    := 0.000;
        CLKOUT0_USE_FINE_PS  : boolean := false;
        CLKOUT1_DIVIDE       : integer := 1;
        CLKOUT1_DUTY_CYCLE   : real    := 0.500;
        CLKOUT1_PHASE        : real    := 0.000;
        CLKOUT1_USE_FINE_PS  : boolean := false;
        CLKOUT2_DIVIDE       : integer := 1;
        CLKOUT2_DUTY_CYCLE   : real    := 0.500;
        CLKOUT2_PHASE        : real    := 0.000;
        CLKOUT2_USE_FINE_PS  : boolean := false;
        CLKOUT3_DIVIDE       : integer := 1;
        CLKOUT3_DUTY_CYCLE   : real    := 0.500;
        CLKOUT3_PHASE        : real    := 0.000;
        CLKOUT3_USE_FINE_PS  : boolean := false;
        CLKOUT4_CASCADE      : boolean := false;
        CLKOUT4_DIVIDE       : integer := 1;
        CLKOUT4_DUTY_CYCLE   : real    := 0.500;
        CLKOUT4_PHASE        : real    := 0.000;
        CLKOUT4_USE_FINE_PS  : boolean := false;
        CLKOUT5_DIVIDE       : integer := 1;
        CLKOUT5_DUTY_CYCLE   : real    := 0.500;
        CLKOUT5_PHASE        : real    := 0.000;
        CLKOUT5_USE_FINE_PS  : boolean := false;
        CLKOUT6_DIVIDE       : integer := 1;
        CLKOUT6_DUTY_CYCLE   : real    := 0.500;
        CLKOUT6_PHASE        : real    := 0.000;
        CLKOUT6_USE_FINE_PS  : boolean := false;
        COMPENSATION         : string  := "ZHOLD";
        DIVCLK_DIVIDE        : integer := 1;
        REF_JITTER1          : real    := 0.010;
        REF_JITTER2          : real    := 0.010;
        SS_EN                : string  := "FALSE";
        SS_MODE              : string  := "CENTER_HIGH";
        SS_MOD_PERIOD        : integer := 10000;
        STARTUP_WAIT         : boolean := false
    );
    port (
        CLKFBOUT     : out std_ulogic := '0';
        CLKFBOUTB    : out std_ulogic := '0';
        CLKFBSTOPPED : out std_ulogic := '0';
        CLKINSTOPPED : out std_ulogic := '0';
        CLKOUT0      : out std_ulogic := '0';
        CLKOUT0B     : out std_ulogic := '0';
        CLKOUT1      : out std_ulogic := '0';
        CLKOUT1B     : out std_ulogic := '0';
        CLKOUT2      : out std_ulogic := '0';
        CLKOUT2B     : out std_ulogic := '0';
        CLKOUT3      : out std_ulogic := '0';
        CLKOUT3B     : out std_ulogic := '0';
        CLKOUT4      : out std_ulogic := '0';
        CLKOUT5      : out std_ulogic := '0';
        CLKOUT6      : out std_ulogic := '0';
        DO           : out std_logic_vector(15 downto 0) := (others => '0');
        DRDY         : out std_ulogic := '0';
        LOCKED       : out std_ulogic := '0';
        PSDONE       : out std_ulogic := '0';
        CLKFBIN      : in  std_ulogic;
        CLKIN1       : in  std_ulogic;
        CLKIN2       : in  std_ulogic := '0';
        CLKINSEL     : in  std_ulogic := '1';
        DADDR        : in  std_logic_vector(6 downto 0) := (others => '0');
        DCLK         : in  std_ulogic := '0';
        DEN          : in  std_ulogic := '0';
        DI           : in  std_logic_vector(15 downto 0) := (others => '0');
        DWE          : in  std_ulogic := '0';
        PSCLK        : in  std_ulogic := '0';
        PSEN         : in  std_ulogic := '0';
        PSINCDEC     : in  std_ulogic := '0';
        PWRDWN       : in  std_ulogic := '0';
        RST          : in  std_ulogic := '0'
    );
end entity MMCME2_ADV;

architecture sim of MMCME2_ADV is
begin
    LOCKED <= not RST;
end architecture sim;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OSERDESE2 is
    generic (
        DATA_RATE_OQ       : string  := "DDR";
        DATA_RATE_TQ       : string  := "DDR";
        DATA_WIDTH         : integer := 4;
        INIT_OQ            : bit     := '0';
        INIT_TQ            : bit     := '0';
        IS_CLKDIV_INVERTED : bit     := '0';
        IS_CLK_INVERTED    : bit     := '0';
        IS_D1_INVERTED     : bit     := '0';
        IS_D2_INVERTED     : bit     := '0';
        IS_D3_INVERTED     : bit     := '0';
        IS_D4_INVERTED     : bit     := '0';
        IS_D5_INVERTED     : bit     := '0';
        IS_D6_INVERTED     : bit     := '0';
        IS_D7_INVERTED     : bit     := '0';
        IS_D8_INVERTED     : bit     := '0';
        IS_T1_INVERTED     : bit     := '0';
        IS_T2_INVERTED     : bit     := '0';
        IS_T3_INVERTED     : bit     := '0';
        IS_T4_INVERTED     : bit     := '0';
        SERDES_MODE        : string  := "MASTER";
        SRVAL_OQ           : bit     := '0';
        SRVAL_TQ           : bit     := '0';
        TBYTE_CTL          : string  := "FALSE";
        TBYTE_SRC          : string  := "FALSE";
        TRISTATE_WIDTH     : integer := 4
    );
    port (
        OFB       : out std_ulogic := '0';
        OQ        : out std_ulogic := '0';
        SHIFTOUT1 : out std_ulogic := '0';
        SHIFTOUT2 : out std_ulogic := '0';
        TBYTEOUT  : out std_ulogic := '0';
        TFB       : out std_ulogic := '0';
        TQ        : out std_ulogic := '0';
        CLK       : in  std_ulogic;
        CLKDIV    : in  std_ulogic;
        D1        : in  std_ulogic;
        D2        : in  std_ulogic;
        D3        : in  std_ulogic;
        D4        : in  std_ulogic;
        D5        : in  std_ulogic;
        D6        : in  std_ulogic;
        D7        : in  std_ulogic;
        D8        : in  std_ulogic;
        OCE       : in  std_ulogic;
        RST       : in  std_ulogic;
        SHIFTIN1  : in  std_ulogic;
        SHIFTIN2  : in  std_ulogic;
        T1        : in  std_ulogic;
        T2        : in  std_ulogic;
        T3        : in  std_ulogic;
        T4        : in  std_ulogic;
        TBYTEIN   : in  std_ulogic;
        TCE       : in  std_ulogic
    );
end entity OSERDESE2;

architecture sim of OSERDESE2 is
    signal latched     : std_ulogic_vector(0 to 7) := (others => '0');
    signal shift_reg   : std_ulogic_vector(0 to 9) := (others => '0');
    signal bit_idx     : integer range 0 to 9 := 0;
    signal just_loaded : std_ulogic := '0';
begin
    gen_slave: if SERDES_MODE = "SLAVE" generate
    begin
        process(CLKDIV, RST)
        begin
            if RST = '1' then
                SHIFTOUT1 <= '0';
                SHIFTOUT2 <= '0';
            elsif rising_edge(CLKDIV) then
                if OCE = '1' then
                    SHIFTOUT1 <= D3;
                    SHIFTOUT2 <= D4;
                end if;
            end if;
        end process;
        OQ <= '0';
    end generate;

    gen_master: if SERDES_MODE /= "SLAVE" generate
    begin
        process(CLK, CLKDIV, RST)
        begin
            if RST = '1' then
                latched     <= (others => '0');
                shift_reg   <= (others => '0');
                bit_idx     <= 0;
                just_loaded <= '0';
                OQ          <= '0';
            else
                if rising_edge(CLKDIV) and OCE = '1' then
                    shift_reg(0 to 7) <= (D1, D2, D3, D4, D5, D6, D7, D8);
                    OQ <= D1;
                    bit_idx <= 1;
                    just_loaded <= '1';
                elsif rising_edge(CLK) then
                    if just_loaded = '1' then
                        just_loaded <= '0';
                    else
                        OQ <= shift_reg(bit_idx);
                        if bit_idx < 9 then
                            bit_idx <= bit_idx + 1;
                        end if;
                    end if;
                elsif falling_edge(CLK) then
                    just_loaded <= '0';
                    if bit_idx = 1 then
                        shift_reg(8) <= SHIFTIN1;
                        shift_reg(9) <= SHIFTIN2;
                    end if;
                    OQ <= shift_reg(bit_idx);
                    if bit_idx < 9 then
                        bit_idx <= bit_idx + 1;
                    end if;
                end if;
            end if;
        end process;
    end generate;
end architecture sim;
