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
        calInputSel             : out    std_logic;
		DAC						: out    DAC_array_type;
		SMA_J3					: in     std_logic;
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
	signal  trig_count_all     : std_logic_vector(31 downto 0);
    signal  trig_count	       : std_logic_vector(31 downto 0);
    signal  trig_count_reset   : std_logic;
	signal	FLL_lock           : std_logic_vector(N-1 downto 0);
	signal	rampDone           : std_logic_vector(7 downto 0);
	signal	eventCount         : std_logic_vector(31 downto 0);		-- increments for every trigger event (i.e. only signal triggers, not for pps triggers)
 	signal	Wlkn_fdbk_current  : natArray;
 	signal	VCDL_count         : array32;
	signal	dacData            : dacChain_data_array_type;
	signal	pro_vdd            : natArray16;
	signal 	serialNumber       : natural;		-- increments for every frame sent, regardless of type
	signal 	trig_clear         : std_logic;	
	signal  cmd				   : cmd_type;
	signal 	calSwitchEnable    : std_logic_vector(14 downto 0);	
	signal	psecDataStored     : std_logic_vector(7 downto 0);
	signal	systemTime_reset   : std_logic;
	signal	acc_trig		   : std_logic;
	signal	self_trig		   : std_logic;
	signal	digitize_request   : std_logic;
	signal	digitize_done	   : std_logic;
	signal	trig_out		   : std_logic;
	signal 	trig_busy 		   : std_logic;
	signal 	led_trig		   : std_logic_vector(8 downto 0);
	signal 	led_mono		   : std_logic_vector(8 downto 0);
    signal  reset_sync         : std_logic;
	
	signal  rxparams           : RX_Param_jcpll_type;
    signal  rxparams_syncAcc   : RX_Param_jcpll_type;
    signal  rxparams_acc       : RX_Param_acc_type;

    signal fifoRead            : std_logic_vector(N-1 downto 0);
    signal fifoDataOut         : array16;
    signal fifoOcc             : array16;
    signal dataToSend          : hs_input_array;
    signal dataToSend_valid    : std_logic_vector(1 downto 0);
    signal dataToSend_kout     : std_logic_vector(1 downto 0);
    signal dataToSend_ready    : std_logic_vector(1 downto 0);

    signal sys_timestamp       : std_logic_vector(63 downto 0);
    signal sys_ts_read         : std_logic;
    signal sys_ts_valid        : std_logic;
    signal wr_timestamp	       : std_logic_vector(63 downto 0);
    signal wr_ts_read          : std_logic;
    signal wr_ts_valid         : std_logic;

    signal backpressure_in     : std_logic;
    signal backpressure_in_x   : std_logic;
    signal backpressure_in_man : std_logic;
    signal backpressure_in_ser : std_logic;

    signal backpressure_acdc    : std_logic_vector(N-1 downto 0);
    signal backpressure_in_acdc : std_logic;
    
    signal  serialTx_data      : std_logic_vector(1 downto 0);

    signal wrTime_fast         : std_logic_vector(31 downto 0);
    signal wrTime_pps          : std_logic_vector(31 downto 0);
    signal pps                 : std_logic;
    signal pps_z               : std_logic_vector(1 downto 0);
    signal reset_wr_z          : std_logic;

    signal wr_timeOcc          : std_logic_vector(5 downto 0);
    signal sys_timeOcc         : std_logic_vector(5 downto 0);

    signal clkRate_ACC         : std_logic_vector(15 downto 0);
    signal clkRate_jcpll       : std_logic_vector(15 downto 0);
    
    signal trig_out_debug   : std_logic;
		
begin


-- SMA connectors
pps <= SMA_J3;



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
led_trig(2) <= '0';
led_trig(3) <= cmd.valid;
led_trig(4) <= jcpll_lock and clock.altPllLock;
led_trig(5) <= '0';
led_trig(6) <= serialTx.ack;
led_trig(7) <= reset.global or selfTrig_mode;
led_trig(8) <= '0';


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
    if (t >= 400) then
      r := '0';
    else
      r := '1';
      t := t + 1;
    end if;
    reset.acc <= r;
  end if;
end process;

-- reset synchronizers

