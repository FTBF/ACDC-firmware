---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      ANNIE - ACC
-- FILE:         fastCounter64.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  A 64-bit counter that is designed for speed 
--						Comprised of 4 x 16 bit counters
--						The carry signal is pipelined 
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;


entity fastCounter64 is
	PORT
	(
		clock		:	IN	STD_LOGIC;
		reset		:	in	std_logic;
		q			: 	out std_logic_vector(63 downto 0)
	);
end fastCounter64;


architecture vhdl of fastCounter64 is


	type counterArray_type is array (3 downto 0) of std_logic_vector(15 downto 0);	
	type maxCountArray_type is array (2 downto 0) of boolean;	
   signal	count			:	counterArray_type;	-- array of 16-bit counters
   signal	maxCount			:	std_logic_vector(2 downto 0);
	
	

begin



						
FAST_COUNTER : process(clock)
begin
	if (rising_edge(clock)) then
		
		if (reset = '1') then

			for i in 0 to 3 loop		
				count(i) <= x"0000";			
			end loop;
			
		
		else
			
			

			-- compare
			if (count(0) = x"FFFE") then maxCount(0) <= '1'; else maxCount(0) <= '0'; end if;	-- when counter 0 is at FFFF, maxCount(0) will be 1
			if (count(1) = x"FFFF") then maxCount(1) <= '1'; else maxCount(1) <= '0'; end if;	
			if (count(2) = x"FFFF") then maxCount(2) <= '1'; else maxCount(2) <= '0'; end if;	
			
			
			
			-- count
			count(0) <= count(0) + 1;
			if (maxCount(0) = '1') then count(1) <= count(1) + 1; end if;
			if (maxCount(1 downto 0) = "11") then count(2) <= count(2) + 1; end if;
			if (maxCount(2 downto 0) = "111") then count(3) <= count(3) + 1; end if;

	
			
		end if;
	end if;
end process;
	
	
	
	
-- output
q <= count(3) & count(2) & count(1) & count(0);




end vhdl;











