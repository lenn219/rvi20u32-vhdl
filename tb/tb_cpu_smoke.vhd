library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

entity tb_cpu_smoke is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_cpu_smoke is
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '1';
  signal halted     : std_logic;
  signal halt_ill   : std_logic;
  signal leds       : std_logic_vector(7 downto 0);
  signal uart_tx    : std_logic;
  signal imem_we    : std_logic := '0';
  signal imem_addr  : addr_t := (others => '0');
  signal imem_wdata : word_t := (others => '0');
  signal running    : boolean := true;

  type prog_t is array (natural range <>) of word_t;

  -- addi x10,15; lui x14,0x20000; sw x10,0(x14); ecall
  constant PROG_SIMPLE : prog_t := (
    x"00f00513",
    x"20000737",
    x"00a72023",
    x"00000073"
  );

  -- Full smoke (committed hex)
  constant PROG_SMOKE : prog_t := (
    x"00000513",
    x"00100593",
    x"00600613",
    x"00b50533",
    x"00158593",
    x"fec5cce3",
    x"100006b7",
    x"00a6a023",
    x"20000737",
    x"00a72023",
    x"00000073"
  );
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.cpu_top
    generic map (IMEM_DEPTH_WORDS => 256, DMEM_DEPTH_BYTES => 256)
    port map (
      clk => clk,
      rst => rst,
      halted => halted, halt_ill => halt_ill,
      leds => leds, uart_tx => uart_tx,
      imem_we => imem_we, imem_addr => imem_addr, imem_wdata => imem_wdata
    );

  main : process
    variable timeout : integer;

    procedure tick is
    begin
      wait until rising_edge(clk);
    end procedure;

    procedure load_and_run(constant prog : prog_t; constant expect_led : std_logic_vector(7 downto 0)) is
    begin
      rst <= '1';
      imem_we <= '0';
      tick; tick;
      for i in prog'range loop
        imem_addr  <= std_logic_vector(to_unsigned(i * 4, 32));
        imem_wdata <= prog(i);
        imem_we    <= '1';
        tick;
      end loop;
      imem_we <= '0';
      tick;
      rst <= '0';
      timeout := 0;
      while halted = '0' and timeout < 800 loop
        tick;
        timeout := timeout + 1;
      end loop;
      check_equal(halted, '1');
      check_equal(halt_ill, '0');
      check(timeout < 800, "timeout waiting for ECALL");
      check_equal(leds, expect_led);
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("simple_addi_led_ecall") then
        load_and_run(PROG_SIMPLE, x"0F");
      elsif run("sum_1_to_5_ecall") then
        load_and_run(PROG_SMOKE, x"0F");
      end if;
    end loop;

    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
