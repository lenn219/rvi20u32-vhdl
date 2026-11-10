library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Board-agnostic FPGA wrapper (XC7A200T class).
-- Clock: expect 50 MHz CPU clock on clk (MMCM external / later).
-- Pins: map in a board XDC when SKU is known (deferred).
entity fpga_top is
  port (
    clk     : in  std_logic;
    rst_btn : in  std_logic; -- async, active-high
    leds    : out std_logic_vector(7 downto 0);
    uart_tx : out std_logic
  );
end entity;

architecture rtl of fpga_top is
  signal rst_meta : std_logic := '1';
  signal rst_sync : std_logic := '1';
  signal halted   : std_logic;
  signal halt_ill : std_logic;
  signal led_r    : std_logic_vector(7 downto 0);
begin
  -- 2-FF reset synchronizer (async assert, sync deassert)
  process (clk, rst_btn)
  begin
    if rst_btn = '1' then
      rst_meta <= '1';
      rst_sync <= '1';
    elsif rising_edge(clk) then
      rst_meta <= '0';
      rst_sync <= rst_meta;
    end if;
  end process;

  u_cpu : entity work.cpu_top
    port map (
      clk        => clk,
      clk_uart   => clk,
      rst        => rst_sync,
      halted     => halted,
      halt_ill   => halt_ill,
      leds       => led_r,
      uart_tx    => uart_tx,
      imem_we    => '0',
      imem_addr  => (others => '0'),
      imem_wdata => (others => '0')
    );

  -- Show halt on LED7, illegal on LED6, program LEDs on 5:0
  leds <= halted & halt_ill & led_r(5 downto 0);
end architecture;
