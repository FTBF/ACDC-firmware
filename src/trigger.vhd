---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         trigger.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         May 2021
--
-- DESCRIPTION:  trigger processes
---------------------------------------------------------------------------------

	
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.defs.all;
use work.LibDG.pulseSync;



entity trigger is
	port(
			clock						: in	clock_type;
			reset						: in	std_logic;   
			systemTime				: in  std_logic_vector(63 downto 0);
			testMode					: in  testMode_type;
			trigSetup				: in	trig_type;
			selfTrig					: in 	selfTrig_type;
			trigInfo					: out	trigInfo_type;
			acc_trig					: in	std_logic;	-- trig from central card (LVDS)
			sma_trig					: in	std_logic;	-- on-board SMA input
			self_trig				: in	std_logic;	
			digitize_request		: out	std_logic;
			transfer_request		: out	std_logic;
			digitize_done			: in	std_logic;
			transfer_enable		: out std_logic;	
			transfer_done			: in	std_logic;
			eventCount				: out	std_logic_vector(31 downto 0);
			ppsCount					: buffer std_logic_vector(31 downto 0);
			beamGateCount			: buffer std_logic_vector(31 downto 0);
			timestamp				: out std_logic_vector(63 downto 0);
			beamgate_timestamp	: out std_logic_vector(63 downto 0);
			frameType				: out natural;
			acc_beamGate			: buffer std_logic;
			trig_detect 			: out std_logic;
			trig_valid 				: out std_logic;
			trig_abort 				: out std_logic;
			signal_trig_detect	: buffer std_logic;
			pps_detect 				: out std_logic;
			busy						: out std_logic;
			trig_event				: buffer std_logic;
			trig_clear				: buffer std_logic;
			trig_out					: buffer std_logic;
			trig_rate_count		: out natural
			);
end trigger;

architecture vhdl of trigger is





	signal 	acc_trig_latch_z:	std_logic;
	signal 	acc_trig_latch_z2: std_logic;
	signal 	trig_latch:	std_logic;
	signal 	trig_latch_x:	std_logic;
	signal 	trig_latch_z:	std_logic;
	signal 	trig_latch_z2:	std_logic;
	signal	trig_common: std_logic;
	signal	resetRequest: std_logic;
	signal	timestamp_z: std_logic_vector(63 downto 0);
	signal	prev_mode: natural;
	signal 	acc_trig_z:	std_logic;
	signal 	acc_trig_x:	std_logic;
	signal 	beamGate:	std_logic;
	signal 	beamGate_z:	std_logic;
	signal 	beamGate_z2:	std_logic;
	signal 	beamGate_latch:	std_logic;
	signal 	beamGate_narrow:	std_logic;
	signal	pps_trig: std_logic;
	signal	mode_z: natural;
	signal 	beamgate_timestamp_z: std_logic_vector(63 downto 0);
	
	
	
	
	
begin  



