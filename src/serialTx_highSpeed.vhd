library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;
use work.LibDG.all;

entity serialTx_highSpeed is
  Port(
    clk    : in  std_logic;
    reset  : in  reset_type;
    output : out std_logic_vector(1 downto 0)
    );
end entity serialTx_highSpeed;

architecture vhdl of serialTx_highSpeed is

  signal prbs_pattern : std_logic_vector(15 downto 0);
  
begin  -- architecture vhdl

  prbsGen: prbsGenerator
    generic map (
      ITERATIONS => 2,
      POLY       => X"6000")
    port map (
      clk    => clk,
      reset  => reset.serialFast,
      input  => prbs_pattern,
      output => prbs_pattern);

  ddr_iobuf_inst: ddr_iobuf
    port map (
      datain_h => prbs_pattern(0) & prbs_pattern(0),
      datain_l => prbs_pattern(1) & prbs_pattern(1),
      outclock => clk,
      dataout  => output);

end architecture vhdl;
