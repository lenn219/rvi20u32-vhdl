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
    variable prod_ss : signed(63 downto 0);
    variable prod_uu : unsigned(63 downto 0);
    variable prod_su : signed(65 downto 0);
    variable a_s33 : signed(32 downto 0);
    variable b_u33 : signed(32 downto 0);
    variable a_s : signed(31 downto 0);
    variable b_s : signed(31 downto 0);
    variable a_u : unsigned(31 downto 0);
    variable b_u : unsigned(31 downto 0);
    variable q_s : signed(31 downto 0);
    variable r_s : signed(31 downto 0);
    variable q_u : unsigned(31 downto 0);
    variable r_u : unsigned(31 downto 0);
  begin
    a_s := signed(a);
    b_s := signed(b);
    a_u := unsigned(a);
    b_u := unsigned(b);
    result := (others => '0');

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

      when ALU_MUL =>
        prod_ss := a_s * b_s;
        result := std_logic_vector(prod_ss(31 downto 0));
      when ALU_MULH =>
        prod_ss := a_s * b_s;
        result := std_logic_vector(prod_ss(63 downto 32));
      when ALU_MULHU =>
        prod_uu := a_u * b_u;
        result := std_logic_vector(prod_uu(63 downto 32));
      when ALU_MULHSU =>
        a_s33 := resize(a_s, 33);
        b_u33 := signed(std_logic_vector'('0' & b));
        prod_su := a_s33 * b_u33;
        result := std_logic_vector(prod_su(63 downto 32));

      when ALU_DIV =>
        if b_u = 0 then
          result := (others => '1'); -- -1
        elsif a = x"80000000" and b = x"FFFFFFFF" then
          result := x"80000000"; -- overflow
        else
          q_s := a_s / b_s;
          result := std_logic_vector(q_s);
        end if;
      when ALU_DIVU =>
        if b_u = 0 then
          result := (others => '1');
        else
          q_u := a_u / b_u;
          result := std_logic_vector(q_u);
        end if;
      when ALU_REM =>
        if b_u = 0 then
          result := a;
        elsif a = x"80000000" and b = x"FFFFFFFF" then
          result := (others => '0');
        else
          r_s := a_s rem b_s;
          result := std_logic_vector(r_s);
        end if;
      when ALU_REMU =>
        if b_u = 0 then
          result := a;
        else
          r_u := a_u rem b_u;
          result := std_logic_vector(r_u);
        end if;
    end case;
    y <= result;
  end process;
end architecture;
