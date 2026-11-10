library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- QMTECH Wukong (XC7A100T FGG676) board wrapper.
-- Clock: 50 MHz oscillator. UART: onboard USB-UART (CP2102 V2 / CH340N V3).
-- Drives BOTH V2 and V3 user-LED pin pairs so either revision blinks.
entity board_top is
  generic (
    -- "uart_hello" = embedded boot image (recommended for Vivado).
    -- Or a filesystem path to a .hex for sim / custom images.
    IMEM_INIT_HEX     : string   := "uart_hello";
    UART_CLKS_PER_BIT : positive := 434  -- 50e6 / 115200
  );
  port (
    clk_50mhz : in  std_logic;
    -- Active-low keys (either holds CPU in reset). Official demos use Key0=H7;
    -- LiteX uses Key1=M6. Wire both.
    key0_n    : in  std_logic;                     -- H7
    key1_n    : in  std_logic;                     -- M6
    -- User LEDs are active-low on the schematic (FPGA sinks current).
    led_v2    : out std_logic_vector(1 downto 0);  -- V16 / V17 (board rev V2)
    led_v3    : out std_logic_vector(1 downto 0);  -- G21 / G20 (board rev V3)
    uart_tx   : out std_logic;                     -- FPGA → USB-UART RXD (E3)
    uart_rx   : in  std_logic                      -- USB-UART TXD → FPGA (F3)
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

  -- Free-running ~1 Hz heartbeat proves the 50 MHz clock is alive even if
  -- the CPU image failed to load.
  signal hb_cnt    : unsigned(25 downto 0) := (others => '0');
  signal hb_q      : std_logic := '0';

  signal led0_n    : std_logic;
  signal led1_n    : std_logic;
begin
  -- Press either Key0 or Key1 → reset
  rst_async <= (not key0_n) or (not key1_n);

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

  process (clk_50mhz)
  begin
    if rising_edge(clk_50mhz) then
      if hb_cnt = to_unsigned(25_000_000 - 1, hb_cnt'length) then
        hb_cnt <= (others => '0');
        hb_q   <= not hb_q;
      else
        hb_cnt <= hb_cnt + 1;
      end if;
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

  -- Active-low LEDs: drive 0 to light.
  -- LED0 = CPU MMIO soft blink (uart_hello). LED1 = HW heartbeat (~1 Hz).
  led0_n <= not leds_cpu(0);
  led1_n <= not hb_q;

  led_v2(0) <= led0_n;
  led_v2(1) <= led1_n;
  led_v3(0) <= led0_n;
  led_v3(1) <= led1_n;

  -- uart_rx reserved for future RX MMIO; constrained so the pin is defined.
end architecture;
