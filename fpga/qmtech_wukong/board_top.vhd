library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- QMTECH Wukong (XC7A100T FGG676) board wrapper.
-- Oscillator: 50 MHz. CPU+UART run on a divided 5 MHz clock so the combo
-- IMEM/DMEM pipeline meets timing (50 MHz showed WNS ≈ -84 ns).
-- UART: 9600 8N1 via UART_CLKS_PER_BIT = round(5e6/9600) = 521.
entity board_top is
  generic (
    IMEM_INIT_HEX     : string   := "uart_hello";
    -- CPU clock is 5 MHz (50 MHz / 10). Do not use 434 (that was 115200@50MHz).
    UART_CLKS_PER_BIT : positive := 521;  -- 5e6 / 9600 ≈ 520.8
    CLK_DIV_HALF      : positive := 5    -- toggle every 5 cycles of 50 MHz → 5 MHz
  );
  port (
    clk_50mhz : in  std_logic;
    key0_n    : in  std_logic;                     -- H7
    key1_n    : in  std_logic;                     -- M6
    led_v2    : out std_logic_vector(1 downto 0);  -- V16 / V17 (V2)
    led_v3    : out std_logic_vector(1 downto 0);  -- G21 / G20 (V3)
    uart_tx   : out std_logic;                     -- FPGA → USB-UART RXD (E3)
    uart_rx   : in  std_logic                      -- USB-UART TXD → FPGA (F3)
  );
end entity;

architecture rtl of board_top is
  component BUFG
    port (
      I : in  std_logic;
      O : out std_logic
    );
  end component;

  signal rst_async : std_logic;
  signal rst_meta  : std_logic := '1';
  signal rst_sync  : std_logic := '1';
  signal halted    : std_logic;
  signal halt_ill  : std_logic;
  signal leds_cpu  : std_logic_vector(7 downto 0);
  signal tx        : std_logic;

  signal div_cnt     : natural range 0 to 31 := 0;
  signal clk_cpu_int : std_logic := '0';
  signal clk_cpu     : std_logic;

  -- Heartbeat on the raw 50 MHz domain (~1 Hz)
  signal hb_cnt    : unsigned(25 downto 0) := (others => '0');
  signal hb_q      : std_logic := '0';

  signal led0_n    : std_logic;
  signal led1_n    : std_logic;

  attribute KEEP       : string;
  attribute DONT_TOUCH : string;
  attribute KEEP of clk_cpu_int       : signal is "TRUE";
  attribute DONT_TOUCH of clk_cpu_int : signal is "TRUE";
begin
  rst_async <= (not key0_n) or (not key1_n);

  -- 50 MHz → 5 MHz square wave (period 200 ns). Required because combo
  -- IMEM/DMEM + EX resolve needs ~100 ns; 20 ns @ 50 MHz fails hard.
  process (clk_50mhz)
  begin
    if rising_edge(clk_50mhz) then
      if div_cnt = CLK_DIV_HALF - 1 then
        div_cnt <= 0;
        clk_cpu_int <= not clk_cpu_int;
      else
        div_cnt <= div_cnt + 1;
      end if;
    end if;
  end process;

  u_bufg_cpu : BUFG
    port map (
      I => clk_cpu_int,
      O => clk_cpu
    );

  -- Reset synchronizer in the CPU clock domain
  process (clk_cpu, rst_async)
  begin
    if rst_async = '1' then
      rst_meta <= '1';
      rst_sync <= '1';
    elsif rising_edge(clk_cpu) then
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
      clk        => clk_cpu,
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

  led0_n <= not leds_cpu(0);
  led1_n <= not hb_q;

  led_v2(0) <= led0_n;
  led_v2(1) <= led1_n;
  led_v3(0) <= led0_n;
  led_v3(1) <= led1_n;
end architecture;
