	component nios_audio_system is
		port (
			adc_ready_export    : in  std_logic                     := 'X';             -- export
			audio_in_export     : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
			audio_out_export    : out std_logic_vector(15 downto 0);                    -- export
			channel0_export     : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
			channel1_export     : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
			clk_clk             : in  std_logic                     := 'X';             -- clk
			reset_reset_n       : in  std_logic                     := 'X';             -- reset_n
			sample_ready_export : in  std_logic                     := 'X'              -- export
		);
	end component nios_audio_system;

	u0 : component nios_audio_system
		port map (
			adc_ready_export    => CONNECTED_TO_adc_ready_export,    --    adc_ready.export
			audio_in_export     => CONNECTED_TO_audio_in_export,     --     audio_in.export
			audio_out_export    => CONNECTED_TO_audio_out_export,    --    audio_out.export
			channel0_export     => CONNECTED_TO_channel0_export,     --     channel0.export
			channel1_export     => CONNECTED_TO_channel1_export,     --     channel1.export
			clk_clk             => CONNECTED_TO_clk_clk,             --          clk.clk
			reset_reset_n       => CONNECTED_TO_reset_reset_n,       --        reset.reset_n
			sample_ready_export => CONNECTED_TO_sample_ready_export  -- sample_ready.export
		);

