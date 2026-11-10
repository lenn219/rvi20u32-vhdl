library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

-- DUT vs Unicorn signature for mul-01 (riscv-arch-test M suite).
entity tb_arch_mul is
  generic (
    runner_cfg : string;
    ram_hex    : string := "../compliance/work/mul-01/ram.hex";
    tohost_hex : string := "80000000";
    begin_hex  : string := "80000000";
    end_hex    : string := "80000000";
    ref_sig    : string := "../compliance/work/mul-01/ref.signature"
  );
end entity;

architecture tb of tb_arch_mul is
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '1';
  signal halted     : std_logic;
  signal halt_ill   : std_logic;
  signal load_we    : std_logic := '0';
  signal load_addr  : addr_t := (others => '0');
  signal load_wdata : word_t := (others => '0');
  signal peek_addr  : addr_t := (others => '0');
  signal peek_rdata : word_t;
  signal running    : boolean := true;

  function hex_to_addr(constant s : string) return addr_t is
    variable v : unsigned(31 downto 0) := (others => '0');
    variable nibble : integer;
    variable c : character;
  begin
    for i in s'range loop
      c := s(i);
      if c >= '0' and c <= '9' then
        nibble := character'pos(c) - character'pos('0');
      elsif c >= 'a' and c <= 'f' then
        nibble := character'pos(c) - character'pos('a') + 10;
      elsif c >= 'A' and c <= 'F' then
        nibble := character'pos(c) - character'pos('A') + 10;
      else
        nibble := 0;
      end if;
      v := shift_left(v, 4) or to_unsigned(nibble, 32);
    end loop;
    return std_logic_vector(v);
  end function;
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.compliance_soc
    generic map (
      RAM_DEPTH_BYTES => 1024 * 1024,
      RESET_PC        => x"80000000",
      TOHOST_ADDR     => hex_to_addr(tohost_hex)
    )
    port map (
      clk => clk, rst => rst, halted => halted, halt_ill => halt_ill,
      load_we => load_we, load_addr => load_addr, load_wdata => load_wdata,
      peek_addr => peek_addr, peek_rdata => peek_rdata
    );

  main : process
    file fhex : text;
    file fref : text;
    variable l : line;
    variable timeout : integer;
    variable addr_u : unsigned(31 downto 0);
    variable val : unsigned(31 downto 0);
    variable nibble : integer;
    variable c : character;
    variable got, exp : word_t;
    variable mismatches : integer;
    variable begin_a, end_a : addr_t;

    procedure tick is
    begin
      wait until rising_edge(clk);
    end procedure;

    procedure load_ram(constant path : in string) is
    begin
      file_open(fhex, path, read_mode);
      addr_u := x"80000000";
      while not endfile(fhex) loop
        readline(fhex, l);
        if l'length < 8 then
          next;
        end if;
        val := (others => '0');
        for i in 0 to 7 loop
          c := l.all(i + 1);
          if c >= '0' and c <= '9' then
            nibble := character'pos(c) - character'pos('0');
          elsif c >= 'a' and c <= 'f' then
            nibble := character'pos(c) - character'pos('a') + 10;
          elsif c >= 'A' and c <= 'F' then
            nibble := character'pos(c) - character'pos('A') + 10;
          else
            nibble := 0;
          end if;
          val := shift_left(val, 4) or to_unsigned(nibble, 32);
        end loop;
        load_addr  <= std_logic_vector(addr_u);
        load_wdata <= std_logic_vector(val);
        load_we    <= '1';
        tick;
        addr_u := addr_u + 4;
      end loop;
      file_close(fhex);
      load_we <= '0';
      tick;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);
    begin_a := hex_to_addr(begin_hex);
    end_a   := hex_to_addr(end_hex);

    while test_suite loop
      if run("mul_01_vs_ref") then
        rst <= '1';
        tick; tick;
        load_ram(ram_hex);
        rst <= '0';
        timeout := 0;
        while halted = '0' and timeout < 500000 loop
          tick;
          timeout := timeout + 1;
        end loop;
        check(halted = '1', "timeout/halt waiting for tohost");
        check_equal(halt_ill, '0');

        mismatches := 0;
        file_open(fref, ref_sig, read_mode);
        addr_u := unsigned(begin_a);
        while not endfile(fref) and addr_u < unsigned(end_a) loop
          readline(fref, l);
          if l'length < 8 then
            next;
          end if;
          val := (others => '0');
          for i in 0 to 7 loop
            c := l.all(i + 1);
            if c >= '0' and c <= '9' then
              nibble := character'pos(c) - character'pos('0');
            elsif c >= 'a' and c <= 'f' then
              nibble := character'pos(c) - character'pos('a') + 10;
            elsif c >= 'A' and c <= 'F' then
              nibble := character'pos(c) - character'pos('A') + 10;
            else
              nibble := 0;
            end if;
            val := shift_left(val, 4) or to_unsigned(nibble, 32);
          end loop;
          exp := std_logic_vector(val);
          peek_addr <= std_logic_vector(addr_u);
          wait for 1 ns;
          got := peek_rdata;
          if got /= exp then
            mismatches := mismatches + 1;
          end if;
          addr_u := addr_u + 4;
        end loop;
        file_close(fref);
        check_equal(mismatches, 0);
      end if;
    end loop;

    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
