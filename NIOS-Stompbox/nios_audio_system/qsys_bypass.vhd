-- Implements a simple Nios II system for the DE-series board.
-- Inputs: SW7ยก0 are parallel port inputs to the Nios II system
-- CLOCK_50 is the system clock
-- KEY0 is the active-low system reset
-- Outputs:LEDG7ยก0 are parallel port outputs from the Nios II system


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY qsys_bypass IS

PORT (
	CLOCK_50 : IN STD_LOGIC;
	--====LEDs & Switches====--
	KEY : IN STD_LOGIC_VECTOR (0 DOWNTO 0);
	SW : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
	LEDG : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
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
	--SW 		: in  std_logic_vector(2 downto 0); -- canal a visulizar en LEDR
	--LEDR 		: out  std_logic_vector(9 downto 0);
	ADC_SCLK  	: out std_logic;
	ADC_CS_N  	: out std_logic;
	ADC_DOUT  	: in  std_logic;
	ADC_DIN	 	: out std_logic
	);
END qsys_bypass;

ARCHITECTURE bypass_rtl OF qsys_bypass IS
	COMPONENT nios_audio_system
		PORT (
			SIGNAL clk_clk: IN STD_LOGIC;
			SIGNAL reset_reset_n : IN STD_LOGIC;
			SIGNAL audio_in_export : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			SIGNAL audio_out_export : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
			SIGNAL sample_ready_export : IN STD_LOGIC;
			SIGNAL channel0_export : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			SIGNAL channel1_export : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			SIGNAL adc_ready_export : IN STD_LOGIC
		);
	END COMPONENT;
	
	--Declaro los componentes que voy a utilizar:
	component au_setup generic	(
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
	
	component AD7928_cyclic generic (
		CH_NUMBER : natural range 1 to 8 := 8;
		CLK_DIVBIT : natural range 1 to 11 := 11;
		SAMPLE_CYCLES : natural range 1 to 1000000 := 1	);
	port (
		reset		: in std_logic;
		clk		: in std_logic;
		dout		: in std_logic;
		cs_n		: out std_logic;
		sclk		: out std_logic;
		din		: out std_logic;
		ch0		: out std_logic_vector(11 downto 0);
		ch1		: out std_logic_vector(11 downto 0);
		ch2		: out std_logic_vector(11 downto 0);
		ch3		: out std_logic_vector(11 downto 0);
		ch4		: out std_logic_vector(11 downto 0);
		ch5		: out std_logic_vector(11 downto 0);
		ch6		: out std_logic_vector(11 downto 0);
		ch7		: out std_logic_vector(11 downto 0);
		ready		: out std_logic	);
	end component;
	
	--AUDIO SIGNALS
	signal reset 	   : std_logic;
	signal in_ready   : std_logic;
	signal out_ready  : std_logic;
	signal sample_in  : std_logic_vector(15 downto 0);
	signal sample_out : std_logic_vector(15 downto 0);
	--ADC SIGNALS
	signal adc_rdy		: std_logic;
	signal chan0		: std_logic_vector(11 downto 0);
	signal chan1		: std_logic_vector(11 downto 0);
	signal chan0_16	: std_logic_vector(15 downto 0);
	signal chan1_16	: std_logic_vector(15 downto 0);
	

	
	BEGIN
	
	reset <= not(KEY(0));
	
	ConfCodec: au_setup
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
				
	NiosII : nios_audio_system
		PORT MAP(
			clk_clk=>CLOCK_50,
			reset_reset_n=>KEY(0),
			audio_in_export=>sample_in(15 DOWNTO 0),
			audio_out_export=>sample_out(15 DOWNTO 0),
			sample_ready_export=>in_ready,
			channel0_export=>chan0_16,
			channel1_export=>chan1_16,
			adc_ready_export=>adc_rdy
		);
	
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
				ch0  	=> chan0, --Volume
				ch1  	=> chan1, --Distorsion
				ready  	=> adc_rdy 	);
			
		chan0_16 <= "0000" & chan0(11 downto 4) & "0000";
		chan1_16 <= "0000" & chan1;
	
	
END bypass_rtl;