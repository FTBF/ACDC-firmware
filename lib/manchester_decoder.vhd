-- based on: https://lauri.xn--vsandi-pxa.com/hdl/fsm/manchester.html, by Lauri Võsandi
-- Note, the above citation contains several mistakes (is wrong at almost all steps) which have been correced below

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
  type state_type is ( S0, S1, S2, S3, S4, S5, S6 );

  signal q_next     : std_logic;
  signal state      : state_type;
  signal state_next : state_type;
begin
    u1: process(all)
    begin
      case state is
        when S0 =>
          if i = '1' then state_next <= S4; q_next <= '1';
          else            state_next <= S1; q_next <= '0';
          end if;

        when S1 =>        state_next <= S2; q_next <= '0';

        when S2 =>
          if i = '1' then state_next <= S3; q_next <= '0';
          else            state_next <= S0; q_next <= '0';
          end if;

        when S3 =>        state_next <= S0; q_next <= '0';

        when S4 =>        state_next <= S5; q_next <= '1';

        when S5 =>
          if i = '1' then state_next <= S0; q_next <= '1';
          else            state_next <= S6; q_next <= '1';
          end if;

        when S6 =>        state_next <= S0; q_next <= '1';
                          
      end case;
    end process;

    -- State transition occurs during rising edge of the clock
    u2: process(clk, resetn)
    begin
        if resetn = '0' then
          state <= S0;
          q <= '0';
        elsif rising_edge(clk) then
          state <= state_next;
          q <= q_next;  
        end if;
    end process;
end behaviour;
