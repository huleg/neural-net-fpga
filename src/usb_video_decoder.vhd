----------------------------------------------------------------------------------
-- Company: 		EE119c
-- Engineer: 		Quinn Osha
-- 
-- Create Date:    17:04:43 04/17/2015 
-- Design Name: 		neaural-net-fpga
-- Module Name:    usb_video_decoder - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 	This entity implements a decoder of the USB video class data
-- stream. 
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

entity usb_video_decoder is
    Port ( Clock : in  STD_LOGIC;
           Reset : in  STD_LOGIC;
           DataIn : in  STD_LOGIC_VECTOR (7 downto 0);
           BaseAddress : in  STD_LOGIC_VECTOR (15 downto 0);
           DataOut : in  STD_LOGIC_VECTOR (7 downto 0);
           AddressOut : in  STD_LOGIC_VECTOR (15 downto 0));
end usb_video_decoder;

architecture Behavioral of usb_video_decoder is

begin


end Behavioral;

