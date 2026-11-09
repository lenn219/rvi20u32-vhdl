library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

entity forward_unit is
  port (
    idex_rs1      : in  reg_addr_t;
    idex_rs2      : in  reg_addr_t;
    idex_use_rs1  : in  std_logic;
    idex_use_rs2  : in  std_logic;
    exmem_rd      : in  reg_addr_t;
    exmem_we      : in  std_logic;
    exmem_load    : in  std_logic;
    memwb_rd      : in  reg_addr_t;
    memwb_we      : in  std_logic;
    fwd_a         : out std_logic_vector(1 downto 0); -- 00=reg 10=exmem 01=memwb
    fwd_b         : out std_logic_vector(1 downto 0)
  );
end entity;

architecture rtl of forward_unit is
begin
  process (all)
  begin
    fwd_a <= "00";
    fwd_b <= "00";

    -- MEM/WB first, then EX/MEM overrides (higher priority)
    if idex_use_rs1 = '1' and unsigned(idex_rs1) /= 0 then
      if memwb_we = '1' and memwb_rd = idex_rs1 then
        fwd_a <= "01";
      end if;
      if exmem_we = '1' and exmem_load = '0' and exmem_rd = idex_rs1 then
        fwd_a <= "10";
      end if;
    end if;

    if idex_use_rs2 = '1' and unsigned(idex_rs2) /= 0 then
      if memwb_we = '1' and memwb_rd = idex_rs2 then
        fwd_b <= "01";
      end if;
      if exmem_we = '1' and exmem_load = '0' and exmem_rd = idex_rs2 then
        fwd_b <= "10";
      end if;
    end if;
  end process;
end architecture;
