---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         commandHandler.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  receives 32bit commands and generates appropriate control signals locally
--                
--
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;


entity commandHandler is
	port (
      reset		     : in    std_logic;
      clock		     : in	   std_logic;
      clock_out	     : in	   std_logic;        
      din		     : in    std_logic_vector(31 downto 0);
      din_valid	     : in    std_logic;
      params         : out   RX_Param_jcpll_type;
      params_syncAcc : out   RX_Param_jcpll_type;
      params_acc     : out   RX_Param_acc_type
      );
end commandHandler;


architecture vhdl of commandHandler is
  signal params_z : RX_Param_jcpll_type;
  signal resetn : std_logic;
begin	
	
   
   
-- note
-- the signals generated in this process either stay set until a new command arrives to change them,
-- or they will last for one clock cycle and then reset
--

params_syncAcc <= params_z;
  
-- CDC for sys clk output parameters
resetn <= not reset;
param_handshake_sync_1: entity work.param_handshake_sync
  port map (
    src_clk      => clock,
    src_params   => params_z,
    src_aresetn  => resetn,
    dest_clk     => clock_out,
    dest_params  => params,
    dest_aresetn => resetn
    );

   
COMMAND_HANDLER:	process(clock)
variable psecSel: 		natural range 0 to N;
variable cmdType: 		std_logic_vector(3 downto 0);
variable cmdOption: 		std_logic_vector(3 downto 0);
variable cmdOption2: 		std_logic_vector(3 downto 0);
variable cmdValue: 		std_logic_vector(11 downto 0);
variable cmdLongVal: 	std_logic_vector(15 downto 0);
variable acdc_cmd: 		std_logic_vector(31 downto 0);	
variable m: 		natural;
variable x: natural;	
variable opt: natural range 0 to 15;
variable init: std_logic:='1';

