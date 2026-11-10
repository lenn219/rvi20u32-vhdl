library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- QMTECH Wukong (XC7A100T FGG676) board wrapper.
-- Clock: 50 MHz oscillator. UART: onboard USB-UART bridge.
-- Default pinout matches Wukong V2 (see wukong.xdc for V3 LED notes).
entity board_top is
  generic (
    -- Path relative to Vivado run directory / GHDL cwd; set in synth TCL.
    IMEM_INIT_HEX     : string   := "uart_hello.hex";
    UART_CLKS_PER_BIT : positive := 434  -- 50e6 / 115200
  );
  port (
    clk_50mhz : in  std_logic;
    rst_n     : in  std_logic;                     -- Key1, active-low
    led       : out std_logic_vector(1 downto 0);  -- active-low
    uart_tx   : out std_logic;                     -- FPGA → USB-UART
    uart_rx   : in  std_logic                      -- USB-UART → FPGA (unused)
  );
end entity;

architecture rtl of board_top is
  signal rst_async : std_logic;
  signal rst_meta  : std_logic := '1';
  signal rst_sync  : std_logic := '1';
  signal halted    : std_logic;
  signal halt_ill  : std_logic;
  signal leds_cpu  : std_logic_vector(7 downto 0);
  signal tx        : std_logic;
begin
  rst_async <= not rst_n;

  process (clk_50mhz, rst_async)
  begin
    if rst_async = '1' then
      rst_meta <= '1';
      rst_sync <= '1';
    elsif rising_edge(clk_50mhz) then
      rst_meta <= '0';
      rst_sync <= rst_meta;
    end if;
  end process;

  u_cpu : entity work.cpu_top
    generic map (
      IMEM_DEPTH_WORDS  => 1024,
      DMEM_DEPTH_BYTES  => 4096,
      UART_CLKS_PER_BIT => UART_CLKS_PER_BIT,
      IMEM_INIT_HEX     => IMEM_INIT_HEX
    )
    port map (
      clk        => clk_50mhz,
      rst        => rst_sync,
      halted     => halted,
      halt_ill   => halt_ill,
      leds       => leds_cpu,
      uart_tx    => tx,
      imem_we    => '0',
      imem_addr  => (others => '0'),
      imem_wdata => (others => '0')
    );

  uart_tx <= tx;

  -- Active-low board LEDs driven by CPU MMIO @ 0x20000000 (soft blink in uart_hello.hex).
  -- Invert: software writes 1 = LED on.
  led(0) <= not leds_cpu(0);
  led(1) <= not leds_cpu(1);

  -- uart_rx reserved for future RX MMIO; pin is constrained in XDC
end architecture;
