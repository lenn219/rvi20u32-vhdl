library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.rv32_pkg.all;

-- Unit test: bit-bang UART TX 8N1, decode the wire.
entity tb_uart_tx is
  generic (runner_cfg : string);
end entity;

architecture tb of tb_uart_tx is
  constant CLKS : positive := 4;
  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal we_data  : std_logic := '0';
  signal wdata    : word_t := (others => '0');
  signal rdata_st : word_t;
  signal tx       : std_logic;
  signal tx_byte  : std_logic_vector(7 downto 0);
  signal tx_valid : std_logic;
  signal running  : boolean := true;
begin
  clk <= not clk after 5 ns when running else '0';

  uut : entity work.mmio_uart_tx
    generic map (CLKS_PER_BIT => CLKS)
    port map (
      clk => clk, rst => rst, we_data => we_data, wdata => wdata,
      rdata_st => rdata_st, tx => tx, tx_byte => tx_byte, tx_valid => tx_valid
    );

  main : process
    variable got : std_logic_vector(7 downto 0);
    variable i   : integer;

    procedure tick is
    begin
      wait until rising_edge(clk);
    end procedure;

    procedure wait_ready is
      variable guard : integer := 0;
    begin
      while rdata_st(0) = '0' and guard < 2000 loop
        tick;
        guard := guard + 1;
      end loop;
      check_equal(rdata_st(0), '1');
    end procedure;

    -- Sample mid-bit after observing start bit
    procedure recv_byte(variable b : out std_logic_vector(7 downto 0)) is
      variable bits : std_logic_vector(7 downto 0);
    begin
      while tx = '1' loop
        tick;
      end loop; -- start bit falling
      -- wait to middle of start bit
      for i in 1 to CLKS / 2 loop
        tick;
      end loop;
      check_equal(tx, '0'); -- still in start
      for i in 0 to 7 loop
        for j in 1 to CLKS loop
          tick;
        end loop;
        bits(i) := tx;
      end loop;
      for j in 1 to CLKS loop
        tick;
      end loop;
      check_equal(tx, '1'); -- stop
      b := bits;
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);

    while test_suite loop
      if run("tx_0x55_wire") then
        rst <= '1'; we_data <= '0'; tick; tick;
        rst <= '0'; tick;
        check_equal(tx, '1');
        wait_ready;

        wdata <= x"00000055";
        we_data <= '1';
        tick;
        we_data <= '0';
        tick; -- accept pulse was previous cycle; now busy transmitting
        check_equal(tx_byte, std_logic_vector'(x"55"));
        check_equal(rdata_st(1), '1'); -- busy

        recv_byte(got);
        check_equal(got, std_logic_vector'(x"55"));
        wait_ready;
        check_equal(rdata_st(1), '0');

      elsif run("tx_hi_string") then
        rst <= '1'; we_data <= '0'; tick; tick;
        rst <= '0'; tick;

        -- 'H' 'i' '\n'
        for i in 0 to 2 loop
          wait_ready;
          case i is
            when 0 => wdata <= x"00000048";
            when 1 => wdata <= x"00000069";
            when others => wdata <= x"0000000A";
          end case;
          we_data <= '1'; tick; we_data <= '0';
          recv_byte(got);
          case i is
            when 0 => check_equal(got, std_logic_vector'(x"48"));
            when 1 => check_equal(got, std_logic_vector'(x"69"));
            when others => check_equal(got, std_logic_vector'(x"0A"));
          end case;
        end loop;
        wait_ready;
      end if;
    end loop;

    running <= false;
    test_runner_cleanup(runner);
  end process;
end architecture;
