library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Constants.ALL;

entity ALU_Control is
    port(
        alu_op    : in  std_logic_vector(2 downto 0);
        funct3    : in  std_logic_vector(2 downto 0);
        funct7_b5 : in  std_logic;
        alu_ctrl  : out std_logic_vector(3 downto 0)
    );
end entity ALU_Control;

architecture Behavioral of ALU_Control is
begin

    process(alu_op, funct3, funct7_b5)
    begin
        case alu_op is
            when ALUOP_LOAD_STORE =>
                alu_ctrl <= ALU_ADD;

            when ALUOP_BRANCH =>
                case funct3 is
                    when F3_BEQ | F3_BNE   => alu_ctrl <= ALU_SUB;
                    when F3_BLT | F3_BGE   => alu_ctrl <= ALU_SLT;
                    when F3_BLTU | F3_BGEU => alu_ctrl <= ALU_SLTU;
                    when others            => alu_ctrl <= ALU_SUB;
                end case;

            when ALUOP_R_TYPE =>
                case funct3 is
                    when F3_ADD_SUB =>
                        if funct7_b5 = '1' then
                            alu_ctrl <= ALU_SUB;
                        else
                            alu_ctrl <= ALU_ADD;
                        end if;
                    when F3_SLL     => alu_ctrl <= ALU_SLL;
                    when F3_SLT     => alu_ctrl <= ALU_SLT;
                    when F3_SLTU    => alu_ctrl <= ALU_SLTU;
                    when F3_XOR     => alu_ctrl <= ALU_XOR;
                    when F3_SRL_SRA =>
                        if funct7_b5 = '1' then
                            alu_ctrl <= ALU_SRA;
                        else
                            alu_ctrl <= ALU_SRL;
                        end if;
                    when F3_OR      => alu_ctrl <= ALU_OR;
                    when F3_AND     => alu_ctrl <= ALU_AND;
                    when others     => alu_ctrl <= ALU_ADD;
                end case;

            when ALUOP_I_TYPE =>
                case funct3 is
                    when F3_ADD_SUB => alu_ctrl <= ALU_ADD;
                    when F3_SLL     => alu_ctrl <= ALU_SLL;
                    when F3_SLT     => alu_ctrl <= ALU_SLT;
                    when F3_SLTU    => alu_ctrl <= ALU_SLTU;
                    when F3_XOR     => alu_ctrl <= ALU_XOR;
                    when F3_SRL_SRA =>
                        if funct7_b5 = '1' then
                            alu_ctrl <= ALU_SRA;
                        else
                            alu_ctrl <= ALU_SRL;
                        end if;
                    when F3_OR      => alu_ctrl <= ALU_OR;
                    when F3_AND     => alu_ctrl <= ALU_AND;
                    when others     => alu_ctrl <= ALU_ADD;
                end case;

            when ALUOP_LUI =>
                alu_ctrl <= ALU_PASS_B;

            when others =>
                alu_ctrl <= ALU_ADD;
        end case;
    end process;

end Behavioral;
