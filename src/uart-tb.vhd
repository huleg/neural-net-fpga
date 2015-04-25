--
--  uart-tb.vhd
--
--  Test Bench for UART transmitter and receiver.
--
--  This is not an exhaustive testbench; it simply puts data into the UART
--  transmitter, and checks that the same data comes out the other side from the
--  receiver.
--
--  Revision History:
--      24 Apr 2015     Brian Kubisiak      Initial revision.
--

library ieee;
use     ieee.std_logic_1164.all;

-- Our testbench entity has no ports; it is completely self-contained.
entity uart_tb is
end uart_tb;


architecture TB_ARCHITECTURE of uart_tb is

--
-- uarttx
--
--  This component is one of the units-under-test. It is an asynchronous
--  transmitter for the UART design. It takes in data on the parallel input
--  (along with a signal telling it to start transmitting), and outputs the data
--  serially.
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
    component uarttx is
        generic ( N : integer := 8 );
        port
        (
            reset   : in  std_logic;                        -- Reset the UART
            clk     : in  std_logic;                        -- Baud clock
            data    : in  std_logic_vector(N-1 downto 0);   -- Parallel data out
            rdy     : in  std_logic;                        -- New data ready
            ack     : out std_logic;                        -- Ack data ready
            tx      : out std_logic                         -- Serial data input
        );
    end component;

--
-- uartrx
--
--  This component is the unit-under-test. It is an asynchronous receiver for
--  the UART design. It takes in serial data at the baud rate determined by the
--  clock, and outputs the data in parallel.
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
    component uartrx is
        generic ( N : integer := 8 );
        port (
            reset   : in  std_logic;                        -- Reset the UART
            clk     : in  std_logic;                        -- Baud clock
            rx      : in  std_logic;                        -- Serial data in
            data    : out std_logic_vector(N-1 downto 0);   -- Parallel data out
            rdy     : out std_logic;                        -- New data ready
            err     : out std_logic                         -- Error occurred
        );
    end component;


    -- Stimulus signals - signals mapped to the input ports of tested entity
    signal clk      : std_logic;    -- System clock
    signal reset    : std_logic;    -- Reset UART
    signal data_tx  : std_logic_vector(7 downto 0); -- Data to send
    signal rdy_tx   : std_logic;    -- Data input should be sent

    -- Outputs - signals that are checked against the expected outputs of the
    -- test bench.
    signal ack      : std_logic;    -- New data is being transmitted
    signal data_rx  : std_logic_vector(7 downto 0); -- Received data
    signal rdy_rx   : std_logic;    -- New data has been received
    signal err      : std_logic;    -- Error ocurred during transmission

    -- Line for transferring data between the transmitter and receiver.
    signal transmit : std_logic;

    -- Indicates that the simulation has finished
    signal END_SIM  : boolean := FALSE;

    -- Type for holding the test vectors. We need this because VHDL doesn't like
    -- declaring an array of std_logic_vector without a new type.
    type DataVec is array (0 to 5) of std_logic_vector(7 downto 0);

    -- We should see the following data output from the UART:
    constant test_vec: DataVec := ("11010111", "11111111", "00000000",
                                   "10101010", "00001111", "11110000");

begin

    -- Declare the units-under-test and wire up all its inputs to stimulus
    -- signals and outputs to tested signals.
    UUT_rx: uartrx
        generic map ( N => 8 )
        port map (
            -- Map inputs to stimulus signals:
            clk   => clk,
            reset => reset,

            -- Line for transferring the data:
            rx    => transmit,

            -- Map outputs to tested signals:
            data  => data_rx,
            rdy   => rdy_rx,
            err   => err
        );
    UUT_tx: uarttx
        generic map ( N => 8 )
        port map (
            -- Map inputs to stimulus signals:
            reset => reset,
            clk   => clk,
            data  => data_tx,
            rdy   => rdy_tx,

            -- Line for transferring the data:
            tx    => transmit,

            -- Map outputs to tested signals:
            ack   => ack
        );

    -- Send data into the transmitter. This will test transmitting a burst as
    -- well as transmitting isolated characters.
    TxData: process
    begin

        -- Reset the UART
        reset <= '0';

        -- Start without transmitting data
        rdy_tx <= '1';

        -- Wait a clock for it to completely reset
        wait until clk = '1';
        wait until clk = '0';

        -- Transmitter should be transmitting stop bits now, we can stop
        -- resetting
        reset <= '1';

        -- Transmit the first 4 characters in quick succession
        for i in 0 to 3 loop

            -- Start transmitting data.
            data_tx <= test_vec(i);
            rdy_tx  <= '0';

            -- Once the transfer is acknowledged, go on to the next vector
            wait until ack = '0';

        end loop;

        -- Done transmitting for a little bit.
        rdy_tx <= '1';

        for i in 4 to 5 loop

            -- Wait for a long time for a break between transmissions
            wait for 500 ns;

            -- Start the next transmission.
            data_tx <= test_vec(i);
            rdy_tx  <= '0';

            -- Wait for acknowledgement before continuing
            wait until ack = '0';
            rdy_tx <= '1';

        end loop;

        -- Finished transmitting all data; just wait here.
        wait;

    end process;

    -- Check the data on the receiver, making sure that it is the same as the
    -- transmitted data.
    RxData: process
    begin

        for i in 0 to 5 loop

            -- Wait until a new character is received.
            wait until rdy_rx = '0';
            -- Check data on the next rising edge of the clock.
            wait until (clk'event and clk = '1');

            assert (data_rx = test_vec(i))
                report "Incorrect data received."
                severity ERROR;

            -- Now wait for the ready signal to clear.
            wait until rdy_rx = '1';

        end loop;

        -- Notify once all tests have passed.
        assert (FALSE) report "All tests completed." severity NOTE;

        -- Simulation is over once all the outputs have been tested.
        END_SIM <= TRUE;
        wait;

    end process;

    -- Check to make sure that the error signal is never asserted.
    CheckErr: process(err)
    begin

        -- Make sure that the error signal isn't asserted.
        assert (err = '1')
            report "Error found on receiver."
            severity ERROR;

    end process;

    -- This process will generate a clock with a 20 ns period and a 50% duty
    -- cycle. Once the end of the simulation has been reached (END_SIM = TRUE),
    -- then the clock will stop oscillating.
    GenClock: process
    begin

        -- this process generates a 20 ns 50% duty cycle clock
        -- stop the clock when the end of the simulation is reached
        if END_SIM = FALSE then
            clk <= '0';
            wait for 10 ns;
        else
            wait;
        end if;

        if END_SIM = FALSE then
            clk <= '1';
            wait for 10 ns;
        else
            wait;
        end if;

    end process;

end TB_ARCHITECTURE;

