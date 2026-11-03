library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity PC is
    port(
        clk    : in  std_logic;
        rst    : in  std_logic;
        pc_in  : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        pc_out : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity PC;

architecture Behavioral of PC is
    attribute X_INTERFACE_INFO      : string;
    attribute X_INTERFACE_PARAMETER : string;
    attribute X_INTERFACE_INFO of rst      : signal is "xilinx.com:signal:reset:1.0 rst RST";
    attribute X_INTERFACE_PARAMETER of rst : signal is "POLARITY ACTIVE_HIGH";

    signal pc_reg : std_logic_vector(WORD_WIDTH - 1 downto 0) := X"00000000";
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pc_reg <= X"00000000";
            else
                pc_reg <= pc_in(31 downto 1) & '0';
            end if;
        end if;
    end process;

    pc_out <= pc_reg;

end Behavioral;
