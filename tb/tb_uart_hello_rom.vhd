library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

-- FPGA-image smoke using the *fast* hex (short delay). Board uses uart_hello.hex (slow).
entity tb_uart_hello_rom is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_uart_hello_rom is
  constant CLKS : positive := 4;
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '1';
  signal halted     : std_logic;
  signal halt_ill   : std_logic;
  signal leds       : std_logic_vector(7 downto 0);
  signal uart_tx    : std_logic;
  signal running    : boolean := true;
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.cpu_top
    generic map (
      IMEM_DEPTH_WORDS  => 256,
      DMEM_DEPTH_BYTES  => 256,
      UART_CLKS_PER_BIT => CLKS,
      IMEM_INIT_HEX     => "sw/hex/uart_hello_fast.hex"
    )
    port map (
      clk => clk,
      clk_uart   => clk,
      rst => rst,
      halted => halted, halt_ill => halt_ill,
      leds => leds, uart_tx => uart_tx,
      imem_we => '0', imem_addr => (others => '0'), imem_wdata => (others => '0')
    );

  main : process
    variable got : std_logic_vector(7 downto 0);
    type bytes_t is array (0 to 3) of std_logic_vector(7 downto 0);
    variable expect : bytes_t := (x"48", x"69", x"0D", x"0A");

    procedure tick is
    begin
      wait until rising_edge(clk);
    end procedure;

    procedure recv_byte(variable b : out std_logic_vector(7 downto 0)) is
      variable bits : std_logic_vector(7 downto 0);
      variable guard : integer := 0;
    begin
      while uart_tx = '1' and guard < 20000 loop
        tick;
        guard := guard + 1;
      end loop;
      check(uart_tx = '0', "timeout waiting for UART start");
      for i in 1 to CLKS / 2 loop tick; end loop;
      for i in 0 to 7 loop
        for j in 1 to CLKS loop tick; end loop;
        bits(i) := uart_tx;
      end loop;
      for j in 1 to CLKS loop tick; end loop;
      b := bits;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("rom_prints_hi_crlf") then
        rst <= '1'; tick; tick; rst <= '0';
        -- After delay: LED toggled 0→1, then UART "Hi\r\n"
        recv_byte(got);
        check_equal(got, expect(0));
        check_equal(leds(0), '1');  -- still in first half before next toggle
        for n in 1 to 3 loop
          recv_byte(got);
          report "ROM UART byte=" & to_hstring(got);
          check_equal(got, expect(n));
        end loop;
        for i in 1 to 200 loop tick; end loop;
        check_equal(halted, '0');
      end if;
    end loop;
    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
