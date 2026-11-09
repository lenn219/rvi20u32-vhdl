library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Simple LED MMIO register (low 8 bits drive leds).
entity mmio_leds is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    we    : in  std_logic;
    wdata : in  word_t;
    rdata : out word_t;
    leds  : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of mmio_leds is
  signal reg_q : word_t := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg_q <= (others => '0');
      elsif we = '1' then
        reg_q <= wdata;
      end if;
    end if;
  end process;

  rdata <= reg_q;
  leds  <= reg_q(7 downto 0);
end architecture;
