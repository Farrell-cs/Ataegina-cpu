library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package VCOMPONENTS is

    component BUFG
        port (
            O : out std_ulogic;
            I : in  std_ulogic
        );
    end component;

    component BUFIO
        port (
            O : out std_ulogic;
            I : in  std_ulogic
        );
    end component;

    component BUFR
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
    end component;

    component OBUFDS
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
    end component;

    component PLLE2_BASE
        generic (
            BANDWIDTH          : string  := "OPTIMIZED";
            CLKFBOUT_MULT      : integer := 5;
            CLKFBOUT_PHASE     : real    := 0.000;
            CLKIN1_PERIOD      : real    := 0.000;
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
            CLKFBOUT : out std_ulogic;
            CLKOUT0  : out std_ulogic;
            CLKOUT1  : out std_ulogic;
            CLKOUT2  : out std_ulogic;
            CLKOUT3  : out std_ulogic;
            CLKOUT4  : out std_ulogic;
            CLKOUT5  : out std_ulogic;
            LOCKED   : out std_ulogic;
            CLKFBIN  : in  std_ulogic;
            CLKIN1   : in  std_ulogic;
            PWRDWN   : in  std_ulogic;
            RST      : in  std_ulogic
        );
    end component;

    component PLLE2_ADV
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
            CLKFBOUT : out std_ulogic;
            CLKOUT0  : out std_ulogic;
            CLKOUT1  : out std_ulogic;
            CLKOUT2  : out std_ulogic;
            CLKOUT3  : out std_ulogic;
            CLKOUT4  : out std_ulogic;
            CLKOUT5  : out std_ulogic;
            DO       : out std_logic_vector(15 downto 0);
            DRDY     : out std_ulogic;
            LOCKED   : out std_ulogic;
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
    end component;

    component MMCME2_ADV
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
            CLKFBOUT     : out std_ulogic;
            CLKFBOUTB    : out std_ulogic;
            CLKFBSTOPPED : out std_ulogic;
            CLKINSTOPPED : out std_ulogic;
            CLKOUT0      : out std_ulogic;
            CLKOUT0B     : out std_ulogic;
            CLKOUT1      : out std_ulogic;
            CLKOUT1B     : out std_ulogic;
            CLKOUT2      : out std_ulogic;
            CLKOUT2B     : out std_ulogic;
            CLKOUT3      : out std_ulogic;
            CLKOUT3B     : out std_ulogic;
            CLKOUT4      : out std_ulogic;
            CLKOUT5      : out std_ulogic;
            CLKOUT6      : out std_ulogic;
            DO           : out std_logic_vector(15 downto 0);
            DRDY         : out std_ulogic;
            LOCKED       : out std_ulogic;
            PSDONE       : out std_ulogic;
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
    end component;

    component OSERDESE2
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
            OFB       : out std_ulogic;
            OQ        : out std_ulogic;
            SHIFTOUT1 : out std_ulogic;
            SHIFTOUT2 : out std_ulogic;
            TBYTEOUT  : out std_ulogic;
            TFB       : out std_ulogic;
            TQ        : out std_ulogic;
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
    end component;

end package VCOMPONENTS;
