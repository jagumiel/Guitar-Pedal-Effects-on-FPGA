	nios_audio_system u0 (
		.audio_in_export     (<connected-to-audio_in_export>),     //     audio_in.export
		.audio_out_export    (<connected-to-audio_out_export>),    //    audio_out.export
		.channel1_export     (<connected-to-channel1_export>),     //     channel1.export
		.clk_clk             (<connected-to-clk_clk>),             //          clk.clk
		.reset_reset_n       (<connected-to-reset_reset_n>),       //        reset.reset_n
		.sample_ready_export (<connected-to-sample_ready_export>), // sample_ready.export
		.channel2_export     (<connected-to-channel2_export>)      //     channel2.export
	);

