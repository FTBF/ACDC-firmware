library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL; 
use work.defs.all;
use work.components.all;


entity gearbox_12to16 is 
  port(
    clk   : in std_logic;
    reset : in std_logic;

    data_in        : in  std_logic_vector(11 downto 0);
    data_in_valid  : in  std_logic;
    data_out       : out std_logic_vector(15 downto 0);
    data_out_valid : out std_logic
);		
		
end gearbox_12to16;

architecture vhdl of gearbox_12to16 is

  signal gearbox_sr      : std_logic_vector(23 downto 0);
  signal counter         : unsigned(1 downto 0);
  signal data_in_valid_z : std_logic;
  
begin

  input_SR : process(clk)
  begin
    if rising_edge(clk) then
      if data_in_valid = '1' then
        gearbox_sr <= data_in & gearbox_sr(23 downto 12);
      else
        gearbox_sr <= gearbox_sr;
      end if;
      
      if reset = '1' then
        counter <= "11";
      elsif data_in_valid = '1' then
        counter <= counter + 1;
      end if;

      data_in_valid_z <= data_in_valid;
    end if;
  end process;

  output_mux : process(all)
  begin
    case counter is
      when "00"    => data_out <= gearbox_sr(15 downto 0);
      when "01"    => data_out <= gearbox_sr(19 downto 4);
      when "10"    => data_out <= gearbox_sr(23 downto 8);
      when others  => data_out <= gearbox_sr(15 downto 0);
    end case;

    if data_in_valid_z = '1' and counter /= "11" then
      data_out_valid <= '1';
    else
      data_out_valid <= '0';
    end if;
  end process;

end vhdl;
