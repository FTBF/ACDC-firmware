---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         Wilkinson_feedback_loop.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  Essentially a frequency locked loop
---------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.defs.all;



entity Wilkinson_Feedback_Loop is
	Port (
        reset    				: in std_logic;
        clock			      : in clock_type; --One period of clock.wilkUpdate defines how long we count Wilkinson rate pulses
        WILK_MONITOR_BIT   : in std_logic;
        target     			: in natural; 	-- target number of rising edges on  wilk monitor bit in the specified measuring period (100ms)
        current	 			: out natural;	-- the current count value
        dacValue   			: buffer natural range 0 to 4095;
		  lock					: out std_logic
        );
end Wilkinson_Feedback_Loop;

architecture Behavioral of Wilkinson_Feedback_Loop is

		constant MaxCount	: natural := 65500;	
		signal countEnable 	: std_logic := '0';
      signal clear				: std_logic := '0';
      signal count        	: natural;
		  
begin
        
		  
process(clock.sys)
variable step			: natural;
variable newValue		: natural;
variable error			: natural;
variable sign			: std_logic;
constant InitValue 	: natural:= 16#820#; 
constant MinValue 	: natural:= 16#400#; 
constant MaxValue 	: natural:= 16#999#; 
type STATE_TYPE is ( CLEAR_COUNT, WAIT_FOR_START_SIGNAL, START, STOP, LATCH, UPDATE, DELAY);
variable state: STATE_TYPE := CLEAR_COUNT;
variable t: natural;
begin
	if (rising_edge(clock.sys)) then
						
		if (reset = '1') then
			
			dacValue <= InitValue;
			
			
		else
		
			case state is

			
				when CLEAR_COUNT =>	
					
					countEnable <= '0';
               clear <= '1';
					state := WAIT_FOR_START_SIGNAL;
					
					
				when WAIT_FOR_START_SIGNAL =>
					
               clear <= '0';
					if (clock.wilkUpdate = '1') then		-- wait for timing start marker (10Hz clock)
						state := START;
					end if;

					
				when START =>

					countEnable <= '1';
					if (clock.wilkUpdate = '1') then		-- wait for timing stop marker (10Hz clock)
						state := STOP;
					end if;
					
					
				when STOP =>

					countEnable <= '0';
					state := LATCH;
					
					
				when LATCH =>	
            
					current <= count;
					state := UPDATE;
				
				
				when UPDATE =>
                                       
					-- check the size of the error and which direction it is in error
					if (current > target) then 
						sign := '1'; 	-- measured frequency is too high
						error := current - target;
					else
						sign := '0';	-- measured frequency is too low
						error := target - current;
					end if;
						
					-- set step size
					if (error > 200) then step := 10; else step := 1; end if;
					
					-- calc new value
					if (error > 2) then
						if (sign = '1') then
							newValue := dacValue + step;
							if (newValue > MaxValue) then newValue := MaxValue; end if;
						else
							newValue := dacValue - step;
							if (newValue < MinValue) then newValue := MinValue; end if;
						end if;					
					end if;
					
					-- set the new dac value
					dacValue <= newValue;
					
					-- lock detect
					if (error <= 100) then lock <= '1'; else lock <= '0'; end if;
					
               t := 0;
					state := DELAY;
					
					
            when DELAY =>					
					
					if (clock.wilkUpdate = '1') then		-- 10Hz clock
						t := t + 1;
						if (t >= 3) then 
							state := CLEAR_COUNT;
						end if;
					end if;
                                       

			end case;
		end if;
	end if;
end process;

		  
		  
COUNTER: process(WILK_MONITOR_BIT, countEnable, clear) 
begin              
	if (clear = '1') then
		count <= 0;
   elsif ( countEnable = '1' and rising_edge(WILK_MONITOR_BIT) ) then
      if (count < MaxCount) then count <= count + 1; end if;
   end if;
end process;

        
		  




end Behavioral;



























