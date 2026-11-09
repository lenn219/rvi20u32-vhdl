library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

entity tb_dmem is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_dmem is
  signal clk   : std_logic := '0';
  signal addr  : addr_t := (others => '0');
  signal we    : std_logic := '0';
  signal be    : std_logic_vector(3 downto 0) := (others => '0');
  signal wdata : word_t := (others => '0');
  signal rdata : word_t;
  signal running : boolean := true;
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.dmem
    generic map (DEPTH_BYTES => 256)
    port map (
      clk => clk, addr => addr, we => we, be => be,
      wdata => wdata, rdata => rdata
    );

  main : process
    procedure tick is
    begin
      wait until rising_edge(clk);
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("word_rw") then
        addr <= x"00000004"; wdata <= x"A1B2C3D4"; be <= "1111"; we <= '1';
        tick;
        we <= '0';
        tick;
        wait for 1 ns;
        check_equal(rdata, std_logic_vector'(x"A1B2C3D4"));
      elsif run("byte_enable") then
        addr <= x"00000008"; wdata <= x"FFFFFFFF"; be <= "1111"; we <= '1';
        tick;
        wdata <= x"0000005A"; be <= "0001"; we <= '1';
        tick;
        we <= '0';
        tick;
        wait for 1 ns;
        check_equal(rdata, std_logic_vector'(x"FFFFFF5A"));
      end if;
    end loop;

    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
