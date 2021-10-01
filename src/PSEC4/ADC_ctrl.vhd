---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         ADC_ctrl.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  
--
--------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.defs.all;


entity ADC_Ctrl is 
	port(
		clock			:	in		std_logic;			--40MHz	
		reset			:	in		std_logic;
		start			:	in		std_logic;
		RO_EN 		:	out	std_logic;
		adcClear		:	out	std_logic;
		adcLatch		:	out	std_logic;
		rampStart	:	out	std_logic;
		rampDone		:	out	std_logic
);
end ADC_Ctrl;

architecture vhdl of ADC_Ctrl is
	
	
	signal 	RAMP_CNT		:	std_logic_vector(10 downto 0);


begin
	

----------------------------------------------------------------
--PSEC-4 WILK. ADC CONTROL
---------------------------------------------------------------- 		
process(clock)
variable i : integer range 50 downto 0;
type state_type is (INIT,  RAMPING, EXTLATCH_RISE, EXTLATCH_FALL,  RAMP_DONE);
variable state	:	state_type;
variable startFlag: boolean;
begin
	if (falling_edge(clock)) then
		
		if (reset = '1') then 
			
			RAMPStart	<= '0';
			rampDone 	<= '0';
			RAMP_CNT 	<= (others => '0');
			state			:= INIT;
			adcClear 	<= '1';
			adcLatch 	<= '0'; --latch follows trigger for now
			i 				:= 0;
			RO_EN 		<= '1';
			startFlag := false;

		else
		
			if (start = '1')  then startFlag := true; end if;		-- latch the start flag
				
		
			case state is
				
				-------------------------						
				when INIT =>
				
					if (startFlag) then
						i	:= i+1;   -- some setup time
						adcLatch <= '1';
						RO_EN 	<= '0';
						RAMPStart <= '1';
						if i = 12 then
							i	:= 0;
							RAMPStart	<= '0';
							state	:= RAMPING;
						end if;
					end if;
					
				-------------------------	
				when RAMPING =>					
					adcClear 	<= '0';  	 -- ramp active low
					RAMP_CNT 	<= RAMP_CNT + 1;
					if RAMP_CNT = WILKRAMPCOUNT then  --set ramp length w.r.t. clock
						RAMP_CNT 	<= (others => '0');
							RO_EN 		<='1';
						state 	:= EXTLATCH_RISE;
					end if;
			
				-------------------------
				when EXTLATCH_RISE =>   --latch transparency pulse
					i 	:= i+1;
					if i = 1 then
						i	:= 0;
						state	:= EXTLATCH_FALL;
					end if;
					
				
				when EXTLATCH_FALL =>
					i	:= i+1;
					if i = 1  then	
						i	:= 0;
						state := RAMP_DONE;
					end if;

				-------------------------
				when RAMP_DONE =>
					rampDone 	<= '1';
			
			end case;
		end if;
	end if;
end process;		


	
	
	
	
		
	


	
									
								
							
							
						
end vhdl;
	
		
		