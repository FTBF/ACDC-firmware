---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         LED_driver.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  state machine to generate flash signals to the leds
--	 					or monostable operation - depending on the mode setting
--						Input variable 'setup' contains the mode and timing info for each led
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;



entity LED_driver is
	port (
		clock	      : in std_logic;        
		setup			: in ledSetup_type;
		output      : out std_logic
	);
end LED_driver;


architecture vhdl of LED_driver is



	signal	latch:			std_logic;
	signal	input_z:			std_logic;
	signal	edgeDetect:		std_logic;
	signal	latchReset:		std_logic;
	signal	state:			std_logic;
	signal	output_clocked: std_logic;
	
	


begin




-- multiplexer for direct output
output <= setup.input when (setup.mode = ledMode.direct) else output_clocked;





------------------------------------
--	LED CTRL
------------------------------------

LED_edge_detect: process(latchReset, setup.input)		-- edge detect used for monostable mode (in case i/p is on a different clock)
begin
	if (latchReset = '1') then 
		latch <= '0';
	elsif (rising_edge(setup.input)) then
		latch <= '1';  
	end if;
end process;


-- process led state according to the settings
LED_ctrl_process: process(clock)
variable t_flash: natural;
variable t_mono: natural;
begin
	if (rising_edge(clock)) then						
			
			
		edgeDetect <= latch;	-- synchronize the detected edge
		input_z <= setup.input;	-- synchronize input to the processing clock
			
			
			
		-- flash period counter
		t_flash := t_flash + 1;
		if (t_flash >= setup.period) then t_flash := 0; end if;
			
			
			
		case setup.mode is
						
						
						
			when ledMode.flashing =>			

				if (t_flash < setup.onTime) then
					state <= input_z; 
				else
					state <= '0';
				end if;				
			
			
			
			when ledMode.monostable =>
				
				if (t_mono > 0) then t_mono := t_mono - 1; end if;			
				if (input_z = '1' or edgeDetect = '1') then t_mono := setup.onTime; end if;
				if (t_mono > 0) then state <= '1'; else state <= '0';	end if;
			
			
			
			when others => 
				
				state <= '0';
				
				
				
		end case;
			
			
		output_clocked <= state; 
			
			
	elsif (falling_edge(clock)) then
		latchReset <= edgeDetect;		-- clear the edge detect latch
	end if;
end process;
				



              
			
end vhdl;































