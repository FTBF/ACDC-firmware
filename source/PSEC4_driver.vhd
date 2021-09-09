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
use work.components.dataBuffer;
use work.components.ADC_Ctrl;
use work.components.Wilkinson_Feedback_Loop;
use work.components.VCDL_Monitor_Loop;



entity PSEC4_driver is
	port(	
	
		clock					: in	clock_type;
		reset					: in  std_logic;
		trig					: in  std_logic;
		trigSign				: in	std_logic;
		selftrig_clear		: in  std_logic;
		digitize_request	: in 	std_logic;
		rampDone				: buffer	std_logic;
		adcReset				: in 	std_logic;
		PSEC4_in				: in 	PSEC4_in_type;
		DLL_reset			: in  std_logic;
		Wlkn_fdbk_target	: in  natural;
		PSEC4_out			: buffer PSEC4_out_type;
		VCDL_count			: out	natural;
		DAC_value			: out natural range 0 to 4095;
		Wlkn_fdbk_current : out natural;
		DLL_monitor			: out std_logic;
		ramReadAddress		: in natural;
		ramDataOut			: out std_logic_vector(15 downto 0);
		ramBufferFull		: out std_logic;
		FLL_lock				: out	std_logic
		);
	
end PSEC4_driver;
	
	
	
architecture vhdl of	PSEC4_driver is

	
	
	
	
   
begin




------------------------------------
--	TRIGGER 
------------------------------------

PSEC4_out.extTrig <= trig;		
PSEC4_out.trigClear <= selfTrig_clear or reset;





------------------------------------
--	WILKINSON ADC CONTROL
------------------------------------

ADC_map: ADC_Ctrl port map(
		clock			=> clock.sys,			--40MHz	
		reset			=> adcReset,
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
	clock			=> clock.sys,
	reset			=> adcReset,
	start			=> rampDone,
	ramReadAddress	=> ramReadAddress,
	ramDataOut	=> ramDataOut,
	done			=> ramBufferFull);

	



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
	



		
		
------------------------------------
--	VCDL MONITOR
------------------------------------

VCDL_MON_map : VCDL_Monitor_Loop port map(
		clock				   => clock,
		VCDL_MONITOR_BIT  => PSEC4_in.DLL_clock,
		countReg				=> VCDL_count);
										 
					
					
			
			
			
------------------------------------
--	WILKINSON FEEDBACK LOOP
------------------------------------

xWILK_FDBK	:	Wilkinson_Feedback_Loop port map(
	reset				 		=> reset,     
   clock  					=> clock,     
   WILK_MONITOR_BIT   	=> PSEC4_in.ringOsc_mon, 
   target				 	=> Wlkn_fdbk_target,
   current				 	=> Wlkn_fdbk_current,
   dacValue			   	=> DAC_value,
	lock						=> FLL_lock);		-- frequency locked loop lock signal
			




 
end vhdl;
