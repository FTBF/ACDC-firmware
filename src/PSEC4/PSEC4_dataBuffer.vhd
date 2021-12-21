---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         PSEC4_dataBuffer.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  a process to store data from the PSEC4 into firmware fifo
--
--------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;



entity dataBuffer is 
	port(	

		PSEC4_in : in	PSEC4_in_type;		
		channel :  OUT  natural range 0 to 7 := 1;  -- default value for sim
		Token :  OUT  STD_LOGIC_VECTOR(1 DOWNTO 0);	
		blockSelect : out STD_LOGIC_VECTOR(2 DOWNTO 0);	
		readClock: out std_logic;	
		clock					:	in		clock_type;   	--40MHz clock from jitter cleaner
		reset					:	in		std_logic;	
		start					:  in		std_logic;
		fifoRead         		:	in	    std_logic; 
		fifoDataOut			:	out	std_logic_vector(15 downto 0);
        fifoOcc             : out std_logic_vector(12 downto 0);
		done					:	out	std_logic);	-- the psec data has been read out and stored in fifo
		
		
end dataBuffer;

architecture vhdl of dataBuffer is

signal	writeEnable: std_logic;
signal	writeData: std_logic_vector(15 downto 0);
signal	blockSel: natural;
signal	sample_wrAddr: unsigned(7 downto 0);

begin
		
writeData <= "000" & PSEC4_in.overflow & PSEC4_in.data;

txFifo: txFifo_hs
  port map (
    aclr    => reset,
    data    => writeData,
    rdclk   => clock.serial25,
    rdreq   => fifoRead,
    wrclk   => clock.sys,
    wrreq   => writeEnable,
    q       => fifoDataOut,
    rdempty => open,
    rdusedw => fifoOcc,
    wrfull  => open,
    wrusedw => open);

	
-- write address
--writeAddress <= "000" & channel_wrAddr_slv & sample_wrAddr_slv;	-- 3 bit channel number + 8 bit sample number
	
-- psec4 control signals
blockSelect <= std_logic_vector(to_unsigned(blockSel,3));	


WR_PROCESS:	process(clock.sys)

type state_type is (
	IDLE,
	INSERT_TOKEN, 
	RD_SETUP,
	WR,
	CLK0, CLKA, CLKB, CLKD,
	WAIT_TOKEN, 
	WRITE_DONE);
	
variable wrCount: natural;
variable state: state_type;
variable i: natural;		-- sample number

begin
	
	if (rising_edge(clock.sys)) then
			
		if (reset = '1')  then	state := IDLE; end if;

		
		case state is
				
				
			when IDLE =>

				Token	<= "00";
				channel <= 1;
				readClock <= '0';
				writeEnable	<= '0';
				blockSel  	<= 5; -- clears ASIC token
				done	 		<= '0';
				if (start = '1') then state := CLK0; end if;
								
		
			when CLK0 => readClock <= '1'; state := RD_SETUP;


			when RD_SETUP =>
					
					sample_wrAddr <=  X"00";
					channel <= 1;
					blockSel   	<= 1;
					state := CLKA; 
									
				
			when CLKA => readClock <= '1'; state := INSERT_TOKEN;
					
					
			when INSERT_TOKEN =>

					if (channel >= 4 and channel <= 6) then
						Token <= "01"; 
					else
						Token <= "10"; 
					end if;
					readClock <= '0';
					state := CLKB;
					
					
			when CLKB => readClock <= '1'; state := WAIT_TOKEN;
					
					
			when WAIT_TOKEN =>
						
					Token <= "00";
					wrCount	:= 0;
					readClock <= '0';
					state := CLKD;
								
			
			when CLKD => 
			
				readClock <= '1'; 	
				writeEnable <= '1';
				state := WR;
				
				
			when WR => 	-- write to firmware fifo
				
					readClock <= '0';
					writeEnable <= '0'; 
					sample_wrAddr <= sample_wrAddr + 1;
					wrCount := wrCount + 1;
					if (wrCount < 64) then
						state := CLKD;
					else
						if (blockSel >= 4) then
							blockSel <= 1;
							if (channel >= 6) then
								state := WRITE_DONE;
							else
								channel <= channel + 1;
								state	:= INSERT_TOKEN; 
							end if;
						else
							blockSel <= blockSel + 1;
							state	:= INSERT_TOKEN; 
						end if;	
					end if;				
					
					
			when WRITE_DONE =>

					done <= '1';
                    state := IDLE;
					
					
		end case;
		
	end if;
	
end process;
	
	
	
	



end vhdl;
