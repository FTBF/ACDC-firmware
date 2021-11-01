library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;
use work.LibDG.all;

entity serialTx_highSpeed is
  Port(
    clk        : in  clock_type;
    reset      : in  reset_type;
    outputMode : in  std_logic_vector(1 downto 0);
    output     : out std_logic_vector(1 downto 0)
    );
end entity serialTx_highSpeed;

architecture vhdl of serialTx_highSpeed is

  signal prbs_pattern : std_logic_vector(15 downto 0);
  signal dout_10b : std_logic_vector(9 downto 0);
  signal dout_10b_sync : std_logic_vector(9 downto 0);
  signal serial_out : std_logic_vector(1 downto 0);
  signal serial_cnt : unsigned(2 downto 0);
  signal idleStream : std_logic_vector(7 downto 0);
  signal output1 : std_logic_vector(7 downto 0);
  signal enc_kin : std_logic;
  
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

  output_mux : process(clk.serial25)
  begin
    if rising_edge(clk.serial25) then
      case outputMode is
        when "01"   =>
          output1 <= prbs_pattern(7 downto 0);
          enc_kin <= '0';
        when others =>
          output1 <= idleStream;
          enc_kin <= '1';
      end case;
    end if;
  end process;

  encoder_8b10b_inst: encoder_8b10b
    port map (
      clock      => clk.serial25,
      rd_reset   => '0',
      din        => output1,
      din_valid  => '1',
      kin        => enc_kin,
      dout       => dout_10b,
      dout_valid => open,
      rd_out     => open);

  serializer : process(clk.serial125)
  begin
    if rising_edge(clk.serial125) then
      if reset.serial = '1' then
        serial_cnt <= "000";
        dout_10b_sync <= "0000000000";
      else
        if serial_cnt < 4 then
          serial_cnt <= serial_cnt + 1;
        else
          serial_cnt <= "000";
        end if;

        if serial_cnt = 0 then
          dout_10b_sync <= dout_10b;
        else
          dout_10b_sync <= dout_10b_sync(7 downto 0) & "00";
        end if;
        
        serial_out <= dout_10b_sync(9 downto 8);

      end if;
    end if;
  end process;

    
  ddr_iobuf_inst: ddr_iobuf
    port map (
      datain_h => serial_out(1) & not serial_out(1),
      datain_l => serial_out(0) & not serial_out(0),
      outclock => clk.serial125,
      dataout  => output);

end architecture vhdl;
