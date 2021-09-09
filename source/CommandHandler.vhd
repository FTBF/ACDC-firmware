---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         commandHandler.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
-- modified for revC Aug2021
-- DESCRIPTION:  receives 32bit commands and generates appropriate control signals locally
--                
--
---------------------------------------------------------------------------------																			 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;																																			 

entity commandHandler is
	port (
		reset 					: in   	std_logic;
		clock			      	: in	std_logic;        
		din			      	   	: in    std_logic_vector(31 downto 0);
		din_valid				: in    std_logic;
		trigSetup				: out trigSetup_type;   
		Vbias					: out natArray16;    
		DLL_Vdd					: out natArray16;     
		calEnable				: out std_logic_vector(14 downto 0);   
		calInputSel          : out std_logic;
		reset_request			: out std_logic;   
		DLL_resetRequest		: out std_logic;   
		PLL_resetRequest		: out std_logic;   
		PLL_ConfigRequest		: out std_logic;   
		PLL_ConfigReg			: out std_logic_vector(31 downto 0);   
		RO_target				: out natArray;   
		ramReadRequest			: out std_logic;   
		IDrequest				: out std_logic;
		ledFunction				: out ledFunction_array;
		ledTestFunction			: out ledTestFunction_array;
		ledTest_onTime			: out ledTest_onTime_array;
		testMode				: out testMode_type
		);
end commandHandler;

architecture vhdl of commandHandler is
	
