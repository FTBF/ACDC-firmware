---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
-- PROJECT:      ANNIE - ACDC
-- FILE:         defs.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         May 2021
--
-- DESCRIPTION:  definitions
--
---------------------------------------------------------------------------------


library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package defs is


type firmwareVersion_type is record
	number : std_logic_vector(15 downto 0);
	year : std_logic_vector(15 downto 0);
	MMDD:	std_logic_vector(15 downto 0);
end record;



--------------------------------
-- VERSION INFO
--------------------------------
constant firmwareVersion: firmwareVersion_type:= (
	
	number => 	x"0400", 
	year => 		x"2021",	
	MMDD => 		x"1005"			-- month, date
	
);
--
-- Version history:


-- 0304 2021/06/22	Modifed DLL control loop so that it steps the dac value quicker if it is far away from target value, hence it gets there quicker
-- 0303 2021/06/21 	Added a command to enable/disable the DLL control
-- 0302 2021/06/14	Wilkinson feedback loop & VCDL monitor - combined both into a single synchronous process
-- 0301 2021/06/14	Transmitter sends two sync bytes (K28.7 and K28.0) and receiver must see both of these to lock on
--							This avoids the possibility of a false sync where an inverted K28.7 appears overlapping a K28.7 and a K28.0
-- 0300 2021/05/31	Synchronous comms running at 40Mbps instead of uart running at 20Mbps
-- 0201 2021/05/28   Added beamgate timestamping in acdc. This data is sent in the psec frame
-- 0200 2021/05/10 	Major structural changes to trigger mechanism; 
--							added multiplexed pps signal and beam gate; 
--							pll lock fail counter; 
--							pps trig counter
--							variable frame lengths (pps=8, psec=7795, id=32)
-- 0102 2021/04/27 External clock detect now looks at pps signal and if present assumes the ext clock is also present and switches to it.
-- 0101 2021/04/23 Beam gate delay & length - changed resolution to 25ns [40MHz clock] 
-- 0100 2021/02/12 Added another trigger mode (mode 9) to trigger on the rising edge of pps signal, from acc via lvds. 
--						 Note: it uses the same lvds line as s/w trig and acc sma trig, so the acc must multiplex to select the correct input according to the trigger mode.
-- 0017 2020/12/14 Fixed error in writing to DACs
-- 0017 2020/10/14 Initial version
--
--------------------------------



constant N:	natural:= 5;	-- the number of PSEC4 chips on the ACDC card
constant M:	natural:= 6;	-- the number of channels on each PSEC4 chip



--defs for the SERDES links
constant STARTWORD				: 	std_logic_vector := x"1234";
constant ENDWORD					: 	std_logic_vector := x"4321";
constant PSEC_END_WORD 			:  std_logic_vector := x"FACE";


--type defs

type info_type is array (4 downto 0, 0 to 13) of std_logic_vector(15 downto 0);




constant WILKRAMPCOUNT	: integer   := 160; --set ramp length w.r.t. clock
constant RAM_ADR_SIZE  	: integer   := 14;


type natArray	 	is array (N-1 downto 0) of natural;	-- 32 bits range by default
type natArray24 	is array (N-1 downto 0) of natural range 0 to 16777215;
type natArray16	is array (N-1 downto 0) of natural range 0 to 65535;
type natArray12 	is array (N-1 downto 0, M-1 downto 0) of natural range 0 to 4095;
type natArray5 	is array (N-1 downto 0) of natural range 0 to 31;
type natArray4 	is array (N-1 downto 0) of natural range 0 to 15;
type natArray3 	is array (N-1 downto 0) of natural range 0 to 7;

