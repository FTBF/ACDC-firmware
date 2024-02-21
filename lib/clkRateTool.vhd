library IEEE; 
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;
use work.LibDG.all;



entity clkRateTool is
  Generic(
		  CLK_REF_RATE_HZ  : natural := 100000000;
		  COUNTER_WIDTH    : natural := 32;
		  MEASURE_PERIOD_s : natural := 1;
		  MEASURE_TIME_s   : real := 0.001
		  );

	Port(
	  reset_in   : in std_logic;
	  clk_ref    : in std_logic;
	  clk_test   : in std_logic;
	  value      : out std_logic_vector(COUNTER_WIDTH-1 downto 0)
	);
end clkRateTool;

architecture vhdl of clkRateTool is
	constant REF_ROLLOVER : natural := (CLK_REF_RATE_HZ * MEASURE_PERIOD_s);
	constant SAMPLE_TIME  : natural := natural(real(CLK_REF_RATE_HZ) * MEASURE_TIME_s);

	signal refCtr         : natural;
	signal rateCtr        : natural;
    signal rateCtr_gray        : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal rateCtr_bin         : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal rateCtr_gray_refclk : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal rateCtr_refclk : std_logic_vector(COUNTER_WIDTH-1 downto 0);

	signal async_reset           : std_logic;
	signal async_reset_clk_test : std_logic;

begin
  

  --=======================================================================
  -- reference clock domain
  --=======================================================================

  
  counter: process(clk_ref)
  begin
    if rising_edge(clk_ref) then
		if (reset_in = '1') then
			refCtr <= 0;
			async_reset <= '1';
			value <= (others => '1');
		else
			-- When we start a new measurement cycle, reset the test clock
			-- counter and send the ref clock counter
			if (refCtr = REF_ROLLOVER) then
				refCtr <= 0;
				async_reset <= '1';
			else
				refCtr <= refCtr + 1;
				async_reset <= '0';
			end if;

			-- After we're done measuring, take the value in the test clock counter
			-- Add 6 to account for the systematic offset caused by the clock
			-- domain crossers.
			if (refCtr = SAMPLE_TIME) then
				value <= std_logic_vector(unsigned(rateCtr_refclk) + 6);
			end if;
		end if;
    end if;
    
  end process;

  --value <= std_logic_vector(to_unsigned(rateCtr, COUNTER_WIDTH));
  
  -- If the test clock isn't running, this reset will not deassert, but
  -- this is actually just fine.  The result of that is that rateCtr will
  -- stay at 0, which is exactly what happens anyway if the test clock
  -- isn't running.
  -- Anyway, this CDC block should make timing closure a little easier
  reset_Sync : sync_Bits_Altera
    generic map (
      BITS  => 1,
      INIT  => x"00000000",
      SYNC_DEPTH => 2
      )
    port map (
      Clock => clk_test,
      Input(0) => async_reset,
      Output(0) => async_reset_clk_test
      );

  -- This CDC block helps make timing closure easier by moving the rateCtr
  -- into the clk_ref domain.
  --convert rate counter to gray code
  rateCtr_bin <= std_logic_vector(to_unsigned(rateCtr, COUNTER_WIDTH));
  rateCtr_gray_conv : process(clk_test)
  begin
    if rising_edge(clk_test) then
      rateCtr_gray <= rateCtr_bin xor ('0' & rateCtr_bin(COUNTER_WIDTH - 1 downto 1));
    end if;
  end process;

  --transfer gray count value to clk_ref domain
  rateCtr_Sync : sync_Bits_Altera
    generic map (
      BITS  => COUNTER_WIDTH,
      INIT  => x"00000000",
      SYNC_DEPTH => 2
      )
    port map (
      Clock => clk_ref,
      Input => rateCtr_gray,
      Output => rateCtr_gray_refclk
      );

  -- convert gary count back to binary count 
  rateCtr_bin_conv : process(all)
  begin
      rateCtr_refclk(COUNTER_WIDTH - 1) <= rateCtr_gray_refclk(COUNTER_WIDTH - 1);
      rateCtr_refclk(COUNTER_WIDTH - 2 downto 0) <= rateCtr_refclk(COUNTER_WIDTH - 1 downto 1) xor rateCtr_gray_refclk(COUNTER_WIDTH - 2 downto 0);
--      for i in (COUNTER_WIDTH - 2) to 0 loop
--        rateCtr_refclk(i) <= rateCtr_refclk(i+1) xor rateCtr_gray_refclk(i);
--      end loop;
  end process;
  

--=======================================================================
  -- test clock domain
  --=======================================================================

  test_domain : process(clk_test, async_reset_clk_test)
    begin
      if (async_reset_clk_test = '1') then
        rateCtr <= 0;
      else
        if rising_edge(clk_test) then
          rateCtr <= rateCtr + 1;
        end if;
      end if;
	end process;

end vhdl;
