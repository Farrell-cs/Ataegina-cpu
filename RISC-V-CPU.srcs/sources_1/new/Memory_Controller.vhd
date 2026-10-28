library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Memory_Controller is
    generic(
        MEM_WORDS : integer := 1024
    );
    port(
        clk        : in  std_logic;
        inst_addr  : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        inst_out   : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        mem_read   : in  std_logic;
        mem_write  : in  std_logic;
        funct3     : in  std_logic_vector(2 downto 0);
        data_addr  : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        data_in    : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        data_out   : out std_logic_vector(WORD_WIDTH - 1 downto 0)
    );
end entity Memory_Controller;

architecture Behavioral of Memory_Controller is
    type RAM_Array is array (0 to MEM_WORDS - 1) of std_logic_vector(WORD_WIDTH - 1 downto 0);
    signal RAM : RAM_Array := (others => (others => '0'));
begin
    
    -- Port A: Instruction Fetch (Word-aligned)
    inst_out <= RAM(to_integer(unsigned(inst_addr(11 downto 2))))
                when to_integer(unsigned(inst_addr(11 downto 2))) < MEM_WORDS
                else (others => '0');
    
    -- Port B: Synchronous Data Write (Stores: SB, SH, SW)
    process(clk)
        variable word_idx    : integer;
        variable byte_offset : integer range 0 to 3;
        variable temp_word   : std_logic_vector(31 downto 0);
    begin
        if rising_edge(clk) then
            word_idx    := to_integer(unsigned(data_addr(11 downto 2)));
            byte_offset := to_integer(unsigned(data_addr(1 downto 0)));

            if (mem_write = '1' and word_idx < MEM_WORDS) then
                temp_word := RAM(word_idx);
                case funct3 is
                    when F3_BYTE =>
                        case byte_offset is
                            when 0 => temp_word(7 downto 0)   := data_in(7 downto 0);
                            when 1 => temp_word(15 downto 8)  := data_in(7 downto 0);
                            when 2 => temp_word(23 downto 16) := data_in(7 downto 0);
                            when 3 => temp_word(31 downto 24) := data_in(7 downto 0);
                        end case;
                    when F3_HALF =>
                        if byte_offset < 2 then
                            temp_word(15 downto 0) := data_in(15 downto 0);
                        else
                            temp_word(31 downto 16) := data_in(15 downto 0);
                        end if;
                    when others =>
                        temp_word := data_in;
                end case;
                RAM(word_idx) <= temp_word;
            end if;
        end if;
    end process;

    -- Port B: Combinational Data Read (Loads: LB, LH, LW, LBU, LHU)
    process(all)
        variable word_idx       : integer;
        variable byte_offset    : integer range 0 to 3;
        variable fetched_word   : std_logic_vector(31 downto 0);
        variable target_byte    : std_logic_vector(7 downto 0);
        variable target_half    : std_logic_vector(15 downto 0);
    begin
        data_out <= (others => '0');

        if mem_read = '1' then
            word_idx    := to_integer(unsigned(data_addr(11 downto 2)));
            byte_offset := to_integer(unsigned(data_addr(1 downto 0)));

            if word_idx < MEM_WORDS then
                fetched_word := RAM(word_idx);
            else
                fetched_word := (others => '0');
            end if;

            case byte_offset is
                when 0 => target_byte := fetched_word(7 downto 0);
                when 1 => target_byte := fetched_word(15 downto 8);
                when 2 => target_byte := fetched_word(23 downto 16);
                when 3 => target_byte := fetched_word(31 downto 24);
            end case;

            if byte_offset < 2 then
                target_half := fetched_word(15 downto 0);
            else
                target_half := fetched_word(31 downto 16);
            end if;

            case funct3 is
                when F3_BYTE =>
                    data_out <= std_logic_vector(resize(signed(target_byte), 32));
                when F3_BYTE_U =>
                    data_out <= std_logic_vector(resize(unsigned(target_byte), 32));
                when F3_HALF =>
                    data_out <= std_logic_vector(resize(signed(target_half), 32));
                when F3_HALF_U =>
                    data_out <= std_logic_vector(resize(unsigned(target_half), 32));
                when others =>
                    data_out <= fetched_word;
            end case;
        end if;
    end process;

end Behavioral;