type wordArray	is array (N-1 downto 0) of std_logic_vector(15 downto 0);
type array32 	is array (N-1 downto 0) of std_logic_vector(31 downto 0);
type array24 	is array (N-1 downto 0) of std_logic_vector(23 downto 0);
type array16 	is array (N-1 downto 0) of std_logic_vector(15 downto 0);
type array13 	is array	(N-1 downto 0) of	std_logic_vector(12 downto 0);
type array12 	is array	(N-1 downto 0) of	std_logic_vector(11 downto 0);
type array10 	is array	(N-1 downto 0) of	std_logic_vector(9 downto 0);
type array6 	is array (N-1 downto 0) of std_logic_vector(5 downto 0);
type array5 	is array	(N-1 downto 0) of std_logic_vector(4 downto 0);	
type array4 	is array	(N-1 downto 0) of std_logic_vector(3 downto 0);	
type array3 	is array	(N-1 downto 0) of std_logic_vector(2 downto 0);	
type array2 	is array	(N-1 downto 0) of std_logic_vector(1 downto 0);	
type bitArray 	is array (N-1 downto 0) of std_logic;	
type trigger_array 		is array (5 downto 0) of 	std_logic_vector(15 downto 0);

type hs_input_array is array (1 downto 0) of std_logic_vector(7 downto 0);

constant trigRate_MaxCount: integer:= 60000;

type selfTrig_rateCount_array is array (0 to 4, 0 to 5) of natural;







------------------------------------
--	CLOCKS
------------------------------------

type clockSource_type is record
	localOsc		:	std_logic;
	jcpll			:	std_logic;
    accOsc          :   std_logic;
    wr100           :   std_logic;
end record;


type jcpll_ctrl_type is record
	spi_latchEnable	:	std_logic;
	spi_mosi				:	std_logic;
	spi_clock			:	std_logic;
	testMode				:	std_logic;
	testsync				:	std_logic;
	powerDown			:	std_logic;
	outputEnable			:	std_logic;
end record;


type clock_type is record
    sys			:	std_logic;
    x4				:	std_logic;
    x8				:	std_logic;
    acc40			:	std_logic;
    acc160				:	std_logic;
    acc320				:	std_logic;
    serial25    : std_logic;
    serial125   : std_logic;
    wr100       : std_logic;
    usb         :	std_logic;  
    update		:	std_logic;
    altpllLock  :	std_logic;
    accpllLock  :	std_logic;
    serialpllLock : std_logic;
    wrpllLock   : std_logic;
end record;






------------------------------------
--	COMMAND
------------------------------------
type cmd_type is record
	word		:	std_logic_vector(31 downto 0);
	valid		:	std_logic;
end record;




------------------------------------
--	DAC
------------------------------------

type DAC_type is record
	serialData	: std_logic;
	serialClock	: std_logic;
	load			: std_logic;
	clear			: std_logic;	-- active low
end record;


type DAC_array_type is array (0 to 3) of DAC_type;


type serialDAC_type is record
	dataSize		: natural;
	channels		: natural;
	maxValue		: natural;
end record;


-------------------------------------
constant serialDAC: serialDAC_type:= 
(
	dataSize => 12,
	channels => 8,
	maxValue => 4095
);
-------------------------------------


type dacData_type is array (0 to 7) of natural range 0 to serialDAC.maxValue;
type DACchain_data_type is array (0 to 1) of dacData_type;		-- 2 devices in each chain
type DACchain_data_array_type is array (0 to 3) of DACchain_data_type;		-- 3 chains
type dacWordArray_type is array (0 to N-1) of natural range 0 to serialDAC.maxValue;






------------------------------------
--	Error vector
------------------------------------
type errorVector_type is record
	frameTransferTimeout	: std_logic;
	digitizeTimeout		: std_logic;
end record;







------------------------------------
--	Frame type
------------------------------------
type FrameType_name_type is record
	psec		: natural;
	pps		: natural;
	id			: natural;
end record;


-------------------------------------
constant FrameType_name: FrameType_name_type:= 
(
	psec		=> 0,
	pps		=> 1,
	id			=> 2
);







------------------------------------
--	LEDS
------------------------------------
type LEDSetup_type is array (8 downto 0) of std_logic_vector(15 downto 0);
type LEDPreset_type is array (0 to 15) of LEDSetup_type;







------------------------------------
--	PSEC4 
------------------------------------

