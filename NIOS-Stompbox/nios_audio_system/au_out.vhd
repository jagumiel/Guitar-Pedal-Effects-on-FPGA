---------------------
--  au_out.vhd
---------------------
--	envia una muestra de 16 bits al codec por la linea serie
--	Se supone que el codec está configurado para trabajar en modo master,
--  y con formato "justificado a izquierda"
--	Se envia la misma muestra por los dos canales
-------------------------------------------------------
--	Andoni Arruti
--  30/10/2011
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity au_out is
	port (
		clk, reset	: in	std_logic;
		daclrc		: in	std_logic;
		bclk		: in	std_logic;
		sample		: in	std_logic_vector(15 downto 0);
		dacdat		: out	std_logic;
		ready		: out	std_logic	);
end au_out;

architecture a of au_out is
-- estados presente y siguiente de uc
	type estado is (e0, e1, e2, e3, e4, e5, e6);
	signal ep, es	: estado;
-- registro de desplazamiento
	signal srdato 	: std_logic_vector(16 downto 0);
	signal lddato	: std_logic;
	signal desplaza	: std_logic;
-- contador de bits
	signal cbits 	: integer range 0 to 15;
	signal incbits	: std_logic;
	signal ultimo	: std_logic;
-- entradas sincronizadas 
	signal daclrcs	: std_logic;
	signal bclks	: std_logic;
	
begin
-- ==================================================
-- Unidad de control
-- calculo de estado siguiente -------------------------
	process (ep, daclrcs, bclks, ultimo)
	begin
		case ep is
			when e0 =>
				if daclrcs='1' and bclks='0' 	then	es <= e1;
				else								es <= e0;
				end if;
			when e1 =>
													es <= e2;
			when e2 =>
				if bclks='1' 	then				es <= e3;
				else								es <= e2;
				end if;
			when e3 =>
				if bclks='0' 	then				es <= e4;
				else								es <= e3;
				end if;
			when e4 =>
				if ultimo='0' 	then				es <= e2;
				elsif daclrcs='0' then				es <= e0;
				else								es <= e5;
				end if;
			when e5 =>
				if daclrcs='0' and bclks='0' 	then	es <= e6;
				else								es <= e5;
				end if;
			when e6 =>
													es <= e2;
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
	lddato		<= '1' when ep=e1 					else '0';
	desplaza	<= '1' when ep=e4 or ep=e6 			else '0';
	incbits		<= '1' when ep=e4 					else '0';
	ready	<= '1' when ep=e1 					else '0';
-- ==================================================
-- Unidad de proceso
-- registro de desplazamiento -------------------------
	process (clk, reset)
	begin
		if (reset='1') then
			srdato <= "00000000000000000";
		elsif (clk'event and clk='1') then
			if (lddato='1') then
				srdato <= sample & '0';
			elsif (desplaza='1') then
				srdato <= srdato(15 downto 0) & srdato(16);
			end if;
		end if;
	end process;
	dacdat <= srdato(16);
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
			daclrcs <= '0';
			bclks <= '0';
		elsif (clk'event and clk='1') then
			daclrcs <= daclrc;
			bclks <= bclk;
		end if;
	end process;
end a;