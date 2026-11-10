library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Minimal M-mode CSR file for Zicsr + traps (arch-test privilege / handlers).
entity csr_file is
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    csr_op       : in  csr_op_t;
    csr_addr     : in  std_logic_vector(11 downto 0);
    rs1_or_uimm  : in  word_t;
    csr_rdata    : out word_t;
    csr_illegal  : out std_logic;
    csr_we       : in  std_logic;
    trap_take    : in  std_logic;
    trap_pc      : in  addr_t;
    trap_cause   : in  word_t;
    trap_tval    : in  word_t;
    mret_take    : in  std_logic;
    mtvec_out    : out addr_t;
    mepc_out     : out addr_t
  );
end entity;

architecture rtl of csr_file is
  signal mstatus_q  : word_t := (others => '0');
  signal mie_q      : word_t := (others => '0');
  signal mtvec_q    : word_t := (others => '0');
  signal mscratch_q : word_t := (others => '0');
  signal mepc_q     : word_t := (others => '0');
  signal mcause_q   : word_t := (others => '0');
  signal mtval_q    : word_t := (others => '0');
  signal mip_q      : word_t := (others => '0');

  -- RV32 + I + M + bit XLEN=32 (mxl=1 in [31:30])
  constant MISA_VAL : word_t := x"40001100"; -- MXL=1, extensions I+M

  signal rdata_c    : word_t;
  signal wdata_c    : word_t;
  signal addr_ok    : std_logic;
  signal do_write   : std_logic;
  signal read_only  : std_logic;
begin
  mtvec_out <= mtvec_q(31 downto 2) & "00";
  mepc_out  <= mepc_q(31 downto 1) & '0';

  process (csr_addr, mstatus_q, mie_q, mtvec_q, mscratch_q, mepc_q, mcause_q, mtval_q, mip_q)
  begin
    addr_ok   <= '1';
    read_only <= '0';
    case csr_addr is
      when CSR_MSTATUS  => rdata_c <= mstatus_q;
      when CSR_MISA     => rdata_c <= MISA_VAL; read_only <= '1';
      when CSR_MIE      => rdata_c <= mie_q;
      when CSR_MTVEC    => rdata_c <= mtvec_q;
      when CSR_MSCRATCH => rdata_c <= mscratch_q;
      when CSR_MEPC     => rdata_c <= mepc_q;
      when CSR_MCAUSE   => rdata_c <= mcause_q;
      when CSR_MTVAL    => rdata_c <= mtval_q;
      when CSR_MIP      => rdata_c <= mip_q;
      when CSR_MHARTID  => rdata_c <= (others => '0'); read_only <= '1';
      when others =>
        -- WARL stub: unimplemented CSRs read as 0 (avoids trap storms in bring-up)
        rdata_c   <= (others => '0');
        addr_ok   <= '1';
        read_only <= '1';
    end case;
  end process;

  csr_rdata   <= rdata_c;
  csr_illegal <= '0'; -- subset + stubs; decode still flags truly illegal SYSTEM encodings

  process (csr_op, rdata_c, rs1_or_uimm)
    variable mask : word_t;
  begin
    mask := rs1_or_uimm;
    case csr_op is
      when CSR_RW | CSR_RWI =>
        wdata_c <= mask;
        do_write <= '1';
      when CSR_RS | CSR_RSI =>
        wdata_c <= rdata_c or mask;
        do_write <= '1' when unsigned(mask) /= 0 else '0';
      when CSR_RC | CSR_RCI =>
        wdata_c <= rdata_c and not mask;
        do_write <= '1' when unsigned(mask) /= 0 else '0';
      when others =>
        wdata_c <= rdata_c;
        do_write <= '0';
    end case;
  end process;

  process (clk)
    variable mstatus_n : word_t;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        mstatus_q  <= (others => '0');
        mie_q      <= (others => '0');
        mtvec_q    <= (others => '0');
        mscratch_q <= (others => '0');
        mepc_q     <= (others => '0');
        mcause_q   <= (others => '0');
        mtval_q    <= (others => '0');
        mip_q      <= (others => '0');
      elsif trap_take = '1' then
        mstatus_n := mstatus_q;
        mstatus_n(7) := mstatus_q(3);
        mstatus_n(3) := '0';
        mstatus_n(12 downto 11) := "11";
        mstatus_q <= mstatus_n;
        mepc_q    <= trap_pc(31 downto 1) & '0';
        mcause_q  <= trap_cause;
        mtval_q   <= trap_tval;
      elsif mret_take = '1' then
        mstatus_n := mstatus_q;
        mstatus_n(3) := mstatus_q(7);
        mstatus_n(7) := '1';
        mstatus_n(12 downto 11) := "00";
        mstatus_q <= mstatus_n;
      elsif csr_we = '1' and do_write = '1' and read_only = '0' then
        case csr_addr is
          when CSR_MSTATUS =>
            mstatus_q(3) <= wdata_c(3);
            mstatus_q(7) <= wdata_c(7);
            mstatus_q(12 downto 11) <= wdata_c(12 downto 11);
          when CSR_MIE      => mie_q      <= wdata_c;
          when CSR_MTVEC    => mtvec_q    <= wdata_c(31 downto 2) & "00";
          when CSR_MSCRATCH => mscratch_q <= wdata_c;
          when CSR_MEPC     => mepc_q     <= wdata_c(31 downto 1) & '0';
          when CSR_MCAUSE   => mcause_q   <= wdata_c;
          when CSR_MTVAL    => mtval_q    <= wdata_c;
          when CSR_MIP      => mip_q      <= wdata_c;
          when others => null;
        end case;
      end if;
    end if;
  end process;
end architecture;
