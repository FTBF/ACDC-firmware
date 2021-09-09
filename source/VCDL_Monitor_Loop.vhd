---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         VCDL_Monitor_Loop.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  
--
--------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.defs.all;


entity VCDL_Monitor_Loop is
     Port (
             clock       			: in clock_type; --One period of this clock defines how long we count Wilkinson rate pulses
             VCDL_MONITOR_BIT    : in std_logic;
             countReg	 			: out natural
        );
end VCDL_Monitor_Loop;

architecture vhdl of VCDL_Monitor_Loop is
        type STATE_TYPE is ( MONITORING, SETTLING, LATCHING, CLEARING_AND_ADJUSTING );
        signal state                   : STATE_TYPE := MONITORING;
        signal countEnable : std_logic := '0';
        signal countReset  : std_logic := '0';
        signal count       : natural;
begin

        process(clock.sys)
        begin
               if (rising_edge(clock.sys)) then
                    if (clock.dacUpdate = '1') then		-- slow update clock
							
								case state is
                                when MONITORING =>
                                        countEnable <= '1';
                                        countReset  <= '0';
                                        state <= SETTLING;
                                when SETTLING =>
                                        countEnable <= '0';
                                        countReset  <= '0';
                                        state <= LATCHING;
                                when LATCHING =>
                                        countEnable <= '0';
                                        countReset  <= '0';
                                        countReg <= count;
                                        state <= CLEARING_AND_ADJUSTING;													
                                when CLEARING_AND_ADJUSTING =>
                                        countEnable <= '0';
                                        countReset  <= '1';
                                        state <= MONITORING;
                        end case;
								
								
						end if;
                end if;
        end process;

        process(VCDL_MONITOR_BIT, countEnable, countReset) 
        begin
                if (countReset = '1') then
                        count <= 0;
                elsif ( countEnable = '1' and rising_edge(VCDL_MONITOR_BIT) ) then
                        count <= count + 1;
                end if;
        end process;

end vhdl;
