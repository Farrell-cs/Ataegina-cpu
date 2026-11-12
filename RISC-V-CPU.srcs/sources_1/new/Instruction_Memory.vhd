library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.Constants.ALL;

entity Instruction_Memory is
    generic(
        IMEM_WORDS : integer := 1024
    );
    port(
        clk           : in  std_logic := '0';
        write_en      : in  std_logic := '0';
        write_address : in  std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
        write_data    : in  std_logic_vector(WORD_WIDTH - 1 downto 0) := (others => '0');
        read_address  : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        instruction   : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Instruction_Memory;

architecture Behavioral of Instruction_Memory is
    constant ADDR_BITS : natural := clog2(IMEM_WORDS);
    type rom_array is array (0 to IMEM_WORDS - 1) of std_logic_vector(WORD_WIDTH - 1 downto 0);

    impure function init_rom(file_name : string) return rom_array is
        file mem_file        : text;
        variable file_status : file_open_status;
        variable l_buf       : line;
        variable temp_rom    : rom_array := (others => X"00000013");
        variable h_val       : std_logic_vector(31 downto 0);
    begin
        file_open(file_status, mem_file, file_name, read_mode);
        assert file_status = open_ok
            report "CRITICAL: Instruction_Memory could not open " & file_name severity failure;
        if file_status = open_ok then
            for i in 0 to IMEM_WORDS - 1 loop
                exit when endfile(mem_file);
                readline(mem_file, l_buf);
                hread(l_buf, h_val);
                temp_rom(i) := h_val;
            end loop;
            file_close(mem_file);
        end if;
        return temp_rom;
    end function;

    signal rom : rom_array := init_rom("imem.mem");
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if write_en = '1' then
                rom(to_integer(unsigned(write_address(ADDR_BITS + 1 downto 2)))) <= write_data;
            end if;
        end if;
    end process;

    instruction <= rom(to_integer(unsigned(read_address(ADDR_BITS + 1 downto 2))));

end Behavioral;
