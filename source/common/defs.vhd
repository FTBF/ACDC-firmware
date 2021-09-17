---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
-- PROJECT:      ANNIE - ACDC
-- FILE:         defs.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Dec 2020
--
-- DESCRIPTION:  definitions
--
---------------------------------------------------------------------------------


library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package defs is
	
	--------------------------------------------
	-- select board oscillator frequency
	-- There are two options: 25MHz or 125MHz
	constant OscFreq: natural:= 125;
	--------------------------------------------
	
	type firmwareVersion_type is record
		number : std_logic_vector(15 downto 0);
		year : std_logic_vector(15 downto 0);
		MMDD:	std_logic_vector(15 downto 0);
	end record;
	
	
	
	--------------------------------
	-- VERSION INFO
	--------------------------------
	constant firwareVersion: firmwareVersion_type:= (
	
	number => 		x"0102", 
	year => 		x"2021",	
	MMDD => 		x"0817"			-- month, date
	
	);
	--
	-- Version history:
	--
	-- 0017 2020/10/14 Initial version
	-- 0017 2020/12/14 Fixed error in writing to DACs
	-- 0100 2021/02/12 Added another trigger mode (mode 9) to trigger on the rising edge of pps signal, from acc via lvds. 
	--						 Note: it uses the same lvds line as s/w trig and acc sma trig, so the acc must multiplex to select the correct input according to the trigger mode.
	--
	--------------------------------
	
	
	
	constant N:	natural:= 5;	-- the number of PSEC4 chips on the ACDC card
	constant M:	natural:= 6;	-- the number of channels on each PSEC4 chip
	
	
	
	--defs for the SERDES links
	constant STARTWORD				: 	std_logic_vector := x"1234";
	constant STARTWORD_8a			: 	std_logic_vector := x"B7";
	constant STARTWORD_8b			: 	std_logic_vector := x"34";
	constant ENDWORD					: 	std_logic_vector := x"4321";
	constant PSEC_END_WORD 			:  std_logic_vector := x"FACE";
	
	
	--type defs
	
	type info_type is array (4 downto 0, 0 to 13) of std_logic_vector(15 downto 0);
	
	
	
	
	constant WILKRAMPCOUNT	: integer   := 160; --set ramp length w.r.t. clock
	constant RAM_ADR_SIZE  	: integer   := 14;
	
	
	
	type natArray	 	is array (N-1 downto 0) of natural;	-- 32 bits range by default
	type natArray24 	is array (N-1 downto 0) of natural range 0 to 16777215;
	type natArray16	is array (N-1 downto 0) of natural range 0 to 65535;
	type natArray12 	is array (N-1 downto 0) of natural range 0 to 4095;
	type natArray5 	is array (N-1 downto 0) of natural range 0 to 31;
	type natArray4 	is array (N-1 downto 0) of natural range 0 to 15;
	type natArray3 	is array (N-1 downto 0) of natural range 0 to 7;
	
	type wordArray	is array (N-1 downto 0) of std_logic_vector(15 downto 0);
	type array32 	is array (N-1 downto 0) of std_logic_vector(31 downto 0);
	type array24 	is array (N-1 downto 0) of std_logic_vector(23 downto 0);
	type array16 	is array (N-1 downto 0) of std_logic_vector(15 downto 0);
	type array12 	is array	(N-1 downto 0) of	std_logic_vector(11 downto 0);
	type array6 	is array (N-1 downto 0) of std_logic_vector(5 downto 0);
	type array5 	is array	(N-1 downto 0) of std_logic_vector(4 downto 0);	
	type array4 	is array	(N-1 downto 0) of std_logic_vector(3 downto 0);	
	type array3 	is array	(N-1 downto 0) of std_logic_vector(2 downto 0);	
	type array2 	is array	(N-1 downto 0) of std_logic_vector(1 downto 0);	
	type bitArray 	is array (N-1 downto 0) of std_logic;	
	type trigger_array 		is array (5 downto 0) of 	std_logic_vector(15 downto 0);
	
	constant trigRate_MaxCount: integer:= 60000;
	
	type selfTrig_rateCount_array is array (0 to 4, 0 to 5) of natural;
	
	
	------------------------------------
	--	CLOCKS
	------------------------------------
	
	type clockSource_type is record
		localOsc		:	std_logic;
		jcpll			:	std_logic;
		usb_IFCLK	:	std_logic;
	end record;
	
	type jcpll_ctrl_type is record
		spi_latchEnable	:	std_logic;
		spi_mosi				:	std_logic;
		spi_clock			:	std_logic;
		powerDown			:	std_logic;
		outputEnable      :  std_logic;
		aux_in            :  std_logic;
		testsync          :  std_logic;
	end record;
		
	type clock_type is record
		sys			:	std_logic;
		x4				:	std_logic;
		x8				:	std_logic;
        local40     : std_logic;
        local160    : std_logic;
		usb         :	std_logic;  
		timer			:	std_logic;
		dacUpdate	:	std_logic;
		wilkUpdate	:	std_logic;
		altpllLock  :	std_logic;
  		localpllLock  :	std_logic;  
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
	--	LEDS
	------------------------------------
	constant numberOfLEDs: natural := 9;
	
	type LEDmode_type is record
		direct		: natural;
		monostable	: natural;
		flashing		: natural;
	end record;
	
	
	constant ledMode: LEDmode_type:= (1,2,3);		-- arbitrary numbers to identify different modes
	
	type LEDsetup_type is record
		input:			std_logic;
		mode:			natural;
		period:			natural;
		onTime:			natural;
	end record;
	
	type LEDtestSetup_type is record
		source:			natural;
		onTime:			natural;
		enable:			std_logic;
	end record;
	
	
	
	-- (led index, mode)
	type ledSetup_array_type is array (0 to 8, 0 to 3) of ledSetup_type;
	type ledFunction_array is array (0 to 8) of natural range 0 to 3;
	type ledTestFunction_array is array (0 to 8) of natural range 0 to 255;
	type ledTest_onTime_array is array (0 to 8) of natural range 0 to 4095;
	
	
	
	
	------------------------------------
	--	PSEC4 
	------------------------------------
	
	type PSEC4_in_type is record
		data			: std_logic_vector(11 downto 0);
		overflow		: std_logic;
		ringOsc_mon		: std_logic;
		DLL_clock		: std_logic;
		trig			: std_logic_vector(5 downto 0);
	end record;
	
	
	type PSEC4_out_type is record
		DLLreset_n		: std_logic;
		trigClear		: std_logic;
		rampStart		: std_logic;
		readClock		: std_logic;
		extTrig			: std_logic;
		ADCclear		: std_logic;
		ringOsc_enable	: std_logic;
		ADClatch		: std_logic;
		channel			: natural range 0 to M;
		TokDecode		: std_logic_vector(2 downto 0);
		TokIn			: std_logic_vector(1 downto 0);
	end record;
	
	
	
	type PSEC4_in_array_type is array (0 to N-1) of PSEC4_in_type;
	type PSEC4_out_array_type is array (0 to N-1) of PSEC4_out_type;
	
	------------------------------------
	--	RESET
	------------------------------------
	type reset_type is record
		global		:	std_logic;
		request		:	std_logic;
	end record;
	
	
	------------------------------------
	--	TEST MODE
	------------------------------------
	
	type testMode_type is record
		sequencedPsecData	:	std_logic;
		trig_noTransfer: std_logic;
	end record;
	
	
	
	
	
	
	------------------------------------
	--	TRIGGER
	------------------------------------
	
	
	type trigSetup_type is record
		
		mode					:	natural range 0 to 15;
		enable				: 	std_logic;
		transferEnableReq:	std_logic;		-- tells the acdc that one frame of data may be transmitted
		transferDisableReq:	std_logic;
		resetReq:	std_logic;					-- clear system time counter and event counter
		eventAndTime_reset:	std_logic;					-- clear system time counter and event counter
		valid_window_start	:  natural range 0 to 4095;	
		valid_window_len	:  natural range 0 to 4095;	
		use_clocked_trig:  std_logic;
		
		
		-- self trig
		selfTrig_mask				:	array6;			-- high = enable this bit for generating self-triggers
		selfTrig_coincidence_min:	natural range 0 to 31;	-- the minimum number of simultaneous [enabled] self-trig inputs that generates a trigger event
		selfTrig_threshold		:	natArray12;			-- A value that drives a DAC to set the analogue voltage threshold for self-trigger
		selfTrig_detect_mode: std_logic;
		selfTrig_sign: std_logic;
		selfTrig_use_coincidence: std_logic;
		
		
		
		-- sma
		sma_invert: std_logic;
		sma_detect_mode: std_logic;
		
		-- acc
		acc_invert: std_logic;
		acc_detect_mode: std_logic;
		
	end record;
	
	
	type trigInfo_type is array (0 to 2, 0 to 4) of std_logic_vector(15 downto 0);
	
	
	
	
	
	------------------------------------
	--	UART TX
	------------------------------------
	type uartTx_type is record
		byte				:	std_logic_vector(7 downto 0);
		valid				:	std_logic;
		serial			:	std_logic;
		ready	         :	std_logic;
		dataAck       	:	std_logic;
		dataTransferDone:	std_logic;
	end record;
	
	
	
	
	------------------------------------
	--	UART RX
	------------------------------------
	type uartRx_type is record
		serial			:	std_logic;
		byte				:	std_logic_vector(7 downto 0);
		valid				:	std_logic;
		error	         :	std_logic;
	end record;
	
	
	
	
	------------------------------------
	--	USB 
	------------------------------------
	
	type USB_in_type is record
		CTL		: std_logic_vector(2 downto 0);
		CLKOUT	: std_logic;
		WAKEUP	: std_logic;
	end record;
	
	
	type USB_out_type is record
		RDY	: std_logic_vector(1 downto 0);
	end record;
	
	
	type USB_bus_type is record
		FD	: std_logic_vector(15 downto 0);
		PA	: std_logic_vector(7 downto 0);
	end record;
	
	
	------------------------------------
	--	USB TX
	------------------------------------
	type usbTx_type is record
		word				:	std_logic_vector(7 downto 0);
		valid				:	std_logic;
		serial			:	std_logic;
		ready	         :	std_logic;
		dataAck       	:	std_logic;
		dataTransferDone:	std_logic;
	end record;
	
	
	
	
	------------------------------------
	--	USB RX
	------------------------------------
	type usbRx_type is record
		serial			:	std_logic;
		word				:	std_logic_vector(7 downto 0);
		valid				:	std_logic;
		error	         :	std_logic;
	end record;
	
    -----------------------------------
    --  rx parameter type
    -----------------------------------
    type RX_Param_type is record
        trigSetup               : trigSetup_type;   
        Vbias                   : natArray16;    
        DLL_Vdd                 : natArray16;     
        calEnable               : std_logic_vector(14 downto 0);   
        calInputSel             : std_logic;
        reset_request           : std_logic;   
        DLL_resetRequest        : std_logic;   
        PLL_resetRequest        : std_logic;   
        PLL_ConfigRequest       : std_logic;   
        PLL_ConfigReg           : std_logic_vector(31 downto 0);   
        RO_target               : natArray;   
        ramReadRequest          : std_logic;   
        IDrequest               : std_logic;
        ledFunction             : ledFunction_array;
        ledTestFunction         : ledTestFunction_array;
        ledTest_onTime          : ledTest_onTime_array;
        testMode                : testMode_type;
    end record;
	
	
end defs;






