-- brief description:
---------------------
-- A trigger is detected which has different sources depending on the mode:-
--
-- sma input
-- acc (sma, software or pps)
-- self trigger (generated by psec4 chips when signal level exceeds threshold on selected channels
--
-- For some modes a validation signal must also be received within a certain time of the trigger
-- This can come from sma input or acc
--





---------------------------------------
-- TRIGGER SELECT
---------------------------------------


TRIG_SEL: process(trigSetup, acc_trig, acc_beamGate, pps_trig, sma_trig, self_trig)
begin
	case trigSetup.mode is
		when 0 => trig_common <= '0';				-- mode 0 trigger off
		when 1 => trig_common <= acc_trig;		-- mode 1 software trigger (from acc)
		when 2 => trig_common <= acc_trig;		-- mode 2 sma trigger (ACC)
		when 3 => trig_common <= sma_trig;		-- mode 3 sma trigger (ACDC)
		when 4 => trig_common <= self_trig;		-- mode 4 self trigger
		when 5 => trig_common <= (self_trig and acc_beamGate) or pps_trig;	-- mode 5 self trigger with sma validation (ACC) & multiplexed pps
		when 6 => trig_common <= self_trig and sma_trig;							-- mode 6 self trigger with sma validation (ACDC)
		when 7 => trig_common <= acc_trig and sma_trig;								-- mode 7 sma trigger (ACC) with sma validation (ACDC)
		when 8 => trig_common <= (sma_trig and acc_beamGate) or pps_trig;		-- mode 8 sma trigger (ACDC) with sma validation (ACC) & multiplexed pps
		when 9 => trig_common <= pps_trig;		-- mode 9 pps trigger (from ACC)
		when others => trig_common <= '0';
	end case;
end process;







---------------------------------------
-- TRIGGER LATCH
---------------------------------------


-- Edge detect
TRIG_EDGE_DETECT: process(trig_common, trig_clear)
begin
	if (trig_clear = '1') then
		trig_latch <= '0';
	elsif (rising_edge(trig_common)) then
		trig_latch <= '1';
		beamGate_latch <= beamGate;			-- this is for modes that use pps trigger & beamgate to help decide what caused the trigger
	end if;
end process;

trig_out <= trig_latch;			-- trigger to PSEC chips







---------------------------------------
-- TRIGGER TIMESTAMP GENERATOR
---------------------------------------
-- generate a timestamp value for when the trigger latch goes high

TIMESTAMP_GEN: process(clock.x8)
begin
	if (rising_edge(clock.x8)) then
		trig_latch_z <= trig_latch;		-- synchronize to fast clock
		trig_latch_z2 <= trig_latch_z;
		if (trig_latch_z = '1' and trig_latch_z2 = '0') then	-- rising edge
			timestamp_z <= systemTime;
		end if;
	end if;
end process;





	
	
	
	
---------------------------------------
-- BEAMGATE TIMESTAMP GENERATOR
---------------------------------------
-- generate a timestamp value for when the beamgate signal goes high

BG_TIMESTAMP_GEN: process(clock.x8)
begin
	if (rising_edge(clock.x8)) then
		acc_trig_latch_z <= acc_trig;		-- synchronize to fast clock
		acc_trig_latch_z2 <= acc_trig_latch_z;
		if (acc_trig_latch_z = '1' and acc_trig_latch_z2 = '0') then	-- rising edge
			beamgate_timestamp_z <= systemTime;
		end if;
	end if;
end process;





	
	
	
	
---------------------------------------
-- TRIGGER CONTROL STATE MACHINE
---------------------------------------

TRIG_CTRL: process(clock.sys)

type state_type is (
	TRIG_RESET, 
	TRIG_WAIT, 
	DISAMBIGUATE, 
	COPY_TIMESTAMP,
	DIGITIZE_INIT, 
	DIGITIZE_WAIT, 
	FRAME_TRANSFER_INIT, 
	FRAME_TRANSFER_WAIT,
	TRIG_DONE
);
	
variable t: natural;
variable state: state_type;
variable transfer_en: boolean;	-- allow transfer of data to acc

-- flags
variable trig_detect_flag: std_logic;
variable trig_abort_flag: std_logic;
variable trig_valid_flag: std_logic;
variable trig_event_flag: std_logic;
variable pps_detect_flag: std_logic;
variable signal_trig_detect_flag: std_logic;
variable timeout: natural;

begin
	if (rising_edge(clock.sys)) then
	
		trig_detect_flag := '0';
		trig_valid_flag := '0';
		trig_abort_flag := '0';
		trig_event_flag := '0';
		pps_detect_flag := '0';
		signal_trig_detect_flag := '0';
		
		-- synchronize to sys clock
		trig_latch_x <= trig_latch;
		acc_trig_x <= acc_trig;
		
		-- reset trigger state if mode change
		prev_mode <= trigSetup.mode;
		if (prev_mode /= trigSetup.mode or trigSetup.resetReq = '1') then 
			state := TRIG_RESET; 
		end if;			
				
		-- global reset or event count reset request
		if (reset = '1' or trigSetup.eventAndTime_reset = '1') then 

			transfer_en := false;
			state := TRIG_RESET;
			eventCount <= X"00000000";
			ppsCount <= X"00000000";

		else
		
			-- frame transfer control
			if (trigSetup.transferEnableReq = '1') then transfer_en := true; end if;
			if (trigSetup.transferDisableReq = '1') then transfer_en := false; end if;

			-- trigger elapsed time counter
			if (t < 400000000) then t := t + 1; end if;		-- time since trigger
		

			case state is
			
			
			
				when TRIG_RESET =>
				
					trig_clear <= '1';		-- clear the latches
					if (trig_latch_x = '0') then state := TRIG_WAIT; end if;		-- verify the latch is clear before waiting for a latch high signal
						
	
	
				when TRIG_WAIT =>				-- wait for an incoming trigger trigger signal
									
					trig_clear <= '0';		-- enable the trigger latches
					
					if (trig_latch_x = '1') then		-- trigger latch went high					
						
						trig_detect_flag := '1';
						t := 0;		-- time since trigger 
						
						if (trigSetup.mode = 9) then
							frameType <= frameType_name.pps;	-- pps frame type 
						else
							frameType <= frameType_name.psec;	-- default frame type = PSEC data
						end if;
						
						-- In some modes, pps-beam gate disambiuation is required due to multiplexed signals 						
						if (trigSetup.mode = 5 or trigSetup.mode = 8) then		
							state := DISAMBIGUATE;
						else
							state := COPY_TIMESTAMP;						
						end if;
										
					end if;
				
				
				
				
				-- trigger happened but we need to decide what was the cause. It could be:				
				-- (i) pps
				-- (ii) beam gate [false trigger]
				-- (iii) signal trigger
				when DISAMBIGUATE =>		
					
						if (beamGate_latch = '1') then		-- signal trigger 
							signal_trig_detect_flag := '1';
							state := COPY_TIMESTAMP;				
						
						else											-- acc trig (pps or beam gate). We need to check the pulse width to determine which it was
						
							if (t <= 4) then					
								
								if (acc_trig_x = '0') then			-- acc signal went low again i.e. short pulse- it was a pps trigger									
									
									pps_detect_flag := '1';
									frameType <= frameType_name.pps;		-- flag that it is a pps type trigger
									state := COPY_TIMESTAMP;	
								
								end if;
				
							else			-- timeout. It must be a long pulse -hence it was beamgate pulse that caused the trigger

								trig_abort_flag := '1';
								state := TRIG_RESET;			-- false trigger- abort the trigger process. It was beam gate, which is not a trigger signal
						
							end if;
					
		
						end if;
								
						
						
						
				when COPY_TIMESTAMP =>				-- timestamp value has already  been latched but copy its value and sync to sys clk
				
					timestamp <= timestamp_z;
					beamgate_timestamp <= beamgate_timestamp_z;			-- the time value of the most recent rising edge on beamgate
					if (testMode.trig_noTransfer = '1') then 
						state := TRIG_DONE;
					elsif (frameType = frameType_name.pps) then		-- skip the psec digitization stage for pps frame as only timestamp info is required
						state := FRAME_TRANSFER_INIT;
					else
						state := DIGITIZE_INIT;
					end if;
						
				
				
				when DIGITIZE_INIT =>				-- request to start transfer of data from psec to fpga
				
					digitize_request <= '1';
					state := DIGITIZE_WAIT;
				
				
				
				
				when DIGITIZE_WAIT =>				-- wait for the PSEC chip data to be transferred to the fpga RAM
				
					digitize_request <= '0';
					if (digitize_done = '1') then state := FRAME_TRANSFER_INIT; end if;
						
										
				
				
				when FRAME_TRANSFER_INIT =>				-- wait until the ACC is ready to receive a data frame
					
					if (transfer_en) then			
						transfer_request <= '1';
						transfer_en := false;
						state := FRAME_TRANSFER_wAIT;
					end if;
				
				
				
				
				when FRAME_TRANSFER_WAIT =>						-- transfer data to the acc
				
					transfer_request <= '0';
					if (transfer_done = '1') then	state := TRIG_DONE; end if;
					
					
				
				
				when TRIG_DONE =>

					trig_valid_flag := '1';					
					case frameType is
						when frameType_name.pps => ppsCount <= ppsCount + 1;				 
						when frameType_name.psec => eventCount <= eventCount + 1; trig_event_flag := '1';	
						when others => null;
					end case;
					state := TRIG_RESET;
					
				
			
				

						
			end case;
				
				
				
				
			-- output flags	
			if (trig_detect_flag = '1') then trig_detect <= '1'; else trig_detect <= '0'; end if;
			if (trig_valid_flag = '1') then trig_valid <= '1'; else trig_valid <= '0'; end if;
			if (trig_abort_flag = '1') then trig_abort <= '1'; else trig_abort <= '0'; end if;
			if (pps_detect_flag = '1') then pps_detect <= '1'; else pps_detect <= '0'; end if;
			if (signal_trig_detect_flag = '1') then signal_trig_detect <= '1'; else signal_trig_detect <= '0'; end if;
			
				
				
			if (state = TRIG_WAIT) then busy <= '0'; else busy <= '1'; end if;
		
			trig_event <= trig_event_flag;
				
				
					
				
				
				
		end if;
		
		if (transfer_en) then transfer_enable <= '1'; else transfer_enable <= '0'; end if;
		
	end if;
	
end process;











--------------------------------------
-- beam gate demultiplexer
--------------------------------------		
-- recover beam gate signal from the combined pps-beamgate signal
-- pulse width: pps < 75ns, beam gate >75ns so remove any pulses that have width <75ns
--
-- The beam gate output pulse width will be smaller than the input width due to the time taken to check the pulse width
-- but this is not so time-critical
-- 
-- pps signal cannot be recovered because rising edge must be passed directly to trigger, 
-- hence you don't know how long the pulse is until it's too late
--
-- There are two versions of the beam gate output:
-- beamGate			the version that will be latched by the trigger mechanism
-- beamGate_narrow	the version that will be applied to the AND gate to enable the trigger signal
--
-- the only difference is that beamGate starts slightly before bg narrow and ends slightly after. (1 clock @160MHz difference at each end)
-- the reason is to remove any problems or glitches if a signal occurs at the extreme ends of the window
-- These problems are due to the fact that this circuit is asynchronous
-- With the two versions, the trigger mechanism can be sure that if it latches beamGate low at trigger time
-- the cause was definitely not the signal trigger as it is gated off

DEMUX: process(clock.x4)
variable t: natural range 0 to 255:= 0;
variable bg: std_logic;		-- variable used to denote beamGate from which the outputs are generated
variable bg_z: std_logic;	-- delayed version of above
variable state: natural range 0 to 255:= 0;
begin
	if (rising_edge(clock.x4)) then
	
		if (t < 255) then t := t + 1; end if;		-- time since last rising edge on acc_trig
					
		
		acc_trig_z <= acc_trig;
		mode_z <= trigSetup.mode;
		
		-- beam gate function
		if (acc_trig_z = '0') then 			
			
			t := 0; 
			bg := '0';
		
		elsif (t > 12) then		-- 75ns
			
			if (mode_z = 5 or mode_z = 8) then bg := '1';	end if;		-- set high but only if in beamgate mode
		
		end if;
					
					
		-- generate the output signals. Two windows- one inside the other			
		case bg is
		
			when '0' =>
		
				beamGate_narrow <= '0';
				if (bg_z = '0') then beamGate <= '0'; end if;
			
			when others =>
		
				beamGate <= '1';
				if (bg_z = '1') then beamGate_narrow <= '1'; end if;
		
		end case;
		
		
		-- record prev value
		bg_z := bg;
		
	end if;
end process;


-- pps trigger recovery. Note that it will go high on pps or beam gate pulse initially, until the pulse length is checked
pps_trig <= (not beamGate) and acc_trig;			-- pps trigger is forced low during beam gate high
acc_beamGate <= beamGate_narrow;		-- acc_beamGate is used in trig function

-- essentially (not beamGate) selects pps trigger and beamGate_narrow selects signal trigger,
-- in a way that they don't overlap, i.e. there is a small gap where neither is selected.




BEAMGATE_COUNTER: process(clock.sys)
begin
	if (rising_edge(clock.sys)) then
		beamGate_z <= beamGate;
		beamGate_z2 <= beamGate;
		if (reset = '1' or trigSetup.eventAndTime_reset = '1') then 
			beamGateCount <= X"00000000";
		elsif (beamGate_z = '1' and beamGate_z2 = '0') then
			beamGateCount <= beamGateCount + 1;
		end if;
	end if;
end process;


				

				
				
				
	
------------------
-- TRIG INFO
------------------
-- read back as part of the psec data frame
-- serves as confirmation of the trigger setup status

--
trigInfo(0,0) <= beamgate_timestamp(63 downto 48);
trigInfo(0,1) <= beamgate_timestamp(47 downto 32);
trigInfo(0,2) <= beamgate_timestamp(31 downto 16);
trigInfo(0,3) <= beamgate_timestamp(15 downto 0);

trigInfo(0,4)(15 downto 12) <= std_logic_vector(to_unsigned(trigSetup.mode, 4));
trigInfo(0,4)(11 downto 10) <= trigSetup.sma_invert & selfTrig.sign;
trigInfo(0,4)(9 downto 0) <= "00000" & std_logic_vector(to_unsigned(selfTrig.coincidence_min, 5));

--
trigInfo(1,0) <= "0000000000" & selfTrig.mask(0);
trigInfo(1,1) <= "0000000000" & selfTrig.mask(1);
trigInfo(1,2) <= "0000000000" & selfTrig.mask(2);
trigInfo(1,3) <= "0000000000" & selfTrig.mask(3);
trigInfo(1,4) <= "0000000000" & selfTrig.mask(4);

--
trigInfo(2,0) <= x"0" & std_logic_vector(to_unsigned(selfTrig.threshold(0), 12));
trigInfo(2,1) <= x"0" & std_logic_vector(to_unsigned(selfTrig.threshold(1), 12));
trigInfo(2,2) <= x"0" & std_logic_vector(to_unsigned(selfTrig.threshold(2), 12));
trigInfo(2,3) <= x"0" & std_logic_vector(to_unsigned(selfTrig.threshold(3), 12));
trigInfo(2,4) <= x"0" & std_logic_vector(to_unsigned(selfTrig.threshold(4), 12));








------------------------------
-- TRIGGER RATE COUNTER
------------------------------
-- count the number of trig events in one second 

RATE_COUNT_GEN: process(clock.sys)
variable count: natural;
variable t: natural;
begin
	if (rising_edge(clock.sys)) then
		
		if (reset = '1' or trigSetup.eventAndTime_reset = '1') then
		
			t := 0;
			count := 0;
			trig_rate_count <= 0;
			
			
		else
		
		
			if (trig_event = '1') then
				if (count < trigRate_MaxCount) then count := count + 1; end if;
			end if;				
			
			t := t + 1;		-- clock cycle counter
			 
			if (t = 40000000) then		-- after 1 second record the count and then reset 

				t := 0;
				trig_rate_count <= count;
				count := 0;
				
			end if;
			
		end if;
		
	end if;
end process;






	
end vhdl;






