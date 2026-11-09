library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

entity hazard_unit is
  port (
    idex_mem_read : in  std_logic;
    idex_rd       : in  reg_addr_t;
    ifid_rs1      : in  reg_addr_t;
    ifid_rs2      : in  reg_addr_t;
    ifid_use_rs1  : in  std_logic;
    ifid_use_rs2  : in  std_logic;
    redirect      : in  std_logic;
    stall         : out std_logic;
    flush_ifid    : out std_logic;
    flush_idex    : out std_logic
  );
end entity;

architecture rtl of hazard_unit is
  signal load_use : std_logic;
begin
  load_use <= '1' when idex_mem_read = '1'
                and unsigned(idex_rd) /= 0
                and (
                  (ifid_use_rs1 = '1' and ifid_rs1 = idex_rd) or
                  (ifid_use_rs2 = '1' and ifid_rs2 = idex_rd)
                )
              else '0';

  stall      <= load_use;
  -- On taken branch/jump: flush IF/ID and ID/EX. Load-use stall wins over redirect flush of IF/ID hold.
  flush_ifid <= redirect and not load_use;
  flush_idex <= redirect or load_use; -- bubble into EX on stall or redirect
end architecture;
