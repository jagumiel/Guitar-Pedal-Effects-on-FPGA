library ieee;
use ieee.std_logic_1164.all;
USE ieee.NUMERIC_STD.all;
use ieee.std_logic_signed.all;

entity testaudio_DE1SoC is 
 port(		CLOCK_50 	:  in  std_logic;
		KEY 		:  in  std_logic_vector(0 downto 0);
		--====AUDIO====--
		AUD_XCK 	:  out std_logic;
		AUD_BCLK 	:  in  std_logic;
		AUD_ADCLRCK 	:  in  std_logic;
		AUD_DACLRCK 	:  in  std_logic;
		AUD_ADCDAT 	:  in  std_logic;
		AUD_DACDAT 	:  out std_logic;
		FPGA_I2C_SCLK 	:  out std_logic;
		FPGA_I2C_SDAT 	:  inout  std_logic;
		--====ADC====--
		SW 		: in  std_logic_vector(9 downto 0); -- canal a visulizar en LEDR
		LEDR 		: out  std_logic_vector(9 downto 0);
		ADC_SCLK  	: out std_logic;
		ADC_CS_N  	: out std_logic;
		ADC_DOUT  	: in  std_logic;
		ADC_DIN	 	: out std_logic;
		--====HEXADECIMAL====--
		HEX0 : OUT STD_LOGIC_VECTOR(0 TO 6);
		HEX1 : OUT STD_LOGIC_VECTOR(0 TO 6);
		HEX2 : OUT STD_LOGIC_VECTOR(0 TO 6);
		HEX3 : OUT STD_LOGIC_VECTOR(0 TO 6);
		HEX4 : OUT STD_LOGIC_VECTOR(0 TO 6);
		HEX5 : OUT STD_LOGIC_VECTOR(0 TO 6)	);
end testaudio_DE1SoC;

architecture a of testaudio_DE1SoC is 

	component au_setup
	 generic	(
			SAMPLE_RATE	: integer range 1 to 3 );
	 port(	reset 	 : in std_logic;
		clk_50	 : in std_logic;
		mic_lin	 : in std_logic;
		i2c_sdat : inout std_logic;
		i2c_sclk : out std_logic;
		aud_xck	 : out std_logic	);
	end component;

	component au_in
	 port (
			clk, reset : in	std_logic;
			adclrc 	: in	std_logic;
			bclk 	: in	std_logic;
			adcdat 	: in	std_logic;
			sample 	: out	std_logic_vector(15 downto 0);
			ready 	: out	std_logic	);
	end component;

	component au_out
	 port (
			clk, reset : in	std_logic;
			daclrc	: in	std_logic;
			bclk 	: in	std_logic;
			sample 	: in	std_logic_vector(15 downto 0);
			dacdat 	: out	std_logic;
			ready	: out	std_logic	);
	end component;

	
	component AD7928_cyclic is
	 generic	(
		CH_NUMBER 	: natural range 1 to 8 := 8;
		CLK_DIVBIT 	: natural range 1 to 11 := 11;
		SAMPLE_CYCLES 	: natural range 1 to 1000000 := 1	);
	 port (
			reset: in std_logic;
			clk	: in std_logic;
			dout	: in std_logic;
			cs_n	: out std_logic;
			sclk	: out std_logic;
			din	: out std_logic;
			ch0	: out std_logic_vector(11 downto 0);
			ch1	: out std_logic_vector(11 downto 0);
			ch2	: out std_logic_vector(11 downto 0);
			ch3	: out std_logic_vector(11 downto 0);
			ch4	: out std_logic_vector(11 downto 0);
			ch5	: out std_logic_vector(11 downto 0);
			ch6	: out std_logic_vector(11 downto 0);
			ch7	: out std_logic_vector(11 downto 0);
			ready	: out std_logic	);
	end component;

	component booster
	 port (
			sample_in : in	std_logic_vector(15 downto 0);
			multiplier : in	std_logic_vector(15 downto 0);
			sample_out : out std_logic_vector(15 downto 0)
		);
	end component;

	component distortion
	 port (
			sample_in : in	std_logic_vector(15 downto 0);
			dist_pos : in	std_logic_vector(15 downto 0);
			gain : in	std_logic_vector(15 downto 0);
			sample_out : out std_logic_vector(15 downto 0)
		);
	end component;

	component tremolo
	 port (
			sample_in  : in	std_logic_vector(15 downto 0);
			sample_out : out std_logic_vector(15 downto 0);
			LD_Sample  : in std_logic;
			clk 	   : in std_logic;
			cl 	   : in std_logic;
			--Parametros:
			rate 	: in std_logic_vector(15 downto 0); --Velocidad del tremolo
			atack 	: in std_logic_vector(15 downto 0);--Define el corte Brusco o suave?
			wave 	: in std_logic_vector(1 downto 0)  --Forma de la onda. Seno, cuadrada, triangular?
		);
	end component;


	component overdrive
	 port (
			sample_in : in	std_logic_vector(15 downto 0);
			dist_pos : in	std_logic_vector(15 downto 0);
			gain : in	std_logic_vector(15 downto 0);
			sample_out : out std_logic_vector(15 downto 0)
		);
	end component;

	--AUDIO SIGNALS
	signal reset 	  : std_logic;
	signal in_ready   : std_logic;
	signal out_ready  : std_logic;
	signal sample_in  : std_logic_vector(15 downto 0);
	signal sample_od : std_logic_vector(15 downto 0);
	signal sample_dis : std_logic_vector(15 downto 0);
	signal sample_trm : std_logic_vector(15 downto 0);
	signal sample_out : std_logic_vector(15 downto 0);
	--boost/dist
	signal multiplier : std_logic_vector(15 downto 0);
	signal pot_distor : std_logic_vector(15 downto 0);
	--ADC SIGNALS
	signal ready 		:  std_logic;
	signal ch0, ch1, ch2, ch3 	:  std_logic_vector(11 downto 0);
	--TREMOLO FX SIGNALS
	signal velocidad, ataque: std_logic_vector(15 downto 0);
	signal onda	  	: std_logic_vector(1 downto 0);