RESET_SYNC_block : sync_Bits_Altera
  generic map(
    BITS         => 1,                       -- number of bit to be synchronized
    INIT         => x"00000000",             -- initialization bits
    SYNC_DEPTH   => 2                       -- generate SYNC_DEPTH many stages, at least 2
  )
  port map(
    Clock         => clock.sys,
    Input(0)      => reset.acc,
    Output(0)     => reset_sync
  );
resst_global_gen : process(clock.sys)
begin
  if(rising_edge(clock.sys)) then
    reset.global <= reset_sync or not clock.altpllLock;
  end if;
end process;
  
RESET_SYNC_25MHz : sync_Bits_Altera
  generic map (
    BITS       => 1,
    INIT       => x"00000000",
    SYNC_DEPTH => 2)
  port map (
    Clock  => clock.serial25,
    Input(0)  => reset.acc,
    Output(0) => reset.serial);

RESET_SYNC_125MHz : sync_Bits_Altera
  generic map (
    BITS       => 1,
    INIT       => x"00000000",
    SYNC_DEPTH => 2)
  port map (
    Clock  => clock.serial125,
    Input(0)  => reset.serial,
    Output(0) => reset.serialFast);

RESET_SYNC_WR250MHz: sync_Bits_Altera
  generic map (
    BITS       => 1,
    INIT       => x"00000000",
    SYNC_DEPTH => 2)
  port map (
    Clock  => clock.wr250,
    Input(0)  => reset.acc,
    Output(0) => reset.wr);

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
    clkRate_ACC       => clkRate_ACC,
    clkRate_jcpll     => clkRate_jcpll,
    reset             => reset.acc);



------------------------------------
--	LVDS 
------------------------------------
LVDS_out(0) <=	serialTx.serial;	--  serial comms tx
LVDS_out(1) <=	'0';	-- not used -- PLL CLK OUTPUT ONLY!!!
LVDS_out(2) <=	serialTx_data(0);	-- data links
LVDS_out(3) <=  serialTx_data(1);   -- data links
serialRx.serial     <= LVDS_in(0);  --  serial comms rx
acc_trig            <= LVDS_in(1);
backpressure_in_man <= LVDS_in(2);

manchester_decoder_backpressure: manchester_decoder
  port map (
    clk    => clock.x8,
    resetn => not reset.global,
    i      => backpressure_in_man,
    q      => backpressure_in_x);


backpressure_sync : process(clock.sys)
begin
  if rising_edge(clock.sys) then
    backpressure_in <= backpressure_in_x;
  end if;
end process;
  

backpressure_cdc: sync_Bits_Altera
  generic map(
    BITS          => 1,
    INIT          => x"00000000",
    SYNC_DEPTH    => 2)
  port map (
    Clock  => clock.serial25,
    Input(0)  => backpressure_in,
    Output(0) => backpressure_in_ser);

debug2 <= PSEC4_in(0).DLL_clock;
debug3 <= PSEC4_in(1).DLL_clock;
   
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
    trigger     => trig_out,
    backpressure_out => backpressure_in_acdc,
    outputMode => rxparams.outputMode,
    output => serialTx_data);
	
data_readout_control_inst: data_readout_control
  port map (
    clock            => clock,
    reset            => reset,
    backpressure     => backpressure_in_ser,
    fifoRead         => fifoRead,
    fifoDataOut      => fifoDataOut,
    fifoOcc          => fifoOcc,
    sys_timestamp	 => sys_timestamp,
    sys_ts_read      => sys_ts_read,
    sys_ts_valid     => sys_ts_valid, 
    wr_timestamp	 => wr_timestamp,
    wr_ts_read       => wr_ts_read,
    wr_ts_valid      => wr_ts_valid,
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
        reset_serial   => reset.serial,
		clock	       => clock.acc40,
        clock_out      => clock.sys,
        clock_serial   => clock.serial25,
        din		       => cmd.word,	
        din_valid      => cmd.valid,
        params         => rxparams,
        params_syncAcc => rxparams_syncAcc,
        params_acc     => rxparams_Acc
		);

calEnable 	<= rxparams_acc.calEnable;
calInputSel <= rxparams_acc.calInputSel;
reset.request <= rxparams_acc.reset_request;
		
