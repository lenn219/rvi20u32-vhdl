library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- Single RW memory for compliance (async read, sync write).
entity unified_ram is
  generic (
    DEPTH_BYTES : positive := 1024 * 1024
  );
  port (
    clk        : in  std_logic;
    -- Instruction port (read)
    i_addr     : in  addr_t;
    i_rdata    : out word_t;
    -- Data port
    d_addr     : in  addr_t;
    d_we       : in  std_logic;
    d_be       : in  std_logic_vector(3 downto 0);
    d_wdata    : in  word_t;
    d_rdata    : out word_t;
    -- Host load / peek
    load_we    : in  std_logic := '0';
    load_addr  : in  addr_t := (others => '0');
    load_wdata : in  word_t := (others => '0');
    peek_addr  : in  addr_t := (others => '0');
    peek_rdata : out word_t
  );
end entity;

architecture rtl of unified_ram is
  constant DEPTH_WORDS : positive := DEPTH_BYTES / 4;
  type ram_t is array (0 to DEPTH_WORDS - 1) of word_t;
  signal ram : ram_t := (others => (others => '0'));

  -- Index within mapped window using low address bits (1 MiB => [19:2]).
  function idx(a : addr_t) return integer is
  begin
    return to_integer(unsigned(a(19 downto 2))) mod DEPTH_WORDS;
  end function;
begin
  process (clk)
    variable word : word_t;
    variable wi : integer;
  begin
    if rising_edge(clk) then
      if load_we = '1' then
        ram(idx(load_addr)) <= load_wdata;
      elsif d_we = '1' then
        wi := idx(d_addr);
        word := ram(wi);
        if d_be(0) = '1' then word(7 downto 0) := d_wdata(7 downto 0); end if;
        if d_be(1) = '1' then word(15 downto 8) := d_wdata(15 downto 8); end if;
        if d_be(2) = '1' then word(23 downto 16) := d_wdata(23 downto 16); end if;
        if d_be(3) = '1' then word(31 downto 24) := d_wdata(31 downto 24); end if;
        ram(wi) <= word;
      end if;
    end if;
  end process;

  i_rdata    <= ram(idx(i_addr));
  d_rdata    <= ram(idx(d_addr));
  peek_rdata <= ram(idx(peek_addr));
end architecture;
