library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.std_logic_unsigned.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity main is
    port (
        sw : in std_logic_vector (15 downto 0);
        clock : in std_logic;
        btn : in std_logic_vector (4 downto 0);
        led : out std_logic_vector (15 downto 0);
        SSEG_CA : out std_logic_vector (7 downto 0);
        SSEG_AN : out std_logic_vector (3 downto 0)
     );
end main;

architecture Behavioral of main is
--Definitions of the components
component controlunit
  port(
        clock  : in std_logic; --! Clock
        reset  : in std_logic; --! Reset
        ROLL   : in std_logic; --! button for the roll
        HOLD   : in std_logic; --! button for hold
        NEWGAME: in std_logic; --! button for new game
        ENADIE : out std_logic; --! Enable Die to increment
        LDSU   : out std_logic; --! Add DIE to SUR register
        LDT1   : out std_logic; --! Add SUR to TR1 register
        LDT2   : out std_logic; --! Add SUR to TR2 register
        RSSU   : out std_logic; --! Reset SUR register
        RST1   : out std_logic; --! Reset TR1 register
        RST2   : out std_logic; --! Reset TR2 register
        BP1    : out std_logic; --! enables blinking
        CP     : inout std_logic; --! current player (register outside)
        FP     : inout std_logic; --! First player (register outside)
        DIE1   : in std_logic; --! signal that the die is at one
        WN     : in std_logic --! WIN has been achieved by a player
    );
end component;

component datapath
    port(
        clock  : in std_logic; --! Clock
        reset  : in std_logic; --! Reset
        ENADIE : in std_logic; --! Enable Die to increment
        LDSU   : in std_logic; --! Add DIE to SUR register
        LDT1   : in std_logic; --! Add SUR to TR1 register
        LDT2   : in std_logic; --! Add SUR to TR2 register
        RSSU   : in std_logic; --! Reset SUR register
        RST1   : in std_logic; --! Reset TR1 register
        RST2   : in std_logic; --! Reset TR2 register
        CP     : inout std_logic; --! current player (register outside)
        FP     : inout std_logic; --! First player (register outside)
        DIGIT0 : out std_logic_vector( 3 downto 0 ); --! digit to the right
        DIGIT1 : out std_logic_vector( 3 downto 0 ); --! 2nd digit to the left
        DIGIT2 : out std_logic_vector( 3 downto 0 ); --! 3rd digit to the left
        DIGIT3 : out std_logic_vector( 3 downto 0 ); --! digit to the left
        LEDDIE : out std_logic_vector(2 downto 0); --! LEDs to display the die value
        DIE1   : out std_logic; --! signal that a one has been obtained
        WN     : out std_logic --! WIN has been achieved by a player
          );
end component;

component debouncer
generic (
    counter_size : integer := 15
  );
    port(
    clock, reset : in std_logic; --! clock and reset
    bouncy       : in std_logic; --! input that can bounce even in less than one clock cycle (the debouncer can be connected to a slow clock)
    pulse    : out std_logic; --! send a pulse as soon as the stable state of the button touch is verified
    debounced: out std_logic --! provide an out that is the stable version
    );
end component;

component segment_driver
generic (
      size : integer := 20 --! size of the counter 2^20 max
    );
    Port (
      clock  : in std_logic; --! Clock
      reset  : in std_logic; --! Reset
      digit0 : in std_logic_vector( 3 downto 0 ); --! digit to the left
      digit1 : in std_logic_vector( 3 downto 0 ); --! digit number 2 from left
      digit2 : in std_logic_vector( 3 downto 0 ); --! digit number 3 from left
      digit3 : in std_logic_vector( 3 downto 0 ); --! digit uttermost right
      CA     : out std_logic_vector(7 downto 0); --! Cathodes
      AN     : out std_logic_vector( 3 downto 0 ) --! Anodes
    );

end component;

constant BLINK_DELAY_MAX : std_logic_vector(26 downto 0) := "101111101011110000100000000";

signal blink_cnt   : std_logic_vector(26 downto 0) := (others => '0');
signal blink_toggle: std_logic := '0';

signal digit0 : std_logic_vector (3 downto 0);
signal digit1 : std_logic_vector (3 downto 0);
signal digit2 : std_logic_vector (3 downto 0);
signal digit3 : std_logic_vector (3 downto 0);

