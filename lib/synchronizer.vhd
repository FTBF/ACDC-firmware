---------------------------------------------------------------------------------
-- Univ. of Chicago HEP / electronics design group
--    -- + KICP 2015 --
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         synchronizer.vhd
-- AUTHOR:       D. Greenshields
-- DATE:         Oct 2020
--
-- DESCRIPTION:  used to transfer valid signals from one clock domain to another
--                note that valid_in must not be high for two consecutive  
--                clock cycles
--
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.defs.all;
use work.components.all;



entity pulseSync is
   port (
      inClock	    : in std_logic;
		outClock     : in std_logic;
		din_valid	 : in	std_logic;       
      dout_valid   : out std_logic);
		
end pulseSync;

architecture vhdl of pulseSync is

	
	
   
   signal sync_latch : std_logic := '0'; -- initial values for sim
   signal sync_latch_z : std_logic := '0'; -- initial values for sim
   signal sync_reset : std_logic := '0'; -- initial values for sim
   signal valid_in_z : std_logic;
   
   
   
	
begin	




------------------------------------
--	DATA SYNCHRONIZER
------------------------------------


-- Purpose is to take a single 'data valid' pulse in from one clock domain,
-- and forward it to another clock domain also as a single pulse
--
-- assumptions
-- 1. Data in and valid in will arrive on rising edge of clock in
-- 2. data_in will remain unchanged until a new din valid appears
-- 3. there will never be two consecutive 1's on valid in




FALLING_EDGE_DETECT: process(inClock)
--latch valid_in on the falling edge of clock in
--
-- This gives a safeguard that there is some delay between valid in rising 
-- and the output clock clocking the data, thus ensuring the clock out
-- does not rise before the data is present at the input
begin
   if (falling_edge(inClock)) then
      valid_in_z <= din_valid;
   end if;
end process;



-- detect rising edge on valid in
RISING_EDGE_DETECT: process(valid_in_z, sync_reset)
begin
   if (sync_reset = '1') then 
      sync_latch <= '0';
   elsif (rising_edge(valid_in_z)) then
      sync_latch <= '1';  
   end if;
end process;



-- clock the data and valid out using the out clock
-- and reset the latch
VALID_DATA_OUT: process(outClock)
begin
   if (rising_Edge(OutClock)) then
      sync_latch_z <= sync_latch; 
   elsif (falling_edge(OutClock)) then
      sync_reset <= sync_latch_z;
   end if;
end process;
   
dout_valid <= sync_latch_z; 
 
			
end vhdl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.defs.all;
use work.components.all;


entity pulseSync2 is
  Port(
    src_clk     : in std_logic;
    src_pulse   : in std_logic;
    src_aresetn : in std_logic;

    dest_clk     : in std_logic;
    dest_pulse   : out std_logic;
    dest_aresetn : in std_logic);
end pulseSync2;

architecture vhdl of pulseSync2 is
  signal src_pulse_1 : std_logic;
  signal src_pulse_2 : std_logic;
  
  signal sync_pulse_1 : std_logic;
  signal sync_pulse_2 : std_logic;
  
  signal dest_pulse_1 : std_logic;  

begin
  
  -- src clock domain edge detection
  src_clk_domain : process(src_clk, src_aresetn)
  begin
    if src_aresetn = '0' then
      src_pulse_1 <= '0';
      src_pulse_2 <= '0';
    else
      if rising_Edge(src_clk) then
        src_pulse_1 <= src_pulse;
        src_pulse_2 <= (src_pulse and not src_pulse_1) xor src_pulse_2;
      end if;
    end if;
  end process;

  dest_clk_domain : process(dest_clk, dest_aresetn)
  begin
    if dest_aresetn = '0' then
      dest_pulse_1 <= '0';
      dest_pulse <= '0';

      sync_pulse_1 <= '0';
      sync_pulse_2 <= '0';
    else
      if rising_Edge(dest_clk) then
        sync_pulse_1 <= src_pulse_2;
        sync_pulse_2 <= sync_pulse_1;

        dest_pulse_1 <= sync_pulse_2;
        dest_pulse <= dest_pulse_1 xor sync_pulse_2;
      end if;
    end if;
  end process;
  
  
end vhdl;
  



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.defs.all;
use work.components.all;
use work.pulseSync2;

entity param_handshake_sync is
  port (
    src_clk : in std_logic;
    src_params : in RX_Param_jcpll_type;
    src_aresetn : in std_logic;

    dest_clk : in std_logic;
    dest_params : out RX_Param_jcpll_type;
    dest_aresetn : in std_logic
  );
end entity param_handshake_sync;

