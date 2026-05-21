/*-------------------------------------------------------------------------------------------------------------------
-- 
-- 
-- #       #######                                                 #                                               
-- #                                                               #                                               
-- #                                                               #                                               
-- ############### ############### ############### ############### ############### ############### ############### 
-- #             #               # #                             # #             #               # #               
-- #             # ############### #               ############### #             # ############### ############### 
-- #             # #             # #               #             # #             # #             #               # 
-- #             # ############### #               ############### ############### ############### ############### 
--                                                                                                                 
--         ####### ####### ####### #######                                         ############### ############### 
--                                                                                 #               #             # 
--                                                                                 #   ########### #             # 
--                                                                                 #             # #             # 
-- https://github.com/andykarpov/karabas-go                                        ############### ############### 
--
-- FPGA VT100 core for Karabas-Go Mini
--
-- @author Pavel Tsybulin, 2026
-- @author Andy Karpov <andy.karpov@gmail.com>
-- EU, 2026
------------------------------------------------------------------------------------------------------------------*/

`timescale 1ns / 1ps
`default_nettype none

module karabas_minig_top (
	//------------------ global clock --------
	input wire 				CLK_50MHZ,

	//------------------ esp8266 uart --------
	inout wire 				UART_RX,
	inout wire 				UART_TX,
	inout wire 				UART_CTS,

	//------------------ sram ----------------
	output wire [20:0] 	MA,
	inout wire [15:0] 	MD,
	output wire [1:0] 	MWR_N,
	output wire [1:0] 	MRD_N,

	//------------------ sdram ---------------
	output wire [1:0] 	SDR_BA,
	output wire [12:0] 	SDR_A,
	output wire 			SDR_CLK,
	output wire [1:0] 	SDR_DQM,
	output wire 			SDR_WE_N,
	output wire 			SDR_CAS_N,
	output wire 			SDR_RAS_N,
	inout wire [15:0] 	SDR_DQ,

	//------------------ sd2 -----------------
	output wire 			SD_CS_N,
	output wire 			SD_CLK,
	inout wire 				SD_DI,
	inout wire 				SD_DO,
	input wire 				SD_DET_N,

	//------------------ ft812 rgb + sync ----
	input wire [7:0] 		VGA_R,
	input wire [7:0] 		VGA_G,
	input wire [7:0] 		VGA_B,
	input wire 				VGA_HS,
	input wire 				VGA_VS,

	//------------------ dvi / hdmi ----------
	output wire [3:0] 	TMDS_P,
	output wire [3:0] 	TMDS_N,

	//------------------ ft812 spi and ctl ---
	inout wire 				FT_SPI_CS_N,
	inout wire 			FT_SPI_SCK,
	input wire 				FT_SPI_MISO,
	inout wire 			FT_SPI_MOSI,
	input wire 				FT_INT_N,
	input wire 				FT_CLK,
	input wire 				FT_DE,
	output wire 			FT_CLK_OUT,

	//------------------ cf card -------------
	output wire [2:0] 	WA,
	output wire [1:0] 	WCS_N,
	output wire 			WRD_N,
	output wire 			WWR_N,
	output wire 			WRESET_N,
	inout wire [15:0] 	WD,

	//------------------ analog in/out -------	
	output wire 			TAPE_OUT,
	input wire 				TAPE_IN,

   //------------------ i2s dac -------------
	output wire          DAC_BCK,
	output wire          DAC_WS,
	output wire          DAC_DAT,

	//------------------ adc -----------------
	output wire 			ADC_CLK,
	inout wire 				ADC_BCK,
	inout wire 				ADC_LRCK,
	input wire 				ADC_DOUT,
	
	//------------------ esp32 i2s and cs ----
	inout wire           ESP32_SPI_CS_N,
	input wire           ESP32_PCM_BCK,
	input wire           ESP32_PCM_RLCK,
	input wire           ESP32_PCM_DAT,	

	//------------------ mcu spi -------------
	input wire 				MCU_CS_N,
	input wire 				MCU_SCK,
	inout wire 				MCU_MOSI,
	output wire 			MCU_MISO,
	input wire [5:0] 		MCU_IO,

	//------------------ midi ----------------
	output wire 			MIDI_TX,

	//------------------ optional flash ------
	output wire 			FLASH_CS_N,
	input wire  			FLASH_DO,
	output wire 			FLASH_DI,
	output wire 			FLASH_SCK,
	output wire 			FLASH_WP_N,
	output wire 			FLASH_HOLD_N
);

	// unused signals yet
	assign FLASH_CS_N 	= 1'b1;
	assign FLASH_DI 		= 1'b1;
	assign FLASH_SCK 		= 1'b0;
	assign FLASH_WP_N 	= 1'b1;
	assign FLASH_HOLD_N 	= 1'b1;

	assign TAPE_OUT		= 1'b0;
	assign UART_CTS 		= 1'b0;
	assign WA 				= 3'b0;
	assign WCS_N 			= 2'b11;
	assign WRD_N 			= 1'b1;
	assign WWR_N 			= 1'b1;
	assign WRESET_N 		= 1'b1;
	assign MA 				= 21'b0;
	assign MWR_N			= 2'b11;
	assign MRD_N 			= 2'b11;
	assign SDR_BA 			= 2'b00;
	assign SDR_A 			= 12'b0;
	assign SDR_CLK 		= 1'b0;
	assign SDR_DQM 		= 2'b00;
	assign SDR_WE_N 		= 1'b1;
	assign SDR_CAS_N 		= 1'b1;
	assign SDR_RAS_N 		= 1'b1;
	assign SD_CS_N			= 1'b1;
	assign SD_CLK			= 1'b1;
	assign MIDI_TX			= 1'b1;
	assign FT_SPI_CS_N	= 1'b1 ;
	assign FT_SPI_MOSI	= 1'bZ ;
	assign FT_SPI_SCK		= 1'bZ ;
	assign FT_CLK_OUT    = 1'b0;
	assign ADC_CLK			= 1'b0;
	assign ADC_BCK			= 1'b0;
	assign ADC_LRCK		= 1'b0;
	assign ESP32_SPI_CS_N = 1'b1;
	
	// VT wrapper
	
	wire areset, v_clk, clk, video_hsync, video_vsync, video_blank, beeper, dvi_only;
	wire [23:0] video_rgb;
	wire [15:0] audio_mix_l, audio_mix_r;
	
	vt_top vt_top(
		// global pins
		.clk(CLK_50MHZ),
		.mcu_mosi(MCU_MOSI),
		.mcu_miso(MCU_MISO),
		.mcu_sck(MCU_SCK),
		.mcu_cs_n(MCU_CS_N),
		// vt signals
		.areset(areset),
		.v_clk(v_clk),
		.p_clk(clk),
		.rgb(video_rgb),
		.hs(video_hsync),
		.vs(video_vsync),
		.blank(video_blank),
		.audio_l(audio_mix_l),
		.audio_r(audio_mix_r),
		.beeper(beeper),
		.dvi_only(dvi_only)
	);

	// hdmi

	hdmi_top #(.SAMPLERATE(48000)) hdmi_top(
		.clk				(v_clk),
		.reset			(areset),

		.vga_rgb			(video_rgb),
		.vga_hs			(video_hsync),
		.vga_vs			(video_vsync),
		.vga_de			(~video_blank),

		.audio_en		(~dvi_only),
		.audio_l			(audio_mix_l),
		.audio_r			(audio_mix_r),

		.tmds_p			(TMDS_P),
		.tmds_n			(TMDS_N)
	);

	// i2s DAC 
	
	PCM5102 #(.DAC_CLK_DIV_BITS(3)) PCM5102(
		.clk				(clk),
		.reset			(areset),
		.left				(audio_mix_l),
		.right			(audio_mix_r),
		.din				(DAC_DAT),
		.bck				(DAC_BCK),
		.lrck				(DAC_WS)
	);
	
endmodule
