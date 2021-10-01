---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         selfTrigger.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Aug 2020
--
-- DESCRIPTION:  self trigger processes
---------------------------------------------------------------------------------

	
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.defs.all;
use work.LibDG.all;



entity selfTrigger is
	port(
			clock						: in	clock_type;
			reset						: in	std_logic;   
			PSEC4_in					: in 	PSEC4_in_array_type;
			testMode					: in  testMode_type;
			trigSetup				: in 	trig_type;
			selfTrig					: in	selfTrig_type;
			trig_out					: out	std_logic;
			rateCount				: out selfTrig_rateCount_array
			);
end selfTrigger;

architecture vhdl of selfTrigger is


	signal	self_trig_sync: array6;
	signal	selfTrig_mask_z: array6;
	signal	psec_chip_sum: natArray4;
	signal 	rateCount_z: selfTrig_rateCount_array;
	signal	rateCount_valid: std_logic;
	signal	rateCount_valid_z: std_logic;
	signal 	reset_z: std_logic;
	signal 	eventAndTime_reset_z: std_logic;
	signal	selfTrig_OR_combined: std_logic;
	
	signal	rate_count_latch_reset: array6;
	signal	rate_count_latch_z: array6;
	signal	rate_count_latch: array6;
	signal	asic_sum: natArray3;
	signal	sum: natArray5;
	signal	selfTrig_ASIC_OR: std_logic_vector(N-1 downto 0);

	
	-- coincidence detection
	signal	coincidence_trig: std_logic;
	
	
	
	
begin  






---------------------------------------
-- SELF-TRIG 'OR'
---------------------------------------
-- unclocked, no clock jitter
-- provides the lowest-latency method of detecting a trigger on any psec self-trig channel
SELF_TRIG_OR_GATE: process(PSEC4_in, selfTrig.mask)
variable s: std_logic;
begin
	s := '0';
	for i in 0 to N-1 loop		-- for each PSEC4 chip
		for j in 0 to M-1 loop		-- for each channel of the PSCE4 chip
			s := s or (PSEC4_in(i).trig(j) and selfTrig.mask(i)(j));
		end loop;
		selfTrig_OR_combined <= s;
	end loop;
end process;









---------------------------------------
-- SELF-TRIG SUM
---------------------------------------
-- add the total number of active self trig bits
--
-- synchronize the self-trig bits to fast clock (160MHz)
-- This is essential if doing any prcoessing other than simple combinational logic, such as addition
-- signals are gated with the enable signal
SELF_TRIG_ADDER: process(clock.x4)
variable s: natural range 0 to 7;
variable self_trig_sum: natural range 0 to 31;
begin
	if (rising_edge(clock.x4)) then		
		for i in 0 to N-1 loop		-- for each psec4 device
			s := 0;
			for j in 0 to M-1 loop		-- for each channel of the psec4 device
				selfTrig_mask_z(i)(j) <= selfTrig.mask(i)(j); -- sync the enable signal to fast clock
				self_trig_sync(i)(j) <= PSEC4_in(i).trig(j) and selfTrig_mask_z(i)(j);
				if (self_trig_sync(i)(j) = '1') then s := s + 1; end if;
			end loop;
			asic_sum(i) <= s;		-- sum of active self-trig outputs for the psec4 chip
		end loop;
		self_trig_sum := asic_sum(0) + asic_sum(1) + asic_sum(2) + asic_sum(3) + asic_sum(4);	

-- CHANNEL COINCIDENCE CHECK
-- check all 30 channels for level of coincidence 

		if (self_trig_sum >= selfTrig.coincidence_min) then
			coincidence_trig <= '1';
		else 
			coincidence_trig <= '0';
		end if;
	end if;
end process;










---------------------------------------
-- TRIG OUT
---------------------------------------

TRIG_GEN: process(selfTrig.use_coincidence, coincidence_trig, selfTrig_OR_combined)
begin
	if (selfTrig.use_coincidence = '1') then
		trig_out <= coincidence_trig;
	else
		trig_out <= selfTrig_OR_combined;
	end if;
end process;





















------------------------------
-- SELF TRIG RATE COUNTER
------------------------------
-- count the number of self trig events in one second on each channel of each psec chip (30 channels in total)


-- latch rising edge of self-trig signal from psec chip
SELF_TRIG_RATE_COUNT_N: for i in 0 to N-1 generate 
	SELF_TRIG_RATE_COUNT_M: for j in 0 to M-1 generate 
		SLEF_TRIG_EDGE_DETECT: risingEdgeDetect port map(clock.sys, PSEC4_in(i).trig(j), rate_count_latch_z(i)(j));
	end generate;
end generate;



SELFTRIG_RATE_COUNT_GEN: process(clock.sys)
variable count: selfTrig_rateCount_array;
variable t: natural;
begin
	if (rising_edge(clock.sys)) then
		
		
		if (reset = '1' or trigSetup.eventAndTime_reset = '1') then
		
			t := 0;
			
			for i in 0 to N-1 loop
				for j in 0 to M-1 loop
					count(i,j) := 0; 
					rateCount(i,j) <= 0;
				end loop;
			end loop;
			
			
			
		else
		
		
			for i in 0 to N-1 loop
				for j in 0 to M-1 loop
					if (rate_count_latch_z(i)(j) = '1' and count(i,j) < trigRate_MaxCount) then 
						count(i,j) := count(i,j) + 1; 
					end if;
				end loop;
			end loop;
			
			t := t + 1;		-- clock cycle counter
			 
			if (t = 40000000) then		-- after 1s record the counts and then reset them

				t := 0;
				
				for i in 0 to N-1 loop
					for j in 0 to M-1 loop
						rateCount(i,j) <= count(i,j);
						count(i,j) := 0;
					end loop;
				end loop;
				
			end if;
			
		end if;
		
	end if;
end process;









	
end vhdl;