type PSEC4_in_type is record
	data			: std_logic_vector(11 downto 0);
	overflow		: std_logic;
	ringOsc_mon	: std_logic;
	DLL_clock	: std_logic;
	trig			: std_logic_vector(5 downto 0);
end record;


type PSEC4_out_type is record
	DLLreset_n	: std_logic;
	trigClear	: std_logic;
	rampStart	: std_logic;
	readClock	: std_logic;
	extTrig		: std_logic;
	ADCclear		: std_logic;
	ringOsc_enable	: std_logic;
	ADClatch		: std_logic;
	channel		: natural range 0 to M;
	TokDecode	: std_logic_vector(2 downto 0);
	TokIn			: std_logic_vector(1 downto 0);
end record;



type PSEC4_in_array_type is array (0 to N-1) of PSEC4_in_type;
type PSEC4_out_array_type is array (0 to N-1) of PSEC4_out_type;






------------------------------------
--	RESET
------------------------------------
type reset_type is record
    global		:	std_logic;
    acc         :   std_logic;
    serial      :   std_logic;
    serialFast  :   std_logic;
    wr          :   std_logic;
	request		:	std_logic;
end record;







------------------------------------
--	TEST MODE
------------------------------------

type testMode_type is record
	sequencedPsecData	:	std_logic;
	trig_noTransfer: std_logic;
	DLL_updateEnable: std_logic_vector(4 downto 0);
end record;
 
 
 


 
------------------------------------
--	TRIGGER
------------------------------------


type trig_type is record
	mode					:	natural range 0 to 15;
	transferEnableReq:	std_logic;		-- tells the acdc that one frame of data may be transmitted
	transferDisableReq:	std_logic;
	resetReq:	std_logic;					-- clear system time counter and event counter
	eventAndTime_reset:	std_logic;					-- clear system time counter and event counter
	sma_invert: std_logic;
    timeout : natural range 0 to 127;
end record;


type selfTrig_type is record
	mask				:	array6;			-- high = enable this bit for generating self-triggers
	coincidence_min:	natural range 0 to 31;	-- the minimum number of simultaneous [enabled] self-trig inputs that generates a trigger event
	threshold		:	natArray12;			-- A value that drives a DAC to set the analogue voltage threshold for self-trigger
	sign				: std_logic;
	use_coincidence: std_logic;
end record;



type trigInfo_type is array (0 to 2, 0 to 4) of std_logic_vector(15 downto 0);





------------------------------------
--	SERIAL TX
------------------------------------
type serialTx_type is record
	data				:	std_logic_vector(7 downto 0);
	req				:	std_logic;
	serial			:	std_logic;
   ack 	      	:	std_logic;
	trigTransferDone:	std_logic;
end record;





------------------------------------
--	SERIAL RX
------------------------------------
type serialRx_type is record
	serial					:	std_logic;
	data						:	std_logic_vector(7 downto 0);
	valid						:	std_logic;
	kout						:	std_logic;
   rx_clock_fail			:	std_logic;
   symbol_align_error	:	std_logic;
   symbol_code_error		:	std_logic;
   disparity_error		:	std_logic;
end record;




-----------------------------------
--  rx parameter type
-----------------------------------
type RX_Param_jcpll_type is record
  trigSetup               : trig_type;
  selfTrig                : selfTrig_type;   
  Vbias                   : natArray16;    
  DLL_Vdd                 : natArray16;     
  DLL_resetRequest        : std_logic;
  ramReadRequest          : std_logic;
  RO_target               : natArray;   
  testMode                : testMode_type;
end record;

type RX_Param_acc_type is record
  calEnable               : std_logic_vector(14 downto 0);   
  reset_request           : std_logic;   
  IDrequest               : std_logic;
  PLL_resetRequest        : std_logic;   
  PLL_ConfigRequest       : std_logic;   
  PLL_ConfigReg           : std_logic_vector(31 downto 0);   
  outputMode              : std_logic_vector(1 downto 0);
end record;

	



end defs;






