architecture vhdl of param_handshake_sync is

  component pulseSync2 is
    port (
      src_clk      : in  std_logic;
      src_pulse    : in  std_logic;
      src_aresetn  : in  std_logic;
      dest_clk     : in  std_logic;
      dest_pulse   : out std_logic;
      dest_aresetn : in  std_logic);
  end component pulseSync2;

  signal src_params_latch : RX_Param_jcpll_type;
  signal src_latch        : std_logic;
  signal src_latch_sync   : std_logic;
  signal dest_latch       : std_logic;
  signal dest_latch_sync  : std_logic;

begin

  src2dest_sync : pulseSync2
  port map (
    src_clk      => src_clk,
    src_pulse    => src_latch,
    src_aresetn  => src_aresetn,
    dest_clk     => dest_clk,
    dest_pulse   => src_latch_sync,
    dest_aresetn => dest_aresetn
  );
  
  dest2src_sync : pulseSync2
  port map (
    src_clk      => dest_clk,
    src_pulse    => dest_latch,
    src_aresetn  => dest_aresetn,
    dest_clk     => src_clk,
    dest_pulse   => dest_latch_sync,
    dest_aresetn => src_aresetn
  );

  sync_DLL_resetRequest : pulseSync2
  port map (
    src_clk      => src_clk,
    src_pulse    => src_params.DLL_resetRequest,
    src_aresetn  => src_aresetn,
    dest_clk     => dest_clk,
    dest_pulse   => dest_params.DLL_resetRequest,
    dest_aresetn => dest_aresetn
  );
  
  sync_eventAndTime_reset : pulseSync2
  port map (
    src_clk      => src_clk,
    src_pulse    => src_params.trigSetup.eventAndTime_reset,
    src_aresetn  => src_aresetn,
    dest_clk     => dest_clk,
    dest_pulse   => dest_params.trigSetup.eventAndTime_reset,
    dest_aresetn => dest_aresetn
  );
  
  sync_transferEnableReq : pulseSync2
  port map (
    src_clk      => src_clk,
    src_pulse    => src_params.trigSetup.transferEnableReq,
    src_aresetn  => src_aresetn,
    dest_clk     => dest_clk,
    dest_pulse   => dest_params.trigSetup.transferEnableReq,
    dest_aresetn => dest_aresetn
  );
  
  sync_transferDisableReq : pulseSync2
  port map (
    src_clk      => src_clk,
    src_pulse    => src_params.trigSetup.transferDisableReq,
    src_aresetn  => src_aresetn,
    dest_clk     => dest_clk,
    dest_pulse   => dest_params.trigSetup.transferDisableReq,
    dest_aresetn => dest_aresetn
  );
  
  sync_resetReq : pulseSync2
  port map (
    src_clk      => src_clk,
    src_pulse    => src_params.trigSetup.resetReq,
    src_aresetn  => src_aresetn,
    dest_clk     => dest_clk,
    dest_pulse   => dest_params.trigSetup.resetReq,
    dest_aresetn => dest_aresetn
  );
  
  src_clk_domain : process(src_clk)
  begin
    if rising_Edge(src_clk) then
      if dest_latch_sync = '1' then
        src_params_latch <= src_params;
        src_latch <= '1';
      else
        src_params_latch <= src_params_latch;
        src_latch <= '0';
      end if;
    end if;
  end process;    

  dest_clk_domain : process(dest_clk, dest_aresetn)
  begin
    if dest_aresetn = '0' then
      dest_latch <= '1';
    else
      if rising_Edge(dest_clk) then
        if src_latch_sync = '1' then
          dest_params.trigSetup.mode       <= src_params_latch.trigSetup.mode;
          dest_params.trigSetup.sma_invert <= src_params_latch.trigSetup.sma_invert;
          dest_params.selfTrig             <= src_params_latch.selfTrig;
          dest_params.Vbias                <= src_params_latch.Vbias;
          dest_params.DLL_Vdd              <= src_params_latch.DLL_Vdd;
          dest_params.RO_target            <= src_params_latch.RO_target;
          dest_params.testMode             <= src_params_latch.testMode;

          dest_latch <= '1';
        else
          dest_params.trigSetup.mode       <= dest_params.trigSetup.mode;
          dest_params.trigSetup.sma_invert <= dest_params.trigSetup.sma_invert;
          dest_params.selfTrig             <= dest_params.selfTrig;
          dest_params.Vbias                <= dest_params.Vbias;
          dest_params.DLL_Vdd              <= dest_params.DLL_Vdd;
          dest_params.RO_target            <= dest_params.RO_target;
          dest_params.testMode             <= dest_params.testMode;

          dest_latch <= '0';
        end if;
      end if;
    end if;
  end process;
  
end vhdl;  
  