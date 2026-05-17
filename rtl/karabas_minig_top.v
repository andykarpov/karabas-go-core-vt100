`timescale 1ns / 1ps
`default_nettype none
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

// Warning! HW_ID2 and HW_ID3 macroses are defined in the Synthesize - XST process properties!

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
	input wire 				MCU_MOSI,
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

wire clk10, clkready, clk_p, clk_n, sdclock ;
	
	pll pll_top(
		.inclk0(CLK_50MHZ),
		.areset(1'b0),
		.locked(clkready),
		.c0(clk10), 	// 10MHz VT100
		.c1(clk_p),		// 50MHz CPU
		.c2(clk_n),		// 50Mhz CPU 180deg
		.c3(sdclock)	//	12.5Mhz SD Card
	) ;
	
	wire areset = ~clkready ;

	// hdmi
	wire [7:0] hdmi_freq;
	hdmi_top #(.SAMPLERATE(48000)) hdmi_top(
		.clk				(v_clk),
		.reset			(areset),

		.vga_rgb			({osd_r[7:0], osd_g[7:0], osd_b[7:0]}),
		.vga_hs			(video_hsync),
		.vga_vs			(video_vsync),
		.vga_de			(~video_blank),

		.audio_en		(~dvi_only),
		.audio_l			(audio_mix_l),
		.audio_r			(audio_mix_r),

		.tmds_p			(TMDS_P),
		.tmds_n			(TMDS_N),

		.freq				(hdmi_freq)
	);

	// ------- i2s DAC --------------
	wire [15:0] audio_out_l, audio_out_r;
	wire [15:0] audio_mix_l, audio_mix_r;
	PCM5102 #(.DAC_CLK_DIV_BITS(3)) PCM5102(
		.clk				(clk_p),
		.reset			(areset),
		.left				(audio_mix_l),
		.right			(audio_mix_r),
		.din				(DAC_DAT),
		.bck				(DAC_BCK),
		.lrck				(DAC_WS)
	);

	// ------- audio mix
	assign audio_out_l = {1'b0, beeper, 14'b0};
	assign audio_out_r = {1'b0, beeper, 14'b0};
	assign audio_mix_l = audio_out_l;
	assign audio_mix_r = audio_out_r;

	//---------- MCU ------------
	wire [7:0] ps2_scancode;
	wire ps2_scancode_upd;
	wire [1:0] hw_btn;
	wire [7:0] uart_rx_data, uart_rx_idx, uart_tx_data;
	wire uart_tx_wr;
	wire [15:0] softsw_command, osd_command;
	wire [7:0] hwid;
	wire dvi_only;
	wire mcu_busy;

	mcu mcu(
		.CLK				(clk_p),
		.N_RESET			(~areset),

		.MCU_MOSI		(MCU_MOSI),
		.MCU_MISO		(MCU_MISO),
		.MCU_SCK			(MCU_SCK),
		.MCU_SS			(MCU_CS_N),

		.MCU_SPI_FT_SS	(MCU_IO[3]),
		.MCU_SPI_SD2_SS(MCU_IO[2]),

		.KB_SCANCODE	(ps2_scancode),
		.KB_SCANCODE_UPD(ps2_scancode_upd),

		.XT_SCANCODE	(),
		.XT_SCANCODE_UPD(),

		.BTNS				(hw_btn),

		.RTC_A			(8'b0),
		.RTC_DI			(8'b0),
		.RTC_DO			(),
		.RTC_CS			(1'b0),
		.RTC_WR_N		(1'b1),

		.UART_RX_DATA	(uart_rx_data),
		.UART_RX_IDX	(uart_rx_idx),	 
		.UART_TX_DATA	(uart_tx_data),
		.UART_TX_WR		(uart_tx_wr),

		.UART_TX_MODE	(1'b0),
		.UART_DLL		(8'b0),
		.UART_DLM		(8'b0),
		.UART_DLL_WR	(1'b0),
		.UART_DLM_WR	(1'b0),

		.SOFTSW_COMMAND(softsw_command),	
		.OSD_COMMAND	(osd_command),

		.HWID				(hwid),
		.DVI_ONLY		(dvi_only),

		.DEBUG_ADDR		(16'd0),
		.DEBUG_DATA		(16'd0),

		.BUSY				(mcu_busy)
	);

	//--------- OSD --------------
	wire [7:0] osd_r, osd_g, osd_b;
	overlay overlay(
		.CLK(clk_p),
		.RGB_I({video_r, video_g, video_b}),
		.RGB_O({osd_r, osd_g, osd_b}),
		.HSYNC_I(video_hsync),
		.VSYNC_I(video_vsync),
		.OSD_COMMAND(osd_command)
	) ;
	
	//--------- VT100 -------------
	
	wire video_hsync, video_vsync, video_blank;
	wire [7:0] video_r, video_g, video_b;
	wire beeper;
	wire ps2k_c, ps2k_d;
	wire vt_tx, vt_rx;
	wire v_clk;

	vt100_top vt100(
		.clkin(clk_p),
		.c0(clk10),
		.resetbtn(~sw_reset || ~hw_btn[1]),
		.tx(vt_tx),
		.rx(vt_rx),
		.vgar(video_r),
		.vgag(video_g),
		.vgab(video_b),
		.vgah(video_hsync),
		.vgav(video_vsync),
		.vga_blank(video_blank),
		.vgaclk(v_clk),
		.ps2k_c(ps2k_c),
		.ps2k_d(ps2k_d),
		.audio(beeper)
	) ;

	usb_ps2_convertor usb2ps2(
		.clk(clk_p),
		.kb_scancode(ps2_scancode),
		.kb_scancode_upd(ps2_scancode_upd),
		.PS2data(ps2k_d),
		.PS2clock(ps2k_c)
	) ;
	
	// MCU UART <--> VT serial bridge
	mcu_uart_bridge(
		.clk(clk_p),
		.uart_rx_data(uart_rx_data),
		.uart_rx_idx(uart_rx_idx),
		.uart_tx_data(uart_tx_data),
		.uart_tx_wr(uart_tx_wr),
		.tx(vt_rx),
		.rx(vt_tx)
	);
	
	// SOFT SWITCHES
	
	wire sw_reset;
	
	soft_switches sosw(
		.clk(clk_p),
		.sw_command(softsw_command),
		.sw_reset(sw_reset)
	) ;
	
endmodule
