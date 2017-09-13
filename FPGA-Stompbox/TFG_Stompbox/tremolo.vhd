------------------------------------------------------------------------------------------------
--  tremolo.vhd
------------------------------------------------------------------------------------------------
-- Etapa de amplificacion limpia.
-- Dado un valor parametrizado multiplica la senal de entrada y retorna dicha senal amplificada.
-- Se descartan los 9 bits mas significativos despues del signo para controlar la ganancia.
------------------------------------------------------------------------------------------------
-- Jose Angel Gumiel
--  11/02/2017
------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity tremolo is
	port(
		--Datos:
		sample_in  : in std_logic_vector(15 downto 0);
		sample_out : out std_logic_vector(15 downto 0);
		LD_Sample  : in std_logic;
		clk 	   : in std_logic;
		cl	   : in std_logic;
		--Parametros:
		rate 	: in std_logic_vector(15 downto 0);--Velocidad del tremolo
		atack 	: in std_logic_vector(15 downto 0);--Como va a ser la diferencia entre la amplitud minima y la maxima.
		wave 	: in std_logic_vector(1 downto 0)  --Forma de la onda. Seno, cuadrada, triangular?
	);
end entity tremolo;


architecture a of tremolo is

	component wave_setup
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
	end component;

	component booster
		port (
			sample_in : in	std_logic_vector(15 downto 0);
			multiplier : in	std_logic_vector(15 downto 0);
			sample_out : out std_logic_vector(15 downto 0)
		);
	end component;

	signal amplitude 	: std_logic_vector(15 downto 0);
	signal cls_counter	: std_logic_vector(18 downto 0);
	signal doble		: std_logic_vector(18 downto 0);
	constant mult_por_dos	: std_logic_vector(2 downto 0):="010"; --Multiplicador por dos, ya que no puedo dividir.
	constant cero	 	: std_logic_vector(18 downto 0):="0000000000000000000";
	--Valores que toma la amplitud
	constant low_gain 	: std_logic_vector(15 downto 0):="0000000010000001";
	constant high_gain 	: std_logic_vector(15 downto 0):="0000001111111111";
	--Valores que toma la frecuencia
	signal ratio 		: std_logic_vector(15 downto 0);--El valor que almaceno de lo que llega del ADC (Pot)
	signal ataque 		: std_logic_vector(15 downto 0);--El valor que almaceno de lo que llega del ADC (Pot)
	constant max_freq 	: std_logic_vector(15 downto 0):="0000100101100000"; --10Hz (Subida y bajada en 100ms)
	constant min_freq 	: std_logic_vector(15 downto 0):="0100011001010000"; --1.5Hz
	--Cuando empieza el ciclo?
	signal LD_Div		: std_logic;

begin
	--Quiero definir un ratio minimo y maximo. El ratio SOLO quiero que se actualice cuando haya terminado de contar.
	ratio<= max_freq when (rate<max_freq and cls_counter=cero) else --10Hz
		min_freq when (rate>min_freq and cls_counter=cero) else --1.5Hz
		rate when (cls_counter=cero);

	--Lo mismo para el ataque. Solo quiero que se actualice en cada ciclo.
	ataque<= atack when (cls_counter=cero);

	tremolo: process(clk)
	begin
		doble<=signed(ratio)*signed(mult_por_dos);
		if(cl='1')then
			cls_counter<=cero;
		elsif(clk'event and clk='1') then
			if(LD_Sample='1') then
				if (cls_counter=doble)then
					cls_counter<=cero;
					LD_Div<='1'; --Para llamar a la division
				else
					cls_counter<=cls_counter+'1';
					LD_Div<='0';
				end if;
			end if;
		end if;
	end process;

	
	--s0	Instanciar un componente que me diga que amplitud usar.
	s0 : wave_setup
		port map (	rate 	=> ratio,
				wave 	=> wave,
				atack	=> ataque,
				gain 	=> amplitude,
				counter => cls_counter,
				LD_Div 	=> LD_Div,
				clk_Samp=> LD_Sample,
				clk	=> clk,
				cl	=> cl
			);

	s1 : booster
		port map (	sample_in => sample_in,
				multiplier => amplitude,
				sample_out => sample_out 	
		);

end architecture a;