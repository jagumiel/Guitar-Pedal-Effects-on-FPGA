
module nios_audio_system (
	audio_in_export,
	audio_out_export,
	channel1_export,
	clk_clk,
	reset_reset_n,
	sample_ready_export,
	channel2_export);	

	input	[15:0]	audio_in_export;
	output	[15:0]	audio_out_export;
	output	[15:0]	channel1_export;
	input		clk_clk;
	input		reset_reset_n;
	input		sample_ready_export;
	output	[15:0]	channel2_export;
endmodule
