library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Byte-addressable data memory with byte enables.
-- Combinational read (classic MEM/WB); sync write.
-- 8 KiB is fine for sim; FPGA may map to distributed RAM or a sync-BRAM
-- variant later.
entity dmem is
  generic (
    DEPTH_BYTES : positive := DMEM_SIZE
  );
  port (
    clk   : in  std_logic;
    addr  : in  addr_t;
    we    : in  std_logic;
    be    : in  std_logic_vector(3 downto 0);
    wdata : in  word_t;
    rdata : out word_t
  );
end entity;

architecture rtl of dmem is
  constant DEPTH_WORDS : positive := DEPTH_BYTES / 4;
  type ram_t is array (0 to DEPTH_WORDS - 1) of word_t;
  signal ram : ram_t := (others => (others => '0'));
  signal word_idx : integer range 0 to DEPTH_WORDS - 1;
begin
  word_idx <= to_integer(unsigned(addr(addr'high downto 2))) mod DEPTH_WORDS;

  process (clk)
    variable word : word_t;
  begin
    if rising_edge(clk) then
      if we = '1' then
        word := ram(word_idx);
        if be(0) = '1' then word(7 downto 0) := wdata(7 downto 0); end if;
        if be(1) = '1' then word(15 downto 8) := wdata(15 downto 8); end if;
        if be(2) = '1' then word(23 downto 16) := wdata(23 downto 16); end if;
        if be(3) = '1' then word(31 downto 24) := wdata(31 downto 24); end if;
        ram(word_idx) <= word;
      end if;
    end if;
  end process;

  rdata <= ram(word_idx);
end architecture;
