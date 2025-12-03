----------------------------------------------------------------------------------
-- Company: University of Trento
-- Engineer: Philippe Velha
-- 
-- Create Date: 23/11/2023 02:10:40 PM
-- Design Name: piggameV1
-- Module Name: 
-- Project Name: Pig Game
-- Target Devices: Basys 3 
-- Tool Versions: 
-- Description: implement a PIG GAME for teaching purposes
-- 
-- Dependencies: bin7bcd99.vhd and debouncer
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.std_logic_unsigned.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity piggame is
    port (
        SW 			: in  STD_LOGIC_VECTOR (15 downto 0); --! Switches
        BTN 			: in  STD_LOGIC_VECTOR (4 downto 0); --! Buttons (0:UP,1:center,2:down)
        CLK 			: in  STD_LOGIC; --! clock
        LED 			: out  STD_LOGIC_VECTOR (15 downto 0); --! LEDs
        SSEG_CA 		: out  STD_LOGIC_VECTOR (7 downto 0); --! 7 segment cathode
        SSEG_AN 		: out  STD_LOGIC_VECTOR (3 downto 0) --! 7 segment anode   
    );
end piggame;

architecture rtl of piggame is
--Definition of the components

component debouncer
Generic(
    counter_size : integer := 15
        );
Port(
    clock, reset : in std_logic; --! clock and reset
    bouncy       : in std_logic; --! input that can bounce even in less than one clock cycle (the debouncer can be connected to a slow clock)
    pulse    : out std_logic; --! send a pulse as soon as the stable state of the button touch is verified
    debounced: out std_logic --! provide an out that is the stable version
		);
end component;

component seven_segment_driver
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
end component seven_segment_driver;

