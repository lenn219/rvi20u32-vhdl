library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Compliance SoC: same 5-stage core as cpu_top, unified RAM @ 0x80000000.
-- Used with riscv-arch-test (legacy) ELFs linked for Spike-compatible map.
entity compliance_soc is
  generic (
    RAM_DEPTH_BYTES : positive := 1024 * 1024;
    RESET_PC        : addr_t := x"80000000";
    TOHOST_ADDR     : addr_t := x"800048F0"  -- overridden per-ELF by TB
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    halted     : out std_logic;
    halt_ill   : out std_logic;
    -- Host preload / signature peek
    load_we    : in  std_logic := '0';
    load_addr  : in  addr_t := (others => '0');
    load_wdata : in  word_t := (others => '0');
    peek_addr  : in  addr_t := (others => '0');
    peek_rdata : out word_t
  );
end entity;

architecture rtl of compliance_soc is
  signal pc_q, pc_next       : addr_t := RESET_PC;
  signal instr_if            : word_t;
  signal i_addr              : addr_t;

  signal ifid_pc             : addr_t := RESET_PC;
  signal ifid_instr          : word_t := (others => '0');
  signal ifid_valid          : std_logic := '0';

  signal dec_ctrl            : ctrl_t;
  signal dec_imm             : word_t;
  signal dec_rs1, dec_rs2, dec_rd : reg_addr_t;
  signal rf_rdata1, rf_rdata2 : word_t;
  signal rf_rdata1_byp, rf_rdata2_byp : word_t;

  signal idex_ctrl           : ctrl_t := CTRL_NOP;
  signal idex_pc             : addr_t := (others => '0');
  signal idex_imm            : word_t := (others => '0');
  signal idex_rs1, idex_rs2, idex_rd : reg_addr_t := (others => '0');
  signal idex_rdata1, idex_rdata2 : word_t := (others => '0');

  signal fwd_a, fwd_b        : std_logic_vector(1 downto 0);
  signal fwd_rs1, fwd_rs2    : word_t;
  signal alu_a, alu_b, alu_y : word_t;
  signal cmp_eq, cmp_lt, cmp_ltu : std_logic;
  signal branch_taken        : std_logic;
  signal redirect            : std_logic;
  signal redirect_target     : addr_t;

  signal exmem_ctrl          : ctrl_t := CTRL_NOP;
  signal exmem_alu           : word_t := (others => '0');
  signal exmem_store         : word_t := (others => '0');
  signal exmem_rd            : reg_addr_t := (others => '0');
  signal exmem_pc4           : addr_t := (others => '0');

  signal d_addr              : addr_t;
  signal d_we                : std_logic;
  signal d_be                : std_logic_vector(3 downto 0);
  signal d_wdata             : word_t;
  signal d_rdata             : word_t;
  signal load_data           : word_t;

  signal memwb_ctrl          : ctrl_t := CTRL_NOP;
  signal memwb_alu           : word_t := (others => '0');
  signal memwb_load          : word_t := (others => '0');
  signal memwb_rd            : reg_addr_t := (others => '0');
  signal memwb_pc4           : addr_t := (others => '0');
  signal wb_data             : word_t;
  signal rf_we               : std_logic;

  signal stall               : std_logic;
  signal flush_ifid, flush_idex : std_logic;

  signal halted_q            : std_logic := '0';
  signal halt_ill_q          : std_logic := '0';
  signal tohost_hit          : std_logic := '0';

  function align_store(data : word_t; addr : addr_t; size : mem_size_t) return word_t is
    variable r : word_t := (others => '0');
    variable a : integer;
  begin
    a := to_integer(unsigned(addr(1 downto 0)));
    case size is
      when MEM_W => r := data;
      when MEM_H =>
        if a = 0 then r(15 downto 0) := data(15 downto 0);
        else r(31 downto 16) := data(15 downto 0); end if;
      when MEM_B =>
        case a is
          when 0 => r(7 downto 0) := data(7 downto 0);
          when 1 => r(15 downto 8) := data(7 downto 0);
          when 2 => r(23 downto 16) := data(7 downto 0);
          when others => r(31 downto 24) := data(7 downto 0);
        end case;
    end case;
    return r;
  end function;

  function byte_enables(addr : addr_t; size : mem_size_t) return std_logic_vector is
    variable be : std_logic_vector(3 downto 0) := (others => '0');
    variable a  : integer;
  begin
    a := to_integer(unsigned(addr(1 downto 0)));
    case size is
      when MEM_W => be := "1111";
      when MEM_H =>
        if a = 0 then be := "0011"; else be := "1100"; end if;
      when MEM_B =>
        case a is
          when 0 => be := "0001";
          when 1 => be := "0010";
          when 2 => be := "0100";
          when others => be := "1000";
        end case;
    end case;
    return be;
  end function;

  function extend_load(
    raw : word_t; addr : addr_t; size : mem_size_t; unsigned_ext : std_logic
  ) return word_t is
    variable a : integer;
    variable b : std_logic_vector(7 downto 0);
    variable h : std_logic_vector(15 downto 0);
  begin
    a := to_integer(unsigned(addr(1 downto 0)));
    case size is
      when MEM_W => return raw;
      when MEM_H =>
        if a = 0 then h := raw(15 downto 0); else h := raw(31 downto 16); end if;
        if unsigned_ext = '1' then return std_logic_vector(resize(unsigned(h), 32));
        else return std_logic_vector(resize(signed(h), 32)); end if;
      when MEM_B =>
        case a is
          when 0 => b := raw(7 downto 0);
          when 1 => b := raw(15 downto 8);
          when 2 => b := raw(23 downto 16);
          when others => b := raw(31 downto 24);
        end case;
        if unsigned_ext = '1' then return std_logic_vector(resize(unsigned(b), 32));
        else return std_logic_vector(resize(signed(b), 32)); end if;
    end case;
  end function;
