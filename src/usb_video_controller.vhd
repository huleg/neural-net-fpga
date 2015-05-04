----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 	Quinn Osha
-- 
-- Create Date:    23:20:00 04/28/2015 
-- Design Name: 
-- Module Name:    usb_video_controller - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: This is the control block for the UVC video driver.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity usb_video_controller is
	 Generic( 
				num_bits : integer
				);
    Port ( Clock : in  STD_LOGIC; -- system clock
           Reset : in  STD_LOGIC; -- system reset
           Start : in  STD_LOGIC; -- Start retrieving video data 
			  Stop  : in  STD_LOGIC; -- Stop retrieving video data
           UartDataIn : in  STD_LOGIC_VECTOR (num_bits downto 0); -- data from the UART
			  UartDataRdyIn : in STD_LOGIC; -- data ready signal from the UART rx
           UartDataOut : out  STD_LOGIC_VECTOR (num_bits downto 0);-- data to the UART
           UartDataOutRdy : out  STD_LOGIC; -- data ready signal to UART tx
			  FsmReset : out STD_LOGIC -- reset signal to video decoder
			  );
end usb_video_controller;

architecture Behavioral of usb_video_controller is
-- FSM variables
type states is (
    idle,
    sendControl,
	 decodeVideo
);

signal currentState : states; -- The current state of the FSM
signal nextState    : states; -- The next state of the FSM

-- Constants
constant numControlBytes : integer := 32;
constant controlSequence : STD_LOGIC_VECTOR(numControlBytes * 8 - 1 downto 0) 
			:= X"0000000000000101151605000000000000000000000000600900F40B0000";

begin


end Behavioral;

