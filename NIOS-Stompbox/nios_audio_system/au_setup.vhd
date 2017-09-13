---------------------
--  au_setup.vhd
---------------------
--	Configura el codec WM8731 
-------------------------------------------------------
--	Andoni Arruti
--  11/11/2016
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity au_setup is
	generic	(
		SAMPLE_RATE	: integer range 1 to 3 := 3 );
	port (
		reset		: in std_logic;
		clk_50 		: in std_logic;
		mic_lin		: in std_logic; -- si '1' MIC, si '0' LINEIN
		i2c_sdat	: inout std_logic;
		i2c_sclk	: out std_logic;
		aud_xck		: out std_logic		);
end au_setup;

architecture a of au_setup is
-- estados presente y siguiente de UC
	type estado is (e0, e1, e2, e3, e4, e5);
	signal ep, es	: estado;
-- contador de bits
	signal cbits 	: integer range 0 to 24;
	signal incbits	: std_logic;
	signal clbits	: std_logic;
	signal bit24	: std_logic;
	signal stop	: std_logic;
-- contador de direcciones
	constant LADDR 	: integer:=7;
	signal caddr 	: integer range 0 to laddr;
	signal incaddr	: std_logic;
	signal claddr	: std_logic;
	signal lastaddr	: std_logic;
-- contador de tiempo
	signal ctmp 	: unsigned(7 downto 0);
	signal inctmp	: std_logic;
	signal settmp	: std_logic;
	signal up	: std_logic;
	signal down	: std_logic;
-- bit de datos -------------------------
	signal dbit	: std_logic;
	signal ldbit	: std_logic;
	signal setbit0	: std_logic;
	signal setbit1	: std_logic;
	signal setbitz	: std_logic;
	signal sdat	: std_logic;
-- datos de configuracion -------------------------
	signal dato	: std_logic_vector(0 to 23);
-- contador divisor de reloj /4 -------------------------
	signal cclkdiv	: unsigned(1 downto 0);
begin
-- datos de configuracion -------------------------
-- configuracion para entrada por LINEIN
	dato(0 to 7) <= "00110100";	-- direccion del CODEC para escritura
	process (caddr, mic_lin)
	begin
		case caddr is
			when 0 => 
					  dato(8 to 23) <= x"0c00";	-- power down: deshabilitado
			when 1 => dato(8 to 23) <= x"0e41";	-- master, 16 bits, formato justificado izquierda
			when 2 => 
				if SAMPLE_RATE = 3 then
					  dato(8 to 23) <= x"1000";	-- 32 KHz, si xck=12'288 MHz (12'5 MHz -> 32'552083 KHz)
				elsif SAMPLE_RATE = 2 then
					  dato(8 to 23) <= x"1018";	-- 48 KHz, si xck=12'288 MHz (12'5 MHz -> 48'828125 KHz)
				else
					  dato(8 to 23) <= x"100C";	-- 8 KHz, si xck=12'288 MHz (12'5 MHz -> 8'1380208 KHz)
				end if; 

			when 3 => 
				if mic_lin = '1' then
					  dato(8 to 23) <= x"0814";	-- entrada MIC, salida DAC
				else
					  dato(8 to 23) <= x"0810";	-- entrada LINEIN, salida DAC
				end if;
			when 4 => dato(8 to 23) <= x"0579";	-- volumen Lout y Rout
			when 5 => dato(8 to 23) <= x"0117";	-- volumen Lin y Rin
			when 6 => dato(8 to 23) <= x"0A00";	-- habilitar DAC
			when LADDR => dato(8 to 23) <= x"1201";	-- activaci�n
		end case;
	end process;
-- ==================================================
-- Unidad de control
-- calculo de estado siguiente -------------------------
	p_es: process (ep, down, up, stop, bit24, lastaddr, i2c_sdat)
	begin
		case ep is
			when e0 =>
				if down='1' then
					es <= e1;
				else
					es <= e0;
				end if;
			when e1 =>
				if down='1' and stop='1' then
					es <= e2;
				else
					es <= e1;
				end if;
			when e2 =>
				if up='0' then
					es <= e2;
				elsif i2c_sdat='1' then
					es <= e0;
				else
					es <= e3;
				end if;
			when e3 =>
				if down='0' then
					es <= e3;
				elsif bit24='0' then
					es <= e1;
				else
					es <= e4;
				end if;
			when e4 =>
				if down='0' then
					es <= e4;
				elsif lastaddr='0' then
					es <= e0;
				else
					es <= e5;
				end if;
			when e5 =>
				es <= e5;
		end case;
	end process p_es;
