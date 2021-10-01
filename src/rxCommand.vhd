---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         rxCommand.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         May 2021
--
-- DESCRIPTION:  receives 6 byte frames from the uart, 
--						(2 header bytes and 4 instruction bytes)
--
---------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
LIBRARY work;
use work.defs.all;



ENTITY rxCommand IS 
	PORT
	(
		clock 				:  IN  STD_LOGIC;
		din 					:  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		din_valid			:  IN  STD_LOGIC;
		dout 					:  OUT STD_LOGIC_VECTOR(31 DOWNTO 0);	-- instruction word out
		dout_valid			:  OUT STD_LOGIC
	);
END rxCommand;


ARCHITECTURE vhdl OF rxCommand IS 




BEGIN 
	
		

-- looks for a specific 2 byte header indicating start of frame, 
-- then takes the next 4 bytes as a valid instruction word

RX_FRAME_DECODER: process(clock)
variable i: natural; -- recevied byte counter
variable v: std_logic;	-- 'valid' flag
variable t: natural;	-- timeout timer
variable data: std_logic_vector(31 downto 0);

constant header: std_logic_vector(15 downto 0):= x"B734";

begin
	if (rising_edge(clock)) then	
    		
      v := '0';
        
		if (din_valid = '1') then      -- valid data word received from serial receiver			
				
			t := 0;	-- time since last byte received
				
			case i is
					
				-- get frame header	
				when 0 =>	if (din = header(15 downto 8)) then i := 1; end if;																
				when 1 => 	if (din = header(7 downto 0)) then i := 2; elsif (din /= header(15 downto 8)) then i := 0; end if;				
					
				-- get 32-bit command word
				when others => 
			
					data := data(23 downto 0) & din;
					i := i + 1;
					if (i >= 6) then
						i := 0;
						dout <= data;
						v := '1';
					end if;						
						
			end case;           
			
			-- timeout- if a frame was started but not completed then
			-- return to looking for frame header
			if (t > 40000 and i > 0) then i := 0; end if;
				
		end if;
		
		dout_valid <= v;	 	 
	
	end if;
end process;
	
		
	

END vhdl;









