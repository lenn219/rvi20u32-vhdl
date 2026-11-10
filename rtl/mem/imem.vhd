library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.rv32_pkg.all;

-- Word-addressed instruction memory.
-- Combinational read (classic 5-stage IF); sync write for TB/program load.
-- INIT_HEX:
--   "none"        — zeros
--   "uart_hello"  — embedded boot image below (no extra package; Vivado-safe)
--   <path>        — textio load of 8-hex-digit words (sim / optional FPGA)
entity imem is
  generic (
    DEPTH_WORDS : positive := IMEM_SIZE / 4;
    INIT_HEX    : string := "none"
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

  -- Embedded uart_hello.hex (regen: python3 sw/scripts/gen_imem_boot_pkg.py)
  -- Kept inside this architecture so synth needs no separate work.imem_boot_pkg.
  constant IMEM_BOOT_LEN : natural := 32;
  type imem_boot_t is array (0 to IMEM_BOOT_LEN - 1) of word_t;
  constant IMEM_BOOT_IMAGE : imem_boot_t := (
    -- BEGIN_IMEM_BOOT_IMAGE
    0 => x"200006b7",
    1 => x"00868793",
    2 => x"00468713",
    3 => x"00000613",
    4 => x"00164613",
    5 => x"00c6a023",
    6 => x"00bec837",
    7 => x"c2080813",
    8 => x"fff80813",
    9 => x"fe081ee3",
    10 => x"04800513",
    11 => x"024000ef",
    12 => x"06900513",
    13 => x"01c000ef",
    14 => x"00d00513",
    15 => x"014000ef",
    16 => x"00a00513",
    17 => x"00c000ef",
    18 => x"fc9ff06f",
    19 => x"00000013",
    20 => x"0007a583",
    21 => x"0015f593",
    22 => x"fe058ce3",
    23 => x"00a72023",
    24 => x"00008067",
    25 => x"00000013",
    26 => x"00000013",
    27 => x"00000013",
    28 => x"00000013",
    29 => x"00000013",
    30 => x"00000013",
    31 => x"00000013"
    -- END_IMEM_BOOT_IMAGE
  );

  impure function load_hex return ram_t is
    file f : text;
    variable l : line;
    variable mem : ram_t := (others => (others => '0'));
    variable idx : integer := 0;
    variable val : unsigned(31 downto 0);
    variable nibble : integer;
    variable c : character;
    variable status : file_open_status;
  begin
    if INIT_HEX = "none" or INIT_HEX'length = 0 then
      return mem;
    end if;

    -- Embedded UART bring-up image (no filesystem / package dependency).
    if INIT_HEX = "uart_hello" then
      for i in 0 to IMEM_BOOT_LEN - 1 loop
        if i < DEPTH_WORDS then
          mem(i) := IMEM_BOOT_IMAGE(i);
        end if;
      end loop;
      return mem;
    end if;

    file_open(status, f, INIT_HEX, read_mode);
    if status /= open_ok then
      report "imem: could not open INIT_HEX=" & INIT_HEX severity warning;
      return mem;
    end if;
    while not endfile(f) and idx < DEPTH_WORDS loop
      readline(f, l);
      if l'length >= 8 then
        val := (others => '0');
        for i in 0 to 7 loop
          c := l.all(i + 1);
          if c >= '0' and c <= '9' then
            nibble := character'pos(c) - character'pos('0');
          elsif c >= 'a' and c <= 'f' then
            nibble := character'pos(c) - character'pos('a') + 10;
          elsif c >= 'A' and c <= 'F' then
            nibble := character'pos(c) - character'pos('A') + 10;
          else
            nibble := 0;
          end if;
          val := shift_left(val, 4) or to_unsigned(nibble, 32);
        end loop;
        mem(idx) := std_logic_vector(val);
        idx := idx + 1;
      end if;
    end loop;
    file_close(f);
    return mem;
  end function;

  signal ram : ram_t := load_hex;
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
