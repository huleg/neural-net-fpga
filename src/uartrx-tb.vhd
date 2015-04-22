--
--  uartrx-tb.vhd
--
--  Test Bench for UART receiver.
--
--  Revision History:
--      21 Apr 2015     Brian Kubisiak      Initial revision.
--

library ieee;
use     ieee.std_logic_1164.all;

-- Our testbench entity has no ports; it is completely self-contained.
entity uartrx_tb is
end uartrx_tb;

architecture TB_ARCHITECTURE of uartrx_tb is

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
    signal reset    : std_logic;    -- Reset receiver, preparing it for new data
    signal rx       : std_logic;    -- Serial data input to receiver

    -- Outputs - signals that are checked against the expected outputs of the
    -- test bench.
    signal data     : std_logic_vector(7 downto 0); -- Data received by UART
    signal rdy      : std_logic;    -- Data from UART ready for reading
    signal err      : std_logic;    -- UART read invalid data

    -- Indicates that the simulation has finished
    signal END_SIM  : boolean := FALSE;

    -- This signal holds the test pattern to shift into the receiver. It has a
    -- couple of bits at the beginning to allow the UART to reset, followed by
    -- 2 valid bytes, then an invalid, then another valid.
    constant data_in: std_logic_vector(0 to 10*4 + 1) :=
        "11" & "0010101011" & "0101010101" & "0110011010" & "0001100101";

    -- Type for holding the output vectors
    type OutData is array (0 to 3) of std_logic_vector(7 downto 0);

    -- We should see the following data output from the UART:
    constant data_out: OutData :=
        ("01010101", "10101010", "11001101", "00110010");

    -- The 'rdy' signal should exhibit this pattern. For the third pattern, the
    -- 'err' signal will be pulsed instead of the 'rdy' signal.
    constant rdy_sig: std_logic_vector(0 to 3) := "0010";

begin

    -- Declare the unit-under-test and wire up all its inputs to stimulus
    -- signals and outputs to tested signals.
    UUT: uartrx
        generic map ( N => 8 )
        port map  (
            clk   => clk,
            reset => reset,
            rx    => rx,
            data  => data,
            rdy   => rdy,
            err   => err
        );

    -- This process will reset the UART for a couple of clocks, then stimulate
    -- the serial data input with the test signal. Once all the test bits have
    -- been 'transmitted', then simulation will end.
    StimulateInputs: process
    begin

        -- Reset the UART
        reset <= '0';

        -- Set stop bit so UART doesn't begin reading immediately.
        rx <= '1';

        -- Wait a couple of clock cycles to the UART to reset.
        wait until clk = '1';
        wait until clk = '0';
        wait until clk = '1';
        wait until clk = '0';

        -- Start running the receiver
        reset <= '1';

        for i in 0 to 41 loop

            -- Wait for the next rising edge
            wait until clk = '1';

            -- Output the next bit in the stimulus sequence with a short delay
            -- after the clock.
            rx <= data_in(i) after 1 ns;

            -- Hold here for the clock to go low again.
            wait until clk = '0';

        end loop;

        -- Wait a couple more clocks to make sure the data propagates through
        wait until clk = '1';
        wait until clk = '0';
        wait until clk = '1';
        wait until clk = '0';

        -- Simulation is over
        END_SIM <= TRUE;
        wait;

    end process;

    -- This process will wait until the receiver indicates that it has data,
    -- then check to make sure that the data is correct.
    TestOutputs: process
    begin

        for i in 0 to 3 loop

            -- Wait until a new byte is received (whether in error or not)
            wait until (rdy = '0' or err = '0');
            -- Check data on the next rising edge of the clock
            wait until (clk'event and clk = '1');

            -- Check to make sure that the byte is correct and errors are found
            -- only at the proper times
            assert (data = data_out(i) and rdy = rdy_sig(i))
                report "Wrong data on output."
                severity ERROR;

            -- Wait for the signal to be reset
            wait until (rdy = '1' and err = '1');

        end loop;

        -- Notify the simulation once all tests have passed.
        assert (FALSE) report "All outputs tested." severity NOTE;
        wait;

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

