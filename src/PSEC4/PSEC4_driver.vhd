---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         PSEC4_driver.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  Process to interface to a PSEC4 device
--						generates the ADC ramp, and reads out the data into a ram buffer
--						includes Wilkinson feedback loop and dll control
---------------------------------------------------------------------------------


library IEEE; 
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;
use work.LibDG.all;



entity PSEC4_driver is
	port(	
	
		clock					: in	clock_type;
		reset					: in  reset_type;
		DLL_resetRequest	: in  std_logic;
		DLL_updateEnable	: in  std_logic;
		trig					: in  std_logic;
		trigSign				: in	std_logic;
		selftrig_clear		: in  std_logic;
		digitize_request	: in 	std_logic;
		rampDone				: buffer	std_logic;
		adcReset				: in 	std_logic;
		PSEC4_in				: in 	PSEC4_in_type;
		Wlkn_fdbk_target	: in  natural;
		PSEC4_out			: buffer PSEC4_out_type;
		VCDL_count			: out	std_logic_vector(31 downto 0);
		DAC_value			: out natural range 0 to 4095;
		Wlkn_fdbk_current : out natural;
		DLL_monitor			: out std_logic;
		fifoRead         		:	in	    std_logic; 
		fifoDataOut			:	out	std_logic_vector(15 downto 0);
        fifoOcc             : out std_logic_vector(12 downto 0);
        readoutDone         : out std_logic;
		FLL_lock				: out	std_logic
		);
	
end PSEC4_driver;
	
	
architecture vhdl of	PSEC4_driver is
	
  signal VCDL_MONITOR_BIT_z: std_logic;
  signal WILK_MONITOR_BIT_z: std_logic;
  signal DLL_reset: std_logic;
  signal psecReadoutDone : std_logic;
   
begin

------------------------------------
--	DLL RESET
------------------------------------
DLL_RESET_PROCESS : process(clock.sys)
variable t: natural := 0;		-- elaspsed time counter
variable r: std_logic;
begin
	if (rising_edge(clock.sys)) then 						
		if (reset.global = '1' or DLL_resetRequest = '1') then t := 0; end if;		-- restart counter if new reset request	
		if (t >= 40000000) then r := '0'; else r := '1'; t := t + 1; end if;
		DLL_reset <= r; 			
	end if;
end process;
			

------------------------------------
--	TRIGGER 
------------------------------------

PSEC4_out.extTrig <= trig;		
PSEC4_out.trigClear <= selfTrig_clear or reset.global;


------------------------------------
--	WILKINSON ADC CONTROL
------------------------------------

ADC_map: ADC_Ctrl port map(
		clock			=> clock.sys,			--40MHz	
		reset			=> adcReset or psecReadoutDone,
		start			=> digitize_request,
		RO_EN 		=> PSEC4_out.ringOsc_enable,
		adcClear		=> PSEC4_out.adcClear,
		adcLatch		=> PSEC4_out.adcLatch,
		rampStart	=> PSEC4_out.rampStart,
		rampDone		=> rampDone);

		
			
------------------------------------
--	DATA BUFFER
------------------------------------

dataBuffer_map : dataBuffer port map(	
	PSEC4_in 	=> PSEC4_in,		-- input signals from the psec4 chip
	channel 		=> PSEC4_out.channel,
	Token 		=> PSEC4_out.tokIn,
	blockSelect => PSEC4_out.TokDecode,
	readClock	=> PSEC4_out.readClock,
	clock			=> clock,
	reset			=> reset,
	start			=> rampDone,
    fifoRead        => fifoRead,
    fifoDataOut		=> fifoDataOut,
    fifoOcc         => fifoOcc,
	done			=> psecReadoutDone);

readoutDone <= psecReadoutDone;


------------------------------------
--	DLL CONTROL & MONITOR
------------------------------------

PSEC4_out.DLLreset_n <= not DLL_reset;	

