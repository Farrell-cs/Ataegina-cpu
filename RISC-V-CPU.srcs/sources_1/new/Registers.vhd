    library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use ieee.numeric_std.all ; 
    use ieee.std_logic_unsigned.all;
    use work.Constants.ALL;
    
    entity Registers is
        port ( 
            clk       : in  std_logic;
            reg_write : in  std_logic;
            rd_addr   : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
            din       : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
            rs1_addr  : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
            rs2_addr  : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
            out_a     : out std_logic_vector(WORD_WIDTH - 1 downto 0);
            out_b     : out std_logic_vector(WORD_WIDTH - 1 downto 0)
        );
    end entity Registers;
    
    architecture Behavioral of Registers is
        type reg_array is array (0 to NUM_REGISTERS - 1) of std_logic_vector(WORD_WIDTH - 1 downto 0);
        signal reg_file : reg_array := (others => (others => '0'));
    
    begin
        out_a <= (others => '0') when (to_integer(unsigned(rs1_addr)) = 0) else 
                 reg_file(to_integer(unsigned(rs1_addr)));
                 
        out_b <= (others => '0') when (to_integer(unsigned(rs2_addr)) = 0) else 
                 reg_file(to_integer(unsigned(rs2_addr)));
    
        
        
        process(clk)
        begin
        if rising_edge (clk) then
            if (reg_write = '1' and rd_addr /= "00000") then
                reg_file(to_integer(unsigned(rd_addr))) <= din;
            end if;
        end if;
        end process;
    
    end Behavioral;
