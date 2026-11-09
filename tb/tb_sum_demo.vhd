library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

-- Hand-assembled demo: 40 + 2 = 42.
-- Store sum to DMEM, load it back, dump to LED MMIO, print result.
entity tb_sum_demo is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_sum_demo is
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

  -- addi x10,x0,40
  -- addi x11,x0,2
  -- add  x12,x10,x11
  -- lui  x13,0x10000
  -- sw   x12,0(x13)     -- write sum to DMEM @ 0x10000000
  -- lw   x15,0(x13)     -- read sum back from DMEM
  -- lui  x14,0x20000
  -- sw   x15,0(x14)     -- dump read-back value to LED MMIO
  -- ecall
  constant PROG : prog_t := (
    x"02800513",
    x"00200593",
    x"00b50633",
    x"100006b7",
    x"00c6a023",
    x"0006a783",
    x"20000737",
    x"00f72023",
    x"00000073"
  );
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.cpu_top
    generic map (IMEM_DEPTH_WORDS => 256, DMEM_DEPTH_BYTES => 256)
    port map (
      clk => clk, rst => rst,
      halted => halted, halt_ill => halt_ill,
      leds => leds, uart_tx => uart_tx,
      imem_we => imem_we, imem_addr => imem_addr, imem_wdata => imem_wdata
    );

  main : process
    variable timeout  : integer;
    variable sum_led  : integer;
    variable sum_mmio : word_t;
    alias led_reg is << signal uut.u_leds.reg_q : word_t >>;

    procedure tick is
    begin
      wait until rising_edge(clk);
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("sum_40_plus_2") then
        rst <= '1';
        imem_we <= '0';
        tick; tick;

        for i in PROG'range loop
          imem_addr  <= std_logic_vector(to_unsigned(i * 4, 32));
          imem_wdata <= PROG(i);
          imem_we    <= '1';
          tick;
        end loop;
        imem_we <= '0';
        tick;

        rst <= '0';
        timeout := 0;
        while halted = '0' and timeout < 500 loop
          tick;
          timeout := timeout + 1;
        end loop;

        check_equal(halted, '1');
        check_equal(halt_ill, '0');

        sum_led  := to_integer(unsigned(leds));
        sum_mmio := led_reg;

        report "========================================";
        report " SUM DEMO: 40 + 2";
        report " Program wrote sum to DMEM @ 0x10000000,";
        report " then LW'd it back and dumped to LED MMIO.";
        report " cycles_until_halt = " & integer'image(timeout);
        report " LEDs[7:0]         = " & integer'image(sum_led);
        report " LED MMIO (32-bit) = " & integer'image(to_integer(unsigned(sum_mmio)));
        report " expected           = 42 (0x0000002A)";
        report "========================================";

        check_equal(sum_led, 42);
        check_equal(sum_mmio, std_logic_vector'(x"0000002A"));
      end if;
    end loop;

    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