-- almacenamiento de estado presente --------------
	process (clk_50, reset)
	begin
		if (reset='1') then
			ep <= e0;
		elsif (clk_50'event and clk_50='1') then
			ep <= es;
		end if;
	end process;
-- se�ales de control --------------------------------
	inctmp		<= '0' when ep=e5 				else '1';
	settmp		<= '1' when (ep=e0 and down='1')
						 or (ep=e2 and up='1' and i2c_sdat='1')
						 or (ep=e4 and down='1' and lastaddr='0')	else '0';
	setbit0		<= '1' when (ep=e0 and down='1')
						 or (ep=e3 and down='1' and bit24='1')	else '0';
	setbit1		<= '1' when (ep=e4 and down='1')	else '0';
	setbitz		<= '1' when (ep=e2 or ep=e3)	else '0';
	ldbit		<= '1' when (ep=e1 and down='1' and stop='0')
						 or (ep=e3 and down='1' and bit24='0')	else '0';
	incbits		<= '1' when (ep=e1 and down='1' and stop='0')
						 or (ep=e3 and down='1' and bit24='0')	else '0';
	clbits		<= '1' when (ep=e2 and up='1' and i2c_sdat='1')
						 or (ep=e4 and down='1' and lastaddr='0')	else '0';
	claddr		<= '1' when (ep=e2 and up='1' and i2c_sdat='1')
						 or (ep=e4 and down='1' and lastaddr='0')	else '0';
	incaddr		<= '1' when (ep=e4 and down='1' and lastaddr='0')	else '0';
-- ==================================================
-- Unidad de proceso
-- contador de bits -------------------------
	process (clk_50, reset)
	begin
		if (reset='1') then
			cbits <= 0;
		elsif (clk_50'event and clk_50='1') then
			if (incbits='1') then
				cbits <= cbits + 1;
			elsif (clbits='1') then
				cbits <= 0;
			end if;
		end if;
	end process;
	stop <= '1' when cbits=8 or cbits=16 or cbits=24	else '0';
	bit24 <= '1' when cbits=24		else '0';
-- contador de direcciones -------------------------
	process (clk_50, reset)
	begin
		if (reset='1') then
			caddr <= 0;
		elsif (clk_50'event and clk_50='1') then
			if (incaddr='1') then
				caddr <= caddr + 1;
			elsif (claddr='1') then
				caddr <= 0;
			end if;
		end if;
	end process;
	lastaddr <= '1' when caddr=LADDR		else '0';
-- contador de tiempo -------------------------
	process (clk_50, reset)
	begin
		if (reset='1') then
			ctmp <= "10000000";
		elsif (clk_50'event and clk_50='1') then
			if (settmp='1') then
				ctmp <= "10000000";
			elsif (inctmp='1') then
				ctmp <= ctmp + 1;
			end if;
		end if;
	end process;
	i2c_sclk <= ctmp(7);
	up <= '1' when ctmp="01111111"			else '0';
	down <= '1' when ctmp="11111111"		else '0';
-- bit de datos -------------------------
	process (clk_50, reset)
	begin
		if (reset='1') then
			sdat <= '1';
		elsif (clk_50'event and clk_50='1') then
			if (ldbit='1') then
				sdat <= dbit;
			elsif (setbit0='1') then
				sdat <= '0';
			elsif (setbit1='1') then
				sdat <= '1';
			end if;
		end if;
	end process;
	dbit <= dato(cbits);
	i2c_sdat <= sdat when setbitz='0' else 'Z';
-- contador divisor de reloj /4 -------------------------
	process (clk_50, reset)
	begin
		if (reset='1') then
			cclkdiv <= "00";
		elsif (clk_50'event and clk_50='1') then
			cclkdiv <= cclkdiv + 1;
		end if;
	end process;
	aud_xck <= cclkdiv(1);
end a;