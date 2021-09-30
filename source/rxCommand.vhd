---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         rxCommand.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  receives 6 byte frames from the uart, 
--						(2 header bytes and 4 instruction bytes)
--						processing done with uart clock, i/o on system clock
--
---------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
LIBRARY work;
use work.defs.all;
use work.components.uart;
use work.components.pulseSync;
use work.components.timeoutTimer;



ENTITY rxCommand IS 
	PORT
	(
		reset 				:  IN  STD_LOGIC;
		clock 				:  IN  clock_type;
		din 					:  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		din_valid			:  IN  STD_LOGIC;
		dout 					:  OUT STD_LOGIC_VECTOR(31 DOWNTO 0);	-- instruction word out
		dout_valid			:  OUT STD_LOGIC;
		timeoutError		:  OUT STD_LOGIC
	);
END rxCommand;


ARCHITECTURE vhdl OF rxCommand IS 

-- note:
-- din and din_valid are on uart clock
-- reset, wordAlignReset, dout and dout_valid are on sys clock


signal	dout_valid_z   		: std_logic;
signal	reset_z   				: std_logic;
signal	timeoutEnable			: std_logic;
signal	timeoutError_z			: std_logic;
signal	wordAlignReset			: std_logic;


BEGIN 
	
		

-- looks for a specific 2 byte header indicating start of frame, 
-- then takes the next 4 bytes as a valid instruction word


-- synchronize output
SYNC0: pulseSync port map (clock.local160, clock.local40, dout_valid_z, dout_valid);

-- synchronize word align reset
SYNC1: pulseSync port map (clock.timer, clock.local160, timeoutError_z, wordAlignReset);

-- synchronize timeout output
SYNC2: pulseSync port map (clock.timer, clock.local40, timeoutError_z, timeoutError);


process(clock.local160)
   variable i: natural range 0 to 255; -- byte index pos within the received frame
   variable v:  std_logic;	-- 'valid' flag
	variable rxReg	: std_logic_vector(31 downto 0);	-- temporary storage of the rx bytes as they come in
begin
	if (rising_edge(clock.local160)) then	
    		
		-- sync
		reset_z <= reset;
		
		
      if (reset_z = '1' or wordAlignReset = '1') then
			
        dout_valid_z <= '0';
        dout <= x"00000000";
			timeoutEnable <= '0';
			i := 0;
		
      else
			
         v := '0';
         if (din_valid = '1') then      -- valid data received from uart			
				case i is
					
					
					when 0 =>
						if (din = STARTWORD_8a) then  	-- got first byte of header
							i := i + 1; 
							timeoutEnable <= '1';	-- start timeout timer to make sure the rest of the frame arrives in good time, otherwise this indicates a fault
						end if;   
					
					
					when 1 => 
						if (din = STARTWORD_8b) then  	-- got second byte of header 
							i := i + 1;		
						else 
							i := 0; 			-- if not then revert to looking for first byte again
							timeoutEnable <= '0';		-- clear timeout
						end if;  
					
					
					when others =>			-- got header, now wait for data
						rxReg := rxReg(23 downto 0) & din;		-- shift in the msb first
						i := i + 1;
						if (i >= 6) then 	-- now we have received 6 bytes (2 header + 4 data)
							dout <= rxReg;		-- output the 32-bit instruction word
							v := '1';
							i := 0;		-- wait for a new frame
							timeoutEnable <= '0';		-- clear timeout
						end if;
						
						
						
				end case;
			end if;			
			
			dout_valid_z	<= v;	 	 
            
      end if;
	end if;
end process;
	
		
	


-- timeout timer to make sure that byte counter resets to zero after receiving only a partial frame
timeout_map: timeoutTimer port map(		
		clock	     => clock.timer,
		len        => 1000,				
		enable     => timeoutEnable,
		expired    => timeoutError_z);



END vhdl;









