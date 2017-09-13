---------------------
--  au_in.vhd
---------------------
--	transforma los datos serie que vienen del codec WM8731 en 
--	muestras de 16 bits  
--	Se supone que el codec está configurado para trabajar en modo master,
--  y con formato "justificado a izquierda"
--	Se lee sólo el canal izquierdo
-------------------------------------------------------
--	Andoni Arruti
--  28/10/2011
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity au_in is
	port (
		clk, reset		: in	std_logic;
		adclrc			: in	std_logic;
		bclk			: in	std_logic;
		adcdat			: in	std_logic;
		sample			: out	std_logic_vector(15 downto 0);
		ready			: out	std_logic	);
end au_in;

architecture a of au_in is
-- estados presente y siguiente de uc
	type estado is (e0, e1, e2, e3, e4, e5);
	signal ep, es	: estado;
-- registro de desplazamiento
	signal srdato 	: std_logic_vector(15 downto 0);
	signal desplaza	: std_logic;
-- contador de bits
	signal cbits 	: integer range 0 to 15;
	signal incbits	: std_logic;
	signal ultimo	: std_logic;
-- entradas sincronizadas 
	signal adclrcs	: std_logic;
	signal bclks	: std_logic;
	signal adcdats	: std_logic;

	
begin
-- ==================================================
-- Unidad de control
-- calculo de estado siguiente -------------------------
	process (ep, adclrcs, bclks, ultimo)
	begin
		case ep is
			when e0 =>
				if adclrcs='0' 	then				es <= e1;
				else								es <= e0;
				end if;
			when e1 =>
				if adclrcs='1' and bclks='0' 	then	es <= e2;
				else								es <= e1;
				end if;
			when e2 =>
				if bclks='1' 	then				es <= e3;
				else								es <= e2;
				end if;
			when e3 =>
				if ultimo='0' 	then				es <= e4;
				else								es <= e5;
				end if;
			when e4 =>
				if bclks='0' 	then				es <= e2;
				else								es <= e4;
				end if;
			when e5 =>
													es <= e0;
		end case;
	end process;
-- almacenamiento de estado presente --------------
	process (clk, reset)
	begin
		if (reset='1') then
			ep <= e0;
		elsif (clk'event and clk='1') then
			ep <= es;
		end if;
	end process;
-- se�ales de control --------------------------------
	desplaza	<= '1' when ep=e3 				else '0';
	incbits		<= '1' when ep=e3 				else '0';
	ready		<= '1' when ep=e5 				else '0';
-- ==================================================
-- Unidad de proceso
-- registro de desplazamiento -------------------------
	process (clk, reset)
	begin
		if (reset='1') then
			srdato <= "0000000000000000";
		elsif (clk'event and clk='1') then
			if (desplaza='1') then
				srdato <= srdato(14 downto 0) & adcdats;
			end if;
		end if;
	end process;
	sample <= srdato;
-- contador de bits -------------------------
	process (clk, reset)
	begin
		if (reset='1') then
			cbits <= 0;
		elsif (clk'event and clk='1') then
			if (incbits='1') then
				cbits <= cbits + 1;
			end if;
		end if;
	end process;
	ultimo	<= '1' when cbits=15		else '0';
-- sincronización de entradas ----------------
	process (clk, reset)
	begin
		if (reset='1') then
			adclrcs <= '0';
			bclks <= '0';
			adcdats <= '0';
		elsif (clk'event and clk='1') then
			adclrcs <= adclrc;
			bclks <= bclk;
			adcdats <= adcdat;
		end if;
	end process;
end a;