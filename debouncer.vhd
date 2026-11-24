----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    02:13:31 09/24/2013 
-- Design Name: 
-- Module Name:    debouncer - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
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

entity debouncer is
    Port ( Sin : in  STD_LOGIC; 	-- Noisy input (button)
           clk : in  STD_LOGIC;		-- System clock
           Sout : out  STD_LOGIC);  -- Debounced and synchronized output
end debouncer;

architecture Behavioral of debouncer is

	constant num : integer := 25000000; -- Debounce delay (500 ms)
	
	signal contador : integer range 0 to num := 0; 
	
	signal sync_0,sync_1 : std_logic := '0'; -- 2-stage synchronizer flip-flops
	signal estado_btn : std_logic := '0';	 -- Current stable state
begin
	process(clk)
	begin
		if rising_edge(clk) then
			-- Prevent metastability
			sync_0 <= Sin;
			sync_1 <= sync_0;
		
			if contador > 0 then
				-- Wait for bounce to settle
				contador <= contador - 1;
			else
				-- Check for state transition
				if sync_1 /= estado_btn then
					estado_btn <= sync_1; -- Update stable state
					contador <= num;      -- Reset cooldown timer
				end if;
			end if;
		end if;
	end process;
	-- Assign to output port
	Sout <= estado_btn;
end Behavioral;

