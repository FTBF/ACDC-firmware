---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         dacSerial.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Dec 2020
--
-- DESCRIPTION:  DAC serialization module                                             
--    				for use with Linear Tech. LTC2620 Octal 12-bit DAC
--    				latches input data when update goes high and then writes
--						latched data to all channels of all dacs in the chain
--
--						Currently 2 devices per chain x 8 outputs per device = 16 total analogue outputs
--
--						Processed with system clock but activated by a pulse on update clock
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.defs.all;

entity dacSerial is
  port(
        clock           : in    clock_type;
        dataIn          : in    DACchain_data_type;  	-- array (0 to 1) of dac data
        dac    	      : out   dac_type
	);
end dacSerial;
        
architecture vhdl of dacSerial is

  type STATE_TYPE is (IDLE, CREATE_CHAIN_DATA, WRITE_DATA, CLOCK_PULSE, DAC_LOAD);

  signal state          : STATE_TYPE;
  signal latchedData    : DACchain_data_type;  	-- array (0 to 1) of dac data [2 devices on the chain]

begin 

dac.clear <= '1';		-- hold the clear signal inactive

SerialWrite: process(clock.sys)
type dataWord_type is array (0 to 1) of std_logic_vector(11 downto 0);
variable dataWord: dataWord_type;
variable cmd: std_logic_vector(3 downto 0);
variable i : natural;	-- number of bits done
variable channel : natural;	-- channel number
variable address : std_logic_vector(3 downto 0);	-- slv version of channel number
variable chainData : std_logic_vector(63 downto 0);	-- the data that will be written serially
variable k: natural;	-- a clock cycle counter to slow down the timings so that they are compatible with the dac
begin 
	if rising_edge(clock.sys) then         
        
		case STATE is
      
		
			when IDLE  =>                 --idle, DACs not updating
            
				dac.load <= '1';
				dac.serialClock <= '0';
            if (clock.dacUpdate = '1') then
					latchedData <= dataIn;
					channel := 0;
					STATE <= CREATE_CHAIN_DATA;
            end if;
          
			 
			 
			when CREATE_CHAIN_DATA =>   -- generate a frame of data containing command, address, padding and data bits for all devices in the chain
				
				dac.load <= '0';
				cmd := "0011";		-- write to and update the addressed dac
				address := std_logic_vector(to_unsigned(channel,4));
				dataWord(1) := std_logic_vector(to_unsigned(latchedData(1)(channel),12));
				dataWord(0) := std_logic_vector(to_unsigned(latchedData(0)(channel),12));
				chainData(63 downto 32) := x"00" & cmd & address & dataWord(1) & x"0"; -- device 1 (furthest in the chain)
				chainData(31 downto 0) := x"00" & cmd & address & dataWord(0) & x"0"; -- device 0 (nearest in the chain)
				i := 0;		-- number of bits done
				k := 0;
				state <= WRITE_DATA;
				
				
				
			when WRITE_DATA =>             -- write serial bitstream to dacs
            
            dac.serialData <= chainData(63-i); 	-- start with highest bit
            dac.serialclock <= '0';
				k := k + 1;
				if (k >= 5) then 
					k := 0; 	-- hold the data before sending clock high
					state <= CLOCK_PULSE; 
				end if;
				
				
			 
			when CLOCK_PULSE =>             
				
				dac.serialclock <= '1';			-- write the data bit
            k := k + 1;
				if (k >= 5) then 
					i := i + 1;
					k := 0;	-- hold the data before sending clock low
					if (i >= 64) then state <= DAC_LOAD; else	state <= WRITE_DATA; end if;
				end if;
			
			
			when DAC_LOAD =>             
            
				dac.load <= '1';		-- update the dac outputs
            channel := channel + 1;
				if (channel >= 8) then	-- all 8 channels done
					state <= IDLE;          
            else
					state <= CREATE_CHAIN_DATA;
            end if;



		end case;
	end if;
end process;
     
	  
	  
	  
	  
	  
	  
	  
	  
	  
end vhdl;

