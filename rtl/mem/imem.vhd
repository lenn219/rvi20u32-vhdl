library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Word-addressed instruction memory.
-- Combinational read (classic 5-stage IF); sync write for TB/program load.
-- Small depth maps to distributed RAM on Artix-7; BRAM sync-read can replace later.
entity imem is
  generic (
    DEPTH_WORDS : positive := IMEM_SIZE / 4
  );
  port (
    clk   : in  std_logic;
    addr  : in  addr_t;
    rdata : out word_t;
    we    : in  std_logic := '0';
    wdata : in  word_t := (others => '0')
  );
end entity;

architecture rtl of imem is
  type ram_t is array (0 to DEPTH_WORDS - 1) of word_t;
  signal ram : ram_t := (others => (others => '0'));
  signal word_idx : integer range 0 to DEPTH_WORDS - 1;
begin
  word_idx <= to_integer(unsigned(addr(addr'high downto 2))) mod DEPTH_WORDS;

  process (clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        ram(word_idx) <= wdata;
      end if;
    end if;
  end process;

  rdata <= ram(word_idx);
end architecture;
