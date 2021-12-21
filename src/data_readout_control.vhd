---------------------------------------------------------------------------------
--    
--
-- PROJECT:      ANNIE - ACDC
-- FILE:         ACDC_main.vhd
-- AUTHOR:       Joe Pastika
-- DATE:         June 2021
--
-- DESCRIPTION:  top-level firmware module for ACDC
--
---------------------------------------------------------------------------------

library IEEE; 
use ieee.std_logic_1164.all;
USE ieee.numeric_std.ALL; 
use ieee.std_logic_misc.all;
use work.defs.all;
use work.components.all;
use work.LibDG.all;


entity data_readout_control is
  port(
    clock         : in  clock_type;
    reset         : in  reset_type;
    
    fifoRead      : out std_logic_vector(N-1 downto 0);
    fifoDataOut   : in  array16;
    fifoOcc       : in  array13;

    dataToSend        : out hs_input_array;
    dataToSend_valid  : out std_logic_vector(1 downto 0);
    dataToSend_kout   : out std_logic_vector(1 downto 0);
    dataToSend_ready  : in  std_logic_vector(1 downto 0)
);
end data_readout_control;
    
architecture vhdl of data_readout_control is
  constant WORDS_PER_EVENT : natural := 256*6;
  
  signal FIFO_readoutReady : std_logic_vector(N-1 downto 0);
  
begin

  -- detect when there is a full event in the input FIFO 
  detectReadoutReady : process (clock.serial25)
  begin
    if rising_edge(clock.serial25) then
      for i in 0 to N-1 loop
        if (unsigned(fifoOcc(i)) >= WORDS_PER_EVENT) then
          FIFO_readoutReady(i) <= '1';
        else
          FIFO_readoutReady(i) <= '0';
        end if;
      end loop;
    end if;
  end process;
    
  -- control state machine for readout
  readoutContorler : process (clock.serial25)
    type state_type is ( IDLE, PACKETBEGIN, READDATA, PACKETEND );
    variable state : state_type;

    variable chip : unsigned(2 downto 0);
    variable wordCount : unsigned (10 downto 0);
  begin
    if rising_edge(clock.serial25) then
      if reset.serial = '1' then
        state := IDLE;
        chip := "000";
        wordCount := (others => '0');
        fifoRead <= "00000";
        dataToSend <= (X"00", x"00");
        dataToSend_valid <= "00";
        dataToSend_kout <= "00";
      else
        case state is

          when IDLE =>
            chip := "000";
            wordCount := (others => '0');
            fifoRead <= "00000";
            dataToSend <= (X"00", x"00");
            dataToSend_valid <= "00";
            dataToSend_kout <= "00";
            if and_reduce(FIFO_readoutReady) = '1' and dataToSend_ready = "11" then
              state := PACKETBEGIN;
            else
              state := IDLE;
            end if;

          when PACKETBEGIN =>
            chip := chip;
            wordCount := (others => '0');
            fifoRead <= "00000";
            fifoRead(to_integer(chip)) <= '1';
            dataToSend <= (X"F7", x"F7");
            dataToSend_valid <= "11";
            dataToSend_kout <= "11";
            state := READDATA;

          when READDATA =>
            dataToSend <= ( fifoDataOut(to_integer(chip))(15 downto 8), fifoDataOut(to_integer(chip))(7 downto 0) );
            dataToSend_valid <= "11";
            dataToSend_kout <= "00";
            if wordCount < WORDS_PER_EVENT then
              wordCount := wordCount + 1;
              chip := chip;
              fifoRead <= fifoRead;
              state := READDATA;
            else
              wordCount := (others => '0');
              chip := chip + 1;
              if chip < N then
                fifoRead <= "00000";
                fifoRead(to_integer(chip)) <= '1';
                state := READDATA;
              else
                fifoRead <= "00000";
                state := PACKETEND;
              end if;
            end if;

          when PACKETEND =>
            chip := chip;
            wordCount := (others => '0');
            fifoRead <= fifoRead;
            dataToSend <= (X"FB", x"FB");
            dataToSend_valid <= "11";
            dataToSend_kout <= "11";
            state := IDLE;
            
        end case;
      end if;
    end if;
  end process;
  
end vhdl;
  
