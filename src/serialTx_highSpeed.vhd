library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;
use work.LibDG.all;

entity serialTx_highSpeed is
  Port(
    clk         : in  clock_type;
    reset       : in  reset_type;

    input       : in hs_input_array;
    input_ready : out std_logic_vector(1 downto 0);
    input_valid : in std_logic_vector(1 downto 0);
    input_kout  : in std_logic_vector(1 downto 0);

    trigger          : in std_logic;
    backpressure_out : in std_logic;
    
    outputMode  : in  std_logic_vector(1 downto 0);
    output      : out std_logic_vector(1 downto 0)
    );
end entity serialTx_highSpeed;

architecture vhdl of serialTx_highSpeed is

  type a2_2bit  is array (1 downto 0) of std_logic_vector(1 downto 0);
  
  signal prbs_pattern : std_logic_vector(15 downto 0);
  signal serial_out : a2_2bit;
  signal idleStream : std_logic_vector(7 downto 0);
  signal input_ready_z : std_logic_vector(1 downto 0);

begin  -- architecture vhdl
  
  prbsGen: prbsGenerator
    generic map (
      ITERATIONS => 8,
      POLY       => X"6000")
    port map (
      clk    => clk.serial25,
      reset  => reset.serial,
      input  => prbs_pattern,
      output => prbs_pattern);

  idleGenerator : process(clk.serial25)
    variable alignCount : natural range 0 to 1024;
  begin
    if rising_edge(clk.serial25) then
      if reset.serial = '1' then
        alignCount := 0;
        idleStream <= K28_0;
      else
        if alignCount = 1023 then
          alignCount := 0;
          idleStream <= K28_7;
        else
          alignCount := alignCount + 1;
          idleStream <= K28_0;
        end if;
      end if;
    end if;
  end process;

  channel_serialization : for iLink in 0 to 1 generate
    signal output_z : std_logic_vector(7 downto 0);
    signal outputMode_z : std_logic_vector(1 downto 0);
    signal dout_10b : std_logic_vector(9 downto 0);
    signal dout_10b_sync : std_logic_vector(9 downto 0);
    signal enc_kin : std_logic;
    signal serial_cnt : unsigned(2 downto 0);
    signal trigger_z : std_logic;
    signal trigger_z2 : std_logic;
    signal backpressure_out_z  : std_logic;
    signal backpressure_out_z2 : std_logic;
    signal disp_8b10b : std_logic;
    signal trig_latch : std_logic;
    signal trig_latch_25 : std_logic;
    signal trig_release : std_logic;
    signal trig_release_25 : std_logic;
  
  begin

--    trig_sync : pulseSync
--      port map (
--        inClock    => clk.serial25,
--        outClock   => clk.serial25,
--        din_valid  => trigger,
--        dout_valid => trigger_z);

    backpressure_sync: sync_Bits_Altera
      generic map (
        BITS       => 1,
        INIT       => x"00000000",
        SYNC_DEPTH => 2)
      port map (
        Clock     => clk.serial25,
        Input(0)  => backpressure_out,
        Output(0) => backpressure_out_z);
    
    trig_release_25_gen : process(clk.serial25)
    begin
      if rising_edge(clk.serial25) then
        backpressure_out_z2 <= backpressure_out_z;
        outputMode_z <= outputMode;

        input_ready(iLink) <= input_ready_z(iLink);
        
        if trig_latch_25 = '1' then
          trig_release_25 <= '1';
        else
        trig_release_25 <= '0';
        end if;
      end if;
    end process;
                    

    output_mux : process(all)--clk.serial25)
    begin
--      if rising_edge(clk.serial25) then
        case outputMode_z is
          when "01"   =>
            output_z <= prbs_pattern(7 downto 0);
            enc_kin <= '0';
          when "11"   =>
--            if    backpressure_out_z2 = '0' and backpressure_out_z = '1' then
--              output_z <= X"3C";
--              enc_kin <= '1';
--            elsif backpressure_out_z2 = '1' and backpressure_out_z = '0' then
--              output_z <= X"5C";
--              enc_kin <= '1';
--            if trigger_z2 = '0' and trigger_Z = '1' then 
--              output_z <= X"FB";
--              enc_kin <= '1';
            if input_valid(iLink) = '1' then
              output_z <= input(iLink);
              enc_kin <= input_kout(iLink);
            else
              output_z <= idleStream;
              enc_kin <= '1';              
            end if;
          when others =>
            output_z <= idleStream;
            enc_kin <= '1';
        end case;
--      end if;
    end process;

    --input_ready(iLink) <= '1' when (not (trigger_z = '1' and trigger_z2 = '0') and ((backpressure_out_z2 xor backpressure_out_z) = '0')) and outputMode_z = "11" else '0';
    input_ready_z(iLink) <= '1' when (trig_latch_25 = '0' and outputMode_z = "11") else '0';

    enc_8b10b_inst: enc_8b10b
      port map (
        reset   => reset.serial,
        clk     => clk.serial25,
        ena     => not trig_release_25,--'1',--input_valid(iLink),
        KI      => enc_kin,
        datain  => output_z,
        dataout => dout_10b,
        disp_out => disp_8b10b);

    serializer : process(clk.serial125)
    begin
      if rising_edge(clk.serial125) then
        trigger_z <= trigger;
        trigger_z2 <= trigger_z;

        if reset.serial = '1' then
          serial_cnt <= "000";
          dout_10b_sync <= "0101010101";
          serial_out(iLink) <= "01";
          trig_latch <= '0';
          trig_latch_25 <= '0';
          trig_release <= '0';
        else
          if trigger_z = '1' and trigger_z2 = '0' then
            trig_latch <= '1';
          elsif trig_release = '1' then
            trig_latch <= '0';
          end if;
          
          if trigger_z = '1' and trigger_z2 = '0' then
            trig_latch_25 <= '1';
          elsif trig_release_25 = '1' then
            trig_latch_25 <= '0';
          end if;

          if serial_cnt < 4 then
            serial_cnt <= serial_cnt + 1;
          else
            serial_cnt <= "000";
          end if;

          if serial_cnt = 0 then
            if (trigger_z = '1' and trigger_z2 = '0') or trig_latch = '1' then
              trig_release <= '1';
              if disp_8b10b = '1' then
                dout_10b_sync <= "1101101000";
              else
                dout_10b_sync <= "0010010111";
              end if;
            else
              trig_release <= '0';
              dout_10b_sync <= dout_10b;
            end if;
          else
            trig_release <= '0';
            dout_10b_sync <= dout_10b_sync(7 downto 0) & "00";
          end if;
          
          serial_out(iLink) <= dout_10b_sync(9 downto 8);
        end if;
      end if;
    end process;
  end generate;

  -- second input inverted due to p/n swap on LVDS pair on ACDC PCB
  ddr_iobuf_inst: ddr_iobuf
    port map (
      datain_h => serial_out(1)(1) & not serial_out(0)(1),
      datain_l => serial_out(1)(0) & not serial_out(0)(0),
      outclock => clk.serial125,
      dataout  => output);

end architecture vhdl;
