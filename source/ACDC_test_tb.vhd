-------------------------------------------------------------------------------
-- Title      : Testbench for design "ACDC_test"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ACDC_test_tb.vhd
-- Author     :   <Pastika@ITID20020501N>
-- Company    : 
-- Created    : 2021-09-20
-- Last update: 2021-09-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2021 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2021-09-20  1.0      Pastika	Created
-------------------------------------------------------------------------------




--library ACDC;
use work.components.all;
use work.defs.all;
library ieee;
use ieee.NUMERIC_STD.all;	
use ieee.std_logic_1164.all;
use ieee.MATH_REAL.ROUND;
library aldec;
use aldec.random_pkg.all;

-------------------------------------------------------------------------------

entity ACDC_test_tb is

end entity ACDC_test_tb;

-------------------------------------------------------------------------------

architecture vhdl of ACDC_test_tb is

  -- constants 
  constant CLK_PERIOD : time := 40 ns;
  constant OSC_PERIOD : time := 30 ns;
  constant UART_PERIOD : time := 100 ns;
  constant RESET_LENGTH : time := 1500 ns;
  shared variable ENDSIM : boolean := false;

  -- component ports
  signal clockIn        : clockSource_type;
  signal jcpll_ctrl     : jcpll_ctrl_type;
  signal jcpll_lock     : std_logic;
  signal LVDS_in        : std_logic_vector(2 downto 0);
  signal LVDS_out       : std_logic_vector(3 downto 0);
  signal PSEC4_in       : PSEC4_in_array_type;
  signal PSEC4_out      : PSEC4_out_array_type;
  signal PSEC4_freq_sel : std_logic;
  signal PSEC4_trigSign : std_logic;
  signal calEnable      : std_logic_vector(14 downto 0);
  signal calInputSel    : std_logic;
  signal DAC            : DAC_array_type;
  signal SMA_trigIn     : std_logic;
  signal ledOut         : std_logic_vector(numberOfLeds-1 downto 0);   
  
  procedure sendbyte
    (byte : in std_logic_vector(7 downto 0);
	signal bits : out std_logic) is
  begin
	bits <= '0'; 	 -- start bit
	wait for UART_PERIOD;
	for iBit in 0 to 7 loop
      bits <= byte(iBit);
      wait for UART_PERIOD;
	end loop;
	bits <= '1'; 	 -- stop bit
	wait for UART_PERIOD;
  end sendbyte;
	
  procedure sendword
    (word : in std_logic_vector(31 downto 0);
     signal bits : out std_logic) is 
  begin	
	-- header
	sendbyte(STARTWORD_8a, bits);
	wait for UART_PERIOD*5;
	sendbyte(STARTWORD_8b, bits);
	wait for UART_PERIOD*5;
	
	-- data
	for iByte in 0 to 3 loop 
	  sendbyte(word((3 - iByte + 1)*8 - 1 downto (3 - iByte)*8), bits);  
	  wait for UART_PERIOD*5;
	end loop;
  end sendword;

begin  -- architecture vhdl

  -- component instantiation
  DUT: entity work.ACDC_test
    port map (
      clockIn        => clockIn,
      jcpll_ctrl     => jcpll_ctrl,
      jcpll_lock     => jcpll_lock,
      LVDS_in        => LVDS_in,
      LVDS_out       => LVDS_out,
      PSEC4_in       => PSEC4_in,
      PSEC4_out      => PSEC4_out,
      PSEC4_freq_sel => PSEC4_freq_sel,
      PSEC4_trigSign => PSEC4_trigSign,
      calEnable      => calEnable,
      calInputSel    => calInputSel,
      DAC            => DAC,
      SMA_trigIn     => SMA_trigIn,
      ledOut         => ledOut);

  -- clock generation
  LOCAL_OSC_GEN_PROC : process 
  begin
    if ENDSIM = false then
      clockIn.localOsc <= '0';
      wait for OSC_PERIOD / 2;
      clockIn.localOsc <= '1';
      wait for OSC_PERIOD / 2;
    else 
      wait;
    end if;
  end process;	
  
  clockIn.jcpll <= '0';
--  ACC_CLK_GEN_PROC : process 
--  begin
--    if ENDSIM = false then
--      clockIn.jcpll <= '0';
--      wait for CLK_PERIOD / 2;
--      clockIn.jcpll <= '1';
--      wait for CLK_PERIOD / 2;
--    else 
--      wait;
--    end if;
--  end process;	
  
  -- waveform generation
  WaveGen_Proc: process
  begin
    -- insert signal assignments here
    LVDS_in(0) <= '1';
    SMA_trigIn <= '0';	
	wait for 20 us;
	
  	sendword(X"FFF10000", LVDS_in(0)); 
	sendword(X"FFF300a0", LVDS_in(0));
	sendword(X"FFF4a332", LVDS_in(0));
	sendword(X"FFF50000", LVDS_in(0));
	
	wait;


  end process WaveGen_Proc;

  

end architecture vhdl;

-------------------------------------------------------------------------------

--configuration ACDC_test_tb_vhdl_cfg of ACDC_test_tb is
--  for vhdl
--  end for;
--end ACDC_test_tb_vhdl_cfg;

-------------------------------------------------------------------------------
