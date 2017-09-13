---------------------
--  AD7928_cyclic.vhd
---------------------
-- Configura el convertidor AD7928 de la placa DE1-SoC para capturar 
-- secuencialmente los primeros CH_NUMBER canales (Rango 0-5V, "Power mode" normal)
-- y los captura de forma periodica.
-- El reloj de convertidor SCLK se genera dividiendo la frecuencia del reloj CLK 
-- por 2^(CLK_DIVBIT+1)
-- El periodo de muestreo es SAMPLE_CYCLES, medido en ciclos de SCLK, es decir:
--		Tsample = Tclk*2^(CLK_DIVBIT+1)*SAMPLE_CYCLES
-------------------------------------------------------
--	Andoni Arruti
--  25/11/2016
--------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AD7928_cyclic is
  generic	(
    CH_NUMBER : natural range 1 to 8 := 8;
    CLK_DIVBIT : natural range 1 to 11 := 11;
    SAMPLE_CYCLES : natural range 1 to 1000000 := 1	);
  port (
    reset	: in std_logic;
    clk		: in std_logic;
    dout	: in std_logic;
    cs_n	: out std_logic;
    sclk	: out std_logic;
    din		: out std_logic;
    ch0		: out std_logic_vector(11 downto 0);
    ch1		: out std_logic_vector(11 downto 0);
    ch2		: out std_logic_vector(11 downto 0);
    ch3		: out std_logic_vector(11 downto 0);
    ch4		: out std_logic_vector(11 downto 0);
    ch5		: out std_logic_vector(11 downto 0);
    ch6		: out std_logic_vector(11 downto 0);
    ch7		: out std_logic_vector(11 downto 0);
    ready	: out std_logic	);
end AD7928_cyclic;

architecture a of AD7928_cyclic is
-- divisor de frecuencia
  signal clkdiv		: unsigned(CLK_DIVBIT downto 0);
  signal s_clk			: std_logic;
-- estados presente y siguiente de uc
  type estado is (conf0, conf1, idle, rd0, rd1, save, sready);
  signal ep, es		: estado;
-- registro de desplazamiento din
  signal sr_din 	: std_logic_vector(15 downto 0);
  signal wr_din		: std_logic;
  signal ld_cmd		: std_logic;
-- tabla de comandos y contador
  constant LAST_AD : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned(CH_NUMBER-1, 3));
  type LUT4x16 is array (0 to 2) of std_logic_vector(15 downto 0);
  constant CMD : LUT4x16 := (
			"1111111111111111",						-- dummy
			"1111111111111111",						-- dummy
			"110" & LAST_AD & "1110010000"	);	-- activar
  signal cmd_addr	: integer range 0 to 3;
  signal inc_addr : std_logic;
  signal conf_end : std_logic;
-- registro de desplazamiento dout
  signal sr_dout 	: std_logic_vector(14 downto 0);
  signal rd_dout	: std_logic;
-- banco de registros para canales
  type ch_array is array (integer range <>) of std_logic_vector(11 downto 0);
  signal ch			: ch_array(0 to 7);
  signal ch_on		: ch_array(0 to CH_NUMBER-1);
  signal ch_addr	: integer range 0 to CH_NUMBER-1;
  signal ch_dat	: std_logic_vector(11 downto 0);
  signal ld_ch		: std_logic;
  signal last_ch	: std_logic;
-- generacion CS
  signal cs		: std_logic;
-- contador de ciclos SCLK
  signal cs_cycle		: unsigned(3 downto 0);
  signal cyc_15 	: std_logic;
  signal cyc_14 	: std_logic;
  signal avg_counter : unsigned(3 downto 0); --Average counter, para la media aritm.
-- contador de ciclos para periodo de muestreo
  signal sclk_cycle	: integer range 0 to SAMPLE_CYCLES - 1;
  signal sample	 	: std_logic;
