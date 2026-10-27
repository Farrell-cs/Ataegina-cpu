library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.Constants.ALL;

entity Decoder is
    port(
        instruction : in  std_logic_vector(WORD_WIDTH - 1 downto 0);
        opcode      : out std_logic_vector(6 downto 0);
        rd          : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        funct3      : out std_logic_vector(2 downto 0);
        rs1         : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        rs2         : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
        funct7      : out std_logic_vector(6 downto 0);
        imm_out     : out std_logic_vector(WORD_WIDTH - 1 downto 0);
        alu_op      : out std_logic_vector(3 downto 0);
        alu_src_imm : out std_logic;
        reg_write   : out std_logic;
        mem_read    : out std_logic;
        mem_write   : out std_logic;
        branch      : out std_logic;
        jump        : out std_logic
    );
end entity Decoder;

architecture Behavioral of Decoder is
    type formats is (R, I, S, U, B, J);
    signal op_internal     : std_logic_vector(6 downto 0);
    signal funct3_internal : std_logic_vector(2 downto 0);
    signal funct7_internal : std_logic_vector(6 downto 0);
begin

    op_internal     <= instruction(6 downto 0);
    rd              <= instruction(11 downto 7);
    funct3_internal <= instruction(14 downto 12);
    rs1             <= instruction(19 downto 15);
    rs2             <= instruction(24 downto 20);
    funct7_internal <= instruction(31 downto 25);

    opcode <= op_internal;
    funct3 <= funct3_internal;
    funct7 <= funct7_internal;

    process(all)
        variable fmt : formats;
    begin
        -- Identify instruction format
        case op_internal is
            when OP_REG =>
                fmt := R;
            when OP_IMM | OP_LOAD | OP_JALR =>
                fmt := I;
            when OP_STORE =>
                fmt := S;
            when OP_LUI | OP_AUIPC =>
                fmt := U;
            when OP_BRANCH =>
                fmt := B;
            when OP_JAL =>
                fmt := J;
            when others =>
                fmt := R;
        end case;

        -- Immediate generation
        case fmt is
            when I =>
                imm_out <= std_logic_vector(resize(signed(instruction(31 downto 20)), 32));
            when S =>
                imm_out <= std_logic_vector(resize(signed(instruction(31 downto 25) & instruction(11 downto 7)), 32));
            when B =>
                imm_out <= std_logic_vector(resize(signed(instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0'), 32));
            when U =>
                imm_out <= instruction(31 downto 12) & X"000";
            when J =>
                imm_out <= std_logic_vector(resize(signed(instruction(31) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21) & '0'), 32));
            when others =>
                imm_out <= (others => '0');
        end case;

        -- Default control signals
        alu_op      <= ALU_ADD;
        alu_src_imm <= '0';
        reg_write   <= '0';
        mem_read    <= '0';
        mem_write   <= '0';
        branch      <= '0';
        jump        <= '0';

        -- Drive control signals based on opcode
        case op_internal is
            when OP_REG =>
                reg_write   <= '1';
                alu_src_imm <= '0';
                case funct3_internal is
                    when F3_ADD_SUB =>
                        if funct7_internal = F7_ALT then
                            alu_op <= ALU_SUB;
                        else
                            alu_op <= ALU_ADD;
                        end if;
                    when F3_SLL     => alu_op <= ALU_SLL;
                    when F3_SLT     => alu_op <= ALU_SLT;
                    when F3_SLTU    => alu_op <= ALU_SLTU;
                    when F3_XOR     => alu_op <= ALU_XOR;
                    when F3_SRL_SRA =>
                        if funct7_internal = F7_ALT then
                            alu_op <= ALU_SRA;
                        else
                            alu_op <= ALU_SRL;
                        end if;
                    when F3_OR      => alu_op <= ALU_OR;
                    when F3_AND     => alu_op <= ALU_AND;
                    when others     => alu_op <= ALU_ADD;
                end case;

            when OP_IMM =>
                reg_write   <= '1';
                alu_src_imm <= '1';
                case funct3_internal is
                    when F3_ADD_SUB => alu_op <= ALU_ADD;
                    when F3_SLL     => alu_op <= ALU_SLL;
                    when F3_SLT     => alu_op <= ALU_SLT;
                    when F3_SLTU    => alu_op <= ALU_SLTU;
                    when F3_XOR     => alu_op <= ALU_XOR;
                    when F3_SRL_SRA =>
                        if funct7_internal = F7_ALT then
                            alu_op <= ALU_SRA;
                        else
                            alu_op <= ALU_SRL;
                        end if;
                    when F3_OR      => alu_op <= ALU_OR;
                    when F3_AND     => alu_op <= ALU_AND;
                    when others     => alu_op <= ALU_ADD;
                end case;

            when OP_LOAD =>
                reg_write   <= '1';
                mem_read    <= '1';
                alu_src_imm <= '1';
                alu_op      <= ALU_ADD;

            when OP_STORE =>
                mem_write   <= '1';
                alu_src_imm <= '1';
                alu_op      <= ALU_ADD;

            when OP_BRANCH =>
                branch      <= '1';
                alu_src_imm <= '0';
                alu_op      <= ALU_SUB;

            when OP_LUI =>
                reg_write   <= '1';
                alu_src_imm <= '1';
                alu_op      <= ALU_PASS_B;

            when OP_AUIPC =>
                reg_write   <= '1';
                alu_src_imm <= '1';
                alu_op      <= ALU_ADD;

            when OP_JAL =>
                reg_write <= '1';
                jump      <= '1';

            when OP_JALR =>
                reg_write   <= '1';
                jump        <= '1';
                alu_src_imm <= '1';
                alu_op      <= ALU_ADD;

            when others =>
                null;
        end case;
        
        -- I have ZERO clue if this is the proper implementation lmfao, at least it pasts the TB

    end process;

end Behavioral;
