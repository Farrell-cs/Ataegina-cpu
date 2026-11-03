library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Data_Memory is
    generic(
        DMEM_WORDS : integer := 1024
    );
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        funct3     : in  std_logic_vector(2 downto 0);
        address    : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        write_data : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        read_data  : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Data_Memory;

architecture Behavioral of Data_Memory is
    attribute X_INTERFACE_INFO      : string;
    attribute X_INTERFACE_PARAMETER : string;
    attribute X_INTERFACE_INFO of rst      : signal is "xilinx.com:signal:reset:1.0 rst RST";
    attribute X_INTERFACE_PARAMETER of rst : signal is "POLARITY ACTIVE_HIGH";

    constant ADDR_BITS : natural := clog2(DMEM_WORDS);
    type ram_array is array (0 to DMEM_WORDS - 1) of std_logic_vector(WORD_WIDTH - 1 downto 0);

    signal ram : ram_array := (others => (others => '0'));
begin

    -- Synchronous Store (SB, SH, SW)
    process(clk)
        variable word_idx    : natural range 0 to DMEM_WORDS - 1;
        variable byte_offset : natural range 0 to 3;
        variable temp_word   : std_logic_vector(31 downto 0);
    begin
        if rising_edge(clk) then
            word_idx    := to_integer(unsigned(address(ADDR_BITS + 1 downto 2)));
            byte_offset := to_integer(unsigned(address(1 downto 0)));

            if rst = '0' and mem_write = '1' then
                temp_word := ram(word_idx);
                case funct3 is
                    when F3_BYTE =>
                        case byte_offset is
                            when 0 => temp_word(7 downto 0)   := write_data(7 downto 0);
                            when 1 => temp_word(15 downto 8)  := write_data(7 downto 0);
                            when 2 => temp_word(23 downto 16) := write_data(7 downto 0);
                            when 3 => temp_word(31 downto 24) := write_data(7 downto 0);
                        end case;
                    when F3_HALF =>
                        case byte_offset is
                            when 0      => temp_word(15 downto 0)  := write_data(15 downto 0);
                            when 1      => temp_word(23 downto 8)  := write_data(15 downto 0);
                            when others => temp_word(31 downto 16) := write_data(15 downto 0);
                        end case;
                    when others =>
                        temp_word := write_data;
                end case;
                ram(word_idx) <= temp_word;
            end if;
        end if;
    end process;

    -- Combinational Load (LB, LH, LW, LBU, LHU)
    process(ram, mem_read, address, funct3)
        variable word_idx     : natural range 0 to DMEM_WORDS - 1;
        variable byte_offset  : natural range 0 to 3;
        variable fetched_word : std_logic_vector(31 downto 0);
        variable target_byte  : std_logic_vector(7 downto 0);
        variable target_half  : std_logic_vector(15 downto 0);
    begin
        read_data <= (others => '0');

        if mem_read = '1' then
            word_idx     := to_integer(unsigned(address(ADDR_BITS + 1 downto 2)));
            byte_offset  := to_integer(unsigned(address(1 downto 0)));
            fetched_word := ram(word_idx);

            case byte_offset is
                when 0 => target_byte := fetched_word(7 downto 0);
                when 1 => target_byte := fetched_word(15 downto 8);
                when 2 => target_byte := fetched_word(23 downto 16);
                when 3 => target_byte := fetched_word(31 downto 24);
            end case;

            case byte_offset is
                when 0      => target_half := fetched_word(15 downto 0);
                when 1      => target_half := fetched_word(23 downto 8);
                when others => target_half := fetched_word(31 downto 16);
            end case;

            case funct3 is
                when F3_BYTE =>
                    read_data <= std_logic_vector(resize(signed(target_byte), 32));
                when F3_BYTE_U =>
                    read_data <= std_logic_vector(resize(unsigned(target_byte), 32));
                when F3_HALF =>
                    read_data <= std_logic_vector(resize(signed(target_half), 32));
                when F3_HALF_U =>
                    read_data <= std_logic_vector(resize(unsigned(target_half), 32));
                when others =>
                    read_data <= fetched_word;
            end case;
        end if;
    end process;

end Behavioral;
