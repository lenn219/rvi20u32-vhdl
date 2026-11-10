library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Dual-clock UART TX MMIO wrapper.
-- CPU domain posts a byte; baud domain (preferably the board crystal) shifts
-- it out so wire baud does not depend on the CPU clock divider.
entity mmio_uart_tx_cdc is
  generic (
    CLKS_PER_BIT : positive := 5208  -- 50e6 / 9600
  );
  port (
    clk_cpu  : in  std_logic;
    clk_baud : in  std_logic;
    rst_cpu  : in  std_logic;
    we_data  : in  std_logic;
    wdata    : in  word_t;
    rdata_st : out word_t;
    tx       : out std_logic;
    tx_byte  : out std_logic_vector(7 downto 0);
    tx_valid : out std_logic
  );
end entity;

architecture rtl of mmio_uart_tx_cdc is
  signal hold_cpu_q    : std_logic_vector(7 downto 0) := (others => '0');
  signal req_cpu_q     : std_logic := '0';
  signal ack_cpu_meta  : std_logic := '0';
  signal ack_cpu_q     : std_logic := '0';
  signal busy_cpu_meta : std_logic := '0';
  signal busy_cpu_q    : std_logic := '0';
  signal ready_cpu     : std_logic;

  signal req_baud_meta : std_logic := '0';
  signal req_baud_q    : std_logic := '0';
  signal req_baud_d    : std_logic := '0';
  signal ack_baud_q    : std_logic := '0';
  signal rst_baud_meta : std_logic := '1';
  signal rst_baud_q    : std_logic := '1';

  signal we_baud    : std_logic := '0';
  signal wdata_baud : word_t;
  signal st_baud    : word_t;
  signal busy_baud  : std_logic;
begin
  ready_cpu <= (not req_cpu_q) and (not busy_cpu_q);
  rdata_st  <= (0 => ready_cpu, 1 => not ready_cpu, others => '0');

  -- hold_cpu_q is stable for the whole req handshake → safe to present to baud domain
  wdata_baud <= x"000000" & hold_cpu_q;

  process (clk_cpu)
  begin
    if rising_edge(clk_cpu) then
      if rst_cpu = '1' then
        hold_cpu_q    <= (others => '0');
        req_cpu_q     <= '0';
        ack_cpu_meta  <= '0';
        ack_cpu_q     <= '0';
        busy_cpu_meta <= '0';
        busy_cpu_q    <= '0';
      else
        ack_cpu_meta  <= ack_baud_q;
        ack_cpu_q     <= ack_cpu_meta;
        busy_cpu_meta <= busy_baud;
        busy_cpu_q    <= busy_cpu_meta;

        if req_cpu_q = '1' and ack_cpu_q = '1' then
          req_cpu_q <= '0';
        elsif we_data = '1' and req_cpu_q = '0' and busy_cpu_q = '0' then
          hold_cpu_q <= wdata(7 downto 0);
          req_cpu_q  <= '1';
        end if;
      end if;
    end if;
  end process;

  process (clk_baud)
  begin
    if rising_edge(clk_baud) then
      rst_baud_meta <= rst_cpu;
      rst_baud_q    <= rst_baud_meta;
    end if;
  end process;

  process (clk_baud)
  begin
    if rising_edge(clk_baud) then
      if rst_baud_q = '1' then
        req_baud_meta <= '0';
        req_baud_q    <= '0';
        req_baud_d    <= '0';
        ack_baud_q    <= '0';
        we_baud       <= '0';
      else
        req_baud_meta <= req_cpu_q;
        req_baud_q    <= req_baud_meta;
        req_baud_d    <= req_baud_q;
        we_baud       <= '0';

        if req_baud_q = '1' and req_baud_d = '0' and busy_baud = '0' and ack_baud_q = '0' then
          we_baud    <= '1';
          ack_baud_q <= '1';
        elsif req_baud_q = '0' then
          ack_baud_q <= '0';
        end if;
      end if;
    end if;
  end process;

  u_tx : entity work.mmio_uart_tx
    generic map (CLKS_PER_BIT => CLKS_PER_BIT)
    port map (
      clk      => clk_baud,
      rst      => rst_baud_q,
      we_data  => we_baud,
      wdata    => wdata_baud,
      rdata_st => st_baud,
      tx       => tx,
      tx_byte  => tx_byte,
      tx_valid => tx_valid
    );

  busy_baud <= st_baud(1);
end architecture;
