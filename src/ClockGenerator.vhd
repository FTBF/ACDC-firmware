---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         clockGenerator.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  generates different clock frequencies for the firmware using
-- 					an on-board pll and also an external jitter cleaning pll
--
---------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.components.pll;
use work.components.acc_pll;
use work.components.serial_pll;
use work.LibDG.all;
use work.defs.all;



entity ClockGenerator is
	Port(
		clockIn		: 	in 		clockSource_type;				
		jcpll			:	out 		jcpll_ctrl_type;
		clock			: 	buffer	clock_type;
        PLL_ConfigRequest       : in std_logic;
        PLL_ConfigReg           : in std_logic_vector(31 downto 0);
        reset                   : in std_logic
	);		
end ClockGenerator;


architecture vhdl of ClockGenerator is


  -- constants 
  -- set depending on osc frequency
  constant TIMER_CLK_DIV_RATIO: natural:= 40000;	-- 40MHz / 40000 = 1kHz
  constant SERIAL_CLK_DIV_RATIO: natural:= 100;	-- 40MHz / 1000 = 40kHz	(exact freq is not too critical)

  signal PLL_ConfigRequest_sync : std_logic;
  signal serialClock	: std_logic := '0'; --default for sim
	
begin



clock.usb <= '0'; --clockIn.usb_IFCLK;
clock.wr100 <= clockIn.wr100;
	
-- system clocks
PLL_MAP : pll port map
(
	inclk0	=>		clockIn.jcpll, 
	c0			=>		clock.sys, 		--	40MHz
	c1			=>		clock.x4,	-- 160MHz
	c2			=>		clock.x8,	-- 320MHz
	c3			=>		open,		-- 10MHz
	locked	=>		clock.altpllLock
);     
				
acc_pll_inst : acc_pll PORT MAP (
		inclk0	 => clock.serial25,
		c0	 => clock.acc40,
		c1	 => clock.acc160,
		c2	 => clock.acc320,
		locked	 => clock.accpllLock
	);

serial_pll_inst: serial_pll
  port map (
    inclk0 => clockIn.accOsc,
    c0     => clock.serial125,
    c1     => clock.serial25,
    locked => clock.serialpllLock);
	
---------------------------------------
-- UPDATE CLOCK GENERATOR
---------------------------------------
WILK_CLK_GEN: process(clock.sys)
variable t: natural;
begin
	if (rising_edge(clock.sys)) then
		t := t + 1;
		if (t >= 4000000) then 	-- 100ms cycle time = 10Hz
			clock.update <= '1'; t := 0; 	
		else
			clock.update <= '0';
		end if;	
	end if;
end process;

	
	
	
	
	
	
	
---------------------------------------
-- JITTER CLEANER PROGRAMMING CLOCK GENERATOR
---------------------------------------
CLK_DIV_SERIAL: process(clock.acc40)		
variable t: natural range 0 to 65535;
begin
	if (rising_edge(clock.acc40)) then
		t := t + 1;
		if (t >= SERIAL_CLK_DIV_RATIO) then t := 0; end if;
		if (t >= SERIAL_CLK_DIV_RATIO /2) then serialClock <= '1'; else serialClock <= '0'; end if;
	end if;
end process;

	
	
	

	
---------------------------------------
-- JITTER CLEANER CONTROLLER	
---------------------------------------

	jcpll.testsync <= '0';			-- must be tied low
	jcpll.spi_clock <= not jcpll.SPI_latchEnable and serialClock;
	
	

-------------------------------------------------------------------------------


pll_configreq_sync: pulseSync2
  port map (
    src_clk      => clock.acc40,
    src_pulse    => PLL_ConfigRequest,
    src_aresetn  => not reset,
    dest_clk     => serialClock,
    dest_pulse   => PLL_ConfigRequest_sync,
    dest_aresetn => not reset);


process(serialClock)

	type STATE_TYPE is ( IDLE, PWR_UP, WRITE_DATA, GND_STATE); 
	variable state          : STATE_TYPE;	
	variable i	: natural;
	variable t	: natural:= 0;
	variable dataSel	: natural;
	variable data		: std_logic_vector(31 downto 0);
	
	begin
		if (falling_edge(serialClock)) then
		
			
		
			if (t < 40) then
			
				jcpll.SPI_latchEnable <= '1';
				jcpll.powerDown <= '0';		-- active low
                jcpll.outputEnable <= '0';
                jcpll.SPI_MOSI <= '1';
				state	:= PWR_UP;		
				t := t + 1;
		
		
			else
			
				case state is


					when PWR_UP =>
                        jcpll.powerDown <= '1';		-- rising edge on power down
                        jcpll.outputEnable <= '1';
						state	:= IDLE;	

					
					when IDLE =>
						jcpll.SPI_latchEnable <= '1';
						i := 0;		--data bit counter
						data := pll_configReg;
						if 	  pll_configRequest_sync= '1' then		
							state	:= WRITE_DATA;	
							jcpll.SPI_MOSI <= data(i);
							jcpll.SPI_latchEnable <= '1';
						else
							state	:= IDLE;	
						end if;													
											
						
					when WRITE_DATA =>					
						jcpll.SPI_latchEnable <= '0';
						jcpll.SPI_MOSI <= data(i);
						
						if (i >= 31) then 
							state := GND_STATE; 
						else 
							STATE	:= WRITE_DATA;
							i := i + 1;		-- number of serial data bits written
						end if;						

					when GND_STATE =>
						jcpll.SPI_latchEnable <= '1';
						jcpll.powerDown <= '1';
                        jcpll.outputEnable <= '1';
                        state := IDLE;
						
				end case;
			end if;
		end if;
		
	end process;	
	

	
end vhdl;

		
	
	
	
	
	
	
	
	
	
	
	
	
	
	

