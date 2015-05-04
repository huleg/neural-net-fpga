----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:13:25 04/28/2015 
-- Design Name: 
-- Module Name:    usb_video_driver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: This is the complete USB video driver 
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

entity usb_video_driver is
Generic (
        num_input_bits        : integer := 8; -- number of bits from UART tx/rx
        num_red_output_bits   : integer := 5; -- number of red bits to keep
        num_green_output_bits : integer := 6; -- number of green bits to keep
        num_blue_output_bits  : integer := 5  -- number of blue bits to keep
    );
    Port ( Clock : in  STD_LOGIC; -- system clock
           Reset : in  STD_LOGIC; -- Reset
           Start : in  STD_LOGIC; -- Start retrieving video data 
			  Stop  : in  STD_LOGIC; -- Stop retrieving video data
           UartDataIn : in  STD_LOGIC_VECTOR (num_bits downto 0); -- data from the UART
			  UartDataRdyIn : in STD_LOGIC; -- data ready signal from the UART rx
           UartDataOut : out  STD_LOGIC_VECTOR (num_bits downto 0);-- data to the UART
           UartDataOutRdy : out  STD_LOGIC; -- data ready signal to UART tx
			  Hsync   : out STD_LOGIC;    -- horizontal sync out
           Vsync   : out STD_LOGIC;    -- vertical sync out
           Fsync   : out STD_LOGIC;    -- frame sync out
           VideoDataOut : out  STD_LOGIC_VECTOR (num_red_output_bits -- Output data bus
                + num_green_output_bits + num_blue_output_bits - 1 downto 0)
			 );
end usb_video_driver;

architecture Behavioral of usb_video_driver is
	Component usb_video_controller is 
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
	End Component;		  
	
	Component usb_video_decoder is
	Generic (
        num_bits  		      : integer; -- number of bits from UART tx/rx
        num_red_output_bits   : integer; -- number of red bits to keep
        num_green_output_bits : integer; -- number of green bits to keep
        num_blue_output_bits  : integer  -- number of blue bits to keep
   );
	Port ( Clock   : in  STD_LOGIC;    -- system clock
          FsmReset: in  STD_LOGIC;    -- state machine reset
          -- data from UART input stream
          VideoDataIn  : in  STD_LOGIC_VECTOR (num_input_bits - 1 downto 0);
          Hsync   : out STD_LOGIC;    -- horizontal sync out
          Vsync   : out STD_LOGIC;    -- vertical sync out
          Fsync   : out STD_LOGIC;    -- frame sync out
          VideoDataOut : out  STD_LOGIC_VECTOR (num_red_output_bits -- Output data bus
                + num_green_output_bits + num_blue_output_bits - 1 downto 0)
   );
	End Component;
	
begin

Inst_usb_video_controller: usb_video_controller 
GENERIC MAP(
		num_bits => num_bits
		)
PORT MAP(
		Clock => Clock,
		Reset => Reset,
		Start => Start,
		Stop => Stop,
		UartDataIn => UartDataIn,
		UartDataRdyIn => UartDataRdyIn,
		UartDataOut => UartDataOut,
		UartDataOutRdy => UartDataOutRdy,
		FsmReset => FsmReset
	);

Inst_usb_video_decoder: usb_video_decoder 
GENERIC MAP(
		num_bits => num_bits,
      num_red_output_bits => num_red_output_bits,
      num_green_output_bits => num_green_output_bits,
      num_blue_output_bits => num_blue_output_bits
		)
PORT MAP(
		Clock => Clock,
		FsmReset => FsmReset,
		VideoDataIn => UartDataIn,
		Hsync => Hsync,
		Vsync => Vsync,
		Fsync => Fsync,
		VideoDataOut => VideoDataOut
	);


end Behavioral;

