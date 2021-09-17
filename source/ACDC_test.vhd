---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ACDC
-- FILE:         ACDC_main.vhd
-- AUTHOR:       D. Greenshields, Rubinov
-- DATE:         Oct 2020				Jul 2021
--
-- DESCRIPTION:  top-level firmware module for ACDC
--
---------------------------------------------------------------------------------


library IEEE; 
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;


entity ACDC_test is
	port(	
		
		clockIn					: in clockSource_type;
		jcpll_ctrl				: out jcpll_ctrl_type;
		jcpll_lock				: in std_logic;
		LVDS_in					: in std_logic_vector(2 downto 0);
		LVDS_out					: out std_logic_vector(3 downto 0);		
		PSEC4_in					: in PSEC4_in_array_type;
		PSEC4_out				: buffer PSEC4_out_array_type;
		PSEC4_freq_sel			: out std_logic;
		PSEC4_trigSign			: out std_logic;
		calEnable				: inout std_logic_vector(14 downto 0);
		calInputSel          : out std_logic;
		--USB_in					: in USB_in_type;
		--USB_out					: out USB_out_type;
		--USB_bus					: inout USB_bus_type;
		DAC						: out DAC_array_type;
		SMA_trigIn				: in std_logic;
		ledOut     				: out std_logic_vector(numberOfLeds-1 downto 0)
		
		);
end ACDC_test;



architecture vhdl of	ACDC_test is
	
	
	-- system
	signal	clock					: clock_type;
	signal	reset					: reset_type;
	signal	systemTime			: std_logic_vector(63 downto 0);
	
	
	
	-- comms
	signal	uartTx			   : uartTx_type;
	signal	uartRx			   : uartRx_type;
	signal	usbTx			   	: usbTx_type;
	signal	usbRx			   	: usbRx_type;
	


    -- rx parameters
    signal  rxparams : RX_Param_type;
	
	
	-- monitor
	signal	burstFlash : std_logic;
	signal	ledDrv: std_logic_vector(numberOfLeds-1 downto 0);       
	signal	ledClock_1Hz : std_logic;
	signal	ledClock_10Hz : std_logic;
	signal	ledSetup				: ledSetup_array_type;
	signal	PSECmonitorLed	:	std_logic;		
	signal 	DLL_monitor			: bitArray;	
	signal	trigInfo	:			trigInfo_type;
	signal	selfTrig_mode :	std_logic;
	signal	selfTrig_rateCount: selfTrig_rateCount_array;
	signal	trig_rateCount	:	natural;
	signal	FLL_lock : std_logic_vector(N-1 downto 0);
	signal	cableDetect : std_logic;
	signal	phase_mon: std_logic;
	signal	trig_armed: std_logic;
	signal	ledMux: std_logic_vector(31 downto 0);
	signal	validate_pass: std_logic;
	signal	validate_fail: std_logic;
	signal	trig_validate	: std_logic;
	signal	validate_clear	: std_logic;
	
	
	
	
	
	-- data
	signal	timestamp : std_logic_vector(63 downto 0);
	signal	rampDone : std_logic_vector(7 downto 0);
	signal	eventCount : natural;
	signal   dataHandler_timeoutError: std_logic;	
	signal	readAddress: natural;
	signal	readData: wordArray;
	signal	info			: info_type;
--	signal	Wlkn_fdbk_target: natArray;
	signal	Wlkn_fdbk_current: natArray;
	signal	VCDL_count: natArray;
	signal	dacData			:	dacChain_data_array_type;
	signal	pro_vdd			:  natArray16;
	
	
	
	
	-- control
	signal 	trig_clear : std_logic;	
	signal 	DLL_reset			: std_logic;	
	signal   cmd					: cmd_type;
	signal 	adcStart: std_logic;	 	
	signal 	calSwitchEnable: std_logic_vector(14 downto 0);	
	signal	ramBufferFull	:	std_logic_vector(N-1 downto 0);		
	signal	psecDataStored : std_logic_vector(7 downto 0);
	signal	transfer_enable: std_logic;
	
	
	
	-- trig
	signal	acc_trig					: std_logic;
	signal	sma_trig					: std_logic;
	signal	self_trig				: std_logic;
	signal	digitize_request		: std_logic;
	signal	transfer_request		: std_logic;
	signal	digitize_done			: std_logic;
	signal	trig_event				: std_logic;
	signal	trig_out					: std_logic;
	
	
	-- new for PLL config

	
	
	
