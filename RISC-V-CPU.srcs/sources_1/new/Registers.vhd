library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Registers is
    port(
        clk         : in  std_logic;
        rst         : in  std_logic;
        reg_write   : in  std_logic;
        read_reg_1  : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        read_reg_2  : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        write_reg   : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        write_data  : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        read_data_1 : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        read_data_2 : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Registers;

architecture Behavioral of Registers is
    attribute X_INTERFACE_INFO      : string;
    attribute X_INTERFACE_PARAMETER : string;
    attribute X_INTERFACE_INFO of rst      : signal is "xilinx.com:signal:reset:1.0 rst RST";
    attribute X_INTERFACE_PARAMETER of rst : signal is "POLARITY ACTIVE_HIGH";

    type reg_array is array (0 to NUM_REGISTERS - 1) of std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal reg_file : reg_array := (others => (others => '0'));
begin

    read_data_1 <= (others => '0') when (read_reg_1 = "00000") else
                   reg_file(to_integer(unsigned(read_reg_1)));

    read_data_2 <= (others => '0') when (read_reg_2 = "00000") else
                   reg_file(to_integer(unsigned(read_reg_2)));

    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '0' and reg_write = '1' and write_reg /= "00000") then
                reg_file(to_integer(unsigned(write_reg))) <= write_data;
            end if;
        end if;
    end process;

end Behavioral;