begin
	if (rising_edge(clock)) then

      if (init = '1') then
			
			-- do once only at power-up
			
			init := '0';
			params_z.testMode.DLL_updateEnable <= "11111";	-- default is all enabled
		
		end if;
		
		if (reset = '1' or din_valid = '0') then  
		
			if (reset = '1') then
				
				-- POWER-ON DEFAULT VALUES
				--------------------------
				-- WARNING: also set defaults in param_handshake_sync
                for i in 0 to N-1 loop
                    for j in 0 to M-1 loop
                      params_z.selfTrig.threshold(j, i)	<= 0;
                    end loop;
					params_z.selfTrig.mask(i) 			<= "000000";
					params_z.Vbias(i)				<= 16#0800#;
					params_z.DLL_Vdd(i)			<= 16#0CFF#; 
					params_z.RO_Target(i)		<= 16#CA00#;
				end loop;
				params_acc.calEnable			<= (others => '0');
                params_acc.calInputSel          <= '0';
				params_z.testMode.sequencedPsecData <= '0';
				params_z.testMode.trig_noTransfer <= '0';
                params_acc.PLL_ConfigRequest <= '0';		 
                params_acc.PLL_resetRequest <= '0';	 
                params_acc.outputMode <= "00";
                params_acc.IDpage <= "0000";
                
				-- trig
				params_z.trigSetup.mode 	<= 0;
				params_z.trigSetup.sma_invert <= '0';
                params_z.trigSetup.timeout <= 0;
				params_z.selfTrig.coincidence_min <= 1;
			
				---------------------------
			
			end if;

			-- Clear single-pulse signals
			
			params_z.DLL_resetRequest	<= '0';
			params_acc.reset_request   	<= '0';
			params_z.ramReadRequest 	<= '0';
			params_acc.IDrequest			<= '0';
			params_z.trigSetup.eventAndTime_reset <= '0';
			params_z.trigSetup.transferEnableReq <= '0';
			params_z.trigSetup.transferDisableReq <= '0';
			params_z.trigSetup.resetReq <= '0';
			

      else     -- new instruction received
			
			--parse 32 bit instruction word:
			--
			cmdType				:= din(23 downto 20);
			cmdValue			:= din(11 downto 0);
            cmdLongVal			:= din(15 downto 0);

			-- when psecMask not used:
			cmdOption			:= din(19 downto 16);	
            opt := to_integer(unsigned(cmdOption));
			cmdOption2			:= din(15 downto 12);	
			
			-- when psecMask used: ("A" command only)
			psecSel				:= to_integer(unsigned(din(14 downto 12)));
			
			
         case cmdType is  -- command type                

					when x"A" =>	-- set parameter
					
						case cmdOption is
						
							when x"0" =>	-- dll vdd							
                                params_z.DLL_Vdd(psecSel) <= to_integer(unsigned(cmdValue));

							when x"2" =>	-- pedestal offset 
                                params_z.Vbias(psecSel) <= to_integer(unsigned(cmdValue));
	
							when x"4" =>	-- ring oscillator feedback 
                                params_z.RO_target(psecSel) <= to_integer(unsigned(cmdValue));
								
							when x"6" =>	-- self trigger threshold
                                params_z.selfTrig.threshold(psecSel, 0) <= to_integer(unsigned(cmdValue));
								
							when x"7" =>	-- self trigger threshold
                                params_z.selfTrig.threshold(psecSel, 1) <= to_integer(unsigned(cmdValue));
								
							when x"8" =>	-- self trigger threshold
                                params_z.selfTrig.threshold(psecSel, 2) <= to_integer(unsigned(cmdValue));
								
							when x"9" =>	-- self trigger threshold
                                params_z.selfTrig.threshold(psecSel, 3) <= to_integer(unsigned(cmdValue));
								
							when x"A" =>	-- self trigger threshold
                                params_z.selfTrig.threshold(psecSel, 4) <= to_integer(unsigned(cmdValue));
								
							when x"B" =>	-- self trigger threshold
                                params_z.selfTrig.threshold(psecSel, 5) <= to_integer(unsigned(cmdValue));
								
							when others => null;
								
						end case;
						
						
					when x"B" =>	-- trigger 
						
						case cmdOption is
							
							when x"0" => 	-- mode 
								
								params_z.trigSetup.mode <= to_integer(unsigned(din(3 downto 0)));
														
							
													
							when x"1" => 	-- self trig setup
							
								case cmdOption2 is						
									when x"0" => params_z.selfTrig.mask(0) <= din(5 downto 0);
									when x"1" => params_z.selfTrig.mask(1) <= din(5 downto 0);
									when x"2" => params_z.selfTrig.mask(2) <= din(5 downto 0);
									when x"3" => params_z.selfTrig.mask(3) <= din(5 downto 0);
									when x"4" => params_z.selfTrig.mask(4) <= din(5 downto 0);
									when x"5" => params_z.selfTrig.coincidence_min <= to_integer(unsigned(din(4 downto 0)));
									when x"6" => params_z.selfTrig.sign <= din(0);
									when x"8" => params_z.selfTrig.use_coincidence <= din(0); 
									
									
									
									when others => null;
								end case;
								
								

							when x"2" => 	-- timeout
							
                                params_z.trigSetup.timeout <= to_integer(unsigned(din(6 downto 0)));
								
								
								
							when x"5" => 	-- control
							
								case cmdOption2 is
									when x"0" => params_z.trigSetup.transferEnableReq <= '1'; -- tell the acdc that the acc buffer is ready for data
									when x"1" => params_z.trigSetup.resetReq <= '1';
									when x"2" => params_z.trigSetup.eventAndTime_reset <= '1';
									when x"4" => params_z.trigSetup.transferDisableReq <= '1'; -- tell the acdc that the acc buffer is not ready for data
									when others => null;
								end case;
								
								
								
							when x"6" => 	-- test mode
							
								case cmdOption2 is
									when x"0" => params_z.testMode.trig_noTransfer <= din(0);
									when others => null;
								end case;
								
								
								
							when others => null;
						
		
						end case;
						
						
					when x"C" =>	-- calibration		
						
						case cmdOption is
                          when x"0" => params_acc.calEnable(14 downto 0) <= din(14 downto 0);
                          when x"1" => params_acc.calInputSel <= din(0);
                          when others => null;
						end case;
						

						
					when x"D" =>	-- data

                      case cmdOption is
                        
                        when x"0" => 	-- request to send an ID data frame
                          params_acc.IDrequest <= '1';
                          params_acc.IDpage <= cmdValue(3 downto 0);
                          when others => null;
                      end case;
						
					
					when x"E" =>	-- led control

						null;

					
					
					when x"F" =>	-- system command
					
						case cmdOption is					
							
							when x"0" => 	-- debug / test modes
							
								case cmdOption2 is 
									when x"0" => params_z.testMode.sequencedPsecData <= cmdValue(0);
									when x"1" => params_z.testMode.DLL_updateEnable <= cmdValue(4 downto 0);
									when others => null;
								end case;
								
                            when x"1" => 
                              params_z.DLL_resetRequest <= '0';
                              params_acc.PLL_ConfigRequest <= '0';		 
                              --params_acc.PLL_resetRequest <= '0';	  
                              params_acc.reset_request <= '0';
                            when x"2" => params_z.DLL_resetRequest <= '1';
                            when x"3" => params_acc.PLL_ConfigReg(15 downto 0) <= cmdLongVal;
                            when x"4" => params_acc.PLL_ConfigReg(31 downto 16) <= cmdLongVal;
                            when x"5" => params_acc.PLL_ConfigRequest <= '1';
                            when x"6" => params_acc.outputMode <= cmdLongVal(1 downto 0);           

							when x"F" => params_acc.reset_request <= '1';	-- global reset 
							when others => null;
						
						end case;		
							
												
						
					when others =>
						
						null;
		
				end case;
				
      end if;
   end if;
end process;
               
		
end vhdl;
