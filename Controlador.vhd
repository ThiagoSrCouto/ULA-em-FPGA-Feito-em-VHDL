----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:29:42 10/13/2026 
-- Design Name: 
-- Module Name:    Controlador - Behavioral 
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

entity Controlador is
    Port ( clk : in  STD_LOGIC;
           btn : in  STD_LOGIC;
           keys : in  STD_LOGIC_VECTOR (3 downto 0);
           leds : out  STD_LOGIC_VECTOR (7 downto 0));
end Controlador;

architecture Behavioral of Controlador is

	component debouncer is
		 Port ( Sin : in  STD_LOGIC;
				  clk : in  STD_LOGIC;
				  Sout : out  STD_LOGIC);
	end component;

	component ULA is
		Port ( A : in  STD_LOGIC_VECTOR (3 downto 0);
				  B : in  STD_LOGIC_VECTOR (3 downto 0);
				  Sel : in  STD_LOGIC_VECTOR (3 downto 0);
				  FZ : out  STD_LOGIC;
				  FN : out  STD_LOGIC;
				  FO : out  STD_LOGIC;
				  FC : out  STD_LOGIC;
				  Y : out  STD_LOGIC_VECTOR (3 downto 0));
	end component;

	signal fio_botao_limpo, pulso_botao: std_logic;
	signal botao_anterior: std_logic :='0';

	signal reg_A, reg_B, reg_Sel: std_logic_vector(3 downto 0):= "0000";

	signal etapa: integer range 0 to 3 := 0;

	signal fio_res: std_logic_vector(3 downto 0);
	signal fioZ, fioN, fioC, fioO: std_logic;


begin

	-- Instantiating the Debounce filter
    Filtro: debouncer port map(
        clk    => clk, 
        Sin => btn, 
        Sout => fio_botao_limpo
    );

    -- Instantiating the ULA (Connecting internal wires to ULA pins)
    Calculadora: ULA port map(
        A      => reg_A, 
        B      => reg_B, 
        Sel    => reg_Sel,
        Y    => fio_res, 
        FZ => fioZ, 
        FN => fioN, 
        FC => fioC, 
        FO => fioO
    );

	-- State Machine and Button Edge Detection Process
    process(clk)
    begin
        if rising_edge(clk) then
            -- Rising edge detector for the button (generates a single pulse per click)
            botao_anterior <= fio_botao_limpo;
            pulso_botao    <= fio_botao_limpo and (not botao_anterior);
            
            if pulso_botao = '1' then
                if etapa = 0 then
                    reg_Sel <= keys; -- 1: Read operation code
                    etapa <= 1;
                elsif etapa = 1 then
                    reg_A <= keys;   -- 2: Read first operand (A)
                    etapa <= 2;
                elsif etapa = 2 then
                    reg_B <= keys;   -- 3: Read second operand (B)
                    etapa <= 3;        
                elsif etapa = 3 then -- Reset state machine for next operation
						  reg_Sel<="0000";
						  reg_A <="0000";
						  reg_B <="0000";
						  etapa <= 0;
					 end if;
            end if;
        end if;
    end process;

    -- Assigning ULA Results and Flags to the physical 8 LEDs on the board
    -- leds(7..4) = Flags (Overflow, Carry, Negative, Zero)
    -- leds(3..0) = 4-bit Numeric Result
	 
	 leds(7 downto 4) <= "0001" when etapa = 0 else
								"0010" when etapa = 1 else
								"0100" when etapa = 2 else
								(fioO & fioC & fioN & fioZ);
								
	 leds(3 downto 0) <= fio_res when etapa=3 else "0000";

end Behavioral;

