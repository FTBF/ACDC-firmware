---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         ACDC_main.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         June 2021
--
-- DESCRIPTION:  top-level firmware module for ACDC
--
---------------------------------------------------------------------------------


library IEEE; 
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL; 
use ieee.std_logic_misc.all;
use work.defs.all;
use work.components.all;
use work.LibDG.all;



entity ACDC_main is
	port(	
	
		clockIn					: in     clockSource_type;
		jcpll_ctrl				: out    jcpll_ctrl_type;
		jcpll_lock				: in     std_logic;
        jcpll_spi_miso			: in     std_logic;
		LVDS_in					: in	 std_logic_vector(2 downto 0);
		LVDS_out				: out    std_logic_vector(3 downto 0);		
		PSEC4_in				: in     PSEC4_in_array_type;
		PSEC4_out				: buffer PSEC4_out_array_type;
		PSEC4_freq_sel			: out    std_logic;
		PSEC4_trigSign			: out    std_logic;
        enableV1p2a             : out    std_logic;
		calEnable				: inout  std_logic_vector(14 downto 0);
		DAC						: out    DAC_array_type;
		SMA_J5					: inout  std_logic;
		SMA_J16					: in     std_logic;
		ledOut     				: out    std_logic_vector(8 downto 0);
        debug2                  : out    std_logic;
        debug3                  : out    std_logic
);
end ACDC_main;
	
	
	
architecture vhdl of	ACDC_main is

	
	signal	clock			   : clock_type;
	signal	reset			   : reset_type;
	signal	systemTime		   : std_logic_vector(63 downto 0);
	signal	serialTx		   : serialTx_type;
	signal	serialRx		   : serialRx_type;
	signal	txBusy			   : std_logic;
	signal	ledSetup		   : LEDSetup_type;
	signal	ledPreset          : ledPreset_type;
	signal 	DLL_monitor		   : bitArray;	
	signal	trigInfo           : trigInfo_type;
	signal	selfTrig_mode      : std_logic;
	signal	selfTrig_rateCount : selfTrig_rateCount_array;
	signal	trig_rateCount     : natural;
	signal	FLL_lock           : std_logic_vector(N-1 downto 0);
	signal	ppsCount           : std_logic_vector(31 downto 0);
	signal	beamGateCount      : std_logic_vector(31 downto 0);
	signal	acc_beamGate       : std_logic;
	signal	pps_trig           : std_logic;
	signal	timestamp          : std_logic_vector(63 downto 0);
	signal	beamgate_timestamp : std_logic_vector(63 downto 0);
	signal	rampDone           : std_logic_vector(7 downto 0);
	signal	eventCount         : std_logic_vector(31 downto 0);		-- increments for every trigger event (i.e. only signal triggers, not for pps triggers)
	signal	readAddress        : natural;
	signal	readData           : wordArray;
 	signal	Wlkn_fdbk_current  : natArray;
 	signal	VCDL_count         : array32;
	signal	dacData            : dacChain_data_array_type;
	signal	pro_vdd            : natArray16;
	signal 	serialNumber       : natural;		-- increments for every frame sent, regardless of type
	signal 	trig_clear         : std_logic;	
	signal  cmd				   : cmd_type;
	signal 	calSwitchEnable    : std_logic_vector(14 downto 0);	
	signal	psecDataStored     : std_logic_vector(7 downto 0);
	signal	trig_frameType     : natural;
	signal	systemTime_reset   : std_logic;
	signal	acc_trig		   : std_logic;
	signal	self_trig		   : std_logic;
	signal	digitize_request   : std_logic;
	signal	transfer_request   : std_logic;
	signal	digitize_done	   : std_logic;
	signal	trig_event		   : std_logic;
	signal	trig_out		   : std_logic;
	signal	sma_trigIn		   : std_logic;
	signal	trig_detect		   : std_logic;
	signal 	trig_valid 		   : std_logic;
	signal 	trig_abort 		   : std_logic;
	signal 	trig_busy 		   : std_logic;
	signal 	pps_detect 		   : std_logic;
	signal 	signal_trig_detect : std_logic;
	signal 	led_trig		   : std_logic_vector(8 downto 0);
	signal 	led_mono		   : std_logic_vector(8 downto 0);
    signal  reset_acc_z        : std_logic;
	
	signal  rxparams           : RX_Param_jcpll_type;
    signal  rxparams_syncAcc   : RX_Param_jcpll_type;
    signal  rxparams_acc       : RX_Param_acc_type;

    signal fifoRead            : std_logic_vector(N-1 downto 0);
    signal fifoDataOut         : array16;
    signal fifoOcc             : array13;
    signal dataToSend          : hs_input_array;
    signal dataToSend_valid    : std_logic_vector(1 downto 0);
    signal dataToSend_kout     : std_logic_vector(1 downto 0);
    signal dataToSend_ready    : std_logic_vector(1 downto 0);

    signal  serialTx_data      : std_logic_vector(1 downto 0);
		
