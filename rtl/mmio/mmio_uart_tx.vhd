library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Minimal UART TX MMIO stub:
--   write data reg  -> accepts byte, pulses tx for TB/FPGA hook
--   status bit0     -> 0 = ready (always ready in stub; real baud later)
entity mmio_uart_tx is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    we_data  : in  std_logic;
    wdata    : in  word_t;
    rdata_st : out word_t;
    tx       : out std_logic; -- idle high; stub holds high
    tx_byte  : out std_logic_vector(7 downto 0);
    tx_valid : out std_logic  -- 1-cycle pulse when a byte is written
  );
end entity;

architecture rtl of mmio_uart_tx is
  signal valid_q : std_logic := '0';
  signal byte_q  : std_logic_vector(7 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        valid_q <= '0';
        byte_q  <= (others => '0');
      else
        valid_q <= '0';
        if we_data = '1' then
          byte_q  <= wdata(7 downto 0);
          valid_q <= '1';
        end if;
      end if;
    end if;
  end process;

  rdata_st <= (others => '0'); -- bit0=0 => ready
  tx       <= '1';
  tx_byte  <= byte_q;
  tx_valid <= valid_q;
end architecture;
