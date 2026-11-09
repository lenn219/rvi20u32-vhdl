library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- UART TX MMIO (8N1):
--   DATA   @ +0x04 : write low byte starts a frame when ready
--   STATUS @ +0x08 : bit0 = ready (1=accept write), bit1 = busy
-- Idle line is high. Baud via CLKS_PER_BIT (clk cycles per bit).
-- Default 50 MHz / 115200 ≈ 434.
entity mmio_uart_tx is
  generic (
    CLKS_PER_BIT : positive := 434
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    we_data  : in  std_logic;
    wdata    : in  word_t;
    rdata_st : out word_t;
    tx       : out std_logic;
    tx_byte  : out std_logic_vector(7 downto 0);
    tx_valid : out std_logic  -- 1-cycle pulse when a new byte is accepted
  );
end entity;

architecture rtl of mmio_uart_tx is
  type state_t is (ST_IDLE, ST_START, ST_DATA, ST_STOP);
  signal state_q   : state_t := ST_IDLE;
  signal clk_cnt_q : integer range 0 to CLKS_PER_BIT - 1 := 0;
  signal bit_idx_q : integer range 0 to 7 := 0;
  signal shift_q   : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_q      : std_logic := '1';
  signal busy_q    : std_logic := '0';
  signal last_q    : std_logic_vector(7 downto 0) := (others => '0');
  signal accept_q  : std_logic := '0';
begin
  tx       <= tx_q;
  tx_byte  <= last_q;
  tx_valid <= accept_q;
  rdata_st <= (0 => not busy_q, 1 => busy_q, others => '0');

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state_q   <= ST_IDLE;
        clk_cnt_q <= 0;
        bit_idx_q <= 0;
        shift_q   <= (others => '0');
        tx_q      <= '1';
        busy_q    <= '0';
        last_q    <= (others => '0');
        accept_q  <= '0';
      else
        accept_q <= '0';

        case state_q is
          when ST_IDLE =>
            tx_q   <= '1';
            busy_q <= '0';
            if we_data = '1' then
              shift_q  <= wdata(7 downto 0);
              last_q   <= wdata(7 downto 0);
              accept_q <= '1';
              busy_q   <= '1';
              clk_cnt_q <= 0;
              state_q  <= ST_START;
            end if;

          when ST_START =>
            tx_q   <= '0'; -- start bit
            busy_q <= '1';
            if clk_cnt_q = CLKS_PER_BIT - 1 then
              clk_cnt_q <= 0;
              bit_idx_q <= 0;
              state_q   <= ST_DATA;
            else
              clk_cnt_q <= clk_cnt_q + 1;
            end if;

          when ST_DATA =>
            tx_q   <= shift_q(bit_idx_q);
            busy_q <= '1';
            if clk_cnt_q = CLKS_PER_BIT - 1 then
              clk_cnt_q <= 0;
              if bit_idx_q = 7 then
                state_q <= ST_STOP;
              else
                bit_idx_q <= bit_idx_q + 1;
              end if;
            else
              clk_cnt_q <= clk_cnt_q + 1;
            end if;

          when ST_STOP =>
            tx_q   <= '1'; -- stop bit
            busy_q <= '1';
            if clk_cnt_q = CLKS_PER_BIT - 1 then
              clk_cnt_q <= 0;
              busy_q    <= '0';
              state_q   <= ST_IDLE;
            else
              clk_cnt_q <= clk_cnt_q + 1;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture;