begin
-- ==================================================
-- generación sclk con divisor de frecuencia
	process(clk, reset)
	begin
		if reset = '1' then
			clkdiv <= (others => '0');
		elsif (clk'event and clk = '1') then
			clkdiv <= clkdiv + 1;
		end if;
	end process;
	s_clk <= clkdiv(CLK_DIVBIT);
	sclk <= s_clk;
-- ==================================================
-- unidad de control
-- calculo de estado siguiente -------------------------
  p_es: process (ep, cyc_14, cyc_15, conf_end, sample, last_ch)
  begin
    case ep is
      when conf0 =>					es <= conf1;
      when conf1 =>
        if cyc_15='0' then			es <= conf1;
        elsif conf_end='0'	then	es <= conf0;
        else 							es <= idle;
       end if;
      when idle =>
        if sample='0' then			es <= idle;
        else							es <= rd0;
        end if;
      when rd0 =>						es <= rd1;
      when rd1 =>
        if cyc_14='0' then			es <= rd1;
        else							es <= save;
        end if;
      when save =>
        if last_ch='0' then		es <= rd0;
        else							es <= sready;
        end if;
      when sready =>					es <= idle;
    end case;
  end process p_es;
-- almacenamiento de estado presente --------------
  p_ep: process (s_clk, reset)
  begin
    if (reset='1') then
      ep <= conf0;
    elsif (s_clk'event and s_clk='1') then
      ep <= es;
    end if;
  end process p_ep;
-- senales de control --------------------------------
  ld_cmd <= '1' when (ep=conf0)								else '0';
  inc_addr <= '1' when (ep=conf0)							else '0';
  cs <= '1' when (ep=conf1) or (ep=rd1) or (ep=save) 	else '0';
  wr_din <= '1' when (ep=conf1)								else '0';
  rd_dout <= '1' when (ep=rd1)								else '0';
  ld_ch <= '1' when (ep=save)									else '0';
  ready <= '1' when (ep=sready)								else '0';
-- ==================================================
-- unidad de proceso
-- contador de direcciones para tabla de comandos
	process (s_clk, reset)
	begin
		if (reset='1') then
			cmd_addr <= 0;
		elsif (s_clk'event and s_clk='1') then
			if inc_addr = '1' then
				cmd_addr <= cmd_addr + 1;
			end if;
		end if;
	end process;
	conf_end <= '1' when cmd_addr = 3 else '0';
-- registro de desplazamiento din -------------------------
	process (s_clk, reset)
	begin
		if (reset='1') then
			sr_din <= (others => '0');
		elsif (s_clk'event and s_clk='1') then
			if (ld_cmd='1') then
				sr_din <= CMD(cmd_addr);
			elsif (wr_din='1') then
				sr_din <= sr_din(14 downto 0) & '0';
			end if;
		end if;
	end process;
	din <= sr_din(15);
-- registro de desplazamiento dout -------------------------
	process (s_clk, reset)
	begin
		if (reset='1') then
			sr_dout <= (others => '0');
		elsif (s_clk'event and s_clk='1') then
			if (rd_dout='1') then
				sr_dout <= sr_dout(13 downto 0) & dout;
			end if;
		end if;
	end process;
-- banco de registros para canales -------------------------
	ch_addr <= to_integer(unsigned(sr_dout(14 downto 12)));
	ch_dat <= sr_dout(11 downto 0);
	process (s_clk, reset)
	begin
		if (reset='1') then
			ch_on <= (others => x"000");
		elsif (s_clk'event and s_clk='1') then
			if ld_ch = '1' then
				--Media Aritmetica
				--if (avg_counter="1111") then
					--ch_dat<= std_logic_vector(unsigned(ch_dat)/unsigned(avg_counter));
					--ch_on(ch_addr) <= ch_dat;
					--avg_counter<="0000";
				--else
					--Hay que usar otro vector mas grande.
					--ch_dat<=std_logic_vector( unsigned(ch_dat) + unsigned(ch_dat));
					--avg_counter<=avg_counter+1;
				--end if;
				ch_on(ch_addr) <= ch_dat;
			end if;
		end if;
	end process;
	ch(0 to CH_NUMBER-1) <= ch_on;
	ch(CH_NUMBER to 7) <= (others => x"000");
	last_ch <= '1' when ch_addr = CH_NUMBER-1 else '0';
-- salidas de canales --------------------------
	ch0 <= ch(0);
	ch1 <= ch(1);
	ch2 <= ch(2);
	ch3 <= ch(3);
	ch4 <= ch(4);
	ch5 <= ch(5);
	ch6 <= ch(6);
	ch7 <= ch(7);
-- cambio logica CS ----------------------
	cs_n <= not cs;
-- contador de ciclos SCLK -------------------------
	process (s_clk, reset)
	begin
		if (reset='1') then
			cs_cycle <= (others => '0');
		elsif (s_clk'event and s_clk='1') then
			if cs = '1' then
				cs_cycle <= cs_cycle + 1;
			end if;
		end if;
	end process;
	cyc_15 <= '1' when cs_cycle = "1111" else '0';
	cyc_14 <= '1' when cs_cycle = "1110" else '0';
-- contador de ciclos para periodo de muestreo ----------
	process (s_clk, reset)
	begin
		if (reset='1') then
			sclk_cycle <= 0;
		elsif (s_clk'event and s_clk='1') then
			if sclk_cycle = SAMPLE_CYCLES - 1 then
				sclk_cycle <= 0;
			else
				sclk_cycle <= sclk_cycle + 1;
			end if;
		end if;
	end process;
	sample <= '1' when sclk_cycle = SAMPLE_CYCLES - 1 else '0';
end a;