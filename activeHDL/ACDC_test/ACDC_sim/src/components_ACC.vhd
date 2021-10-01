---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
-- PROJECT:      ANNIE 
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
use work.defs_ACC.all;



package components_ACC is


component serialTx_buffer_ACC is
	port(
		clock				: in	std_logic;	--system clock		 
      din				: in	std_logic_vector(31 downto 0);
		din_txReq		: in	std_logic;		 
		din_txAck		: out	std_logic;		 
		dout				: out	std_logic_vector(7 downto 0);
		dout_txReq		: out	std_logic;
		dout_txAck		: in	std_logic
		);			
end component;


component serialRx_buffer is
	port(
		reset				: in	std_logic;	--buffer reset and/or global reset
		clock				: in	std_logic;	--system clock		 
      din				: in	std_logic_vector(7 downto 0);--input data 16 bits
		din_valid		: in	std_logic;		 
      read_enable		: in	std_logic; 	--enable reading from RAM block
		read_address	: in	std_logic_vector(transceiver_mem_depth-1 downto 0);--ram address
		buffer_empty	: out std_logic;
		frame_received	: buffer std_logic;
		dataLen			: out natural range 0 to 65535;
		dout				: out	std_logic_vector(transceiver_mem_width-1 downto 0)--ram data out
		);	
end component;






component txFifo_ACC IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		usedw		: OUT STD_LOGIC_VECTOR (9 DOWNTO 0)
	);
END component;

		
component trigger is
	Port(
		clock		: in	std_logic;
		reset		: in std_logic;
		trig	 	: in trigSetup_type;		
		pps		: in std_logic;
		hw_trig	: in std_logic;
		beamGate_trig: in std_logic;
		trig_out		:  out std_logic_vector(7 downto 0)
		);
end component;



component pll is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;        -- outclk1.clk
		outclk_2 : out std_logic;        -- outclk1.clk
		locked   : out std_logic         --  locked.export
	);
end component;
	
		
		
component ClockGenerator is
	Port(
		clockIn		: in	clockSource_type;
		clock			: buffer clock_type;
		pps			: in std_logic;
		resetRequest: out std_logic;
		useExtRef	: buffer std_logic
	);
end component;
		
		
		
     
      
component LED_driver is
	port (
		clock	      : in std_logic;        
		setup			: in ledSetup_type;
		output      : out std_logic
	);
end component;
     
      
      
      
      
------------------------------------------		
-- command & data processing components
------------------------------------------



component commandHandler is
	port (
		reset						: 	in   	std_logic;
		clock				      : 	in		std_logic;        
      din		      	   :  in    std_logic_vector(31 downto 0);
      din_valid				:  in    std_logic;
		localInfo_readReq    :  out   std_logic;
		rxBuffer_resetReq    :  out   std_logic_vector(7 downto 0);
		rxBuffer_readReq		:	out	std_logic;
		globalResetReq       :  out   std_logic;
      trig		            :	out	trigSetup_type;
      readcHANNEL          :	out	natural range 0 to 15;
		ledSetup					: 	out	LEDSetup_type;
		ledPreset				: 	in		LEDPreset_type;
		extCmd			      : 	out 	extCmd_type;
		testCmd					: 	out	testCmd_type
);
end component;


component dataHandler is
	port (
		reset						: 	in   	std_logic;
		clock				      : 	in		std_logic;        
		serialRx					:	in		serialRx_type;
		pllLock					:  in std_logic;
		trig						: in trigSetup_type;
		channel          		: in natural;
      ramReadEnable        : 	out 	std_logic_vector(7 downto 0);
      ramAddress           :  out   std_logic_vector(transceiver_mem_depth-1 downto 0);
      ramData              :  in    rx_ram_data_type;
      rxDataLen				:  in  	naturalArray_16bit;
		frame_received    	:  in   std_logic_vector(7 downto 0);
      bufferReadoutDone    :  buffer  std_logic_vector(7 downto 0);
      dout 		            : 	out	std_logic_vector(15 downto 0);
		txReq					   : 	out	std_logic;
      txAck                : 	in 	std_logic;
      txLockReq            : 	out	std_logic;
      txLockAck            : 	in  	std_logic;
		rxBuffer_readReq		:	in	std_logic;
      localInfo_readRequest: in std_logic;      
      acdcBoardDetect      : in std_logic_vector(7 downto 0);    
		useExtRef				: in std_logic;   
      
      -- error
      timeoutError  			:	out	std_logic 
);
end component;
		
		
		
      
      
 


component rx_data_ram
	port (
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
		rden		: IN STD_LOGIC  := '1';
		wraddress		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
end component;







component usbDriver is
   port ( 		
		clock   					: in		std_logic;
		rxData_in	  	  	 	: in     std_logic_vector (15 downto 0);  --usb data from PHY
		txData_out				: out    std_logic_vector (15 downto 0);  --usb data bus to PHY
      txBufferReady 			: in  	std_logic;		--the tx buffer on the chip is ready to accept data 
      rxDataAvailable  		: in    	std_logic;     --usb data received flag
      busWriteEnable 		: out   	std_logic;     --when high the fpga outputs data onto the usb bus
      PKTEND  					: out 	std_logic;		--usb packet end flag
      SLWR		      	  	: buffer 	std_logic;		--usb slave interface write signal
      SLOE         			: buffer   	std_logic;    	--usb slave interface bus output enable, active low
		SLRD     	   		: buffer   	std_logic;		--usb  slave interface bus read, active low
      FIFOADR  	   		: out   	std_logic_vector (1 downto 0); -- usb endpoint fifo select, essentially selects the tx fifo or rx fifo
		tx_busReq  				: in		std_logic;  -- request to lock the bus in tx mode, preventing any interruptions from usb read
		tx_busAck  				: out		std_logic;  
      txData_in        		: in   	std_logic_vector(15 downto 0);		
      txReq		        		: in   	std_logic;		
      txAck		        		: out   	std_logic;		
      rxData_out       		: out   	std_logic_vector(31 downto 0);
		rxData_valid     		: out		std_logic;
		test						: out		std_logic_vector(15 downto 0)
);
end component;




	component iobuf
	port(
		datain		: IN 		STD_LOGIC_VECTOR (15 DOWNTO 0);
		oe				: IN  	STD_LOGIC_VECTOR (15 DOWNTO 0);
		dataio		: INOUT 	STD_LOGIC_VECTOR (15 DOWNTO 0);
		dataout		: OUT 	STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;

   
   
   
   
   
   
   
   
   
end components_ACC;























