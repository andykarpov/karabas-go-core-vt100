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

module karabas_go_top(
	input  wire				CLK_50MHZ,
	
	//---------------------------
	inout  wire				UART_RX,
	inout  wire				UART_TX,
	inout  wire				UART_CTS,
	inout  wire				ESP_RESET_N,
	inout  wire				ESP_BOOT_N,
	
	//--------- SRAM ------------------
	output wire	[20:0]	MA,
	inout	 wire	[15:0]	MD,
	output wire	[1:0]		MWR_N,
	output wire	[1:0]		MRD_N,

	//---------- SDRAM -----------------
	output wire	[1:0] 	SDR_BA,
	output wire	[12:0]	SDR_A,
	output wire				SDR_CLK,
	output wire	[1:0]		SDR_DQM,
	output wire				SDR_WE_N,
	output wire				SDR_CAS_N,
	output wire				SDR_RAS_N,
	inout	 wire	[15:0]	SDR_DQ,

	//--------- SD2 ------------------
	output wire				SD_CS_N,
	output wire				SD_CLK,
	inout	 wire				SD_DI,
	inout	 wire				SD_DO,
	input	 wire				SD_DET_N,

	//---------- VGA -----------------
	output wire	[7:0] 	VGA_R,
	output wire	[7:0] 	VGA_G,
	output wire	[7:0] 	VGA_B,
	output wire				VGA_HS,
	output wire				VGA_VS,
	output wire				V_CLK,

	//---------- VDAC2 -----------------
	output wire				FT_SPI_CS_N,
	output wire				FT_SPI_SCK,
	input	 wire				FT_SPI_MISO,
	output wire				FT_SPI_MOSI,
	input	 wire				FT_INT_N,
	input	 wire				FT_CLK,
	output wire				FT_OE_N,

	//---------- IDE -----------------
	output wire	[2:0] 	WA,
	output wire	[1:0] 	WCS_N,
	output wire				WRD_N,
	output wire				WWR_N,
	output wire				WRESET_N,
	inout	 wire	[15:0] 	WD,

	//--------- FLOPPY ------------------
	input	 wire				FDC_INDEX,
	output wire	[1:0] 	FDC_DRIVE,
	output wire				FDC_MOTOR,
	output wire				FDC_DIR,
	output wire				FDC_STEP,
	output wire				FDC_WDATA,
	output wire				FDC_WGATE,
	input  wire				FDC_TR00,
	input  wire				FDC_WPRT,
	input  wire				FDC_RDATA,
	output wire				FDC_SIDE_N,

	//---------------------------	
	output wire				TAPE_OUT,
	input	 wire				TAPE_IN,
	output wire				BEEPER,

	//---------- DAC -----------------
	output wire				DAC_LRCK,
	output wire				DAC_DAT,
	output wire				DAC_BCK,
	output wire				DAC_MUTE,

	//--------- MCU ------------------
	input	 wire				MCU_CS_N,
	input	 wire				MCU_SCK,
	inout	 wire				MCU_MOSI,
	output wire				MCU_MISO,
	input	 wire				MCU_SPI_FT_CS_N,
	input	 wire				MCU_SPI_SD2_CS_N,	
	inout	 wire	[1:0] 	MCU_SPI_IO,

	//---------------------------
	output wire				MIDI_TX,
	output wire				MIDI_CLK,
	output wire				MIDI_RESET_N,

	//---------------------------
	output wire				FLASH_CS_N,
	input	 wire				FLASH_DO,
	output wire				FLASH_DI,
	output wire				FLASH_SCK,
	output wire				FLASH_WP_N,
	output wire				FLASH_HOLD_N	
) ;

	// unused signals	
	assign ESP_RESET_N	= 1'bZ;
	assign ESP_BOOT_N		= 1'bZ;	
	assign FLASH_CS_N		= 1'b1;
	assign FLASH_DI		= 1'b1;
	assign FLASH_SCK		= 1'b0;
	assign FLASH_WP_N		= 1'b1;
	assign FLASH_HOLD_N	= 1'b1;
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
	assign FDC_DRIVE 		= 2'b00;
	assign FDC_MOTOR 		= 1'b0;
	assign FDC_SIDE_N		= 1'b1;
	assign FDC_WDATA		= 1'b1;
	assign FDC_WGATE		= 1'b1;
	assign FDC_STEP		= 1'b1;
	assign FDC_DIR			= 1'b1;
	assign SD_CS_N			= 1'b1;
	assign SD_CLK			= 1'b1;
	assign MIDI_RESET_N	= 1'b1;
	assign MIDI_TX			= 1'b1;
	assign MIDI_CLK		= 1'b0 ;
	assign FT_SPI_CS_N	= 1'b1 ;
	assign FT_SPI_MOSI	= 1'bZ ;
	assign FT_SPI_SCK		= 1'bZ ;
	
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
	
	// VIDEO
	
	assign FT_OE_N = 1'b1 ; // disable FT
	assign VGA_HS = video_hsync;
	assign VGA_VS = video_vsync;
	assign VGA_R = video_rgb[23:16];
	assign VGA_G = video_rgb[15:8];
	assign VGA_B = video_rgb[7:0];
	assign V_CLK = v_clk;

	// HW BEEPER
	
	assign BEEPER = beeper;
	
	// i2s DAC 
	
	PCM5102 #(.DAC_CLK_DIV_BITS(3)) PCM5102(
		.clk				(clk),
		.reset			(areset),
		.left				(audio_mix_l),
		.right			(audio_mix_r),
		.din				(DAC_DAT),
		.bck				(DAC_BCK),
		.lrck				(DAC_LRCK)
	);
	assign DAC_MUTE = 1'b1;
	
endmodule
