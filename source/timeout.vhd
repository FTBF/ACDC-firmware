---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         timeout.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  timeout timer. It can use a slower clock than the calling function
--					  and therefore not be a burden on max frequency 
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 


entity timeoutTimer is
	port (
		clock	      : in std_logic;        
		len         : in natural;
		enable      : in std_logic;
		expired     : out std_logic);
end timeoutTimer;


architecture vhdl of timeoutTimer is


signal	latch: 	std_logic;
signal	latch_z: std_logic;


begin


-- detect falling edge of enable to give a pulse which resets the timer
edge_detect: process(enable, latch_z)
begin
	if (latch_z = '1') then
		latch <= '0';
	elsif (falling_edge(enable)) then		
		latch <= '1';
	end if;
end process;


latch_clear: process(clock)
begin
	if (falling_edge(clock)) then		
		latch_z <= latch;
	end if;
end process;




TIMEOUT_PROCESS: process(clock)
variable t: natural:= 0;
variable x: std_logic;
begin
   if (rising_edge(clock)) then		
      
		if (latch_z = '1') then t := 0; end if;		-- reset the count if enable was taken low
	
		x := '0';
		
		if (enable = '1') then
			
			if (t < len) then
				t := t + 1;
			else
				x := '1';
				t := 0;				-- clear timer so that 'expired' only goes high for a single pulse
			end if;
		
		end if;
		
		expired <= x;	
		
   end if;
end process;


               
               
			
end vhdl;































