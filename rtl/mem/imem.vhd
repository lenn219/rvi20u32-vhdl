library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.rv32_pkg.all;
use work.imem_boot_pkg.all;

-- Word-addressed instruction memory.
-- Combinational read (classic 5-stage IF); sync write for TB/program load.
-- INIT_HEX:
--   "none"        — zeros
--   "uart_hello"  — embedded boot image (imem_boot_pkg; reliable for Vivado)
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

    -- Embedded UART bring-up image (no filesystem dependency in synth).
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
