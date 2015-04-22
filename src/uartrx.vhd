--
-- uartrx.vhd
--
-- Universal asynchronous receiver/transmitter---receiver design.
--
-- This file contains the design for the receiver on a UART. The UART will take
-- in data serially on the RX line, starting with a single low start bit. This
-- implementation uses N-bit characters, 1 stop bit, and no parity bit. The baud
-- rate is the same as the input clock frequency. The design is parameterized on
-- the number of bits in the character.
--
-- Once a full character has been received over the serial line, the 'rdy'
-- output will be pulsed low for one clock to indicate that data is ready. This
-- data will remain latched until the next pulse on the 'rdy' signal.
--
-- If the stop bit is '0' instead of '1', then the 'err' signal will be pulsed
-- low instead of 'rdy'. Even if an error occurred, the received data will still
-- be output.
--
-- The data is loaded as if we received the MSB first. That is, each new bit is
-- shifted into the LSB of the shift register.
--
-- Revision History:
--      17 Apr 2015     Brian Kubisiak      Initial revision.
--      21 Apr 2015     Brian Kubisiak      Changed to MSB-first to match simulation.
--

library ieee;
use     ieee.std_logic_1164.all;

--
-- uartrx
--
--  Parameters:
--      N (integer)             Number of bits per character.
--
--  Inputs:
--      reset (std_logic)       Active-low line to reset the UART receiver.
--      clk (std_logic)         Baud rate clock. The UART will sample the input
--                              signal on every rising edge of the clock.
--      rx (std_logic)          Receive line carrying the serial data.
--
--  Outputs:
--      data (std_logic_vector) Last character received over the UART.
--      rdy (std_logic)         Active-low line indicating when the data is
--                              ready. Once a character is received, this will
--                              pulse low for one clock.
--      err (std_logic)         Active-low signal indicating an error occurred.
--                              Currently, this means that the stop bit was not
--                              high.
entity uartrx is
    generic ( N : integer := 8 );
    port
    (
        reset   : in  std_logic;                        -- Reset the UART.
        clk     : in  std_logic;                        -- Baud clock.
        rx      : in  std_logic;                        -- Serial data input.
        data    : out std_logic_vector(N-1 downto 0);   -- Parallel data output.
        rdy     : out std_logic;                        -- New data ready.
        err     : out std_logic                         -- Error occurred.
    );
end entity;


architecture procedural of uartrx is

    -- Shift register for loading new data from the serial line.
    signal shftrx   : std_logic_vector(N-1 downto 0);
    -- Buffer for outputting the received data.
    signal outbuf   : std_logic_vector(N-1 downto 0);
    -- Counter for indicating the number of bits received. There is 1 start bit,
    -- N data bits, and 1 stop bit for a total of N+2 bits.
    signal state    : integer range 0 to N+1;

begin

    -- Always output the buffered data.
    data <= outbuf;

    --
    -- LoadNextBit
    --
    -- On each clock edge, this process will shift a new bit into the shift
    -- register. Once the character is full, it will pulse the 'rdy' signal low
    -- and output the data. It will then wait for the next start bit to begin
    -- receiving again.
    --
    -- If the stop bit is found to be '0' instead of '1', then the 'err' signal
    -- will be pulsed low instead of 'rdy'.
    --
    LoadNextBit: process (clk)
    begin
        if rising_edge(clk) then

            -- By default, data is not ready and no error has occurred.
            rdy <= '1';
            err <= '1';

            -- By default, latch the output buffer and shift register.
            outbuf <= outbuf;
            shftrx <= shftrx;

            -- First, check for reset conditions.
            if (reset = '0') then

                -- When resetting, we set the counter back to zero to wait for
                -- the next start bit.
                state <= 0;

            -- If no bits loaded, wait for start bit.
            elsif (state = 0) then

                if (rx = '0') then
                    -- Start bit received, begin shifting in data.
                    state <= 1;
                else
                    -- Otherwise, continue waiting.
                    state <= 0;
                end if;

            -- All data has been received.
            elsif (state = N+1) then

                -- Reset counter regardless of data validity.
                state <= 0;
                -- Always output the shifted data, even if it is found to be
                -- invalid.
                outbuf <= shftrx;

                -- Check for a valid stop bit.
                if (rx = '1') then
                    -- Stop bit is valid; indicate data is ready.
                    rdy    <= '0';
                else
                    -- Stop bit invalid; indicate an error occurred.
                    err    <= '0';
                end if;

            -- Still just shifting in the data.
            else

                -- Shift the new data bit into the LSB of the shift register.
                shftrx <= shftrx(N-2 downto 0) & rx;
                -- Go to next state.
                state <= state + 1;

            end if;

        end if;
    end process;

end architecture procedural;

