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

    backpressure  : in  std_logic;

    -- main data FIFOs from PSEC4s
    fifoRead      : out std_logic_vector(N-1 downto 0);
    fifoDataOut   : in  array16;
    fifoOcc       : in  array13;

    -- 320 MHz system clock counter value
    sys_timestamp	 : in  std_logic_vector(63 downto 0);
    sys_ts_read      : out std_logic;
    sys_ts_valid     : in  std_logic;

    -- White Rabbit counter
    wr_timestamp	 : in  std_logic_vector(63 downto 0);
    wr_ts_read       : out std_logic;
    wr_ts_valid      : in  std_logic;

    -- data output to encoder/serializer
    dataToSend        : out hs_input_array;
    dataToSend_valid  : out std_logic_vector(1 downto 0);
    dataToSend_kout   : out std_logic_vector(1 downto 0);
    dataToSend_ready  : in  std_logic_vector(1 downto 0)
);
end data_readout_control;
    
architecture vhdl of data_readout_control is
  constant WORDS_PER_EVENT : natural := 256*6;
  constant WORDS_PER_HEADER : natural := 16;
  
  signal FIFO_readoutReady : std_logic_vector(N-1 downto 0);

  signal eventCount : unsigned(15 downto 0);

  type state_type is ( IDLE, PACKETBEGIN, HEADER, READDATA, PACKETEND );
  signal state : state_type;
  signal chip : unsigned(2 downto 0);
  signal wordCount : unsigned (10 downto 0);

  signal dataToSend_z        : hs_input_array;
  signal dataToSend_valid_z  : std_logic_vector(1 downto 0);
  signal dataToSend_kout_z   : std_logic_vector(1 downto 0);
  signal dataToSend_ready_z  : std_logic_vector(1 downto 0);

  signal dataToSend_z2        : hs_input_array;
  signal dataToSend_valid_z2  : std_logic_vector(1 downto 0);
  signal dataToSend_kout_z2   : std_logic_vector(1 downto 0);
  signal dataToSend_ready_z2  : std_logic_vector(1 downto 0);

begin