begin


-- SMA connectors
sma_trigIn <= SMA_J16;
SMA_J5 <= txBusy;  



------------------------------------
--	LED DRIVER
------------------------------------
-- led matrix index (front panel view):	
--
--	Top      6  7  8	red
-- Middle   3  4  5	yellow
-- Bottom   0  1  2  green

selfTrig_mode <= '1' when (rxparams.trigSetup.mode >= 4 and rxparams.trigSetup.mode <= 6) else '0';

LED_SIG_DETECT: for i in 0 to 8 generate
	LED_MONOSTABLE: monostable_async_level port map (clock.sys, 4000000, led_trig(i), led_mono(i));
end generate;


led_trig(0) <= not serialRx.symbol_align_error;
led_trig(1) <= FLL_lock(1);
led_trig(2) <= signal_trig_detect;
led_trig(3) <= cmd.valid;
led_trig(4) <= jcpll_lock and clock.altPllLock;
led_trig(5) <= pps_detect;
led_trig(6) <= serialTx.ack;
led_trig(7) <= reset.global or selfTrig_mode;
led_trig(8) <= acc_beamGate;


LED_CTRL: process(clock.sys)
begin
	if (rising_edge(clock.sys)) then
		for i in 0 to 8 loop ledOut(i) <= not led_mono(i); end loop;
	end if;
end process;
			


------------------------------------
--	RESET
------------------------------------
RESET_PROCESS : process(clock.acc40, clock.accpllLock)
  variable t: unsigned(8 downto 0) := "000000000";		-- elaspsed time counter
  variable r: std_logic;
begin
  if clock.accpllLock = '0' then
    t := "000000000";
    reset.acc <= '1';
  elsif (rising_edge(clock.acc40)) then 				
    if (reset.request = '1') then t := "000000000"; end if;   -- restart counter if new reset request					 										
    if (t >= 400) then r := '0'; else r := '1'; t := t + 1; end if;
    reset.acc <= r;
  end if;
end process;

-- reset synchronizers
RESET_SYNC : process(clock.sys)
  variable reset_sync_1 : std_logic;
  variable reset_sync_2 : std_logic;
begin
  if rising_edge(clock.sys) then
    reset_sync_1 := reset.acc;
    reset_sync_2 := reset_sync_1;
    reset.global <= reset_sync_2;
  end if;
end process;

PreRESET_SYNC_25MHz : process(clock.acc40)
begin
  if rising_edge(clock.acc40) then
    reset_acc_z <= reset.acc;
  end if;
end process;

RESET_SYNC_25MHz : process(clock.serial25)
  variable reset_sync_1 : std_logic;
  variable reset_sync_2 : std_logic;
begin
  if rising_edge(clock.serial25) then
    reset_sync_1 := reset_acc_z;
    reset_sync_2 := reset_sync_1;
    reset.serial <= reset_sync_2;
  end if;
end process;

RESET_SYNC_125MHz : process(clock.serial125)
  variable reset_sync_1 : std_logic;
  variable reset_sync_2 : std_logic;
begin
  if rising_edge(clock.serial125) then
    reset_sync_1 := reset.serial;
    reset_sync_2 := reset_sync_1;
    reset.serialFast <= reset_sync_2;
  end if;
end process;

