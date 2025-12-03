library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;


entity binbcd is

  Port (
    clock  : in std_logic; --! clock
    reset  : in std_logic; --! reset
    bin    : in std_logic_vector(6 downto 0); --! binary 7 bit
    digit0 : out std_logic_vector( 3 downto 0 ); --! digit units
    digit1 : out std_logic_vector( 3 downto 0 ) --! digit ten  
  );

end binbcd;

architecture Behavioral of binbcd is


begin

  -- Divide the clock
  process ( clock, reset ) begin
    if reset = '1' then
      digit0 <= ( others => '0' );
      digit1 <= ( others => '0' );
    elsif rising_edge( clock ) then
        digit0(3)<= (bin(6) and bin(4)) or (bin(6) and bin(5));
        digit0(2) <= (bin(5) and bin(3)) or (bin(5) and bin(4)) or (bin(6) and (not bin(5)) and (not bin(4)));
        digit0(1) <= ((not bin(6)) and (not bin(5)) and bin(4) and bin(2)) or ((not bin(6)) and (not bin(5)) and bin(4) and bin(3)) or ((not bin(6)) and bin(5) and (not bin(4)) and (not bin(3))) or (bin(6) and (not bin(5)) and (not bin(4))) or (bin(5) and bin(4) and bin(3) and bin(2));
        digit0(0) <= ((not bin(5)) and (not bin(4)) and bin(3) and bin(1) ) or ( (not bin(5)) and (not bin(4)) and bin(3) and bin(2) ) or ( (not bin(6)) and (not bin(5)) and bin(4) and (not bin(3)) and (not bin(2)) ) or ( (not bin(5)) and bin(3) and bin(2) and bin(1) ) or ( bin(5) and (not bin(4)) and (not bin(3)) ) or ( bin(5) and (not bin(3)) and bin(2) ) or ( bin(5) and bin(4) and bin(3) and (not bin(2)) ) or ( bin(6) and (not bin(4)) and bin(2) and bin(1) ) or ( bin(6) and (not bin(4)) and bin(3) ) or ( bin(6) and bin(3) and bin(1) ) or ( bin(6) and bin(3) and bin(2) ) or ( bin(5) and (not bin(3)) and bin(1));
        digit1(3) <= ((not bin(6)) and (not bin(5)) and (not bin(4)) and bin(3) and (not bin(2)) and (not bin(1)) ) or ( (not bin(6)) and (not bin(5)) and bin(4) and (not bin(3)) and (not bin(2)) and bin(1) ) or ( (not bin(6)) and (not bin(5)) and bin(4) and bin(3) and bin(2) and (not bin(1)) ) or ( bin(5) and (not bin(4)) and (not bin(3)) and bin(2) and bin(1) ) or ( bin(5) and bin(4) and (not bin(3)) and (not bin(2)) and (not bin(1)) ) or ( bin(5) and bin(4) and bin(3) and (not bin(2)) and bin(1) ) or ( bin(6) and (not bin(4)) and (not bin(3)) and bin(2) and (not bin(1)) ) or ( bin(6) and (not bin(4)) and bin(3) and bin(2) and bin(1) ) or ( bin(6) and bin(4) and bin(3) and (not bin(2)) and (not bin(1)) ) or ( bin(6) and bin(5) and bin(1));
        digit1(2) <= ((not bin(6)) and (not bin(5)) and bin(4) and (not bin(2)) and (not bin(1)) ) or ( (not bin(6)) and (not bin(5)) and bin(4) and bin(3) and (not bin(2)) ) or ( (not bin(6)) and bin(5) and (not bin(4)) and (not bin(3)) and (not bin(2)) and bin(1) ) or ( bin(5) and bin(4) and (not bin(3)) and bin(2) and bin(1) ) or ( bin(6) and (not bin(4)) and bin(3) and bin(2) and (not bin(1)) ) or ( bin(6) and bin(4) and (not bin(3)) and bin(2) ) or ( bin(6) and bin(4) and bin(2) and bin(1) ) or ( bin(5) and bin(4) and bin(3) and (not bin(2)) and (not bin(1)) ) or ( (not bin(6)) and (not bin(5)) and (not bin(4)) and bin(2) and bin(1) ) or ( bin(6) and (not bin(5)) and (not bin(4)) and (not bin(2)) and bin(1) ) or ( (not bin(6)) and (not bin(4)) and (not bin(3)) and bin(2) and (not bin(1)) ) or ( bin(6) and (not bin(4)) and (not bin(3)) and (not bin(2)) and (not bin(1)) ) or ( bin(5) and (not bin(4)) and bin(3) and bin(2));
        digit1(1) <= ((not bin(5)) and (not bin(4)) and bin(3) and bin(2) and (not bin(1)) ) or ( (not bin(6)) and (not bin(5)) and bin(4) and (not bin(3)) and (not bin(2)) and (not bin(1)) ) or ( (not bin(6)) and (not bin(5)) and bin(4) and bin(3) and (not bin(2)) and bin(1) ) or ( bin(5) and (not bin(4)) and (not bin(3)) and (not bin(1)) ) or ( bin(5) and (not bin(4)) and bin(3) and bin(1) ) or ( bin(5) and (not bin(3)) and bin(2) and (not bin(1)) ) or ( bin(5) and bin(4) and bin(3) and (not bin(2)) and (not bin(1)) ) or ( bin(5) and bin(3) and bin(2) and bin(1) ) or ( bin(6) and (not bin(4)) and bin(3) and (not bin(1)) ) or ( bin(6) and bin(3) and bin(2) and (not bin(1)) ) or ( (not bin(6)) and (not bin(5)) and (not bin(3)) and bin(2) and bin(1) ) or ( (not bin(5)) and (not bin(4)) and (not bin(3)) and (not bin(2)) and bin(1) ) or ( bin(6) and bin(4) and (not bin(3)) and bin(1));
        digit1(0) <= bin(0);
    end if;
  end process;

end behavioral;