begin
  halted   <= halted_q or tohost_hit;
  halt_ill <= halt_ill_q;

  i_addr <= load_addr when load_we = '1' else pc_q;

  u_ram : entity work.unified_ram
    generic map (DEPTH_BYTES => RAM_DEPTH_BYTES)
    port map (
      clk => clk,
      i_addr => i_addr, i_rdata => instr_if,
      d_addr => d_addr, d_we => d_we and not load_we, d_be => d_be,
      d_wdata => d_wdata, d_rdata => d_rdata,
      load_we => load_we, load_addr => load_addr, load_wdata => load_wdata,
      peek_addr => peek_addr, peek_rdata => peek_rdata
    );

  cmp_eq  <= '1' when fwd_rs1 = fwd_rs2 else '0';
  cmp_lt  <= '1' when signed(fwd_rs1) < signed(fwd_rs2) else '0';
  cmp_ltu <= '1' when unsigned(fwd_rs1) < unsigned(fwd_rs2) else '0';

  branch_taken <=
      '1' when idex_ctrl.branch_op = BR_EQ  and cmp_eq = '1' else
      '1' when idex_ctrl.branch_op = BR_NE  and cmp_eq = '0' else
      '1' when idex_ctrl.branch_op = BR_LT  and cmp_lt = '1' else
      '1' when idex_ctrl.branch_op = BR_GE  and cmp_lt = '0' else
      '1' when idex_ctrl.branch_op = BR_LTU and cmp_ltu = '1' else
      '1' when idex_ctrl.branch_op = BR_GEU and cmp_ltu = '0' else
      '0';

  redirect <= (idex_ctrl.jump or branch_taken) and not (halted_q or tohost_hit);

  redirect_target <=
      std_logic_vector(resize(unsigned(fwd_rs1) + unsigned(idex_imm), 32) and x"FFFFFFFE")
        when idex_ctrl.jalr = '1' else
      std_logic_vector(unsigned(idex_pc) + unsigned(idex_imm));

  pc_next <= redirect_target when redirect = '1'
             else std_logic_vector(unsigned(pc_q) + 4);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        pc_q <= RESET_PC;
      elsif (halted_q = '0' and tohost_hit = '0') and stall = '0' then
        pc_q <= pc_next;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or flush_ifid = '1' then
        ifid_pc    <= RESET_PC;
        ifid_instr <= x"00000013";
        ifid_valid <= '0';
      elsif (halted_q = '0' and tohost_hit = '0') and stall = '0' and load_we = '0' then
        ifid_pc    <= pc_q;
        ifid_instr <= instr_if;
        ifid_valid <= '1';
      end if;
    end if;
  end process;

  u_decode : entity work.decode
    port map (
      instr => ifid_instr, ctrl => dec_ctrl, imm => dec_imm,
      rs1 => dec_rs1, rs2 => dec_rs2, rd => dec_rd
    );

  rf_we <= memwb_ctrl.reg_write and not halted_q and not tohost_hit;

  u_regfile : entity work.regfile
    port map (
      clk => clk, rst => rst, we => rf_we,
      waddr => memwb_rd, wdata => wb_data,
      raddr1 => dec_rs1, raddr2 => dec_rs2,
      rdata1 => rf_rdata1, rdata2 => rf_rdata2
    );

  rf_rdata1_byp <= wb_data when (memwb_ctrl.reg_write = '1'
                           and unsigned(memwb_rd) /= 0 and memwb_rd = dec_rs1)
                   else rf_rdata1;
  rf_rdata2_byp <= wb_data when (memwb_ctrl.reg_write = '1'
                           and unsigned(memwb_rd) /= 0 and memwb_rd = dec_rs2)
                   else rf_rdata2;

  u_hazard : entity work.hazard_unit
    port map (
      idex_mem_read => idex_ctrl.mem_read, idex_rd => idex_rd,
      ifid_rs1 => dec_rs1, ifid_rs2 => dec_rs2,
      ifid_use_rs1 => dec_ctrl.use_rs1, ifid_use_rs2 => dec_ctrl.use_rs2,
      redirect => redirect, stall => stall,
      flush_ifid => flush_ifid, flush_idex => flush_idex
    );

  u_forward : entity work.forward_unit
    port map (
      idex_rs1 => idex_rs1, idex_rs2 => idex_rs2,
      idex_use_rs1 => idex_ctrl.use_rs1, idex_use_rs2 => idex_ctrl.use_rs2,
      exmem_rd => exmem_rd, exmem_we => exmem_ctrl.reg_write,
      exmem_load => exmem_ctrl.mem_read,
      memwb_rd => memwb_rd, memwb_we => memwb_ctrl.reg_write,
      fwd_a => fwd_a, fwd_b => fwd_b
    );

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or flush_idex = '1' then
        idex_ctrl <= CTRL_NOP;
        idex_pc <= (others => '0'); idex_imm <= (others => '0');
        idex_rs1 <= (others => '0'); idex_rs2 <= (others => '0'); idex_rd <= (others => '0');
        idex_rdata1 <= (others => '0'); idex_rdata2 <= (others => '0');
      elsif halted_q = '0' and tohost_hit = '0' and load_we = '0' then
        if ifid_valid = '1' then idex_ctrl <= dec_ctrl; else idex_ctrl <= CTRL_NOP; end if;
        idex_pc <= ifid_pc; idex_imm <= dec_imm;
        idex_rs1 <= dec_rs1; idex_rs2 <= dec_rs2; idex_rd <= dec_rd;
        idex_rdata1 <= rf_rdata1_byp; idex_rdata2 <= rf_rdata2_byp;
      end if;
    end if;
  end process;

  with fwd_a select
    fwd_rs1 <= exmem_alu when "10", wb_data when "01", idex_rdata1 when others;
  with fwd_b select
    fwd_rs2 <= exmem_alu when "10", wb_data when "01", idex_rdata2 when others;

  alu_a <= idex_pc when (idex_ctrl.auipc = '1'
                      or idex_ctrl.branch_op /= BR_NONE
                      or (idex_ctrl.jump = '1' and idex_ctrl.jalr = '0'))
           else fwd_rs1;
  alu_b <= idex_imm when idex_ctrl.alu_src_b = '1' else fwd_rs2;

  u_alu : entity work.alu
    port map (
      op => idex_ctrl.alu_op, a => alu_a, b => alu_b, y => alu_y,
      cmp_eq => open, cmp_lt => open, cmp_ltu => open
    );

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        exmem_ctrl <= CTRL_NOP; exmem_alu <= (others => '0');
        exmem_store <= (others => '0'); exmem_rd <= (others => '0');
        exmem_pc4 <= (others => '0');
      elsif halted_q = '0' and tohost_hit = '0' and load_we = '0' then
        exmem_ctrl <= idex_ctrl;
        if idex_ctrl.lui = '1' then exmem_alu <= idex_imm; else exmem_alu <= alu_y; end if;
        exmem_store <= fwd_rs2; exmem_rd <= idex_rd;
        exmem_pc4 <= std_logic_vector(unsigned(idex_pc) + 4);
      end if;
    end if;
  end process;

  d_addr  <= exmem_alu;
  d_we    <= exmem_ctrl.mem_write and not halted_q and not tohost_hit;
  d_be    <= byte_enables(exmem_alu, exmem_ctrl.mem_size) when exmem_ctrl.mem_write = '1'
             else (others => '0');
  d_wdata <= align_store(exmem_store, exmem_alu, exmem_ctrl.mem_size);
  load_data <= extend_load(d_rdata, exmem_alu, exmem_ctrl.mem_size, exmem_ctrl.mem_unsigned);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        tohost_hit <= '0';
      elsif d_we = '1' and d_addr = TOHOST_ADDR and d_wdata /= x"00000000" then
        tohost_hit <= '1';
      end if;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        memwb_ctrl <= CTRL_NOP; memwb_alu <= (others => '0'); memwb_load <= (others => '0');
        memwb_rd <= (others => '0'); memwb_pc4 <= (others => '0');
      elsif halted_q = '0' and tohost_hit = '0' and load_we = '0' then
        memwb_ctrl <= exmem_ctrl; memwb_alu <= exmem_alu;
        memwb_load <= load_data; memwb_rd <= exmem_rd; memwb_pc4 <= exmem_pc4;
      end if;
    end if;
  end process;

  wb_data <= memwb_pc4 when memwb_ctrl.wb_pc4 = '1' else
             memwb_load when memwb_ctrl.mem_read = '1' else
             memwb_alu;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        halted_q <= '0'; halt_ill_q <= '0';
      elsif memwb_ctrl.halt = '1' then
        halted_q <= '1';
        if memwb_ctrl.illegal = '1' then halt_ill_q <= '1'; end if;
      end if;
    end if;
  end process;
end architecture;