-- fix the 1.2V analog linear regular on 
enableV1p2a <= '1';

      
------------------------------------
--	CLOCKS
------------------------------------
clockGen_inst: ClockGenerator
  port map (
    clockIn           => clockIn,
    jcpll             => jcpll_ctrl,
    clock             => clock,
    PLL_ConfigRequest => rxparams_acc.PLL_ConfigRequest,
    PLL_ConfigReg     => rxparams_acc.PLL_ConfigReg,
    reset             => reset.acc);



------------------------------------
--	LVDS 
------------------------------------
LVDS_out(0) <=	serialTx.serial;	--  serial comms tx
LVDS_out(1) <=	'0';	-- not used -- PLL CLK OUTPUT ONLY!!!
LVDS_out(2) <=	serialTx_data(0);	-- data links
LVDS_out(3) <=	serialTx_data(1);	-- data links
serialRx.serial 	<= LVDS_in(0);	--  serial comms rx
acc_trig		 		<= LVDS_in(1);

debug2 <= jcpll_spi_miso;
debug3 <= jcpll_ctrl.spi_clock;
   
------------------------------------
--	SERIAL TX
------------------------------------
-- serial comms to the acc
serialTx_map : synchronousTx_8b10b
	port map(
		clock 				    => clock.acc40,		
		rd_reset				=> reset.acc,
		din 					=> serialTx.data,
		txReq					=> serialTx.req,
		txAck					=> serialTx.ack,
		dout 					=> serialTx.serial	-- serial bitstream out
	);

	
		

------------------------------------
--	SERIAL RX
------------------------------------
-- serial comms from the acc
serialRx_map : synchronousRx_8b10b
	port map(
		clock_sys		   => clock.acc40,
		clock_x4		   => clock.acc160,
		clock_x8		   => clock.acc320,
		din				   => serialRx.serial,
		rx_clock_fail	   => serialRx.rx_clock_fail,
		symbol_align_error => serialRx.symbol_align_error,
		symbol_code_error  => serialRx.symbol_code_error,
		disparity_error	   => serialRx.disparity_error,
		dout 			   => serialRx.data,
		kout 			   => serialRx.kout,
		dout_valid		   => serialRx.valid
	);

------------------------------------
--	SERIAL TX high speed
------------------------------------	
serialTx_highSpeed_inst: serialTx_highSpeed
  port map (
    clk    => clock,
    reset  => reset,
    input       => dataToSend,
    input_ready => dataToSend_ready,
    input_valid => dataToSend_valid,
    input_kout  => dataToSend_kout,
    outputMode => rxparams_acc.outputMode,
    output => serialTx_data);
	
data_readout_control_inst: data_readout_control
  port map (
    clock            => clock,
    reset            => reset,
    fifoRead         => fifoRead,
    fifoDataOut      => fifoDataOut,
    fifoOcc          => fifoOcc,
    dataToSend       => dataToSend,
    dataToSend_valid => dataToSend_valid,
    dataToSend_kout  => dataToSend_kout,
    dataToSend_ready => dataToSend_ready);


------------------------------------
--	RX COMMAND
------------------------------------
-- receives a command word from the ACC
rx_cmd_map: rxCommand PORT map
	(
		clock 	   => clock.acc40,
		din 	   => serialRx.data,
		din_valid  => serialRx.valid and (not serialRx.kout),	-- only want to receive data bytes, not control bytes
		dout 	   => cmd.word,			-- instruction word out
		dOut_valid => cmd.valid
	);		

	
	

------------------------------------
--	COMMAND HANDLER
------------------------------------
cmd_handler_map: commandHandler port map (
		reset	       => reset.acc,
		clock	       => clock.acc40,
        clock_out      => clock.sys,     
        din		       => cmd.word,	
        din_valid      => cmd.valid,
        params         => rxparams,
        params_syncAcc => rxparams_syncAcc,
        params_acc     => rxparams_Acc
		);

calEnable 	<= rxparams_acc.calEnable;
reset.request <= rxparams_acc.reset_request;
		
