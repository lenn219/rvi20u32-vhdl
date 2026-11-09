library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

entity decode is
  port (
    instr : in  word_t;
    ctrl  : out ctrl_t;
    imm   : out word_t;
    rs1   : out reg_addr_t;
    rs2   : out reg_addr_t;
    rd    : out reg_addr_t
  );
end entity;

architecture rtl of decode is
  signal opcode : std_logic_vector(6 downto 0);
  signal funct3 : std_logic_vector(2 downto 0);
  signal funct7 : std_logic_vector(6 downto 0);
begin
  opcode <= instr(6 downto 0);
  funct3 <= instr(14 downto 12);
  funct7 <= instr(31 downto 25);
  rs1    <= instr(19 downto 15);
  rs2    <= instr(24 downto 20);
  rd     <= instr(11 downto 7);

  process (instr, opcode, funct3, funct7)
    variable c : ctrl_t;
    variable v_imm : word_t;
  begin
    c := CTRL_NOP;
    v_imm := (others => '0');

    case opcode is
      when OP_LUI =>
        c.reg_write := '1';
        c.lui       := '1';
        c.alu_op    := ALU_COPY_B;
        c.alu_src_b := '1';
        v_imm       := imm_u(instr);

      when OP_AUIPC =>
        c.reg_write := '1';
        c.auipc     := '1';
        c.alu_op    := ALU_ADD;
        c.alu_src_b := '1';
        v_imm       := imm_u(instr);

      when OP_JAL =>
        c.reg_write := '1';
        c.jump      := '1';
        c.wb_pc4    := '1';
        c.alu_op    := ALU_ADD;
        c.alu_src_b := '1';
        v_imm       := imm_j(instr);

      when OP_JALR =>
        if funct3 = "000" then
          c.reg_write := '1';
          c.jump      := '1';
          c.jalr      := '1';
          c.wb_pc4    := '1';
          c.use_rs1   := '1';
          c.alu_op    := ALU_ADD;
          c.alu_src_b := '1';
          v_imm       := imm_i(instr);
        else
          c.illegal := '1';
          c.halt    := '1';
        end if;

      when OP_BRANCH =>
        c.use_rs1   := '1';
        c.use_rs2   := '1';
        c.alu_op    := ALU_ADD;
        c.alu_src_b := '1';
        v_imm       := imm_b(instr);
        case funct3 is
          when "000" => c.branch_op := BR_EQ;
          when "001" => c.branch_op := BR_NE;
          when "100" => c.branch_op := BR_LT;
          when "101" => c.branch_op := BR_GE;
          when "110" => c.branch_op := BR_LTU;
          when "111" => c.branch_op := BR_GEU;
          when others =>
            c.illegal := '1';
            c.halt    := '1';
            c.branch_op := BR_NONE;
        end case;

      when OP_LOAD =>
        c.reg_write := '1';
        c.mem_read  := '1';
        c.use_rs1   := '1';
        c.alu_op    := ALU_ADD;
        c.alu_src_b := '1';
        v_imm       := imm_i(instr);
        case funct3 is
          when "000" => c.mem_size := MEM_B; c.mem_unsigned := '0';
          when "001" => c.mem_size := MEM_H; c.mem_unsigned := '0';
          when "010" => c.mem_size := MEM_W; c.mem_unsigned := '0';
          when "100" => c.mem_size := MEM_B; c.mem_unsigned := '1';
          when "101" => c.mem_size := MEM_H; c.mem_unsigned := '1';
          when others =>
            c.illegal := '1';
            c.halt    := '1';
        end case;

      when OP_STORE =>
        c.mem_write := '1';
        c.use_rs1   := '1';
        c.use_rs2   := '1';
        c.alu_op    := ALU_ADD;
        c.alu_src_b := '1';
        v_imm       := imm_s(instr);
        case funct3 is
          when "000" => c.mem_size := MEM_B;
          when "001" => c.mem_size := MEM_H;
          when "010" => c.mem_size := MEM_W;
          when others =>
            c.illegal := '1';
            c.halt    := '1';
        end case;

      when OP_OPIMM =>
        c.reg_write := '1';
        c.use_rs1   := '1';
        c.alu_src_b := '1';
        v_imm       := imm_i(instr);
        case funct3 is
          when "000" => c.alu_op := ALU_ADD;
          when "010" => c.alu_op := ALU_SLT;
          when "011" => c.alu_op := ALU_SLTU;
          when "100" => c.alu_op := ALU_XOR;
          when "110" => c.alu_op := ALU_OR;
          when "111" => c.alu_op := ALU_AND;
          when "001" =>
            if funct7 = "0000000" then
              c.alu_op := ALU_SLL;
            else
              c.illegal := '1';
              c.halt    := '1';
            end if;
          when "101" =>
            if funct7 = "0000000" then
              c.alu_op := ALU_SRL;
            elsif funct7 = "0100000" then
              c.alu_op := ALU_SRA;
            else
              c.illegal := '1';
              c.halt    := '1';
            end if;
          when others =>
            c.illegal := '1';
            c.halt    := '1';
        end case;

      when OP_OP =>
        c.reg_write := '1';
        c.use_rs1   := '1';
        c.use_rs2   := '1';
        c.alu_src_b := '0';
        case funct3 is
          when "000" =>
            if funct7 = "0000000" then
              c.alu_op := ALU_ADD;
            elsif funct7 = "0100000" then
              c.alu_op := ALU_SUB;
            else
              c.illegal := '1';
              c.halt    := '1';
            end if;
          when "001" =>
            if funct7 = "0000000" then c.alu_op := ALU_SLL;
            else c.illegal := '1'; c.halt := '1'; end if;
          when "010" =>
            if funct7 = "0000000" then c.alu_op := ALU_SLT;
            else c.illegal := '1'; c.halt := '1'; end if;
          when "011" =>
            if funct7 = "0000000" then c.alu_op := ALU_SLTU;
            else c.illegal := '1'; c.halt := '1'; end if;
          when "100" =>
            if funct7 = "0000000" then c.alu_op := ALU_XOR;
            else c.illegal := '1'; c.halt := '1'; end if;
          when "101" =>
            if funct7 = "0000000" then c.alu_op := ALU_SRL;
            elsif funct7 = "0100000" then c.alu_op := ALU_SRA;
            else c.illegal := '1'; c.halt := '1'; end if;
          when "110" =>
            if funct7 = "0000000" then c.alu_op := ALU_OR;
            else c.illegal := '1'; c.halt := '1'; end if;
          when "111" =>
            if funct7 = "0000000" then c.alu_op := ALU_AND;
            else c.illegal := '1'; c.halt := '1'; end if;
          when others =>
            c.illegal := '1';
            c.halt    := '1';
        end case;

      when OP_MISC =>
        -- FENCE / FENCE.I => NOP
        null;

      when OP_SYSTEM =>
        -- Only ECALL / EBREAK (funct3=0, imm=0/1). CSR ops illegal.
        if funct3 = "000" and instr(31 downto 20) = x"000" then
          c.halt := '1'; -- ECALL
        elsif funct3 = "000" and instr(31 downto 20) = x"001" then
          c.halt := '1'; -- EBREAK
        else
          c.illegal := '1';
          c.halt    := '1';
        end if;

      when others =>
        c.illegal := '1';
        c.halt    := '1';
    end case;

    ctrl <= c;
    imm  <= v_imm;
  end process;
end architecture;
