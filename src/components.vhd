---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
-- PROJECT:      ANNIE - ACDC
-- FILE:         components.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020         
--
-- DESCRIPTION:  component definitions
--
---------------------------------------------------------------------------------


library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.defs.all;


package components is

		
-- ADC ctrl	
component ADC_Ctrl is 
	port(
		clock				:	in		std_logic;			
		reset				:	in		std_logic;
		start				:	in		std_logic;
		RO_EN 			:	out	std_logic;
		adcClear			:	out	std_logic;
		adcLatch			:	out	std_logic;
		rampStart		:	out	std_logic;
		rampDone			:	out	std_logic
);
end component;


-- clock generator
component ClockGenerator is
  port (
    clockIn           : in     clockSource_type;
    jcpll             : out    jcpll_ctrl_type;
    clock             : buffer clock_type;
    PLL_ConfigRequest : in     std_logic;
    PLL_ConfigReg     : in     std_logic_vector(31 downto 0);
    reset             : in     std_logic);
end component ClockGenerator;
		

-- command handler	
component commandHandler is
	port (
        reset	       : in    std_logic;
        reset_serial   : in    std_logic;
		clock	       : in	   std_logic;
        clock_out      : in	   std_logic;
        clock_serial   : in	   std_logic;        
        din		       : in    std_logic_vector(31 downto 0);
        din_valid      : in    std_logic;
        params         : out   RX_Param_jcpll_type;
        params_syncAcc : out   RX_Param_jcpll_type;
        params_acc     : out   RX_Param_acc_type
		);
end component;


