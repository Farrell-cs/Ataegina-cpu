
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PC_Unit is
    port(
        clk : in std_logic;
        opcode : in std_logic_vector(1 downto 0);
        PC_In : in std_logic_vector(31 downto 0);
        PC_Out : out std_logic_vector(31 downto 0)
        );
end entity PC_Unit;

-- Operation Codes:
-- 00: Halt
-- 01: Incrementing
-- 10: Assign/Forwarding
-- 11: Reset

architecture Behavioral of PC_Unit is
signal Current_PC : std_logic_vector(31 downto 0) := X"0000";

begin 
  process (clk)
  begin
    if rising_edge(clk) then
      case opcode is
        when "00" => 	-- NOP, keep PC the same/halt
        when "01" => 	-- increment
          Current_pc <= std_logic_vector(unsigned(Current_pc) + 1);
        when "10" => 	-- set from external input
          current_pc <= PC_In;
        when "11" => 	-- Reset
          Current_pc <= X"0000";
        when others =>
      end case;
    end if;
  end process;

  PC_Out <= Current_pc;


end Behavioral;