--  skid_buffer_lsb: skid_buffer
--    generic map (
--      NBITS => 9)
--    port map (
--      clock                => clock.serial25,
--      reset                => reset.serial,
--      data_in              => dataToSend_kout_z(0) & dataToSend_z(0),
--      data_in_ready        => dataToSend_ready_z(0),
--      data_in_valid        => dataToSend_valid_z(0),
--      data_out(7 downto 0) => dataToSend(0),
--      data_out(8)          => dataToSend_kout(0),
--      data_out_ready       => dataToSend_ready(0),
--      data_out_valid       => dataToSend_valid(0));
--
--  skid_buffer_msb: skid_buffer
--    generic map (
--      NBITS => 9)
--    port map (
--      clock                => clock.serial25,
--      reset                => reset.serial,
--      data_in              => dataToSend_kout_z(1) & dataToSend_z(1),
--      data_in_ready        => dataToSend_ready_z(1),
--      data_in_valid        => dataToSend_valid_z(1),
--      data_out(7 downto 0) => dataToSend(1),
--      data_out(8)          => dataToSend_kout(1),
--      data_out_ready       => dataToSend_ready(1),
--      data_out_valid       => dataToSend_valid(1));

  dataToSend <= dataToSend_z;
  dataToSend_kout <= dataToSend_kout_z;
  dataToSend_ready_z <= dataToSend_ready;
  dataToSend_valid <= dataToSend_valid_z;
  

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
  readoutControler : process (clock.serial25)
  begin
    if rising_edge(clock.serial25) then
      if reset.serial = '1' then
        state <= IDLE;
        chip <= "000";
        wordCount <= (others => '0');
        eventCount <= X"0000";
        sys_ts_read <= '0';
        wr_ts_read <= '0';
      elsif dataToSend_ready_z /= "11" then
        state <= state;
        chip <= chip;
        wordCount <= wordCount;
        sys_ts_read <= '0';
        wr_ts_read <= '0';
      else
        case state is

          when IDLE =>
            chip <= "000";
            wordCount <= (others => '0');
            sys_ts_read <= '0';
            wr_ts_read <= '0';
            if not backpressure = '1' and and_reduce(FIFO_readoutReady) = '1' and dataToSend_ready_z = "11"  and sys_ts_valid = '1' and wr_ts_valid = '1' then
              state <= PACKETBEGIN;
            else
              state <= IDLE;
            end if;

          when PACKETBEGIN =>
            chip <= chip;
            wordCount <= (others => '0');
            state <= HEADER;

          when HEADER =>
            chip <= chip;
            if wordCount < WORDS_PER_HEADER - 1 then
              wordCount <= wordCount + 1;
              sys_ts_read <= '0';
              wr_ts_read <= '0';
              state <= state;
            else
              wordCount <= (others => '0');
              sys_ts_read <= '1';
              wr_ts_read <= '1';
              state <= READDATA;
            end if;
            
          when READDATA =>
            sys_ts_read <= '0';
            wr_ts_read <= '0';
            if wordCount < WORDS_PER_EVENT - 1 then
              wordCount <= wordCount + 1;
              chip <= chip;
              state <= READDATA;
            else
              wordCount <= (others => '0');
              chip <= chip + 1;
              if chip < N - 1 then
                state <= READDATA;
              else
                state <= PACKETEND;
              end if;
            end if;

          when PACKETEND =>
            chip <= chip;
            wordCount <= (others => '0');
            state <= IDLE;
            eventCount <= eventCount + 1;
            
        end case;
      end if;
    end if;
  end process;

  -- combinatoric data mux
  data_mux : process(all)
  begin
    case state is
      when IDLE =>
        dataToSend_z <= (X"00", x"00");
        dataToSend_valid_z <= "00";
        dataToSend_kout_z <= "00";

      when PACKETBEGIN =>
        dataToSend_z <= (X"F7", x"F7");
        dataToSend_valid_z <= "11";
        dataToSend_kout_z <= "11";

      when HEADER =>
        case wordCount is
          when "000"&X"00" =>   dataToSend_z <= (X"ac", X"9c");
          when "000"&X"01" =>   dataToSend_z <= (std_logic_vector(eventCount(15 downto 8)), std_logic_vector(eventCount(7 downto 0)));
          when "000"&X"02" =>   dataToSend_z <= (sys_timestamp(63 downto 56), sys_timestamp(55 downto 48));
          when "000"&X"03" =>   dataToSend_z <= (sys_timestamp(47 downto 40), sys_timestamp(39 downto 32));
          when "000"&X"04" =>   dataToSend_z <= (sys_timestamp(31 downto 24), sys_timestamp(23 downto 16));
          when "000"&X"05" =>   dataToSend_z <= (sys_timestamp(15 downto  8), sys_timestamp( 7 downto  0));
          when "000"&X"06" =>   dataToSend_z <= (wr_timestamp(63 downto 56),  wr_timestamp(55 downto 48));
          when "000"&X"07" =>   dataToSend_z <= (wr_timestamp(47 downto 40),  wr_timestamp(39 downto 32));
          when "000"&X"08" =>   dataToSend_z <= (wr_timestamp(31 downto 24),  wr_timestamp(23 downto 16));
          when "000"&X"09" =>   dataToSend_z <= (wr_timestamp(15 downto  8),  wr_timestamp( 7 downto  0));
          when "000"&X"0F" =>   dataToSend_z <= (X"ca", X"c9");
          when others => dataToSend_z <= (X"00", x"00");
        end case;
        dataToSend_valid_z <= "11";
        dataToSend_kout_z <= "00";
        
      when READDATA =>
        dataToSend_z <= ( fifoDataOut(to_integer(chip))(15 downto 8), fifoDataOut(to_integer(chip))(7 downto 0) );
        dataToSend_valid_z <= "11";
        dataToSend_kout_z <= "00";

      when PACKETEND =>
        dataToSend_z <= (X"9c", x"9c");
        dataToSend_valid_z <= "11";
        dataToSend_kout_z <= "11";
        
    end case;
  end process;

  fifoCtrl_mux : process(all)
  begin
    if dataToSend_ready /= "11" then
      fifoRead <= "00000";
    else
      case state is
        when READDATA =>
          fifoRead <= "00000";
          fifoRead(to_integer(chip)) <= '1';
        when others =>
          fifoRead <= "00000";        
      end case;
    end if;
  end process;

end vhdl;
  