begin	
	
	-- note
	-- the signals generated in this process either stay set until a new command arrives to change them,
	-- or they will last for one clock cycle and then reset
	--
	
	COMMAND_HANDLER:	process(clock)
		variable psecMask: 		std_logic_vector(4 downto 0);
		variable cmdType: 		std_logic_vector(3 downto 0);
		variable cmdOption: 	std_logic_vector(3 downto 0);
		variable cmdOption2: 	std_logic_vector(3 downto 0);
		variable cmdOptionE: 	std_logic_vector(3 downto 0);
		variable cmdValue: 		std_logic_vector(11 downto 0);
		variable cmdLongVal: 	std_logic_vector(15 downto 0);
		variable acdc_cmd: 		std_logic_vector(31 downto 0);	
		
		variable m: 			natural;
		variable x: 			natural;	
		variable opt2: 			natural range 0 to 15;
	begin
		if (rising_edge(clock)) then
			if (reset = '1' or din_valid = '0') then  	  
				if (reset = '1') then
					-- POWER-ON DEFAULT VALUES
					--------------------------
					for i in 0 to N-1 loop
						trigSetup.selfTrig_threshold(i)	<= 0;
						trigSetup.selfTrig_mask(i) <= "000000";
						Vbias(i)			<= 16#0800#;
						DLL_Vdd(i)			<= 16#0CFF#; 
						RO_Target(i)		<= 16#CA00#;
					end loop;							
					DLL_resetRequest <= '0';
					PLL_ConfigRequest <= '0';		 
					PLL_resetRequest <= '0';	  
					reset_request <= '0';
					
					calEnable					<= (others => '0'); 
					calInputSel             <= '0';
					testMode.sequencedPsecData 	<= '0';
					testMode.trig_noTransfer 	<= '0';	

					
					-- trig
					trigSetup.mode 	<= 0;
					trigSetup.enable <= '1';
					trigSetup.selfTrig_coincidence_min <= 1;
					trigSetup.use_clocked_trig <= '1';
					---------------------------
					
				end if;
				
				
				-- Clear single-pulse signals
				DLL_resetRequest	<= '0';
				reset_request   	<= '0';
				ramReadRequest 	<= '0';
				IDrequest			<= '0';
				trigSetup.eventAndTime_reset <= '0';
				trigSetup.transferEnableReq <= '0';
				trigSetup.transferDisableReq <= '0';
				trigSetup.resetReq <= '0';
				
				--
				
			else     -- new instruction received
				--parse 32 bit instruction word:
				--
				cmdType				:= din(23 downto 20);
				cmdValue			:= din(11 downto 0);	   
				cmdLongVal			:= din(15 downto 0);	   
				
				-- when psecMask not used:
				cmdOption			:= din(19 downto 16);	
				cmdOption2			:= din(15 downto 12);	
				opt2 := to_integer(unsigned(cmdOption2));
				
				-- when psecMask used: ("A" command only)
				cmdOptionE			:= din(19 downto 17) & "0";	-- even numbers only
				psecMask				:= din(16 downto 12);
				
				case cmdType is  -- command type                			
					when x"A" =>	-- set parameter
						case cmdOptionE is
							when x"0" =>	-- dll vdd							
								for j in 4 downto 0 loop
									if (psecMask(j) = '1') then
										DLL_Vdd(j) <= to_integer(unsigned(cmdValue));
									end if;
							end loop;
							when x"2" =>	-- pedestal offset 
								for j in 4 downto 0 loop
									if (psecMask(j) = '1') then
										Vbias(j) <= to_integer(unsigned(cmdValue));
									end if;
							end loop;
							when x"4" =>	-- ring oscillator feedback 
								for j in 4 downto 0 loop
									if (psecMask(j) = '1') then 
										RO_target(j) <= to_integer(unsigned(cmdValue));
									end if;
							end loop;
							when x"6" =>	-- self trigger threshold
								for j in 4 downto 0 loop
									if (psecMask(j) = '1') then
										trigSetup.selfTrig_threshold(j) <= to_integer(unsigned(cmdValue));
									end if;
								end loop;
							when others => null;
						end case;
						
					when x"B" =>	-- trigger 
						case cmdOption is
							when x"0" => 	-- mode 
								trigSetup.mode <= to_integer(unsigned(din(3 downto 0)));
							when x"1" => 	-- self trig setup
								case cmdOption2 is						
									when x"0" => trigSetup.selfTrig_mask(0) <= din(5 downto 0);
									when x"1" => trigSetup.selfTrig_mask(1) <= din(5 downto 0);
									when x"2" => trigSetup.selfTrig_mask(2) <= din(5 downto 0);
									when x"3" => trigSetup.selfTrig_mask(3) <= din(5 downto 0);
									when x"4" => trigSetup.selfTrig_mask(4) <= din(5 downto 0);
									when x"5" => trigSetup.selfTrig_coincidence_min <= to_integer(unsigned(din(4 downto 0)));
									when x"6" => trigSetup.selfTrig_sign <= din(0);
									when x"7" => trigSetup.selfTrig_detect_mode <= din(0); -- 0=edge, 1=level
									when x"8" => trigSetup.selfTrig_use_coincidence <= din(0); 
									when others => null;
								end case;
							when x"2" => 	-- sma config
								case cmdOption2 is
									when x"0" => trigSetup.sma_invert <= din(0);			-- 0=normal, 1=invert 
									when x"1" => trigSetup.sma_detect_mode <= din(0);		-- 0=edge, 1=level
									when others => null;
								end case;
							when x"3" => 	-- acc config
								case cmdOption2 is
									when x"0" => trigSetup.acc_invert <= din(0);			 
									when x"1" => trigSetup.acc_detect_mode <= din(0);			 
									when others => null;
								end case;
							when x"4" => 	-- validate
								case cmdOption2 is
									when x"0" => trigSetup.valid_window_start <= to_integer(unsigned(din(11 downto 0)));			 
									when x"1" => trigSetup.valid_window_len <= to_integer(unsigned(din(11 downto 0)));			 
									when others => null;
								end case;
							when x"5" => 	-- control
								case cmdOption2 is
									when x"0" => trigSetup.transferEnableReq <= '1'; -- tell the acdc that the acc buffer is ready for data
									when x"1" => trigSetup.resetReq <= '1';
									when x"2" => trigSetup.eventAndTime_reset <= '1';
									when x"3" => trigSetup.enable <= din(0);
									when x"4" => trigSetup.transferDisableReq <= '1'; -- tell the acdc that the acc buffer is not ready for data
									when x"5" => trigSetup.use_clocked_trig <= din(0);	
									when others => null;
								end case;
							when x"6" => 	-- test mode
								case cmdOption2 is
									when x"0" => testMode.trig_noTransfer <= din(0);
									when others => null;
								end case;
							when others => null;
						end case;
						
					when x"C" =>	-- calibration		
						case cmdOption is
							when x"0" => calEnable(14 downto 0) <= din(14 downto 0);
							when x"1" => calInputSel <= din(0);
							when others => null;
						end case;
						
					
					when x"D" =>	-- data 
						
						case cmdOption is
							when x"0" => IDrequest <= '1';		-- request to send an ID data frame							
							when others => null;
						end case;
					
					when x"E" =>	-- led control
						
						case cmdOption is
							
							-- set the test function number and test on-time option
							when x"8" => 
								ledTestFunction(opt2) <= to_integer(unsigned(din(7 downto 0)));							
								if (din(11) = '1') then 
									ledTest_onTime(opt2) <= 500; 
								else 
									ledTest_onTime(opt2) <= 1;
								end if;
								
								-- set the led function
								-- led function has 4 values:
								--
								-- 0 = standard function
								-- 1 = on
								-- 2 = off
							-- 3 = test function							
							when others =>
								
								x := 0;
								for i in 0 to 8 loop
									ledFunction(i) <= to_integer(unsigned(din(x+1 downto x)));
									x := x + 2;
								end loop;
							
						end case;
						
					
					when x"F" =>	-- system command
						
						case cmdOption is					
							
							when x"0" => 	-- debug / test modes
								
								case cmdOption2 is 
									when x"0" => testMode.sequencedPsecData <= cmdValue(0);
									when others => null;
								end case;
								
							when x"1" => 
								DLL_resetRequest <= '0';
								PLL_ConfigRequest <= '0';		 
								--PLL_resetRequest <= '0';	  
								reset_request <= '0';
							when x"2" => DLL_resetRequest <= '1';
							when x"3" => PLL_ConfigReg(15 downto 0) <= cmdLongVal;
							when x"4" => PLL_ConfigReg(31 downto 16) <= cmdLongVal;
							when x"5" => PLL_ConfigRequest <= '1';
							--when x"7" => PLL_resetRequest <= '1';
							when x"A" => reset_request <= '1';	-- global reset 
							when others => null;
							
						end case;		
						
						
						
						
					
					when others =>
						
						null;
						
						
					
				end case;
				
			end if;
		end if;
	end process;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
end vhdl;