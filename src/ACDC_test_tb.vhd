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
use work.components_ACC.serialTx_buffer_ACC;
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
  constant CLK_PERIOD : time := 25 ns;
  constant OSC_PERIOD : time := 40 ns; 
  constant TX_PERIOD : time := 25 ns;
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
  signal SMA_J5         : std_logic;	   
  signal SMA_J16        : std_logic;
  signal ledOut         : std_logic_vector(9-1 downto 0);   
  
  signal	reset				:	std_logic;  
  signal	serial				:	std_logic;   
  signal byte 			         :   std_logic_vector(7 downto 0);
  signal byte_txReq			: std_logic;
  signal byte_txAck			: std_logic;   
  signal cmd_in                 : std_logic_vector(31 downto 0);
  signal cmd_ready                 : std_logic;		
  signal tx_clk                 : std_logic;
  
  component synchronousTx_8b10b_ACC IS 
	PORT
	(
		clock 				:  IN  std_logic;		
		rd_reset				:	in	 std_logic;
		din 					:  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		txReq					:  IN  STD_LOGIC;
		txAck					:	out std_logic;
		dout 					:  OUT STD_LOGIC	-- serial bitstream out
	);
    END component;
			   		
  
  procedure sendword
  ( constant word : in std_logic_vector(31 downto 0); 
    signal word_out : out std_logic_vector(31 downto 0);
    signal ready : out std_logic) is
  begin					
	-- data
	word_out <= word;
	ready <= '1';
	wait for 25 ns;
	ready <= '0'; 
	wait for 100 ns;
  end sendword;

begin  -- architecture vhdl

  -- component instantiation
  DUT: entity work.ACDC_main
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
      DAC            => DAC,   
	  SMA_J5			=> SMA_J5,
	  SMA_J16			=> SMA_J16,
      ledOut         => ledOut);
	  
------------------------------------
--	SERIAL TX BUFFER
------------------------------------
-- fifo & frame writer for commands to ACDC
tx_buffer_map: serialTx_buffer_ACC port map (
		clock			=> tx_clk,	 
         din				=> cmd_in,
		din_txReq		=> cmd_ready,
		din_txAck		=> open,			-- no flow control on writing to tx buffer, but it is unlikely to overflow because there is a large fifo
		dout				=> byte,
		dout_txReq		=> byte_txReq,
		dout_txAck		=> byte_txAck
	);
			 
------------------------------------
--	SERIAL TX
------------------------------------
-- serial comms to the acdc
tx_comms_map : synchronousTx_8b10b_ACC port map (
		clock 		=> tx_clk,
		rd_reset		=> reset,
		din 			=> byte,
		txReq			=> byte_txReq,
		txAck			=> byte_txAck,
		dout 			=> serial		-- serial bitstream out		 			
	);
	
	LVDS_in(0) <= serial;

  -- clock generation
  ACC_OSC_GEN_PROC : process 
  begin
    if ENDSIM = false then
      clockIn.accOsc <= '0';
      wait for OSC_PERIOD / 2;
      clockIn.accOsc <= '1';
      wait for OSC_PERIOD / 2;
    else 
      wait;
    end if;
  end process;
  
  
  TX_GEN_PROC : process 
  begin
    if ENDSIM = false then
      tx_clk <= '0';
      wait for TX_PERIOD / 2;
      tx_clk <= '1';
      wait for TX_PERIOD / 2;
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
    SMA_J5 <= '0';
    SMA_J16 <= '0';
	reset <= '1';
	cmd_in <= X"00000000";
	cmd_ready <= '0';
	wait for 20 us;	 
	reset <= '0';
	wait for 20 us;	
	
	wait for 2 ms;
	
	sendword(X"FFF10000", cmd_in, cmd_ready);
	sendword(X"FFF300a0", cmd_in, cmd_ready); 
	sendword(X"FFF4a332", cmd_in, cmd_ready); 
	sendword(X"FFF50000", cmd_in, cmd_ready);
	sendword(X"FFF10000", cmd_in, cmd_ready);
	
	wait for 1.2 ms;
	
	sendword(X"FFF38765", cmd_in, cmd_ready); 
	sendword(X"FFF44321", cmd_in, cmd_ready); 
	sendword(X"FFF50000", cmd_in, cmd_ready);
	sendword(X"FFF10000", cmd_in, cmd_ready);

	
	wait;


  end process WaveGen_Proc;

  

end architecture vhdl;

-------------------------------------------------------------------------------

--configuration ACDC_test_tb_vhdl_cfg of ACDC_test_tb is
--  for vhdl
--  end for;
--end ACDC_test_tb_vhdl_cfg;

-------------------------------------------------------------------------------
