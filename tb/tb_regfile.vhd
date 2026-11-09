library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

entity tb_regfile is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_regfile is
  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal we     : std_logic := '0';
  signal waddr  : reg_addr_t := (others => '0');
  signal wdata  : word_t := (others => '0');
  signal raddr1 : reg_addr_t := (others => '0');
  signal raddr2 : reg_addr_t := (others => '0');
  signal rdata1 : word_t;
  signal rdata2 : word_t;
  signal running : boolean := true;
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.regfile
    port map (
      clk => clk, rst => rst, we => we,
      waddr => waddr, wdata => wdata,
      raddr1 => raddr1, raddr2 => raddr2,
      rdata1 => rdata1, rdata2 => rdata2
    );

  main : process
    procedure tick is
    begin
      wait until rising_edge(clk);
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("x0_hardwired") then
        rst <= '1'; we <= '0';
        tick; tick;
        rst <= '0';
        -- Attempt write to x0
        waddr <= "00000"; wdata <= x"DEADBEEF"; we <= '1';
        tick;
        we <= '0';
        raddr1 <= "00000";
        wait for 1 ns;
        check_equal(rdata1, std_logic_vector'(x"00000000"));
      elsif run("write_read_x1_x2") then
        rst <= '1'; we <= '0';
        tick; tick;
        rst <= '0';
        waddr <= "00001"; wdata <= to_word(42); we <= '1';
        tick;
        waddr <= "00010"; wdata <= to_word(99); we <= '1';
        tick;
        we <= '0';
        raddr1 <= "00001"; raddr2 <= "00010";
        wait for 1 ns;
        check_equal(signed(rdata1), 42);
        check_equal(signed(rdata2), 99);
      elsif run("reset_clears") then
        rst <= '0';
        waddr <= "00011"; wdata <= to_word(7); we <= '1';
        tick;
        we <= '0';
        rst <= '1';
        tick; tick;
        rst <= '0';
        raddr1 <= "00011";
        wait for 1 ns;
        check_equal(rdata1, std_logic_vector'(x"00000000"));
      end if;
    end loop;

    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
