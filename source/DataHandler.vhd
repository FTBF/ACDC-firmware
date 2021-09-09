---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         dataHandler.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  transmits the stored ram data from all psec chips over the uart
--					  plus other information
--
--					  processing is done on sysClk, uart I/Os are on uart clock
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.pulseSync;



entity dataHandler is
	port (
		reset					:	in   	std_logic;
		clock					: 	in		clock_type;        
		info					:   in 	info_type;
		IDrequest				:	in		std_logic;
		readRequest				:	in		std_logic;
		uartTx_done				:	out	std_logic;
		ramAddress	            :   out   natural;
		ramData	     	        :   in    wordArray;
		txByte	        	    : 	out	std_logic_vector(7 downto 0);
		txByte_valid	 		: 	out	std_logic;
		txByte_ack	            : 	in 	std_logic; -- a pulse input which shows that the data was sent to the uart
		txReady      	        : 	in 	std_logic; -- uart tx is ready for valid data
		timeoutError  			:	out	std_logic;
		selfTrig_rateCount		:   in 	selfTrig_rateCount_array;
		trig_rateCount			:	in		natural;	 
		PLL_ConfigReg			:   in 	std_logic_vector(31 downto 0);   
		testMode				:	in		testMode_type
		);
end dataHandler;


architecture vhdl of dataHandler is
	
	type state_type is (
	WAIT_FOR_REQUEST,
	GET_DATA,
	SEND_BYTES,
	DATA_ACK);
	
	constant	IDframe_len: natural:= 32;
	
	type frameData_type is array (0 to 31) of std_logic_vector(15 downto 0);
	
	signal IDframe_data: frameData_type;
	
	signal txReady_z: std_logic;
	signal txByte_valid_z:  std_logic;
	signal txByte_ack_z:  std_logic;
	
	signal dataEnable: std_logic;	
	signal dataReset: std_logic;	
	
