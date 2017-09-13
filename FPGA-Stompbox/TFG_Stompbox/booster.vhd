------------------------------------------------------------------------------------------------
--  booster.vhd
------------------------------------------------------------------------------------------------
-- Etapa de amplificacion limpia.
-- Dado un valor parametrizado multiplica la senal de entrada y retorna dicha senal amplificada.
-- Se descartan los 9 bits mas significativos despues del signo para controlar la ganancia.
------------------------------------------------------------------------------------------------
-- Jose Angel Gumiel
--  25/11/2016
------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity booster is
	port(
		--Datos:
		sample_in  : in std_logic_vector(15 downto 0);
		sample_out : out std_logic_vector(15 downto 0);
		--Parametros:
		multiplier : in std_logic_vector(15 downto 0)
	);
end entity booster;

architecture a of booster is
	signal signal_unnormalized: std_logic_vector(31 downto 0);
	begin
		
		signal_unnormalized<=signed(sample_in)*signed(multiplier);
		boost: process(signal_unnormalized)
		begin
			if (signal_unnormalized(31) = '1') then --resultado negativo
				sample_out <= '1' & signal_unnormalized(22 downto 8);
			else --resultado positivo
				sample_out <= '0' & signal_unnormalized(22 downto 8);
			end if;
	end process;
	
end architecture a;