component datapath
Port(
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

component controlunit
Port(
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

-- Type definition


--! Constant definition
constant TMR_CNTR_MAX : std_logic_vector(16 downto 0) := "11000011010100000"; --here 100000 clk cyc for 100,000,000 = clk cycles per second
constant TMR_CNTR_BLINK : std_logic_vector(26 downto 0) := "110000110101000000000000000"; --here 100000 clk cyc for 100,000,000 = clk cycles per second
constant TMR_VAL_MAX : std_logic_vector(3 downto 0) := "1001"; --9

--This is used to determine when the 7-segment display should be
--incremented
signal tmrCntr : std_logic_vector(26 downto 0) := (others => '0');
signal tmrCntrBlink : std_logic_vector(26 downto 0) := (others => '0');
--This counter keeps track of which number is currently being displayed
--on the 7-segment.
signal digit0 : std_logic_vector (3 downto 0);
signal digit1 : std_logic_vector (3 downto 0);
signal digit2 : std_logic_vector (3 downto 0);
signal digit3 : std_logic_vector (3 downto 0);
--Used to determine when a button press has occured
signal btnReg : std_logic_vector (4 downto 0) := "00000";
signal btnDetect : std_logic;

--Debounced btn signals used to prevent single button presses
--from being interpreted as multiple button presses.
signal btnDeBnc : std_logic_vector(4 downto 0);
signal clk_cntr_reg : std_logic_vector (4 downto 0) := (others=>'0'); 

-- those signal are here to relay the connection from controlunit to and from datapath
signal RST1: std_logic := '1'; --! Synchronous reset of TR1
signal RST2: std_logic:= '1'; --! Synchronous reset of TR2
signal LDT1: std_logic; --! add SUR to TR1
signal LDT2: std_logic; --! add SUR to TR2
signal FP  : std_logic; --! Value of the first player
signal CP  : std_logic; --! Value of the current player
signal RSSU: std_logic:= '1'; --! Reset SUR
signal LDSU: std_logic; --! Add DIE to SUR
signal ENADIE: std_logic; --! enable DIE to increment
signal BP1 : std_logic; --! for the blinking

signal center_edge : std_logic; 
signal up_edge : std_logic;
signal left_edge : std_logic; 
signal right_edge : std_logic;
signal down_edge : std_logic; 
signal HOLD : std_logic;
signal ROLL : std_logic;
signal NEWGAME : std_logic;
signal DIE1 : std_logic;
signal WN : std_logic;
-- Architecture of the entity piggame
begin

----------------------------------------------------------
------              Button Control                 -------
----------------------------------------------------------
--Buttons are debounced and their rising edges are detected

--Debounces btn signals
-- Instantiate buttons:
-- BTNC,BTNU,BTNL,BTNR,BTND
center_detect : debouncer
port map (
  clock   => CLK,
  reset   => SW(15),
  bouncy  => BTN(0),
  pulse   => center_edge,
  debounced => ROLL
  );

up_detect : debouncer
port map (
  clock   => CLK,
  reset   => SW(15),
  bouncy  => BTN(1),
  pulse   => up_edge,
  debounced => HOLD
  );

down_detect : debouncer
port map (
  clock   => CLK,
  reset   => SW(15),
  bouncy  => BTN(2),
  pulse   => down_edge,
  debounced => NEWGAME
  );

left_detect : debouncer
port map (
  clock   => CLK,
  reset   => SW(15),
  bouncy  => BTN(3),
  pulse   => left_edge,
  debounced => LED(13)
  );

right_detect : debouncer
port map(
  clock   => CLK,
  reset   => SW(15),
  bouncy  => BTN(4),
  pulse   => right_edge,
  debounced => LED(12)
  );
--------------------------------
thedriver :  seven_segment_driver
port map (
    clock  => CLK,
    reset  => SW(15),
    digit0 => digit3, 
    digit1 => digit2,
    digit2 => digit1,
    digit3 => digit0,
    CA     => SSEG_CA,
    AN     => SSEG_AN
);
datapath_pigagame : datapath
port map(
    clock  => CLK,
    reset  => SW(15),
    ENADIE => ENADIE,
    LDSU   => LDSU,
    LDT1   => LDT1,
    LDT2   => LDT2,
    RSSU   => RSSU,
    RST1   => RST1,
    RST2   => RST2,
    CP     => CP,
    FP     => FP,
    DIGIT0 => digit0,
    DIGIT1 => digit1,
    DIGIT2 => digit2,
    DIGIT3 => digit3,
    LEDDIE => LED(2 downto 0),
    DIE1   => DIE1,
    WN     => WN
);

controlunit_piggame : controlunit
port map(
    clock  => CLK, --! Clock
    reset  => SW(15), --! Reset
    ROLL   => ROLL, --! button for the roll
    HOLD   => HOLD, --! button for hold
    NEWGAME=> NEWGAME, --! button for new game
    ENADIE => ENADIE, --! Enable Die to increment
    LDSU   => LDSU, --! Add DIE to SUR register
    LDT1   => LDT1, --! Add SUR to TR1 register
    LDT2   => LDT2, --! Add SUR to TR2 register
    RSSU   => RSSU, --! Reset SUR register
    RST1   => RST1, --! Reset TR1 register
    RST2   => RST2, --! Reset TR2 register
    BP1    => BP1, --! enables blinking
    CP     => CP, --! current player (register outside)
    FP     => FP, --! First player (register outside)
    DIE1   => DIE1, --! signal that the die is at one
    WN     => WN --! WIN has been achieved by a player
);
timer_blink_process : process(CLK) --! process that counts to around 1 second
variable cs : std_logic; -- keeps track of the current state of the blink
begin

	if (rising_edge(CLK)) then
	   ---- every ms changes display
		if (tmrCntrBlink = TMR_CNTR_BLINK)  then
		tmrCntrBlink <= (others => '0');
		if BP1 = '1' then
		case cs is
		  when '0' =>  LED(15 downto 14) <= "11";
		  when '1' =>  LED(15 downto 14) <= "00";
		  when others => LED(15 downto 14) <= "00";
		end case;
		cs := not cs;
		end if;
		else
		tmrCntrBlink <= tmrCntrBlink +1;
		end if;
	end if;

end process;


checkcp : process(CP)
begin
LED(7) <= '0';
LED(6) <= '0';
    if CP='1' then
        LED(7) <= '1';
        else
        LED(6) <= '1';
    end if;
end process;

end architecture;