------------------------------------
--	DATA HANDLER 
------------------------------------
-- transmits the contents of the ram buffers plus other info over the uart
dataHandler_map: dataHandler port map (
        -- clock and reset signals
		reset			   => reset.acc,
		clock			   => clock.acc40,
        jcpll_clock        => clock.sys,

        --data stream and control signals
        txData	           => serialTx.data,
		txReq	 	   	   => serialTx.req,
        txAck              => serialTx.ack,
		txBusy			   => txBusy,

        --ACC clock parameters 
		serialRX		   => serialRx,
        rxparams           => rxparams_syncAcc,
		IDrequest		   => rxparams_acc.IDrequest,

        --jc pll clock parameters, these need CDC!!!
        trigInfo		   => trigInfo,
		Wlkn_fdbk_current  => Wlkn_fdbk_current,
		pro_vdd			   => pro_vdd,
		vcdl_count		   => vcdl_count,
		timestamp		   => timestamp,
		beamgate_timestamp => beamgate_timestamp,
		ppsCount  		   => ppsCount,
		beamGateCount      => beamGateCount,
        eventCount		   => eventCount,
		readRequest		   => transfer_request,
        trigTransferDone   => serialTx.trigTransferDone,
        ramAddress         => readAddress,
        ramData            => readData,
		selfTrig_rateCount => selfTrig_rateCount,
		trig_rateCount	   => trig_rateCount,
		trig_frameType	   => trig_frameType
);





------------------------------------
--	TRIGGER
------------------------------------
trigger_map: trigger port map(
			clock			   => clock,
			reset			   => reset.global, 
			systemTime		   => systemTime,
			testMode		   => rxparams.testMode,
			trigSetup		   => rxparams.trigSetup,
			selfTrig		   => rxparams.selfTrig,
			trigInfo		   => trigInfo,
			acc_trig		   => acc_trig,
			sma_trig		   => sma_trigIn xor rxparams.trigSetup.sma_invert,
			self_trig		   => self_trig,
			digitize_request   => digitize_request,
			transfer_request   => transfer_request,
			digitize_done	   => digitize_done,
			transfer_enable	   => open,
			transfer_done	   => serialTx.trigTransferDone,
			eventCount		   => eventCount,
			ppsCount		   => ppsCount,
			beamGateCount	   => beamGateCount,
			timestamp		   => timestamp,
			beamgate_timestamp => beamgate_timestamp,
			frameType		   => trig_frameType,
			acc_beamGate	   => acc_beamGate,
			trig_detect 	   => trig_detect,
			trig_valid 		   => trig_valid,
			trig_abort 		   => trig_abort,
			signal_trig_detect => signal_trig_detect,
			pps_detect 		   => pps_detect,
			busy			   => trig_busy,
			trig_event		   => trig_event,
			trig_clear		   => trig_clear,
			trig_out		   => trig_out,
			trig_rate_count	   => trig_rateCount);
			

		
		
	
	
------------------------------------
--	SELF TRIGGER
------------------------------------
selfTrigger_map: selfTrigger port map(
			clock	  => clock,
			reset	  => reset.global,
			PSEC4_in  => PSEC4_in,
			testMode  => rxparams.testMode,
			trigSetup => rxparams.trigSetup,
			selfTrig  => rxparams.selfTrig,	-- self trig setup 
			trig_out  => self_trig,
			rateCount => selfTrig_rateCount
			);

			
		
	


------------------------------------
--	PSEC4 DRIVER
------------------------------------

-- global to all PSEC chips
PSEC4_freq_sel <= '0';
PSEC4_trigSign <= rxparams.selfTrig.sign;

-- driver for each PSEC chip
PSEC4_drv: for i in N-1 downto 0 generate
	PSEC4_drv_map : PSEC4_driver port map(
		clock			  => clock,
		reset			  => reset,
		DLL_resetRequest  => rxparams.DLL_resetRequest,
		DLL_updateEnable  => rxparams.testMode.DLL_updateEnable(i),
		trig			  => trig_out,
		trigSign		  => rxparams.selfTrig.sign,
		selftrig_clear	  => trig_clear,
		digitize_request  => digitize_request,
		rampDone		  => rampDone(i),
		adcReset		  => reset.global,
		PSEC4_in		  => PSEC4_in(i),
		Wlkn_fdbk_target  => rxparams.RO_target(i),
		PSEC4_out		  => PSEC4_out(i),
		VCDL_count		  => VCDL_count(i),
		DAC_value		  => pro_vdd(i),
		Wlkn_fdbk_current => Wlkn_fdbk_current(i),
		DLL_monitor		  => open,			-- not used
        fifoRead          => fifoRead(i),
        fifoDataOut		  => fifoDataOut(i),
        fifoOcc           => fifoOcc(i),
        readoutDone       => psecDataStored(i),
		FLL_lock		  => FLL_lock(i));