------------------------------------
--	DATA HANDLER 
------------------------------------
-- transmits info over the low speed serial
dataHandler_map: dataHandler port map (
        -- clock and reset signals
		reset			   => reset,
		clock			   => clock,

        --data stream and control signals
        txData	           => serialTx.data,
		txReq	 	   	   => serialTx.req,
        txAck              => serialTx.ack,
		txBusy			   => txBusy,

        --ACC clock parameters 
		serialRX		   => serialRx,
        rxparams           => rxparams_syncAcc,
		IDrequest		   => rxparams_acc.IDrequest,
        IDpage             => rxparams_acc.IDpage,
        clkRate_ACC        => clkRate_ACC,
        clkRate_jcpll      => clkRate_jcpll,
        

        --jc pll clock parameters, these need CDC!!!
        trigInfo		   => trigInfo,
		Wlkn_fdbk_current  => Wlkn_fdbk_current,
		pro_vdd			   => pro_vdd,
		vcdl_count		   => vcdl_count,
        FLL_lock           => FLL_lock,
        jcpll_lock         => jcpll_lock,
        eventCount		   => eventCount,
		selfTrig_rateCount => selfTrig_rateCount,
        trig_count_all     => trig_count_all,
        trig_count	       => trig_count,
        backpressure       => backpressure_in,

        --serial25 paramters, these need CDC!!!
        fifoOcc            => fifoOcc,
        wr_timeOcc         => wr_timeOcc,
        sys_timeOcc        => sys_timeOcc

);


------------------------------------
--	TRIGGER
------------------------------------
trigger_map: trigger port map(
			clock			   => clock,
			reset			   => reset, 
			systemTime		   => systemTime,
            wrTime_pps         => wrTime_pps,
            wrTime_fast        => wrTime_fast,
			trigSetup		   => rxparams.trigSetup,
			selfTrig		   => rxparams.selfTrig,
			trigInfo		   => trigInfo,
			acc_trig		   => acc_trig,
			self_trig		   => self_trig,
			digitize_request   => digitize_request,
			digitize_done	   => digitize_done,
			eventCount		   => eventCount,
			sys_timestamp      => sys_timestamp,
            sys_ts_read        => sys_ts_read,
            sys_ts_valid       => sys_ts_valid,
            wr_timestamp       => wr_timestamp,
            wr_ts_read         => wr_ts_read,
            wr_ts_valid        => wr_ts_valid,
            backpressure_in    => backpressure_in,
            backpressure_in_acdc => backpressure_in_acdc,
			busy			   => trig_busy,
			trig_clear		   => trig_clear,
			trig_out		   => trig_out,
            trig_out_debug     => trig_out_debug,
            trig_count_all     => trig_count_all,
            trig_count	       => trig_count,
            trig_count_reset   => trig_count_reset,
            wr_timeOcc         => wr_timeOcc,
            sys_timeOcc        => sys_timeOcc
);
			

			
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
backpressure_in_acdc <= or_reduce(backpressure_acdc);

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
		FLL_lock		  => FLL_lock(i),
        backpressure      => backpressure_acdc(i),
        backpressure_in   => backpressure_in_acdc
);
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
SYS_TIME_RESET: sync_Bits_Altera
  generic map (
    BITS       => 1,
    INIT       => x"00000000",
    SYNC_DEPTH => 2)
  port map (
    Clock     => clock.sys,
    Input(0)  => reset.global or rxparams.trigSetup.eventAndTime_reset,
    Output(0) => systemTime_reset);   

-- white rabbit synchronized counters for absolute time stamp
-- wrTime_fast : 250 MHz counter reset to 0 by PPS
-- wrTime_pps : 1 Hz counter triggered by PPS signal
wrTiming : process ( clock.wr250 )
begin
  -- use falling edge of 250 MHz white rabbit because 1PPS is synchronous to the
  -- rising edge 
  if falling_edge(clock.wr250) then
    pps_z(0) <= pps;
    pps_z(1) <= pps_z(0);
    reset_wr_z <= reset.wr;
    if reset_wr_z = '1' then
      wrTime_fast <= (others => '0');
      wrTime_pps <= (others => '0');
    else
      if pps_z = "01" then
        wrTime_fast <= (others => '0');
        wrTime_pps <= std_logic_vector(unsigned(wrTime_pps) + 1);
      else
        wrTime_fast <= std_logic_vector(unsigned(wrTime_fast) + 1);
      end if;
    end if;
  end if;
end process;

 
end vhdl;
