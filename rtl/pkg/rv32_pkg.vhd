library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv32_pkg is
  constant XLEN : positive := 32;
  subtype word_t is std_logic_vector(XLEN - 1 downto 0);
  subtype addr_t is std_logic_vector(XLEN - 1 downto 0);
  subtype reg_addr_t is std_logic_vector(4 downto 0);

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

  type alu_op_t is (
    ALU_ADD, ALU_SUB,
    ALU_AND, ALU_OR, ALU_XOR,
    ALU_SLL, ALU_SRL, ALU_SRA,
    ALU_SLT, ALU_SLTU,
    ALU_COPY_A, ALU_COPY_B,
    ALU_MUL, ALU_MULH, ALU_MULHSU, ALU_MULHU,
    ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU
  );

  type branch_op_t is (
    BR_EQ, BR_NE, BR_LT, BR_GE, BR_LTU, BR_GEU, BR_NONE
  );

  type mem_size_t is (MEM_B, MEM_H, MEM_W);

  -- Zicsr: CSRRW/CSRRS/CSRRC + immediate forms
  type csr_op_t is (
    CSR_NONE, CSR_RW, CSR_RS, CSR_RC, CSR_RWI, CSR_RSI, CSR_RCI
  );

  type ctrl_t is record
    reg_write    : std_logic;
    mem_read     : std_logic;
    mem_write    : std_logic;
    mem_size     : mem_size_t;
    mem_unsigned : std_logic;
    alu_op       : alu_op_t;
    alu_src_b    : std_logic; -- 0=rs2, 1=imm
    branch_op    : branch_op_t;
    jump         : std_logic;
    jalr         : std_logic;
    lui          : std_logic;
    auipc        : std_logic;
    halt         : std_logic;
    illegal      : std_logic;
    wb_pc4       : std_logic;
    use_rs1      : std_logic;
    use_rs2      : std_logic;
    csr_op       : csr_op_t;
    is_mret      : std_logic;
    is_ecall     : std_logic;
    is_ebreak    : std_logic;
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
    wb_pc4       => '0',
    use_rs1      => '0',
    use_rs2      => '0',
    csr_op       => CSR_NONE,
    is_mret      => '0',
    is_ecall     => '0',
    is_ebreak    => '0'
  );

  -- Machine CSR addresses (subset)
  constant CSR_MSTATUS  : std_logic_vector(11 downto 0) := x"300";
  constant CSR_MISA     : std_logic_vector(11 downto 0) := x"301";
  constant CSR_MIE      : std_logic_vector(11 downto 0) := x"304";
  constant CSR_MTVEC    : std_logic_vector(11 downto 0) := x"305";
  constant CSR_MSCRATCH : std_logic_vector(11 downto 0) := x"340";
  constant CSR_MEPC     : std_logic_vector(11 downto 0) := x"341";
  constant CSR_MCAUSE   : std_logic_vector(11 downto 0) := x"342";
  constant CSR_MTVAL    : std_logic_vector(11 downto 0) := x"343";
  constant CSR_MIP      : std_logic_vector(11 downto 0) := x"344";
  constant CSR_MHARTID  : std_logic_vector(11 downto 0) := x"F14";

  -- Exception causes
  constant CAUSE_MISALIGNED_FETCH : word_t := x"00000000";
  constant CAUSE_ILLEGAL_INSTR    : word_t := x"00000002";
  constant CAUSE_BREAKPOINT       : word_t := x"00000003";
  constant CAUSE_MISALIGNED_LOAD  : word_t := x"00000004";
  constant CAUSE_MISALIGNED_STORE : word_t := x"00000006";
  constant CAUSE_ECALL_M          : word_t := x"0000000B";

  constant IMEM_BASE : unsigned(31 downto 0) := x"00000000";
  constant IMEM_SIZE : integer := 8 * 1024;
  constant DMEM_BASE : unsigned(31 downto 0) := x"10000000";
  constant DMEM_SIZE : integer := 8 * 1024;
  constant MMIO_BASE : unsigned(31 downto 0) := x"20000000";

  -- MMIO offsets from MMIO_BASE
  constant MMIO_LED_OFF    : unsigned(31 downto 0) := x"00000000";
  constant MMIO_UART_OFF   : unsigned(31 downto 0) := x"00000004";
  constant MMIO_UARTST_OFF : unsigned(31 downto 0) := x"00000008";
  constant MMIO_STATUS_OFF : unsigned(31 downto 0) := x"0000000C";

  function to_word(n : integer) return word_t;
  function imm_i(instr : word_t) return word_t;
  function imm_s(instr : word_t) return word_t;
  function imm_b(instr : word_t) return word_t;
  function imm_u(instr : word_t) return word_t;
  function imm_j(instr : word_t) return word_t;
end package;

package body rv32_pkg is
  function to_word(n : integer) return word_t is
  begin
    return std_logic_vector(to_signed(n, XLEN));
  end function;

  function imm_i(instr : word_t) return word_t is
  begin
    return std_logic_vector(resize(signed(instr(31 downto 20)), XLEN));
  end function;

  function imm_s(instr : word_t) return word_t is
    variable i : std_logic_vector(11 downto 0);
  begin
    i := instr(31 downto 25) & instr(11 downto 7);
    return std_logic_vector(resize(signed(i), XLEN));
  end function;

  function imm_b(instr : word_t) return word_t is
    variable i : std_logic_vector(12 downto 0);
  begin
    i := instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & '0';
    return std_logic_vector(resize(signed(i), XLEN));
  end function;

  function imm_u(instr : word_t) return word_t is
  begin
    return instr(31 downto 12) & x"000";
  end function;

  function imm_j(instr : word_t) return word_t is
    variable i : std_logic_vector(20 downto 0);
  begin
    i := instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21) & '0';
    return std_logic_vector(resize(signed(i), XLEN));
  end function;
end package body;
