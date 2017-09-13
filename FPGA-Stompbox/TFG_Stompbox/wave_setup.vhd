------------------------------------------------------------------------------------------------
--  wave_setup.vhd
------------------------------------------------------------------------------------------------
-- Selector de onda.
-- Configura como va a ser la onda de la amplificacion del tremolo.
------------------------------------------------------------------------------------------------
-- Jose Angel Gumiel
--  04/03/2017
------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_arith.all; --Obsoleta. No permitia hacer la division. El numeric_std la sustituye. DOCUMENTAR.
--use ieee.std_logic_signed.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity wave_setup is
	port(
		--Datos:
		rate	: in std_logic_vector(15 downto 0);
		wave	: in std_logic_vector(1 downto 0);
		atack	: in std_logic_vector(15 downto 0);
		gain	: out std_logic_vector(15 downto 0);
		--Control:
		counter	: in std_logic_vector(18 downto 0); --Se necesita saber en que posicion esta el cl_counter del tremolo.
		LD_Div  : in std_logic;
		clk_Samp: in std_logic; --clk_sample. Necesito saber cuando ha llegado una muestra. En el otro modulo, LD_Sample.
		clk	: in std_logic;
		cl	: in std_logic
	);
end entity wave_setup;

architecture a of wave_setup is

	constant cero	: std_logic_vector(15 downto 0):="0000000000000000";
	--Valores que toma la amplitud
	signal min_gain 	: std_logic_vector(15 downto 0):="0000000010000001"; --Inicializo.
	constant max_gain 	: std_logic_vector(15 downto 0):="0000001111111111";
	--Contador
	signal gain_counter	:std_logic_vector(15 downto 0); --Cociente de la division. Cada cuantos pasos hay que incrementar (sumar uno a) la ganancia.

	--otras:
	signal gain_cl_counter 	:std_logic_vector(7 downto 0);
	signal gain_aux		:std_logic_vector(15 downto 0);
	signal diferencia	:unsigned(15 downto 0);
	signal cociente		:unsigned(15 downto 0);

begin

	--The sensitivity list is a list of signals. A change in value on one or more of these signals, causes the process to be activated: 
	set_amplitude: process(rate, wave, counter, clk, cl)
	begin
		if(cl='1')then
			gain_counter<=cero;
			gain_cl_counter<="00000000";
		elsif(clk'event and clk='1') then
			--Configuro cual va a ser el ataque
			--32767/33
			min_gain<=std_logic_vector(unsigned(atack)/integer(33));
			if (wave="00") then --Onda Cuadrada
				if (counter(15 downto 0)<rate) then
					gain<=min_gain;
				else
					gain<=max_gain;
				end if;
			elsif(wave="01") then --Onda de Sierra
				if(clk_Samp='1')then
					diferencia<=(unsigned(max_gain)-unsigned(min_gain));
					cociente<=unsigned(rate)/diferencia;
					gain_counter<=std_logic_vector(cociente);
					if(counter(15 downto 0)=cero)then
						gain_aux<=min_gain;
					else
						if(gain_cl_counter<gain_counter(7 downto 0)) then
							gain_cl_counter<=gain_cl_counter+'1';
						else
							gain_aux<=gain_aux+'1';
							gain_cl_counter<="00000000";
						end if;
					end if;
					gain<=gain_aux;
				end if;
			elsif(wave="10") then --Onda triangular
				if(clk_Samp='1')then
					diferencia<=(unsigned(max_gain)-unsigned(min_gain));
					cociente<=unsigned(rate)/diferencia;
					gain_counter<=std_logic_vector(cociente);
					if(counter(15 downto 0)=cero)then
						gain_aux<=min_gain;
					elsif (counter(15 downto 0)<rate) then
						if(gain_cl_counter<gain_counter(7 downto 0)) then
							gain_cl_counter<=gain_cl_counter+'1';
						else
							gain_aux<=gain_aux+'1';
							gain_cl_counter<="00000000";
						end if;
					else
						if(gain_cl_counter<gain_counter(7 downto 0)) then
							gain_cl_counter<=gain_cl_counter+'1';
						else
							gain_aux<=gain_aux-'1';
							gain_cl_counter<="00000000";
						end if;
					end if;
					gain<=gain_aux;
				end if;
			else
				gain<="0000000000000000";
			end if;
		end if;	
	end process;

end architecture a;
