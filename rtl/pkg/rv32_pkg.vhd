library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv32_pkg is
  constant XLEN : positive := 32;
  subtype word_t is std_logic_vector(XLEN - 1 downto 0);
  subtype addr_t is std_logic_vector(XLEN - 1 downto 0);
  subtype reg_addr_t is std_logic_vector(4 downto 0);

  -- Opcode field (instr[6:0])
  constant OP_LUI    : std_logic_vector(6 downto 0) := "0110111";
  constant OP_AUIPC  : std_logic_vector(6 downto 0) := "0010111";
  constant OP_JAL    : std_logic_vector(6 downto 0) := "1101111";
  constant OP_JALR   : std_logic_vector(6 downto 0) := "1100111";
  constant OP_BRANCH : std_logic_vector(6 downto 0) := "1100011";
  constant OP_LOAD   : std_logic_vector(6 downto 0) := "0000011";
  constant OP_STORE  : std_logic_vector(6 downto 0) := "0100011";
  constant OP_OPIMM  : std_logic_vector(6 downto 0) := "0010011";
  constant OP_OP     : std_logic_vector(6 downto 0) := "0110011";
  constant OP_MISC   : std_logic_vector(6 downto 0) := "0001111";
  constant OP_SYSTEM : std_logic_vector(6 downto 0) := "1110011";

  -- ALU operation select
  type alu_op_t is (
    ALU_ADD, ALU_SUB,
    ALU_AND, ALU_OR, ALU_XOR,
    ALU_SLL, ALU_SRL, ALU_SRA,
    ALU_SLT, ALU_SLTU,
    ALU_COPY_A, ALU_COPY_B
  );

  type branch_op_t is (
    BR_EQ, BR_NE, BR_LT, BR_GE, BR_LTU, BR_GEU, BR_NONE
  );

  type mem_size_t is (MEM_B, MEM_H, MEM_W);

  type ctrl_t is record
    reg_write  : std_logic;
    mem_read   : std_logic;
    mem_write  : std_logic;
    mem_size   : mem_size_t;
    mem_unsigned : std_logic;
    alu_op     : alu_op_t;
    alu_src_b  : std_logic; -- 0=rs2, 1=imm
    branch_op  : branch_op_t;
    jump       : std_logic; -- JAL/JALR
    jalr       : std_logic;
    lui        : std_logic;
    auipc      : std_logic;
    halt       : std_logic; -- ECALL/EBREAK
    illegal    : std_logic;
    wb_pc4     : std_logic; -- write PC+4 (JAL/JALR)
  end record;

  constant CTRL_NOP : ctrl_t := (
    reg_write    => '0',
    mem_read     => '0',
    mem_write    => '0',
    mem_size     => MEM_W,
    mem_unsigned => '0',
    alu_op       => ALU_ADD,
    alu_src_b    => '0',
    branch_op    => BR_NONE,
    jump         => '0',
    jalr         => '0',
    lui          => '0',
    auipc        => '0',
    halt         => '0',
    illegal      => '0',
    wb_pc4       => '0'
  );

  -- Memory map (v1)
  constant IMEM_BASE : unsigned(31 downto 0) := x"00000000";
  constant IMEM_SIZE : integer := 8 * 1024;
  constant DMEM_BASE : unsigned(31 downto 0) := x"10000000";
  constant DMEM_SIZE : integer := 8 * 1024;
  constant MMIO_BASE : unsigned(31 downto 0) := x"20000000";

  function to_word(n : integer) return word_t;
end package;

package body rv32_pkg is
  function to_word(n : integer) return word_t is
  begin
    return std_logic_vector(to_signed(n, XLEN));
  end function;
end package body;
