library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Instruction_Memory is
    generic(
        IMEM_WORDS : integer := 1024
    );
    port(
        read_address : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        instruction  : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Instruction_Memory;

architecture Behavioral of Instruction_Memory is
    constant ADDR_BITS : natural := clog2(IMEM_WORDS);
    type rom_array is array (0 to IMEM_WORDS - 1) of std_logic_vector(WORD_WIDTH - 1 downto 0);

    signal rom : rom_array := (
        0 => X"00A00093", -- 0x00: addi x1, x0, 10
        1 => X"01400113", -- 0x04: addi x2, x0, 20
        2 => X"002081B3", -- 0x08: add  x3, x1, x2 (30)
        3 => X"00302823", -- 0x0C: sw   x3, 16(x0)
        4 => X"01002203", -- 0x10: lw   x4, 16(x0)
        5 => X"00418463", -- 0x14: beq  x3, x4, +8 (jumps to 0x1C)
        6 => X"06300293", -- 0x18: addi x5, x0, 99 (skipped)
        7 => X"02A00293", -- 0x1C: addi x5, x0, 42
        others => X"00000013" -- NOP (addi x0, x0, 0)
    );
begin

    instruction <= rom(to_integer(unsigned(read_address(ADDR_BITS + 1 downto 2))));

end Behavioral;