DLL_MONITOR_PROCESS: process(DLL_reset, PSEC4_in) 
variable t: natural;
variable x: std_logic_vector(23 downto 0);
begin
	if (DLL_reset = '1') then
		t :=	0;
	elsif rising_edge(PSEC4_in.DLL_clock) then
		t := t + 1;
	end if;
	x := std_logic_vector(to_unsigned(t,24));
	DLL_monitor	<=	x(22);
end process;
	
			
------------------------------------------
--	WILKINSON FEEDBACK LOOP & VCDL MONITOR
------------------------------------------
-- basically a frequency locked loop which controls the dac voltage
-- so that the voltage controlled delay line frequency is locked to the system clock.
-- To measure frequency a rising edge detect is used which generates a single output 
-- pulse for each rising edge.
process(clock.sys)
variable t				: natural;
variable d				: natural;
variable countV		: unsigned(31 downto 0);
variable countW		: natural;
variable freq_error	: integer;
variable n        	: integer;
variable error_mag	: integer;
variable limit			: integer;
constant InitValue 	: natural:= 16#820#; 
constant MinValue 	: natural:= 16#400#; 
constant MaxValue 	: natural:= 16#999#; 
variable step			: integer;
variable dir			: std_logic;
type STATE_TYPE is (INIT, CLEAR, ENABLE, UPDATE, SETTLING_TIME);
variable state: STATE_TYPE := INIT;
begin
	if (rising_edge(clock.sys)) then
						
		if (reset.global = '1') then state := INIT; end if;		
			
			
		case state is
		
			when INIT =>
			
				d := InitValue;
				state := CLEAR;
			
			
			when CLEAR =>	
					
				countV := x"00000000";
				countW := 0;
				if (clock.update = '1') then state := ENABLE; end if;
					
					
			when ENABLE =>		-- stays in this state for 100ms
					
				if (VCDL_MONITOR_BIT_z = '1' and countV < 65500) then countV := countV + 1; end if;
				if (WILK_MONITOR_BIT_z = '1' and countW < 65500) then countW := countW + 1; end if;
				if (clock.update = '1') then 
					Wlkn_fdbk_current <= countW;
					VCDL_count <= std_logic_vector(countV);
					state := UPDATE;
				end if;
					
				
			when UPDATE =>
                                       
				freq_error := Wlkn_fdbk_current - Wlkn_fdbk_target;
				
				-- calculate error magnitude
				if (freq_error >= 0) then
					error_mag := freq_error; 
				else 
					error_mag := -freq_error; 
				end if;
				
				-- calculate step size
				if (error_mag = 0) then
					step := 0;
				elsif (error_mag > 1000) then
					step := 10;			-- larger step size if further away, so it gets there quicker
				else
					step := 1;
				end if;							
								
				-- calculate new dac value		
				if (freq_error > 0) then 	-- measured frequency is too high
					if (d < MaxValue and DLL_updateEnable = '1') then d := d + step; end if;
				elsif (freq_error < 0) then
					if (d > MinValue and DLL_updateEnable = '1') then d := d - step; end if;
				end if;								
										
				-- lock detect
				if (error_mag < 400) then FLL_lock <= '1'; else FLL_lock <= '0'; end if;
				t := 0;
				state := SETTLING_TIME;
					
					
			when SETTLING_TIME =>			-- allow time for the dac voltage change and its effects to settle, before measuring again
			
				if (clock.update = '1') then
					t := t + 1;			-- count 100ms cycles. It will take at least one cycle before the DAC driver writes the new data to the dacs
					if (t = 3) then state := CLEAR; end if;
				end if;
				
				
			
		end case;
		
		
		DAC_value <= d;
		
		
	end if;
end process;


edge_detect_wilk_monitor: risingEdgeDetect port map(clock.sys, PSEC4_in.ringOsc_mon, WILK_MONITOR_BIT_z);
edge_detect_vcdl_monitor: risingEdgeDetect port map(clock.sys, PSEC4_in.DLL_clock, VCDL_MONITOR_BIT_z);

 
end vhdl;
