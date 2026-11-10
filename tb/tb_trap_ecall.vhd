library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

-- Minimal trap demo: set mtvec, ecall, handler writes LED, mret, then ecall-halt.
entity tb_trap_ecall is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_trap_ecall is
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

  -- 0x00: auipc x1,0 / addi x1,x1,handler_off  -> approx la
  -- Simpler hand encoding:
  --   lui x6, 0          ; base
  --   addi x6, x6, 0x20  ; handler @ 0x20
  --   csrrw x0, mtvec, x6
  --   ecall              ; -> handler
  --   addi x10, x0, 99   ; after mret
  --   lui x14, 0x20000
  --   sw x10, 0(x14)
  --   ecall              ; mtvec still set? handler will run again - bad
  --
  -- Better: handler clears mtvec then returns; second ecall halts (mtvec=0)
  --
  -- handler @ 0x30 bumps mepc+=4 (skip ecall), clears mtvec, mret
  constant PROG : prog_t := (
    x"03000313", -- 0x00 addi x6, x0, 0x30
    x"30531073", -- 0x04 csrrw x0, mtvec, x6
    x"00000073", -- 0x08 ecall
    x"00700513", -- 0x0C addi x10, x0, 7
    x"20000737", -- 0x10 lui x14, 0x20000
    x"00a72023", -- 0x14 sw x10, 0(x14)
    x"00000073", -- 0x18 ecall -> halt (mtvec cleared)
    x"00000013", -- 0x1C nop
    x"00000013", -- 0x20
    x"00000013", -- 0x24
    x"00000013", -- 0x28
    x"00000013", -- 0x2C
    -- handler @ 0x30
    x"02a00393", -- addi x7, x0, 42
    x"20000737", -- lui x14, 0x20000
    x"00772023", -- sw x7, 0(x14)
    x"341022f3", -- csrrs x5, mepc, x0
    x"00428293", -- addi x5, x5, 4
    x"34129073", -- csrrw x0, mepc, x5
    x"30501073", -- csrrw x0, mtvec, x0
    x"30200073"  -- mret
  );
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.cpu_top
    generic map (IMEM_DEPTH_WORDS => 256, DMEM_DEPTH_BYTES => 256)
    port map (
      clk => clk,
      clk_uart   => clk,
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
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("ecall_trap_then_halt") then
        rst <= '1'; imem_we <= '0'; tick; tick;
        for i in PROG'range loop
          imem_addr  <= std_logic_vector(to_unsigned(i * 4, 32));
          imem_wdata <= PROG(i);
          imem_we    <= '1';
          tick;
        end loop;
        imem_we <= '0'; tick;
        rst <= '0';
        timeout := 0;
        while halted = '0' and timeout < 500 loop
          tick;
          timeout := timeout + 1;
        end loop;
        check_equal(halted, '1');
        check_equal(halt_ill, '0');
        -- Final LED should be 7 (post-mret path), proving trap+mret worked
        check_equal(to_integer(unsigned(leds)), 7);
      end if;
    end loop;
    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