signal btnReg : std_logic_vector (4 downto 0) := "00000";
signal btnDetect : std_logic;

signal HOLD : std_logic;
signal ROLL : std_logic;
signal NEWGAME : std_logic;
signal DIE1 : std_logic;
signal WN : std_logic;

signal RST1: std_logic := '1';
signal RST2: std_logic:= '1'; 
signal LDT1: std_logic; 
signal LDT2: std_logic;
signal FP  : std_logic;
signal CP  : std_logic; 
signal RSSU: std_logic:= '1'; 
signal LDSU: std_logic; 
signal ENADIE: std_logic; 
signal BP1 : std_logic; 

signal center_edge : std_logic; 
signal up_edge : std_logic;
signal left_edge : std_logic; 
signal right_edge : std_logic;
signal down_edge : std_logic; 

signal btnDeBnc : std_logic_vector(4 downto 0);
signal clk_cntr_reg : std_logic_vector (4 downto 0) := (others=>'0'); 

begin

controlunit_piggame : controlunit
port map(
    clock  => clock,
    reset  => sw(15), 
    ROLL   => ROLL,
    HOLD   => HOLD, 
    NEWGAME=> NEWGAME, 
    ENADIE => ENADIE,
    LDSU   => LDSU,
    LDT1   => LDT1, 
    LDT2   => LDT2, 
    RSSU   => RSSU, 
    RST1   => RST1, 
    RST2   => RST2, 
    BP1    => BP1, 
    CP     => CP, 
    FP     => FP, 
    DIE1   => DIE1, 
    WN     => WN 
);

pig_datapath_inst : datapath
port map(
    clock  => clock,
    reset  => sw(15),
    ENADIE => ENADIE,
    LDSU   => LDSU,
    LDT1   => LDT1,
    LDT2   => LDT2,
    RSSU   => RSSU,
    RST1   => RST1,
    RST2   => RST2,
    CP     => CP,
    FP     => FP,
    digit0 => digit0,
    digit1 => digit1,
    digit2 => digit2,
    digit3 => digit3,
    LEDDIE => LED(2 downto 0),
    DIE1   => DIE1,
    WN     => WN
);

inst_CENTER : debouncer
    port map (
        clock     => clock,
        reset     => sw(15),
        bouncy    => btn(0),
        pulse     => center_edge,
        debounced => led(11)  
    );

    inst_UP : debouncer
    port map (
        clock     => clock,
        reset     => sw(15),
        bouncy    => btn(1),
        pulse     => up_edge,
        debounced => HOLD   
    );

    inst_DOWN : debouncer
    port map (
        clock     => clock,
        reset     => sw(15),
        bouncy    => btn(2),
        pulse     => down_edge,
        debounced => NEWGAME 
    );

    inst_LEFT : debouncer
    port map (
        clock     => clock,
        reset     => sw(15),
        bouncy    => btn(3),
        pulse     => left_edge,
        debounced => led(13)    
    );

    inst_RIGHT : debouncer
    port map(
        clock     => clock,
        reset     => sw(15),
        bouncy    => btn(4),
        pulse     => right_edge,
        debounced => ROLL    
    );

sseg_ctrl : segment_driver
    port map (
        clock  => clock,
        reset  => sw(15),
        digit0 => digit3, 
        digit1 => digit2,
        digit2 => digit1,
        digit3 => digit0,
        CA => SSEG_CA,
        AN => SSEG_AN
    );
 

timer_process: process(clock)
variable current_blink_state : std_logic;
begin 

if rising_edge (clock) then
    if (blink_cnt = BLINK_DELAY_MAX) then
    blink_cnt <= (others => '0');
        if BP1 = '1' then
        current_blink_state := not current_blink_state;
        if current_blink_state = '0' then
            led(15 downto 14) <= "11";
        else          
            led(15 downto 14) <= "00";
        end if;
        end if;
    else 
        blink_cnt <= blink_cnt + 1;
    end if;
end if;
end process;


check_CP : process (CP) begin
    if CP = '0' then
        led(6)<= '1';
        led(7)<= '0';
    else
        led(7)<= '1';
        led(6)<= '0';
    end if;
end process;

end Behavioral;
