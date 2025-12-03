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


entity controlunit is

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
end entity controlunit;

architecture rtl of controlunit is
    --type definition
    type PIG_STATE is (INITIAL, BEGINNING, ROLLING, ONE, ROLLHOLD, TEST, WIN);
    --Signal definition
    signal PIG_CURRENT_STATE : PIG_STATE;
    begin
FSM : process(clock)
    begin      
if rising_edge(clock) then
    if reset = '1' then --chosen this one but could be anything to reset
        -- reset
        PIG_CURRENT_STATE <= INITIAL;
        FP <= '0';
    else
    --default values
        ENADIE <= '0';
        LDSU <= '0';
        LDT1 <= '0';
        LDT2 <= '0';
        RSSU <= '0';
        RST1 <= '0';
        RST2 <= '0';
        BP1 <= '0';
    
     --type PIG_STATE is (INIT, BEGINNING, ROLLING, ONE, ROLLHOLD, TEST, WIN);

        case PIG_CURRENT_STATE is
        when INITIAL =>
            
            PIG_CURRENT_STATE <= BEGINNING;

            RST1 <= '1'; --! reset TR1
            RST2 <= '1'; --! reset TR2
            CP <= FP; --! behavioural implmentation
            

        when BEGINNING =>
        RSSU <= '1';
            
            if ROLL = '1' then --! Press the button to roll the dice
                PIG_CURRENT_STATE <= ROLLING;
            end if;
            
        when ROLLING =>
            
            if ROLL = '1' then
                ENADIE <= '1'; --! enables die increment

            else
                PIG_CURRENT_STATE <= ONE;
            end if;

        when ONE =>
            if DIE1 ='1' then
                CP <= not CP;
                PIG_CURRENT_STATE <= BEGINNING;
            else
                PIG_CURRENT_STATE <= ROLLHOLD;
                LDSU <= '1';
            end if;      

        when ROLLHOLD =>
        
            if HOLD = '1' then
                PIG_CURRENT_STATE <= TEST;
                CP <= not CP; 
                if CP = '1' then 
                    LDT1 <= '1'; 
                else 
                    LDT2 <= '1'; 
                end if;
            else
                if ROLL = '1' then
                    PIG_CURRENT_STATE <= ROLLING;
                else
                    PIG_CURRENT_STATE <= ROLLHOLD;
                end if;
            end if; 

        when TEST =>
       

            if WN = '1' then
                PIG_CURRENT_STATE <= WIN;
            else
                PIG_CURRENT_STATE <= BEGINNING;
            end if;
        when WIN =>
        
            BP1 <= '1';
            
            if NEWGAME = '1' then
                FP <= not FP;
                PIG_CURRENT_STATE <= INITIAL;
            else 
                PIG_CURRENT_STATE <= WIN;
            end if;

        end case;

    end if;
end if;
end process;
end architecture ;
   