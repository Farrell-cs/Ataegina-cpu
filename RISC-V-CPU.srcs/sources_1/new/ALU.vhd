library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    port(
        A, B : in std_logic_vector(31 downto 0);
        opcode : in std_logic_vector(3 downto 0);
        signed_f : in std_logic_vector(31 downto 0);
        ALU_Out : out std_logic_vector(31 downto 0)
        );
end entity ALU ;

-- 0000: Addition
-- 0001: Multiplication
-- 0010: Comparison gt
-- 0011: Comparison eq 
-- 0100: Comparison lt
-- 0101: Bitwise AND
-- 0110: Bitwise OR
-- 0111: Bitwise XOR
-- 1000: Bitwise NOT (outputs NOT a)
-- 1001: Logical shift left
-- 1010: Logical shift right
-- 1011: Arithmetic shift right


architecture Behavioral of ALU is

signal ALU_Result : std_logic_vector (31 downto 0);
signal tmp: std_logic_vector (32 downto 0);

begin
   process(A,B,opcode)
 begin
  case(opcode) is
  when "0000" => -- Addition
   ALU_Result <= std_logic_vector(unsigned(A) + unsigned(B)); 
  when "0001" => -- Multiplication
   ALU_Result <= std_logic_vector(to_unsigned((to_integer(unsigned(A)) * to_integer(unsigned(B))),8)) ;
  when "0010" => -- Comparison gt
  if(A>B) then
    ALU_Result <= (0 => '1', others => '0');
   else
    ALU_Result <= (others => '0');
   end if;
  when "0011" => -- Comparison eq
   if(A=B) then
    ALU_Result <= (0 => '1', others => '0');
   else
    ALU_Result <= (others => '0');
   end if;     
  when "0100" => -- Comparison gt
  if(A<B) then
    ALU_Result <= (0 => '1', others => '0');
   else
    ALU_Result <= (others => '0');
   end if;     
  when "0101" => -- Bitwise AND
   ALU_Result <= A and B;
  when "0110" => -- Bitwise OR
   ALU_Result <= A or B;
  when "0111" => --Bitwise XOR
   ALU_Result <= A xor B;
  when "1000" =>
   ALU_Result <= not A;
  when "1001" => -- Logical shift left
   ALU_Result <= std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(B(4 downto 0)))));
  when "1010" => -- Logical shift right
   ALU_Result <= std_logic_vector(shift_right(unsigned(A), to_integer(unsigned(B(4 downto 0)))));
  when "1011" => -- Arithmatic Shift Right
   ALU_Result <= std_logic_vector(shift_right(signed(A), to_integer(unsigned(B(4 downto 0)))));
  when others => 
   ALU_Result <= (others => '0');
  end case;
 end process;
 
 ALU_Out <= ALU_Result;
 
 end Behavioral;