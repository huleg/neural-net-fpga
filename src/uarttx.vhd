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
--
entity uarttx is
    generic ( N : integer := 8 );
    port
    (
        reset   : in  std_logic;                        -- Reset the UART.
        clk     : in  std_logic;                        -- Baud clock.
        data    : in  std_logic_vector(N-1 downto 0);   -- Parallel data output.
        rdy     : in  std_logic;                        -- New data ready.
        tx      : out std_logic                         -- Serial data input.
    );
end entity;


architecture procedural of uarttx is

begin



end architecture procedural;

