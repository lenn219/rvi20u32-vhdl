library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

-- CPU drives UART MMIO: poll ready, send "Hi\n", ecall. TB decodes the wire.
entity tb_uart_hello is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_uart_hello is
  constant CLKS : positive := 4;

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

  -- lui x14,0x20000
  -- addi x15,x14,8        # status
  -- addi x14,x14,4        # data
  -- addi x10,x0,'H'
  -- jal x1, putc
  -- addi x10,x0,'i'
  -- jal x1, putc
  -- addi x10,x0,'\n'
  -- jal x1, putc
  -- ecall
  -- putc:                 # @ 0x28
  --   lw x11,0(x15)
  --   andi x11,x11,1
  --   beq x11,x0,putc
  --   sw x10,0(x14)
  --   jalr x0,0(x1)
  constant PROG : prog_t := (
    x"20000737", -- 0x00 lui x14, 0x20000
    x"00870793", -- 0x04 addi x15, x14, 8
    x"00470713", -- 0x08 addi x14, x14, 4
    x"04800513", -- 0x0C addi x10, x0, 0x48
    x"018000ef", -- 0x10 jal x1, 0x28   (offset +0x18)
    x"06900513", -- 0x14 addi x10, x0, 0x69
    x"010000ef", -- 0x18 jal x1, 0x28   (offset +0x10)
    x"00a00513", -- 0x1C addi x10, x0, 0x0A
    x"008000ef", -- 0x20 jal x1, 0x28   (offset +0x08)
    x"00000073", -- 0x24 ecall
    -- putc @ 0x28
    x"0007a583", -- lw x11, 0(x15)
    x"0015f593", -- andi x11, x11, 1
    x"fe058ce3", -- beq x11, x0, -8   (back to lw)
    x"00a72023", -- sw x10, 0(x14)
    x"00008067"  -- jalr x0, 0(x1)
  );
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.cpu_top
    generic map (
      IMEM_DEPTH_WORDS  => 256,
      DMEM_DEPTH_BYTES  => 256,
      UART_CLKS_PER_BIT => CLKS
    )
    port map (
      clk => clk,
      rst => rst,
      halted => halted, halt_ill => halt_ill,
      leds => leds, uart_tx => uart_tx,
      imem_we => imem_we, imem_addr => imem_addr, imem_wdata => imem_wdata
    );

  main : process
    variable timeout : integer;
    variable got     : std_logic_vector(7 downto 0);
    variable n_rx    : integer;
    type bytes_t is array (0 to 2) of std_logic_vector(7 downto 0);
    variable expect  : bytes_t := (x"48", x"69", x"0A");

    procedure tick is
    begin
      wait until rising_edge(clk);
    end procedure;

    procedure recv_byte(variable b : out std_logic_vector(7 downto 0)) is
      variable bits : std_logic_vector(7 downto 0);
      variable guard : integer := 0;
    begin
      while uart_tx = '1' and guard < 5000 loop
        tick;
        guard := guard + 1;
      end loop;
      check(uart_tx = '0', "timeout waiting for UART start bit");
      for i in 1 to CLKS / 2 loop
        tick;
      end loop;
      for i in 0 to 7 loop
        for j in 1 to CLKS loop
          tick;
        end loop;
        bits(i) := uart_tx;
      end loop;
      for j in 1 to CLKS loop
        tick;
      end loop;
      check_equal(uart_tx, '1');
      b := bits;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("cpu_prints_hi") then
        rst <= '1'; imem_we <= '0'; tick; tick;
        for i in PROG'range loop
          imem_addr  <= std_logic_vector(to_unsigned(i * 4, 32));
          imem_wdata <= PROG(i);
          imem_we    <= '1';
          tick;
        end loop;
        imem_we <= '0'; tick;
        rst <= '0';

        -- Concurrent-ish: receive 3 bytes while CPU runs
        for n_rx in 0 to 2 loop
          recv_byte(got);
          report "UART RX byte = 0x" & to_hstring(got);
          check_equal(got, expect(n_rx));
        end loop;

        timeout := 0;
        while halted = '0' and timeout < 5000 loop
          tick;
          timeout := timeout + 1;
        end loop;
        check_equal(halted, '1');
        check_equal(halt_ill, '0');
      end if;
    end loop;

    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
