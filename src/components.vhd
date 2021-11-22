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
		clock	       : in	   std_logic;
        clock_out      : in	   std_logic;        
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
		clock					:	in		std_logic;   	--40MHz clock from jitter cleaner
		reset					:	in		std_logic;	--transfer done
		start					:  in		std_logic;
		ramReadAddress		:	in		natural; 
		ramDataOut			:	out	std_logic_vector(15 downto 0);	--13 bit RAM-stored data	
		done					:	out	std_logic);	-- the psec data has been read out and stored in ram	
		
end component;
      
   
-- data handler
component dataHandler is
	port (
      reset				 : 	in   	std_logic;
      clock				 : 	in		std_logic;
      jcpll_clock        :  in      std_logic;
      serialRx			 :	in		serialRx_type;
      trigInfo			 :  in 	trigInfo_type;
      rxParams           :  in      RX_Param_jcpll_type;
      Wlkn_fdbk_current	 :	in		natArray;
      pro_vdd			 :	in		natArray16;
      vcdl_count		 :	in		array32;
      timestamp			 :	in		std_logic_vector(63 downto 0);
      beamgate_timestamp : 	in 	std_logic_vector(63 downto 0);
      ppsCount  		 :	in		std_logic_vector(31 downto 0);
      beamGateCount      :	in		std_logic_vector(31 downto 0);
      eventCount		 :	in		std_logic_vector(31 downto 0);
      IDrequest      	 :	in		std_logic;
      readRequest		 :	in		std_logic;
      trigTransferDone	 :	out	std_logic;
      ramAddress         :  out   natural;
      ramData            :  in    wordArray;
      txData	         : 	out	std_logic_vector(7 downto 0);
      txReq	 	   		 : 	out	std_logic;
      txAck			     : 	in 	std_logic; 
      selfTrig_rateCount :  in 	selfTrig_rateCount_array;
      trig_rateCount	 :	in		natural;
      trig_frameType	 :	in		natural;
      txBusy			 :	out	std_logic			-- a flag used for diagnostics and frame time measurement
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
		reset					: in  std_logic;
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
		ramReadAddress		: in natural;
		ramDataOut			: out std_logic_vector(15 downto 0);
		ramBufferFull		: out std_logic;
		FLL_lock				: out std_logic
);
	
end component;


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
			reset						: in	std_logic;   
			systemTime				: in	std_logic_vector(63 downto 0);
			testMode					: in  testMode_type;
			trigSetup				: in	trig_type;
			selfTrig					: in 	selfTrig_type;
			trigInfo					: out	trigInfo_type;
			acc_trig					: in	std_logic;	-- trig from central card (LVDS)
			sma_trig					: in	std_logic;	-- on-board SMA trig
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
			trig_event				: out std_logic;
			trig_clear				: buffer std_logic;
			trig_out					: buffer std_logic;
			trig_rate_count		: out natural);
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
    clk         : in  clock_type;
    reset       : in  reset_type;
    input       : in  hs_input_array;
    input_ready : out std_logic_vector(1 downto 0);
    input_valid : in  std_logic_vector(1 downto 0);
    outputMode  : in  std_logic_vector(1 downto 0);
    output      : out std_logic_vector(1 downto 0)); 
end component serialTx_highSpeed;


component serial_pll is
  port (
    inclk0 : IN  STD_LOGIC := '0';
    c0     : OUT STD_LOGIC;
    c1     : OUT STD_LOGIC;
    locked : OUT STD_LOGIC);
end component serial_pll;

end components;























