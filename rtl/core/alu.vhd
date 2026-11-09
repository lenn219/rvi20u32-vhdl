library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv32_pkg.all;

entity alu is
  port (
    op      : in  alu_op_t;
    a       : in  word_t;
    b       : in  word_t;
    y       : out word_t;
    cmp_eq  : out std_logic;
    cmp_lt  : out std_logic;
    cmp_ltu : out std_logic
  );
end entity;

architecture rtl of alu is
  signal shamt : integer range 0 to 31;
begin
  shamt <= to_integer(unsigned(b(4 downto 0)));

  cmp_eq  <= '1' when a = b else '0';
  cmp_lt  <= '1' when signed(a) < signed(b) else '0';
  cmp_ltu <= '1' when unsigned(a) < unsigned(b) else '0';

  process (op, a, b, shamt)
    variable result : word_t;
  begin
    case op is
      when ALU_ADD =>
        result := std_logic_vector(unsigned(a) + unsigned(b));
      when ALU_SUB =>
        result := std_logic_vector(unsigned(a) - unsigned(b));
      when ALU_AND =>
        result := a and b;
      when ALU_OR =>
        result := a or b;
      when ALU_XOR =>
        result := a xor b;
      when ALU_SLL =>
        result := std_logic_vector(shift_left(unsigned(a), shamt));
      when ALU_SRL =>
        result := std_logic_vector(shift_right(unsigned(a), shamt));
      when ALU_SRA =>
        result := std_logic_vector(shift_right(signed(a), shamt));
      when ALU_SLT =>
        if signed(a) < signed(b) then
          result := (others => '0');
          result(0) := '1';
        else
          result := (others => '0');
        end if;
      when ALU_SLTU =>
        if unsigned(a) < unsigned(b) then
          result := (others => '0');
          result(0) := '1';
        else
          result := (others => '0');
        end if;
      when ALU_COPY_A =>
        result := a;
      when ALU_COPY_B =>
        result := b;
    end case;
    y <= result;
  end process;
end architecture;