-- data ram	
component dataRam IS
	PORT
	(
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		wraddress		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;
		
      
-- data buffer
component dataBuffer is 
	port(	

		PSEC4_in : in	PSEC4_in_type;		
		channel :  OUT  natural range 0 to M-1;
		Token :  OUT  STD_LOGIC_VECTOR(1 DOWNTO 0);	
		blockSelect : out STD_LOGIC_VECTOR(2 DOWNTO 0);	
		readClock: out std_logic;		
		clock					:	in		clock_type;   	--40MHz clock from jitter cleaner
		reset					:	in		reset_type;	--transfer done
		start					:  in		std_logic;
		fifoRead         		:	in	    std_logic; 
		fifoDataOut			:	out	std_logic_vector(15 downto 0);
        fifoOcc             : out std_logic_vector(15 downto 0);
		done					:	out	std_logic; 	-- the psec data has been read out and stored in ram	
        backpressure            : out std_logic;
        backpressure_in         : in  std_logic);
		
end component;
      
   
-- data handler
component dataHandler is
	port (
      reset				 : 	in   	reset_type;
      clock				 : 	in		clock_type;
      serialRx			 :	in		serialRx_type;
      trigInfo			 :  in 	trigInfo_type;
      rxParams           :  in      RX_Param_jcpll_type;
      Wlkn_fdbk_current	 :	in		natArray;
      pro_vdd			 :	in		natArray16;
      vcdl_count		 :	in		array32;
      FLL_lock           :  in      std_logic_vector(N-1 downto 0);
      jcpll_lock		 :  in      std_logic;
      eventCount		 :	in		std_logic_vector(31 downto 0);
      IDrequest      	 :	in		std_logic;
      IDpage             :  in      std_logic_vector(3 downto 0);
      txData	         : 	out	std_logic_vector(7 downto 0);
      txReq	 	   		 : 	out	std_logic;
      txAck			     : 	in 	std_logic; 
      selfTrig_rateCount :  in 	selfTrig_rateCount_array;
      txBusy			 :	out	std_logic;			-- a flag used for diagnostics and frame time measurement
      fifoOcc            :  in  Array16;
      trig_count_all     :  in  std_logic_vector(31 downto 0);
      trig_count	     :  in  std_logic_vector(31 downto 0);
      backpressure       :  in  std_logic;
      wr_timeOcc         :  in  std_logic_vector(5 downto 0);
      sys_timeOcc        :  in  std_logic_vector(5 downto 0)

);
end component;
		
	
-- dac driver   
component DAC_driver is
	port(	
	
		process_clock	: in	std_logic;
		update_clock	: in	std_logic;
		reset				: in	std_logic;
		trigThreshold	:	in array12;
		Vbias				:	in	array12;
		pro_vdd			:  in array12;
		dll_vdd			:	in	array12;		
		dac_out			:	out DAC_array_type
);
end component;
	
      
--dac serial
component dacSerial is
  port(
        clock           : in    clock_type;      -- DAC clk ( < 50MHz ) 
        reset           : in    std_logic;
        dataIn          : in    DACchain_data_type;  	-- array (0 to 1) of dac data
        dac    	      : out   dac_type);
end component;


-- io buffer
 	component iobuf
	port(
		datain		: IN 		STD_LOGIC_VECTOR (15 DOWNTO 0);
		oe				: IN  	STD_LOGIC_VECTOR (15 DOWNTO 0);
		dataio		: INOUT 	STD_LOGIC_VECTOR (15 DOWNTO 0);
		dataout		: OUT 	STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;

	
-- led driver
component LED_driver is
	port (
		clock	      : in std_logic;        
		setup			: in ledSetup_type;
		output      : out std_logic
	);
end component;
		
		
-- pll
component pll is
	port (
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		c1		: OUT STD_LOGIC ;
		c2		: OUT STD_LOGIC ;
		c3		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
end component;

component acc_pll IS
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		c1		: OUT STD_LOGIC ;
		c2		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END component;

	
-- psec4 driver
component PSEC4_driver is
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
        fifoOcc             : out std_logic_vector(15 downto 0);
        readoutDone         : out std_logic;
		FLL_lock				: out std_logic;
        backpressure            : out std_logic;
        backpressure_in         : in  std_logic
);
	
end component;


component gearbox_12to16 is
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;
    data_in        : in  std_logic_vector(11 downto 0);
    data_in_valid  : in  std_logic;
    data_out       : out std_logic_vector(15 downto 0);
    data_out_valid : out std_logic);
end component gearbox_12to16;


component selfTrigger is
	port(
			clock						: in	clock_type;
			reset						: in	std_logic;   
			PSEC4_in					: in 	PSEC4_in_array_type;
			testMode					: in  testMode_type;
			trigSetup				: in	trig_type;
			selfTrig					: in	selfTrig_type;
			trig_out					: out	std_logic;
			rateCount				: out selfTrig_rateCount_array
			);
end component;


-- trigger
component trigger is
	port(
			clock						: in	clock_type;
			reset						: in	reset_type;   
			systemTime				: in	std_logic_vector(63 downto 0);
            wrTime_pps              : in std_logic_vector(31 downto 0);
            wrTime_fast             : in std_logic_vector(31 downto 0);
			trigSetup				: in	trig_type;
			selfTrig					: in 	selfTrig_type;
			trigInfo					: out	trigInfo_type;
			acc_trig					: in	std_logic;	-- trig from central card (LVDS)
			self_trig				: in	std_logic;	
			digitize_request		: out	std_logic;
			digitize_done			: in	std_logic;
			eventCount				: out	std_logic_vector(31 downto 0);
			sys_timestamp				: out std_logic_vector(63 downto 0);
            sys_ts_read      : in std_logic;
            sys_ts_valid     : out std_logic;
			wr_timestamp				: out std_logic_vector(63 downto 0);
            wr_ts_read       : in std_logic;
            wr_ts_valid      : out std_logic;
            backpressure_in  : in std_logic;
            backpressure_in_acdc : in std_logic;
			busy						: out std_logic;
			trig_clear				: buffer std_logic;
			trig_out					: buffer std_logic;
            trig_out_debug   : out std_logic;
			trig_count_all   : out std_logic_vector(31 downto 0);
            trig_count	     : out std_logic_vector(31 downto 0);
            trig_count_reset : in  std_logic;
            wr_timeOcc       : out std_logic_vector(5 downto 0);
            sys_timeOcc      : out std_logic_vector(5 downto 0));
	end component;


				
-- rx command     
component rxCommand IS 
	PORT
	(
		clock 				:  IN  STD_LOGIC;
		din 					:  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		din_valid			:  IN  STD_LOGIC;
		dout 					:  OUT STD_LOGIC_VECTOR(31 DOWNTO 0);	-- instruction word out
		dOut_valid			:  OUT STD_LOGIC
	);
END component;
      
      
     
      
-- vcdl monitor loop
component VCDL_Monitor_Loop is
        Port (
             clock			       : in clock_type; --One period of this clock defines how long we count Wilkinson rate pulses
             VCDL_MONITOR_BIT    : in std_logic;
             countReg				 : out natural
        );
end component;


-- Wilkinson feedback loop
component Wilkinson_Feedback_Loop is
	Port (
        reset    				: in std_logic;
        clock			      : in clock_type; --One period of clock.wilkUpdate defines how long we count Wilkinson rate pulses
        WILK_MONITOR_BIT   : in std_logic;
        target     			: in natural; 	-- target number of rising edges on  wilk monitor bit in the specified measuring period (100ms)
        current	 			: out natural;	-- the current count value
        dacValue   			: buffer natural range 0 to 4095;
		  lock					: out std_logic
        );
end component;


-- ddr_io
component ddr_iobuf is
  port (
    datain_h : IN  STD_LOGIC_VECTOR (1 DOWNTO 0);
    datain_l : IN  STD_LOGIC_VECTOR (1 DOWNTO 0);
    outclock : IN  STD_LOGIC;
    dataout  : OUT STD_LOGIC_VECTOR (1 DOWNTO 0));
end component ddr_iobuf;

-- high speed serial IO 
component serialTx_highSpeed is
  port (
    clk              : in  clock_type;
    reset            : in  reset_type;
    input            : in  hs_input_array;
    input_ready      : out std_logic_vector(1 downto 0);
    input_valid      : in  std_logic_vector(1 downto 0);
    input_kout       : in  std_logic_vector(1 downto 0);
    trigger          : in  std_logic;
    backpressure_out : in std_logic;
    outputMode       : in  std_logic_vector(1 downto 0);
    output           : out std_logic_vector(1 downto 0)); 
end component serialTx_highSpeed;


component serial_pll is
  port (
    inclk0 : IN  STD_LOGIC := '0';
    c0     : OUT STD_LOGIC;
    c1     : OUT STD_LOGIC;
    locked : OUT STD_LOGIC);
end component serial_pll;


component txFifo_hs is
  port (
    aclr    : IN  STD_LOGIC := '0';
    data    : IN  STD_LOGIC_VECTOR (15 DOWNTO 0);
    rdclk   : IN  STD_LOGIC;
    rdreq   : IN  STD_LOGIC;
    wrclk   : IN  STD_LOGIC;
    wrreq   : IN  STD_LOGIC;
    q       : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
    rdempty : OUT STD_LOGIC;
    rdusedw : OUT STD_LOGIC_VECTOR (14 DOWNTO 0);
    wrfull  : OUT STD_LOGIC;
    wrusedw : OUT STD_LOGIC_VECTOR (14 DOWNTO 0)); 
end component txFifo_hs;


component data_readout_control is
  port (
    clock            : in  clock_type;
    reset            : in  reset_type;
    backpressure     : in  std_logic;
    fifoRead         : out std_logic_vector(N-1 downto 0);
    fifoDataOut      : in  array16;
    fifoOcc          : in  array16;
    sys_timestamp	 : in  std_logic_vector(63 downto 0);
    sys_ts_read      : out std_logic;
    sys_ts_valid     : in  std_logic;
    wr_timestamp	 : in  std_logic_vector(63 downto 0);
    wr_ts_read       : out std_logic;
    wr_ts_valid      : in  std_logic;
    dataToSend       : out hs_input_array;
    dataToSend_valid : out std_logic_vector(1 downto 0);
    dataToSend_kout  : out std_logic_vector(1 downto 0);
    dataToSend_ready : in  std_logic_vector(1 downto 0));
end component data_readout_control;

component timeFifo is
  port (
    aclr    : IN  STD_LOGIC := '0';
    data    : IN  STD_LOGIC_VECTOR (63 DOWNTO 0);
    rdclk   : IN  STD_LOGIC;
    rdreq   : IN  STD_LOGIC;
    wrclk   : IN  STD_LOGIC;
    wrreq   : IN  STD_LOGIC;
    q       : OUT STD_LOGIC_VECTOR (63 DOWNTO 0);
    rdempty : OUT STD_LOGIC;
    rdusedw	: OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
    wrfull  : OUT STD_LOGIC);
end component timeFifo;

component pll_wr is
  port (
    areset : IN  STD_LOGIC := '0';
    inclk0 : IN  STD_LOGIC := '0';
    c0     : OUT STD_LOGIC;
    c1     : OUT STD_LOGIC;
    locked : OUT STD_LOGIC); 
end component pll_wr;


end components;























