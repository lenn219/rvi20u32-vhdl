library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

-- 32 x 32-bit register file, x0 hardwired to 0.
-- Async read, sync write on rising clk. Write ignored when rst='1' or waddr=0.
entity regfile is
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    we     : in  std_logic;
    waddr  : in  reg_addr_t;
    wdata  : in  word_t;
    raddr1 : in  reg_addr_t;
    raddr2 : in  reg_addr_t;
    rdata1 : out word_t;
    rdata2 : out word_t
  );
end entity;

architecture rtl of regfile is
  type regs_t is array (0 to 31) of word_t;
  signal regs : regs_t := (others => (others => '0'));
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        regs <= (others => (others => '0'));
      elsif we = '1' and unsigned(waddr) /= 0 then
        regs(to_integer(unsigned(waddr))) <= wdata;
      end if;
    end if;
  end process;

  rdata1 <= (others => '0') when unsigned(raddr1) = 0
            else regs(to_integer(unsigned(raddr1)));
  rdata2 <= (others => '0') when unsigned(raddr2) = 0
            else regs(to_integer(unsigned(raddr2)));
end architecture;
