library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

entity tb_alu is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_alu is
  signal op      : alu_op_t := ALU_ADD;
  signal a, b, y : word_t := (others => '0');
  signal cmp_eq, cmp_lt, cmp_ltu : std_logic;
begin
  uut : entity work.alu
    port map (
      op => op, a => a, b => b, y => y,
      cmp_eq => cmp_eq, cmp_lt => cmp_lt, cmp_ltu => cmp_ltu
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("add") then
        op <= ALU_ADD; a <= to_word(5); b <= to_word(7); wait for 1 ns;
        check_equal(signed(y), 12);
      elsif run("sub") then
        op <= ALU_SUB; a <= to_word(10); b <= to_word(3); wait for 1 ns;
        check_equal(signed(y), 7);
      elsif run("and_or_xor") then
        op <= ALU_AND; a <= x"F0F0F0F0"; b <= x"0FF00FF0"; wait for 1 ns;
        check_equal(y, std_logic_vector'(x"00F000F0"));
        op <= ALU_OR; wait for 1 ns;
        check_equal(y, std_logic_vector'(x"FFF0FFF0"));
        op <= ALU_XOR; wait for 1 ns;
        check_equal(y, std_logic_vector'(x"FF00FF00"));
      elsif run("shifts") then
        op <= ALU_SLL; a <= x"00000001"; b <= x"00000004"; wait for 1 ns;
        check_equal(y, std_logic_vector'(x"00000010"));
        op <= ALU_SRL; a <= x"80000000"; b <= x"00000004"; wait for 1 ns;
        check_equal(y, std_logic_vector'(x"08000000"));
        op <= ALU_SRA; a <= x"80000000"; b <= x"00000004"; wait for 1 ns;
        check_equal(y, std_logic_vector'(x"F8000000"));
      elsif run("slt_sltu") then
        op <= ALU_SLT; a <= to_word(-1); b <= to_word(1); wait for 1 ns;
        check_equal(y, std_logic_vector'(x"00000001"));
        op <= ALU_SLTU; a <= x"FFFFFFFF"; b <= x"00000001"; wait for 1 ns;
        check_equal(y, std_logic_vector'(x"00000000"));
      elsif run("compares") then
        a <= to_word(3); b <= to_word(3); wait for 1 ns;
        check_equal(cmp_eq, '1');
        a <= to_word(-5); b <= to_word(2); wait for 1 ns;
        check_equal(cmp_lt, '1');
        a <= x"00000001"; b <= x"FFFFFFFF"; wait for 1 ns;
        check_equal(cmp_ltu, '1');
      elsif run("copy") then
        op <= ALU_COPY_B; a <= to_word(1); b <= to_word(99); wait for 1 ns;
        check_equal(signed(y), 99);
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;
end architecture;
