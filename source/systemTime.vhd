---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      ANNIE - ACC
-- FILE:         systemTime.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  A fast 64 bit counter running at 320MHz
--						to give a high-resolution timestamp 
--						The reset is controlled so that the counter starts on a known sys clk phase
--
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use work.defs.all;
use work.components.fastCounter64;


entity systemTime_driver is
	PORT
	(
		clock		:	IN	clock_type;
		reset		:	in	std_logic;
		phase_mon: 	out std_logic;
		q			: 	out std_logic_vector(63 downto 0)
	);
end systemTime_driver;


architecture vhdl of systemTime_driver is


	
	
	signal	phase				: natural range 0 to 15;
	signal	sysClk			: std_logic;
	signal	sysClk_z			: std_logic;
	signal	sys_time_reset	: std_logic;
	signal	reset_z			: std_logic;
	
	
	
	
	
	

begin





------------------
-- SYSTEM TIME
------------------

-- 64-bit counter running at 320MHz
TIME_COUNTER: fastCounter64 port map (
		clock		=> clock.x8,
		reset		=> sys_time_reset,
		q			=> q
);









------------------------------
-- SYSTEM CLOCK PHASE COUNTER
------------------------------

-- determine the phase of the system clock (40MHz)
-- it is split into 8 phases defined by the rising edges of clock.x8
-- phase 0 starts at the rising edge of clock.sys
 
SYS_CLK_SYNC: process(clock.x8)
begin
	if (falling_edge(clock.x8)) then
		sysClk <= clock.sys;		
		sysClk_z <= sysClk;		
	end if;
end process;
	

PHASE_COUNTER: process(clock.x8)
begin
	if (rising_edge(clock.x8)) then
		if (phase = 0) then phase_mon <= '1'; else phase_mon <= '0'; end if;
		if (sysClk = '1' and sysClk_z = '0') then		-- rising edge on sysclk
			phase <= 1;
		else
			phase <= phase + 1;
		end if;
	end if;		
end process;
		

			



			
-------------------------------------
-- SYNCHRONOUS RESET
-------------------------------------

-- reset the time counter so that it always starts on same phase of the system clock
SYNC_RESET: process(clock.x8)
variable resetDone: boolean;
begin
	if (rising_edge(clock.x8)) then
		reset_z <= reset;
		
		if (reset_z = '1') then resetDone := false; end if;
		
		if (not resetDone and phase = 7) then		-- choose phase 7 then reset will be high in phase 0
			sys_time_reset <= '1';
			resetDone := true;
		else
			sys_time_reset <= '0';
		end if;
	end if;
end process;





	


end vhdl;