end generate;


DIGITIZED_PSEC_DATA_CHECK: process(clock.sys)		-- essentially an AND gate 
  variable psecDataStored_z   : std_logic_vector(N-1 downto 0) := (others => '0');
begin
    digitize_done <= and_reduce(psecDataStored_z);	-- all PSEC4 chip have stored their data in firmware RAM buffer
	if (rising_edge(clock.sys)) then
      if and_reduce(psecDataStored_z) then
        psecDataStored_z := (others => '0');
      else
		for i in 0 to N-1 loop
          if (psecDataStored(i) = '1') then
            psecDataStored_z(i) := '1';
          end if;
		end loop;          
      end if;
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
			dacData(chain)(device)(1) <= rxparams.selfTrig.threshold(i, 0);
			dacData(chain)(device)(2) <= rxparams.selfTrig.threshold(i, 1);
			dacData(chain)(device)(3) <= pro_vdd(i);
			dacData(chain)(device)(4) <= 4095 - pro_vdd(i);
			dacData(chain)(device)(5) <= 4095 - rxparams.dll_vdd(i);
			dacData(chain)(device)(6) <= rxparams.dll_vdd(i);
			dacData(chain)(device)(7) <= rxparams.selfTrig.threshold(i, 2);
		
			-- increment counters
			device := device + 1;		
			if (device >= 2) then device := 0; chain := chain + 1; end if;						
	
		end loop;

        dacData(3)(0)(0) <= rxparams.selfTrig.threshold(0, 3);
        dacData(3)(0)(1) <= rxparams.selfTrig.threshold(0, 4);
        dacData(3)(0)(2) <= rxparams.selfTrig.threshold(0, 5);
        dacData(3)(0)(3) <= rxparams.selfTrig.threshold(1, 3);
        dacData(3)(0)(4) <= rxparams.selfTrig.threshold(1, 4);
        dacData(3)(0)(5) <= rxparams.selfTrig.threshold(1, 5);
        dacData(3)(0)(6) <= rxparams.selfTrig.threshold(2, 3);
        dacData(3)(0)(7) <= 0;
        dacData(3)(1)(0) <= rxparams.selfTrig.threshold(3, 3);
        dacData(3)(1)(1) <= rxparams.selfTrig.threshold(3, 4);
        dacData(3)(1)(2) <= rxparams.selfTrig.threshold(3, 5);
        dacData(3)(1)(3) <= rxparams.selfTrig.threshold(4, 3);
        dacData(3)(1)(4) <= rxparams.selfTrig.threshold(4, 4);
        dacData(3)(1)(5) <= rxparams.selfTrig.threshold(4, 5);
        dacData(3)(1)(6) <= rxparams.selfTrig.threshold(2, 4);
        dacData(3)(1)(7) <= rxparams.selfTrig.threshold(2, 5);
	end if;
end process;
	

dacSerial_gen: for i in 0 to 3 generate		-- 3x dac daisy chain
	dacSerial_map: dacSerial port map(
        clock			=> clock,
        reset        => reset.global,
        dataIn       => dacData(i),			-- data values (0 to 1)(0 to 7)  =  (chain device number)(device channel)
        dac   			=> dac(i));				-- output pins to dac chip
end generate;



			

		
------------------------------------
--	SYSTEM TIME
------------------------------------
-- 64 bit counter running at 320MHz
SYS_TIME_GEN: fastCounter64 port map (
		clock		=> clock.x8,
		reset		=> systemTime_reset,
		q			=> systemTime
);

		
-- synchronize reset to x8 clock
SYS_TIME_RESET: pulseSync port map (clock.sys, clock.x8, reset.global or rxparams.trigSetup.eventAndTime_reset, systemTime_reset);

   
 

 
 

 
end vhdl;
