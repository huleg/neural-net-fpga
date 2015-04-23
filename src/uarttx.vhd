--
-- uarttx.vhd
--
-- Universal asynchronous receiver/transmitter---transmitter design.
--
-- This file contains the design for the transmitter on a UART. The UART will
-- take in data in parallel on the data bus. It will then output the character
-- in serial on the TX line. This implementation uses N-bit characters, 1 stop
-- bit, and no parity bit. The baud rate is the same as the input clock
-- frequency. The design is parameterized on the number of bits in each
-- character.
--
-- To transmit data, output the desired character to the 'data' input and send
-- the 'rdy' line low. These signals must be latched until the UART sends the
-- 'ack' line low to acknowledge the data. Note that the 'ack' signal will be
-- pulsed low for only a single clock.
--
-- The data is transmitted MSB first; that is, the data is transmitted from the
-- most-significant bit first, down to the least-significant bit last.
--
-- Revision History:
--      22 Apr 2015     Brian Kubisiak      Initial revision.
--

library ieee;
use     ieee.std_logic_1164.all;

--
-- uarttx
--
--  Parameters:
--      N (integer)             Number of bits per character.
--
--  Inputs:
--      reset (std_logic)       Active-low line to reset the UART transmitter.
--      clk (std_logic)         Baud rate clock. The UART will transmit one bit
--                              on every rising edge of the clock.
--      data (std_logic_vector) Next character to send over the UART.
--      rdy (std_logic)         Active-low line indicating that data is ready to
--                              transmit. It should be sent low for at least one
--                              baud.
--
--  Outputs:
--      tx (std_logic)          Transmit line for transmitting the serial data.
--      ack (std_logic)         Active-low signal acknowledging the ready data,
--                              indicating that the new data will now be
--                              transmitted.
--
entity uarttx is
    generic ( N : integer := 8 );
    port
    (
        reset   : in  std_logic;                        -- Reset the UART.
        clk     : in  std_logic;                        -- Baud clock.
        data    : in  std_logic_vector(N-1 downto 0);   -- Parallel data output.
        rdy     : in  std_logic;                        -- New data ready.
        ack     : out std_logic;                        -- Ack data ready.
        tx      : out std_logic                         -- Serial data input.
    );
end entity;


architecture procedural of uarttx is

    -- Register for shifting data out on the transmit line
    signal shfttx   : std_logic_vector(N-1 downto 0);

    -- Counter for indicating the number of bits transmitted. Tere is 1 start
    -- bit, N data bits, and 1 stop bit for a total of N+2 bits.
    signal state    : integer range 0 to N+1;

    -- Latches the rdy signal, resetting whenever the resetrdy signal is active.
    signal rdylatch : std_logic;

begin

    --
    --  DataRdyLatch
    --
    --  This process latches and acknowledges the data ready signal at the end
    --  of each character transmission. The ack signal will go active for a
    --  single clock, while the latch will hold for an entire cycle. Both
    --  signals will be set inactive when the reset input goes active.
    --
    DataRdyLatch: process(clk)
    begin
        if rising_edge(clk) then

            -- When reset is active, both the acknowledge and latch signals go
            -- inactive.
            if (reset = '0') then
                rdylatch <= '1';
                ack      <= '1';

            -- When transmitting the stop bit, check to see if new data is
            -- ready. If it is ready, latch the ready signal and acknowledge the
            -- request to transmit data.
            elsif (state = N+1) then
                rdylatch <= rdy;
                ack      <= rdy;

            -- Else, just keep holding the latch; do not acknowledge any new
            -- requests until the character transmission is over.
            else
                rdylatch <= rdylatch;
                ack      <= '1';
            end if;

        end if;
    end process;


    --
    --  TransmitData
    --
    --  Transmit the data one bit at a time over the 'tx' line whenever data is
    --  valid. After transmission, if new data is available, transfer it to the
    --  shift register and start the transmission cycle again.
    --
    TransmitData: process(clk)
    begin
        if rising_edge(clk) then

            -- By default, latch the shift register.
            shfttx <= shfttx;

            -- When resetting or no data available, output stop bit.
            if (reset = '0' or rdylatch = '1') then

                -- Output stop bit
                tx      <= '1';
                -- Hold in this state to receive new data to transmit.
                state   <=  N+1;

            -- If we are beginning a transmission, output the start bit
            elsif (state = 0) then

                -- Beginning of transmission; output start bit and advance to
                -- next state.
                tx      <= '0';
                state   <=  1;

            -- At the end of a transmission, start new transmission. Note that
            -- we can only get here if new data is available (rdylatch = '0').
            elsif (state = N+1) then

                -- All data has been sent; output a stop bit.
                tx      <= '1';
                -- Start a new transmission.
                state   <=  0;
                -- Load the new data into the shift register.
                shfttx  <= data;

            -- Otherwise, we are in the process of shifting out the data.
            else

                -- Output the next MSB from the shift register.
                tx      <= shfttx(N-1);
                -- Shift the data.
                shfttx  <= shfttx(N-2 downto 0) & 'X';
                -- Advance to next state.
                state   <= state + 1;

            end if;

        end if;
    end process;

end architecture procedural;

