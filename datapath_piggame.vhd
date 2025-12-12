----------------------------------------------------------------------------------
-- Company: University of Trento
-- Engineer: Philippe Velha
-- 
-- Create Date: 14/12/2023 09:11:40 AM
-- Design Name: datapath
-- Module Name: 
-- Project Name: Pig Game
-- Target Devices: Basys 3 
-- Tool Versions: 
-- Description: implement driver for 7-segment display
-- 
-- Dependencies: none
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


entity datapath is

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
end entity datapath;

architecture rtl of datapath is
-- definition of constants
constant frontbits : std_logic_vector(3 downto 0) := (others => '0'); --! bits to be added in front of DIE register for transfer into SUR register
-- definition of the signals
signal TR1 : std_logic_vector(6 downto 0) := (others =>'0'); --! Register TR1
signal TR2 : std_logic_vector(6 downto 0) := (others =>'0'); --! Register TR2
signal SUR : std_logic_vector(6 downto 0) := (others =>'0'); --! Register SUR
signal D   : std_logic_vector(6 downto 0) := (others =>'0'); --! Register D
signal bcd1 : std_logic_vector(3 downto 0):= (others =>'0'); --! result of conversion of TR1 in bcd
signal bcd2 : std_logic_vector(3 downto 0):= (others =>'0'); --! result of conversion of TR1 in bcd
signal bcd3 : std_logic_vector(3 downto 0):= (others =>'0'); --! result of conversion of TR2 in bcd
signal bcd4 : std_logic_vector(3 downto 0):= (others =>'0'); --! result of conversion of TR2 in bcd
----- component definition
component binbcd
Port (
    clock  : in std_logic; --! clock
    reset  : in std_logic; --! reset
    bin    : in std_logic_vector(6 downto 0); --! binary 7 bit
    digit0 : out std_logic_vector( 3 downto 0 ); --! digit units
    digit1 : out std_logic_vector( 3 downto 0 ) --! digit ten  
  );
end component;

    begin
--------------------------------
inst_bin2BCD1 : binbcd --! score player 1
  PORT map(
    clock  => clock,
    reset  => reset,
    bin    => TR1,
    digit0 => bcd1, --resulting BCD number- for TR1
    digit1 => bcd2);

inst_bin2BCD2 : binbcd
  PORT map(
    clock  => clock,
    reset  => reset,
    bin    => TR2,
    digit0 => bcd3, --resulting BCD number- for TR2
    digit1 => bcd4);
--------------------------------
Main_process : process(clock,reset)
variable DIE : std_logic_vector(2 downto 0); --! Register DIE register

 begin
    if reset = '1' then
        -- reset
        DIE := (others => '0'); --! asynchronous reset
    else
        if rising_edge(clock) then
            if RST1 = '1' then
                TR1 <= (others => '0');
            end if;
            if RST2 = '1' then
                TR2 <= (others => '0');
            end if;
            if RSSU = '1' then
                SUR <= (others => '0');
            end if;
            if LDT1 = '1' then
                TR1 <= TR1 + SUR;
            end if;
            if LDT2 = '1' then
                TR2 <= TR2 + SUR;
            end if;
            if ENADIE = '1' then
                case DIE is
                    when "110" => DIE := "001";
                    when others => DIE := DIE +1;
                end case;
            end if;
            
            if DIE ="001" then
                DIE1 <= '1';
            else 
                DIE1 <= '0';
            end if;
            if LDSU = '1' then
                SUR <= SUR + (frontbits & DIE);
            end if;
            if CP ='1' then
                D <= TR2;
            else
                D <= TR1;
            end if;

            if (D > "1100011") then
                WN <= '1';
             else 
                WN <= '0';
            end if;

        end if;
    end if;

--! connection to displays
LEDDIE <= DIE;
DIGIT0 <= bcd1;
DIGIT1 <= bcd2;
DIGIT2 <= bcd3;
DIGIT3 <= bcd4;
end process;

end architecture rtl;