begin 
	
	reset <= not(KEY(0));
	
	inst1: au_setup
		generic map	(SAMPLE_RATE => 3)
		port map(	reset => reset,
				clk_50 => CLOCK_50,
				mic_lin	=> '0',
				i2c_sdat => FPGA_I2C_SDAT,
				i2c_sclk => FPGA_I2C_SCLK,
				aud_xck => AUD_XCK	);
	
	inst2: au_in
		port map(	reset => reset,
				clk => CLOCK_50,
				adclrc	=> AUD_ADCLRCK,
				bclk => AUD_BCLK,
				adcdat => AUD_ADCDAT,
				sample => sample_in,
				ready => in_ready	);
	
	inst3: au_out
		port map(	reset => reset,
				clk => CLOCK_50,
				daclrc	=> AUD_DACLRCK,
				bclk => AUD_BCLK,
				sample => sample_out,
				dacdat => AUD_DACDAT,
				ready => out_ready	);


	inst4 : AD7928_cyclic
		generic map(
			CH_NUMBER 	=> 3,
			CLK_DIVBIT 	=> 11,
			SAMPLE_CYCLES 	=> 1)
		port map (	reset 	=> reset,
				clk 	=> CLOCK_50,
				dout  	=> ADC_DOUT,
				cs_n  	=> ADC_CS_N,
				sclk 	=> ADC_SCLK,
				din 	=> ADC_DIN,
				ch0  	=> ch0, --Volumen
				ch1  	=> ch1, --Distorsion
				ch2  	=> ch2, --Velocidad
				ch3	=>	ch3, --Ataque
				ready  	=> ready 	);



-------------Varlores potenciometros-------------

		multiplier<=std_logic_vector(resize(signed('0' & ch0(11 downto 4) & "000"),16));
		pot_distor<=std_logic_vector(resize(signed('0' & ch1(11 downto 4) & "000"),16));
		velocidad <= std_logic_vector(signed('0' & ch2(11 downto 4)& "0000000"));
		ataque <= std_logic_vector(signed('0' & ch3(11 downto 4)& "0000000"));

-------------DISTOR-------------
		LEDR <= "00" & ch0(11 downto 4);
		--Texto: Dist
		HEX5<="0000001";
		HEX4<="1111001";
		HEX3<="0100100";
		HEX2<="1110000";
		HEX1<="1111111";
		HEX0<="1111111";
		multiplier<=std_logic_vector(resize(signed('0' & ch0(11 downto 4) & "000"),16));
		pot_distor<=std_logic_vector(resize(signed('0' & ch1(11 downto 4) & "000"),16));
		inst5 : distortion
		port map (	
				sample_in => sample_in,
				gain => multiplier,
				dist_pos => pot_distor,
				sample_out => sample_out 	
		);


END a;