begin
	
	
	------------------------------------
	--	LED INDICATOR SETTINGS
	------------------------------------
	
	-- led matrix index (front panel view):	
	--
	--	Top      6  7  8	red
	-- Middle   3  4  5	yellow
	-- Bottom   0  1  2  green
	
	
	-- modes:
	-- 
	-- ledMode.flashing
	-- ledMode.monostable
	-- ledMode.direct
	--
	--
	-- led setup: (input, mode, onTime[ms], period[ms])
	--
	
	-- standard function
	ledSetup(0,0) <= (input => cmd.valid 					, mode => ledMode.monostable	, onTime => 500,	period => 0);
	ledSetup(1,0) <= (input => trig_event 				, mode => ledMode.monostable	, onTime => 500, period => 0);
	ledSetup(2,0) <= (input => burstFlash	and FLL_lock(0), mode => ledMode.direct		, onTime => 0, period => 0);
	ledSetup(3,0) <= (input => uartRx.valid				, mode => ledMode.monostable	, onTime => 500, period => 0);
	ledSetup(4,0) <= (input => jcpll_lock					, mode => ledMode.monostable	, onTime => 500, period => 0);
	ledSetup(5,0) <= (input => selfTrig_mode				, mode => ledMode.monostable	, onTime => 500, period => 0);
	ledSetup(6,0) <= (input => uartTx.valid 				, mode => ledMode.monostable	, onTime => 500, period => 0);
	ledSetup(7,0) <= (input => dll_reset or rxparams.trigSetup.resetReq, mode => ledMode.monostable, onTime => 500, period => 0);
	ledSetup(8,0) <= (input => burstFlash and clock.altPllLock, mode => ledMode.direct, onTime => 0, period => 0);
	
	-- test function
	LED_ON_OFF: for i in 0 to 8 generate
		ledSetup(i,1) <= (input => '1', mode => ledMode.direct, onTime => 0,	period => 0);
		ledSetup(i,2) <= (input => '0', mode => ledMode.direct, onTime => 0,	period => 0);
		ledSetup(i,3) <= (input => ledMux(rxparams.ledTestFunction(i)), mode => ledMode.direct, onTime => 0,	period => 0)
		when (rxparams.ledTest_onTime(i) <= 1) else (input => ledMux(rxparams.ledTestFunction(i)), mode => ledMode.monostable, onTime => rxparams.ledTest_onTime(i),	period => 0);
	end generate;
	
	-- led test signal multiplexer
	ledMux(0) <= '0';
	ledMux(1) <= cmd.valid;
	ledMux(2) <= FLL_lock(0);
	ledMux(3) <= transfer_request;
	ledMux(4) <= uartRx.valid;
	ledMux(5) <= uartTx.valid;
	ledMux(6) <= rxparams.IDrequest;
	ledMux(7) <= uartTx.dataTransferDone;
	ledMux(8) <= digitize_request;
	ledMux(9) <= digitize_done;
	ledMux(10) <= phase_mon;
	ledMux(11) <= self_trig;
	ledMux(12) <= trig_event;
	ledMux(13) <= trig_armed;
	ledMux(14) <= acc_trig;
	ledMux(15) <= sma_trigIn;
	ledMux(16) <= trig_out;
	ledMux(17) <= rampDone(0);
	ledMux(18) <= trig_clear;
	ledMux(19) <= rampDone(0);
	ledMux(20) <= rxparams.dll_resetRequest;
	ledMux(21) <= transfer_enable;	
	ledMux(22) <= PSEC4_in(0).overflow;
	ledMux(23) <= LVDS_in(0);
	ledMux(24) <= LVDS_in(1);
	ledMux(25) <= LVDS_in(2);	
	ledMux(26) <= cableDetect;	
	ledMux(27) <= validate_pass;	
	ledMux(28) <= validate_fail;	
	ledMux(29) <= trig_validate;	
	ledMux(30) <= validate_clear;	
	
	
	
	
	selfTrig_mode <= '1' when (rxparams.trigSetup.mode >= 4 and rxparams.trigSetup.mode <= 6) else '0';
	
	PSECmonitorLed <= PSEC4_out(2).trigClear or (not PSEC4_out(2).DLLreset_n);
	
	burstFlash <= ledClock_1Hz or ledClock_10Hz;
	
	
	LED_driver_gen: for i in 0 to numberOfLeds-1 generate
		LED_driver_map: LED_driver port map (
			clock	 	=> clock.timer,  
			setup		=> (input => '1', mode => ledMode.flashing, onTime => 50, period => 100),
			--setup		=> ledSetup(i, ledFunction(i)),
			output   => ledDrv(i));
		-- leds are inverse logic so invert the outputs
		ledOut(i) <= not ledDrv(i);
	end generate;
	
	
	-- 1Hz clock 
	LED_clock_1Hz: LED_driver port map (
		clock	 	=> clock.timer,        
		setup		=> (input => '1', mode => ledMode.flashing, onTime => 500, period => 1000),
		output   => ledClock_1Hz);
	
	-- 10Hz clock 
	LED_clock_10Hz: LED_driver port map (
		clock	 	=> clock.timer,        
		setup		=> (input => '1', mode => ledMode.flashing, onTime => 50, period => 100),
		output   => ledClock_10Hz);
	
	
	
	
	
	------------------------------------
	--	RESET
	------------------------------------
	RESET_PROCESS : process(clock.sys)
		variable t: natural := 0;		-- elaspsed time counter
		variable r: std_logic;
	begin
		if (rising_edge(clock.sys)) then 				
			if (reset.request = '1') then t := 0; end if;   -- restart counter if new reset request					 										
			if (t >= 40000000) then r := '0'; else r := '1'; t := t + 1; end if;
			reset.global <= r;
		end if;
	end process;
	
	
	
	
	------------------------------------
	--	CLOCKS
	------------------------------------
	
	clockGen_map: ClockGenerator Port map(
		pll_resetRequest	=> rxparams.pll_resetRequest,
		pll_configRequest => rxparams.pll_configRequest,
		pll_configReg	=>		rxparams.pll_configReg,
		clockIn			=> clockIn,		
		jcpll				=>	jcpll_ctrl,
		clock				=> clock			-- the generated clocks for use by the rest of the firmware
		);		
	
	
	
	
	------------------------------------
	--	LVDS 
	------------------------------------
	
	-- out
	LVDS_out(0) <=	uartTx.serial;	--  serial comms tx
	LVDS_out(1) <=	'0';	-- not used
	LVDS_out(2) <=	'0';	-- not used
	LVDS_out(3) <=	'0';	-- not used
	
	-- in
	uartRx.serial 	<= LVDS_in(0);	--  serial comms rx
	acc_trig		 	<= LVDS_in(1);
	cableDetect		<= LVDS_in(2);		-- detect second lvds cable plugged in (1=true, 0=false)
	
	
	
	------------------------------------
	--	UART
	------------------------------------
	-- serial comms with the acc
	uart_map : uart
	GENERIC map (
		dataLen => 8, 
		clockDivRatio => 8 
		)
	port map(
		clock				=> clock.local160,  -- 160MHz clock for communications
		reset				=> reset.global,	-- global reset
		txData			=> uartTx.byte,
		txData_valid	=> uartTx.valid,	
		txData_ack		=> uartTx.dataAck,
		txReady			=>	uartTx.ready,
		txOut				=> uartTx.serial,
		rxData			=> uartRx.byte,
		rxData_valid	=> uartRx.valid,
		rxError			=> uartRx.error,
		rxIn				=> uartRx.serial);
	
	
	
	------------------------------------
	--	RX COMMAND
	------------------------------------
	-- receives a command word from the ACC
		rx_cmd_map: rxCommand PORT map
		(
		reset 			=> reset.global,
		clock 			=> clock,
		din 				=> uartRx.byte,
		din_valid		=> uartRx.valid,
		dout 				=> cmd.word,			-- instruction word out
		dOut_valid		=> cmd.valid);		
	
	
	------------------------------------
	--	COMMAND HANDLER
	------------------------------------
	cmd_handler_map: commandHandler port map (
		reset				=> reset.global,
		clock				=> clock.local40,
        clock_out           => clock.sys,     
		din		      =>	cmd.word,	
		din_valid		=> cmd.valid,
        params          => rxparams
	);

    calEnable <= rxparams.calEnable;
    calInputSel <= rxparams.calInputSel;
    reset.request <= rxparams.reset_request;
	
	------------------------------------
	--	DATA HANDLER 
	------------------------------------
	-- transmits the contents of the ram buffers plus other info over the uart
		dataHandler_map: dataHandler port map (
		reset					=> reset.global,
		clock					=> clock,
		info					=> info,
		IDrequest				=> rxparams.IDrequest,
		readRequest				=> transfer_request,
		uartTx_done				=> uartTx.dataTransferDone,
		ramAddress           	=> readAddress,
		ramData              	=> readData,
		txByte	            	=> uartTx.byte,
		txByte_valid	 	   	=> uartTx.valid,
		txByte_ack           	=> uartTx.dataAck,
		txReady              	=> uartTx.ready,
		timeoutError  			=> dataHandler_timeoutError,
		selfTrig_rateCount		=> selfTrig_rateCount,
		trig_rateCount			=> trig_rateCount,			 
		PLL_ConfigReg			=> rxparams.pll_ConfigReg, 			
		testMode				=> rxparams.testMode
		);
	
	------------------------------------
	--	INFO
	------------------------------------
	
	info_array: process(clock.sys)
	begin
		if (rising_edge(clock.sys)) then
			for i in 0 to N-1 loop
				info(i,0) <= x"BA11";
				info(i,1) <= std_logic_vector(to_unsigned(Wlkn_fdbk_current(i),16));
				info(i,2) <= std_logic_vector(to_unsigned(rxparams.RO_target(i),16));
				info(i,3) <= std_logic_vector(to_unsigned(rxparams.vbias(i),16));
				info(i,4) <= std_logic_vector(to_unsigned(rxparams.trigSetup.selfTrig_threshold(i),16));
				info(i,5) <= std_logic_vector(to_unsigned(pro_vdd(i),16));
				info(i,6) <= trigInfo(0,i);
				info(i,7) <= trigInfo(1,i);
				info(i,8) <= trigInfo(2,i);
				
				if (transfer_request = '1') then
					case i is
						when 0 => info(i,9) <= timestamp(15 downto 0);
						when 1 => info(i,9) <= timestamp(31 downto 16);
						when 2 => info(i,9) <= timestamp(47 downto 32);
						when 3 => info(i,9) <= timestamp(63 downto 48);
						when others => null;
					end case;
					
					case i is
						--when 0 => info(i,10) <= std_ulogic_vector(to_unsigned(eventCount,32))(15 downto 0);
						--when 1 => info(i,10) <= std_ulogic_vector(to_unsigned(eventCount,32))(31 downto 16);
						when others => null;
					end case;
				end if;
				
				
				--info(i,11) <= std_logic_vector(to_unsigned(vcdl_count(i),32))(15 downto 0);
				--info(i,12) <= std_logic_vector(to_unsigned(vcdl_count(i),32))(31 downto 16);
				info(i,13) <= std_logic_vector(to_unsigned(rxparams.dll_vdd(i),16));
			end loop;
		end if;
	end process;
	
	
	
	
	
	
	
	------------------------------------
	--	PSEC4 DRIVER
	------------------------------------
	
	-- global to all PSEC chips
	PSEC4_freq_sel <= '0';
	PSEC4_trigSign <= rxparams.trigSetup.selfTrig_sign;
	
	
	-- driver for each PSEC chip
	PSEC4_drv: for i in N-1 downto 0 generate
		PSEC4_drv_map : PSEC4_driver port map(
			clock					=>	clock,
			reset					=> reset.global,
			trig					=> trig_out,
			trigSign				=> rxparams.trigSetup.selfTrig_sign,
			selftrig_clear		=> trig_clear,
			digitize_request	=> digitize_request,
			rampDone				=> rampDone(i),
			adcReset				=> reset.global or uartTx.dataTransferDone,
			PSEC4_in				=>	PSEC4_in(i),
			DLL_reset			=> DLL_reset,
			Wlkn_fdbk_target	=> rxparams.RO_target(i),
			PSEC4_out			=> PSEC4_out(i),
			VCDL_count			=> VCDL_count(i),
			DAC_value			=> pro_vdd(i),
			Wlkn_fdbk_current => Wlkn_fdbk_current(i),
			DLL_monitor			=> open,			-- not used
			ramReadAddress		=> readAddress,
			ramDataOut			=> readData(i),
			ramBufferFull		=> psecDataStored(i),
			FLL_lock				=> FLL_lock(i));
	end generate;
	
	
	DIGITIZED_PSEC_DATA_CHECK: process(clock.sys)		-- essentially an AND gate 
		variable done: std_logic;
	begin
		if (rising_edge(clock.sys)) then
			done := '1';
			for i in 0 to N-1 loop
				if (psecDataStored(i) = '0') then done := '0'; end if;
			end loop;
			digitize_done <= done;	-- all PSEC4 chip have stored their data in firmware RAM buffer
		end if;
	end process;
	
	
	------------------------------------
	--	DAC DRIVER
	------------------------------------
	-- dacData (chain: 0 to 3) (device: 0 to 1) (channel: 0 to 7) 
	--
	-- 8 dacs per device
	-- 2 devices per chain
	-- 3 chains in total 
	--
	-- PSEC 0 = chain 0, device 0	(DAC U38)
	-- PSEC 1 = chain 0, device 1	(DAC U39)
	-- PSEC 2 = chain 1, device 0	(DAC U40)
	-- PSEC 3 = chain 1, device 1	(DAC U41)
	-- PSEC 4 = chain 2, device 0	(DAC U42)
	--
	-- Additional trig threshold DACs
	-- PSEC 0,1,2 chain 3, device 0 (U18)
	-- PSEC 2,3,4 chain 3, device 1 (U19)
	-- INDEPENDENT Trig threshold settings are not yet implemented!!!!
	--
	AssignDacData: process(clock.sys)
		variable chain: natural;
		variable device: natural;
	begin
		if (rising_edge(clock.sys)) then
			chain := 0;
			device := 0;
			for i in 0 to N-1 loop	-- for each PSEC4 chip			
				--
				dacData(chain)(device)(0) <= rxparams.Vbias(i);
				dacData(chain)(device)(1) <= rxparams.trigSetup.selfTrig_threshold(i);
				dacData(chain)(device)(2) <= rxparams.trigSetup.selfTrig_threshold(i);
				dacData(chain)(device)(3) <= pro_vdd(i);
				dacData(chain)(device)(4) <= 4095 - pro_vdd(i);
				dacData(chain)(device)(5) <= 4095 - rxparams.dll_vdd(i);
				dacData(chain)(device)(6) <= rxparams.dll_vdd(i);
				dacData(chain)(device)(7) <= rxparams.trigSetup.selfTrig_threshold(i);
				
				-- increment counters
				device := device + 1;		
				if (device >= 2) then
					device := 0;
					chain := chain + 1;
				end if;
				
				
			end loop;
			
			dacData(3)(0)(0) <= rxparams.trigSetup.selfTrig_threshold(0);
			dacData(3)(0)(1) <= rxparams.trigSetup.selfTrig_threshold(0);
			dacData(3)(0)(2) <= rxparams.trigSetup.selfTrig_threshold(0);
			dacData(3)(0)(3) <= rxparams.trigSetup.selfTrig_threshold(1);
			dacData(3)(0)(4) <= rxparams.trigSetup.selfTrig_threshold(1);
			dacData(3)(0)(5) <= rxparams.trigSetup.selfTrig_threshold(1);
			dacData(3)(0)(6) <= rxparams.trigSetup.selfTrig_threshold(2);
			dacData(3)(0)(7) <= 0;
			dacData(3)(1)(0) <= rxparams.trigSetup.selfTrig_threshold(3);
			dacData(3)(1)(1) <= rxparams.trigSetup.selfTrig_threshold(3);
			dacData(3)(1)(2) <= rxparams.trigSetup.selfTrig_threshold(3);
			dacData(3)(1)(3) <= rxparams.trigSetup.selfTrig_threshold(4);
			dacData(3)(1)(4) <= rxparams.trigSetup.selfTrig_threshold(4);
			dacData(3)(1)(5) <= rxparams.trigSetup.selfTrig_threshold(4);
			dacData(3)(1)(6) <= rxparams.trigSetup.selfTrig_threshold(2);
			dacData(3)(1)(7) <= rxparams.trigSetup.selfTrig_threshold(2);
			
		end if;
	end process;
	
	
	dacSerial_gen: for i in 0 to 3 generate		-- 3x dac daisy chain
		dacSerial_map: dacSerial port map(
			clock			=> clock,
			dataIn       => dacData(i),			-- data values (0 to 1)(0 to 7)  =  (chain device number)(device channel)
			dac   			=> dac(i));				-- output pins to dac chip
	end generate;
	
	
	
	
	
	
	------------------------------------
	--	TRIGGER
	------------------------------------
	trigger_map: trigger port map(
		clock						=> clock,
		reset						=> reset.global, 
		systemTime				=> systemTime,
		testMode					=> rxparams.testMode,
		trigSetup				=> rxparams.trigSetup,
		trigInfo					=> trigInfo,
		acc_trig					=> acc_trig,
		sma_trig					=> sma_trigIn,
		self_trig				=> self_trig,
		sma_validate			=> sma_trigIn,
		digitize_request		=> digitize_request,
		transfer_request		=> transfer_request,
		digitize_done			=> digitize_done,
		transfer_enable		=> transfer_enable,
		transfer_done			=> uartTx.dataTransferDone,
		eventCount				=> eventCount,
		timestamp				=> timestamp,
		validate_pass			=> validate_pass,
		validate_fail			=> validate_fail,
		trig_validate			=> trig_validate,
		validate_clear			=> validate_clear,
		trig_event				=> trig_event,
		trig_clear				=> trig_clear,
		trig_armed				=> trig_armed,
		trig_out					=> trig_out,
		trig_rate_count		=> trig_rateCount);
	
	
	
	
	
	
	
	------------------------------------
	--	SELF TRIGGER
	------------------------------------
	selfTrigger_map: selfTrigger port map(
		clock						=> clock,
		reset						=> reset.global,
		PSEC4_in					=>	PSEC4_in,
		testMode					=> rxparams.testMode,
		trigSetup				=> rxparams.trigSetup,
		trig_out					=> self_trig,
		rateCount				=> selfTrig_rateCount
		);
	
	
	
	
	
	
	
	------------------------------------
	--	DLL RESET
	------------------------------------
	DLL_RESET_PROCESS : process(clock.sys)
		variable t: natural := 0;		-- elaspsed time counter
		variable r: std_logic;
	begin
		if (rising_edge(clock.sys)) then 						
			if (reset.global = '1' or rxparams.DLL_resetRequest = '1') then t := 0; end if;		-- restart counter if new reset request	
			if (t >= 40000000) then r := '0'; else r := '1'; t := t + 1; end if;
			DLL_reset <= r; 			
		end if;
	end process;
	
	
	
	
	
	
	
	------------------------------------
	--	SYSTEM TIME
	------------------------------------
	-- 64 bit counter running at 320MHz
	SYS_TIME_GEN: systemTime_driver port map(
		clock		=> clock,
		reset		=> reset.global or rxparams.trigSetup.eventAndTime_reset,
		phase_mon => phase_mon,
		q			=> systemTime
		);
	
	
	
	
	
	
end vhdl;
