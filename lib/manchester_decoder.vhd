library ieee;
use ieee.std_logic_1164.all;

entity manchester_decoder is
    port (
        clk    : in std_logic;
        resetn : in std_logic;
        i      : in std_logic;
        q      : out std_logic
    );
end manchester_decoder;

architecture behaviour of manchester_decoder is
  signal Q0 : std_logic;
  signal Q1 : std_logic;
  signal Q2 : std_logic;
  signal Q3 : std_logic;
  signal Q4 : std_logic;
  signal STROBE : std_logic;
  signal STROBE_z : std_logic;
  signal EDGE : std_logic;
  signal nreset_sync : std_logic;
begin

  EDGE <= (Q0 xor (not Q1));

  u1: process(clk)
  begin
    if rising_edge(clk) then
      nreset_sync <= resetn;
    end if;
  end process;
  
  u2: process(clk, nreset_sync)
  begin
    if nreset_sync = '0' then
      Q0 <= '0';
      Q1 <= '0';
      Q2 <= '0';
      Q3 <= '0';
      Q4 <= '0';
      STROBE <= '0';
    elsif rising_edge(clk) then
      Q0 <= i;
      Q1 <= not Q0;
      Q2 <= (EDGE or Q2) and (not Q4);
      Q3 <= Q2;
      Q4 <= Q3 and (Q4 or Q2);
      STROBE <= (not Q2) and (not Q4) and EDGE;
      STROBE_z <= STROBE;

      if STROBE_z = '1' then
        q <= Q1;
      end if;
    end if;
  end process;
end behaviour;
