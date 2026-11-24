----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    13:36:17 10/13/2026
-- Design Name:
-- Module Name:    ULA - Behavioral
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ULA is
    port(
        A      : in  std_logic_vector(3 downto 0); -- 4 bit Operand A
        B      : in  std_logic_vector(3 downto 0); -- 4 bit Operand B
        Sel    : in  std_logic_vector(3 downto 0); -- Operation selector
        Y      : out std_logic_vector(3 downto 0); -- 4 bit Result output
        FZ     : out std_logic;                    -- Zero Flag
        FN     : out std_logic;                    -- Negative Flag
        FC     : out std_logic;                    -- Carry Out / Borrow Flag
        FO     : out std_logic                     -- Overflow Flag
    );
end ULA;

architecture Behavioral of ULA is

    -- Function for Signed Integer Division
    function divide_signed (num : signed(3 downto 0); den : signed(3 downto 0)) return signed is
        variable abs_num, abs_den : unsigned(3 downto 0);
        variable quociente        : unsigned(3 downto 0) := "0000";
        variable resto            : unsigned(3 downto 0);
        variable is_neg           : boolean;
    begin
        -- Error: Division by zero outputs "1111"
        if den = "0000" then
            return "1111"; 
        end if;

        -- Determine if the final result should be negative
        is_neg := (num(3) /= den(3));

        -- Convert inputs to absolute values
        if num(3) = '1' then abs_num := unsigned(-num); else abs_num := unsigned(num); end if;
        if den(3) = '1' then abs_den := unsigned(-den); else abs_den := unsigned(den); end if;

        -- Perform successive subtraction to find the quotient
        resto := abs_num;
        for i in 0 to 15 loop
            if resto >= abs_den and abs_den /= "0000" then
                resto := resto - abs_den;
                quociente := quociente + 1;
            end if;
        end loop;

        -- Reapply the mathematical sign to the final quotient
        if is_neg then return -signed(quociente);
        else return signed(quociente); end if;
    end function;

begin
    process(A, B, Sel)
        -- Variables for 2's complement arithmetic and 5-bit extension
        variable var_A, var_B : signed(4 downto 0);
        variable unsig_A, unsig_B, unsig_Res : unsigned(4 downto 0);
        variable result_temp  : signed(4 downto 0);
        variable result_4b    : std_logic_vector(3 downto 0);
		  variable shift_amt : integer;
    begin
        -- Default flag initialization
        FZ <= '0'; 
        FN <= '0'; 
        FC <= '0'; 
        FO <= '0';
        
        -- Sign extension for signed arithmetic operations
        var_A := resize(signed(A), 5);
        var_B := resize(signed(B), 5);
        
        -- Zero extension for unsigned Carry Out / Borrow calculation
        unsig_A := '0' & unsigned(A);
        unsig_B := '0' & unsigned(B);

        -- Operation decoder based on the 3 least significant bits of Sel
        case Sel(2 downto 0) is
            
            when "000" => -- Addition (2's complement)
                result_temp := var_A + var_B;
                result_4b   := std_logic_vector(result_temp(3 downto 0));
                unsig_Res   := unsig_A + unsig_B;
                
                -- Carry out from MSB
                FC <= std_logic(unsig_Res(4));
                -- Overflow: A and B have same sign, but result has different sign
                FO <= (not (A(3) xor B(3))) and (A(3) xor result_4b(3));

            when "001" => -- Subtraction (2's complement)
                result_temp := var_A - var_B;
                result_4b   := std_logic_vector(result_temp(3 downto 0));
                unsig_Res   := unsig_A - unsig_B;
                
                -- Borrow out from MSB
                FC <= std_logic(unsig_Res(4)); 
                -- Overflow: A and B have different signs, result sign matches B sign
                FO <= (A(3) xor B(3)) and (A(3) xor result_4b(3));

            when "010" => -- Bitwise AND
                result_4b := A and B;
                
            when "011" => -- Bitwise OR
                result_4b := A or B;
                
            when "100" => -- Bitwise XOR
                result_4b := A xor B;
                
            when "101" => -- Arithmetic Shift (A * 2^B)  
					 shift_amt := to_integer(signed(B));
                if shift_amt > 0 then
                    -- Shift Left (Multiply by 2^B)
                    result_4b := std_logic_vector(shift_left(signed(A), shift_amt));
                elsif shift_amt < 0 then
                    -- Shift Right Arithmetic (Divide by 2^B, preserves negative signs)
                    result_4b := std_logic_vector(shift_right(signed(A), -shift_amt));
                else
                    -- B = 0, No shift
                    result_4b := A;
                end if;
                
            when "110" => -- Signed Comparison (A vs B)
                if signed(A) > signed(B) then 
                    result_4b := "0100"; -- A is Greater than B
                elsif signed(A) = signed(B) then 
                    result_4b := "0010"; -- A equals B
                else 
                    result_4b := "0001"; -- A is Less than B
                end if;
                
            when "111" => -- Signed Division (A / B)
                result_4b := std_logic_vector(divide_signed(signed(A), signed(B)));
                
            when others => -- Safety condition
                result_4b := "0000";
        end case;

        -- Assign the internal 4-bit variable to the output port
        Y <= result_4b; 

        -- Set Negative Flag (Checks if the Most Significant Bit is 1)
        if result_4b(3) = '1' then
            FN <= '1'; 
        end if;

        -- Set Zero Flag (Checks if all output bits are 0)
        if result_4b = "0000" then
            FZ <= '1'; 
        end if;

    end process;
end Behavioral;