begin	
	
	
	
	
	
	
	
	
	
	
	
	
	-- synchronize valid output to uart clock
	SYNC0: pulseSync port map (clock.sys, clock.x4, txByte_valid_z, txByte_valid);
	
	-- synchronize data ack input to sys clock
	SYNC1: pulseSync port map (clock.x4, clock.sys, txByte_ack, txByte_ack_z);
	
	
	
	
	DATA_HANDLER: process(clock.sys)
		variable state: state_type;
		variable t: natural; -- timeout value 
		variable i: natural range 0 to 65535;  -- index of the current data word
		variable txWord: std_logic_vector(15 downto 0);
		variable bytesDone: natural;
		variable dev: natural range 0 to 7;
		variable dev_ch: natural range 0 to 7;
		
		-- flags to show the progress of the transmission
		variable SOF_done: boolean;				-- start of frame
		variable Psec4sDone: natural range 0 to 7;
		variable preambleDone: boolean;
		variable psecDataDone: boolean;
		variable trigDone: boolean;
		variable frameDone: boolean;
		variable frameID_done: boolean;
		
		
		type frame_type_type is (PSEC_DATA_FRAME, ID_FRAME);
		variable frame_type: frame_type_type;
		
		
		
	begin
		if (rising_edge(clock.sys)) then
			
			-- sync
			txReady_z <= txReady;
			
			
			
			if (reset = '1') then
				
				state := WAIT_FOR_REQUEST;
				txByte_valid_z <= '0';
				uartTx_done <= '0';
				
				
			else
				
				
				case state is
					
					
					when WAIT_FOR_REQUEST => 
						
						uartTx_done <= '0';
						txByte_valid_z <= '0';
						if (IDrequest = '1') then 
							frame_type := ID_FRAME;
							i := 0;
							t := 0;
							timeoutError <= '0';
							frameDone := false;
							state := GET_DATA;
						elsif (readRequest = '1') then 
							frame_type := PSEC_DATA_FRAME;
							i := 0;
							t := 0;
							ramAddress <= 0;
							timeoutError <= '0';
							SOF_done := false;
							frameID_done := false;
							Psec4sDone := 0;
							preambleDone := false;
							psecDataDone := false;
							trigDone := false;
							frameDone := false;
							state := GET_DATA;
						end if;
						
					
					when GET_DATA =>
						
						-- choose the correct data 
						-----------------------------
						
						
						-- ID frame
						if (frame_type = ID_FRAME) then						
							txWord := IDframe_data(i);
							i := i + 1;
							if (i >= iDframe_len) then frameDone := true; end if;
							
							
							-- PSEC data frame
						elsif (not SOF_done) then		-- start of frame
							txWord := STARTWORD; 
							i := i + 1;
							SOF_done := true;
							
						elsif (not frameID_done) then		-- frame ID word
							txWord := x"A5EC"; 
							i := i + 1;
							frameID_done := true;
							
						elsif (Psec4sDone < 5) then
							
							if (not preambleDone) then		-- preamble
								txWord := x"F005";
								i := 0;
								preambleDone := true;
								
							elsif (not psecDataDone) then
								if (testMode.sequencedPsecData = '1') then
									txWord := std_logic_vector(to_unsigned(i,16));
								else
									txWord := ramData(Psec4sDone);
								end if;
								ramAddress <= ramAddress + 1;
								i := i + 1;
								if (i >= 1536) then			-- 256 words x 6 channels
									psecDataDone := true;
									i := 0;
								end if;
								
							else							-- postamble
								if (i <= 13) then
									txWord := info(Psec4sDone, i);
									i := i + 1;
								else
									txWord := PSEC_END_WORD;
									i := 0;
									ramAddress <= 0;			-- reset address counter for next channel
									Psec4sDone := Psec4sDone + 1;		-- finished the current channel
									preambleDone := false;
									psecDataDone := false;
								end if;
								
								dev := 0;
								dev_ch := 0;
								
							end if;
							
						elsif (not trigDone) then		-- trigger
							
							txWord := std_logic_vector(to_unsigned(selfTrig_rateCount(dev, dev_ch),16)); 
							dev_ch := dev_ch + 1;
							if (dev_ch >= 6) then dev_ch := 0; dev := dev + 1; end if;
							i := i + 1;
							if (i >= 30) then
								i := 0;
								trigDone := true;
							end if;
							
						else
							
							case i is
								when 0 => txWord := std_logic_vector(to_unsigned(trig_rateCount,16));
								when 1 => txWord := x"A5EC";
								when 2 => txWord := ENDWORD;
								when others => null;
							end case;
							i := i + 1;
							if (i >= 3) then
								frameDone := true;
							end if;						
							
						end if;
						
						t := 40000000;  -- set timeout delay 1s for data acknowledge
						bytesDone := 0;
						state := SEND_BYTES;
						
					
					when SEND_BYTES =>
						
						if (txReady_z = '1') then
							case bytesDone is		-- choose the upper or lower byte of the 16-bit word
								when 0 => txByte <= txWord(15 downto 8);	-- send msb first
								when others => txByte <= txWord(7 downto 0);
							end case;
							txByte_valid_z <= '1';
							state := DATA_ACK;
						end if;
						
					
					when DATA_ACK =>
						txByte_valid_z <= '0';
						if (txByte_ack_z = '1') then  -- the new data was acked
							bytesDone := bytesDone + 1;
							t := 0; -- clear timeout
							if (bytesDone >= 2) then 		-- the 16-bit word has been sent
								if (frameDone) then 
									uartTx_done <= '1';
									state := WAIT_FOR_REQUEST;
								else
									state := GET_DATA;
								end if;
							else
								state := SEND_BYTES;
							end if;
						end if;
						
						
					
				end case;
				
				
				
				
				-- timeout error
				
				if (t > 0) then
					t := t - 1;
					if (t = 0) then 
						timeoutError <= '1';   -- generate an output pulse to indicate the error
						state := WAIT_FOR_REQUEST; 
					end if;     
				else
					timeoutError <= '0';
				end if;
				
				
				
				
			end if;
			
		end if;
		
		
	end process;
	
	
	
	--------------------------------------------
	-- ID FRAME DATA
	--------------------------------------------              
	IDframe_data(0) <= x"1234";
	IDframe_data(1) <= x"BBBB";
	IDframe_data(2) <= firwareVersion.number;
	IDframe_data(3) <= firwareVersion.year;
	IDframe_data(4) <= firwareVersion.MMDD;
	IDframe_data(5) <= x"0000";
	IDframe_data(6) <= PLL_ConfigReg(15 downto 0);
	IDframe_data(7) <= PLL_ConfigReg(31 downto 16);
	IDframe_data(8) <= x"0000";
	IDframe_data(9) <= info(0,1);	-- wlkn feedback current (channel 0)		
	IDframe_data(10) <= info(0,2);	-- wlkn feedback target (channel 0)	
	IDframe_data(11) <= x"0000";
	IDframe_data(12) <= x"0000";
	IDframe_data(13) <= x"0000";
	IDframe_data(14) <= x"0000";
	IDframe_data(15) <= x"0000";
	IDframe_data(16) <= x"0000";
	IDframe_data(17) <= x"0000";
	IDframe_data(18) <= x"0000";
	IDframe_data(19) <= x"0000";
	IDframe_data(20) <= x"0000";
	IDframe_data(21) <= x"0000";
	IDframe_data(22) <= x"0000";
	IDframe_data(23) <= x"0000";
	IDframe_data(24) <= x"0000";
	IDframe_data(25) <= x"0000";
	IDframe_data(26) <= x"0000";
	IDframe_data(27) <= x"0000";
	IDframe_data(28) <= x"0000";
	IDframe_data(29) <= x"0000";
	IDframe_data(30) <= x"BBBB";
	IDframe_data(31) <= x"4321";
	
	
	
	
	
	
end vhdl;































