--------------------------------------------------------------------------------
-- Company:         EE119c
-- Engineer:        Quinn Osha
--
-- Create Date:     17:04:43 04/17/2015
-- Design Name:     neaural-net-fpga
-- Module Name:     usb_video_decoder - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:     This entity implements a decoder of the USB video class
--                  data stream.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity usb_video_decoder is
     Generic (
        num_input_bits        : integer; -- number of bits from UART tx/rx
        num_red_output_bits   : integer; -- number of red bits to keep
        num_green_output_bits : integer; -- number of green bits to keep
        num_blue_output_bits  : integer  -- number of blue bits to keep
    );
    Port (
        Clock   : in  STD_LOGIC;    -- system clock
        Reset   : in  STD_LOGIC;    -- system reset
        -- data from UART input stream
        DataIn  : in  STD_LOGIC_VECTOR (num_input_bits - 1 downto 0);

        Hsync   : out STD_LOGIC;    -- horizontal sync out
        Vsync   : out STD_LOGIC;    -- vertical sync out
        Fsync   : out STD_LOGIC;    -- frame sync out
        DataOut : out  STD_LOGIC_VECTOR (num_red_output_bits -- Output data bus
                + num_green_output_bits + num_blue_output_bits - 1 downto 0)
    );
end usb_video_decoder;


architecture Behavioral of usb_video_decoder is

constant HEADER_LENGTH    : integer := 32;  -- num of bytes in video header
constant INACTIVE_SAMPLES : integer := 160; -- num of inactive videoSamples/line
constant ACTIVE_SAMPLES   : integer := 640; -- num of active videoSamples/line
constant TOTAL_SAMPLES    : integer := 800; -- num of total videoSamples/line
constant INACTIVE_LINES   : integer := 45;  -- num of inactive lines/frame
constant ACTIVE_LINES     : integer := 480; -- num of active lines/frame
constant TOTAL_LINES      : integer := 525; -- num of total lines/frame

-- FSM variables
type states is (
    idle,
    activeSubSlot1,
    activeSubSlot2,
    inactiveSubSlot1,
    inactiveSubSlot2,
    inactiveLineSlot1,
    inactiveLineSlot2
);

signal currentState : states; -- The current state of the FSM
signal nextState    : states; -- The next state of the FSM

-- line and column counters

-- counter to track the current line in the frame
signal rowCounter : integer range 0 to TOTAL_SAMPLES;
-- counter to track the current column in the line
signal colCounter : integer range 0 to TOTAL_LINES;


-- pre-DFF output data bus
signal internalDataOut :  STD_LOGIC_VECTOR (num_red_output_bits
                    + num_green_output_bits + num_blue_output_bits - 1 downto 0);
begin

    -- nextState logic
    FSM: process(currentState)
    begin
        -- Current byte is first(low) byte in active videoSubSlot
        if(currentState = activeSubSlot1) then

            -- always going to get second part of subSlot
            nextState <= activeSubSlot2;
            -- output first byte
            internalDataOut(num_input_bits - 1 downto 0) <= DataIn;

        -- Current byte is second (high) byte in active videoSubSlot
        elsif(currentState = activeSubSlot2) then

            if(colCounter < ACTIVE_SAMPLES - 1) then    -- Active samples of line
                nextState <= activeSubSlot1;
            else                                        -- Inactive samples of line
                nextState <= inactiveSubSlot1;
            end if;

            -- output second byte
            internalDataOut(2 * num_input_bits - 1 downto num_input_bits) <= DataIn;

        -- Current byte is first (low) byte in inactive videoSubSlot
        elsif(currentState = inactiveSubSlot1) then

            nextState <= inactiveSubSlot2; -- always going to get second part of subSlot

        -- Current byte is second (high) byte in inactive videoSubSlot
        elsif(currentState = inactiveSubSlot2) then

            if(colCounter < TOTAL_SAMPLES - 1) then   -- still in inactive part of line
                nextState <= inactiveSubSlot1;
            elsif(rowCounter < ACTIVE_LINES - 1) then -- at the end of inactive part of line
                nextState <= activeSubSlot1;
            else
                nextState <= inactiveLineSlot1;
            end if;

        elsif(currentState = inactiveLineSlot1) then

            nextState <= inactiveLineSlot2; -- always going to get second part of lineSlot

        elsif(currentState = inactiveLineSlot2) then

            if(rowCounter < TOTAL_LINES) then   -- still in inactive lines of frame
                nextState <= inactiveLineSlot1;
            else                                -- finished the inactive lines of frame
                nextState <= activeSubSlot1;    -- reset to start of next frame
            end if;

        end if;
    end process;


    process(Clock)
    begin
        if(Clock'event and Clock = '1') then
            if(reset = '0') then
                Hsync    <= '0';        -- default to no newline
                Vsync       <= '0';     -- default to no newSample
                Fsync    <= '0';        -- default to no newFrame

                -- Update row and column counters
                if(colCounter = TOTAL_SAMPLES - 1 and rowCounter = TOTAL_LINES - 1) then
                    -- End of a frame
                    rowCounter <= 0;
                    colCounter <= 0;
                    Fsync         <= '1';   -- signal a new frame
                elsif(colCounter = TOTAL_SAMPLES - 1) then
                    -- End of a line
                    rowCounter <= rowCounter + 1;
                    colCounter <= 0;
                    Hsync   <= '1'; -- a new Line has been started
                else
                    -- Middle of a line
                    rowCounter <= rowCounter;

                    if(nextState = activeSubSlot2 or nextState = inactiveSubSlot2
                            or nextState = inactiveLineSlot2)
                    then
                        -- Only have one of the bytes from SubSlot
                        colCounter <= colCounter;
                    else
                        -- finished current SubSlot, move to next in line
                        colCounter <= colCounter + 1;
                        Vsync <= '1'; -- a new SubSlot sample is ready
                    end if;
                end if;

                -- Update the current state of FSM
                currentState <= nextState;
            else -- reset FSM
                rowCounter  <= 0;
                colCounter  <= 0;
                currentState <= idle;
            end if;
        end if;

    end process;

    dataDFF: process(Clock)
    begin
        if(Clock'event and Clock = '1') then
            DataOut <= internalDataOut; -- Latch internal data bus and send out
        end if;
    end process;

end Behavioral;

