`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		N/A
// Engineer: 		Pavel Tsybulin
// 
// Create Date:    23:04:11 05/13/2026 
// Design Name: 
// Module Name:    karabas_go_top 
// Project Name: 
// Target Devices: karabas-go
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module karabas_go_top(
	input 				CLK_50MHZ,
	
	//---------------------------
	inout 				UART_RX,
	inout 				UART_TX,
	inout 				UART_CTS,
	inout 				ESP_RESET_N,
	inout 				ESP_BOOT_N,
	
	//--------- SRAM ------------------
	output	[20:0]	MA,
	inout		[15:0]	MD,
	output	[1:0]		MWR_N,
	output	[1:0]		MRD_N,

	//---------- SDRAM -----------------
	output	[1:0] 	SDR_BA,
	output	[12:0]	SDR_A,
	output				SDR_CLK,
	output	[1:0]		SDR_DQM,
	output				SDR_WE_N,
	output				SDR_CAS_N,
	output				SDR_RAS_N,
	inout		[15:0]	SDR_DQ,

	//--------- SD2 ------------------
	output				SD_CS_N,
	output				SD_CLK,
	inout					SD_DI,
	inout					SD_DO,
	input					SD_DET_N,

	//---------- VGA -----------------
	output	[7:0] 	VGA_R,
	output	[7:0] 	VGA_G,
	output	[7:0] 	VGA_B,
	output				VGA_HS,
	output				VGA_VS,
	output				V_CLK,

	//---------- VDAC2 -----------------
	output				FT_SPI_CS_N,
	output				FT_SPI_SCK,
	input					FT_SPI_MISO,
	output				FT_SPI_MOSI,
	input					FT_INT_N,
	input					FT_CLK,
	output				FT_OE_N,

	//---------- IDE -----------------
	output	[2:0] 	WA,
	output	[1:0] 	WCS_N,
	output				WRD_N,
	output				WWR_N,
	output				WRESET_N,
	inout		[15:0] 	WD,

	//--------- FLOPPY ------------------
	input					FDC_INDEX,
	output	[1:0] 	FDC_DRIVE,
	output				FDC_MOTOR,
	output				FDC_DIR,
	output				FDC_STEP,
	output				FDC_WDATA,
	output				FDC_WGATE,
	input					FDC_TR00,
	input					FDC_WPRT,
	input					FDC_RDATA,
	output				FDC_SIDE_N,

	//---------------------------	
	output				TAPE_OUT,
	input					TAPE_IN,
	output				BEEPER,

	//---------- DAC -----------------
	output				DAC_LRCK,
	output				DAC_DAT,
	output				DAC_BCK,
	output				DAC_MUTE,

	//--------- MCU ------------------
	input					MCU_CS_N,
	input					MCU_SCK,
	inout					MCU_MOSI,
	output				MCU_MISO,
	input					MCU_SPI_FT_CS_N,
	input					MCU_SPI_SD2_CS_N,	
	inout		[1:0] 	MCU_SPI_IO,

	//---------------------------
	output				MIDI_TX,
	output				MIDI_CLK,
	output				MIDI_RESET_N,

	//---------------------------
	output				FLASH_CS_N,
	input					FLASH_DO,
	output				FLASH_DI,
	output				FLASH_SCK,
	output				FLASH_WP_N,
	output				FLASH_HOLD_N	
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
	assign DAC_LRCK		= 1'b0 ;
	assign DAC_MUTE		= 1'b1 ;
	assign DAC_BCK			= 1'b0 ;
	assign DAC_DAT			= 1'b0 ;
	assign FT_SPI_CS_N	= 1'b1 ;
	assign FT_SPI_MOSI	= 1'bZ ;
	assign FT_SPI_SCK		= 1'bZ ;
	
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

	// mouse / cursor
	wire [7:0] ms_x, ms_y, cursor_x, cursor_y ;
	wire [3:0] ms_z, cursor_z ;
	wire [2:0] ms_b, cursor_b ;
	wire ms_upd ;
	
	// kbd
	wire [7:0] hid_kb_status, hid_kb_dat0, hid_kb_dat1, hid_kb_dat2 ;
	wire [7:0] hid_kb_dat3, hid_kb_dat4, hid_kb_dat5, ps2_scancode ;
	wire ps2_scancode_upd ;
	
	// joy
	wire [12:0] joy_l, joy_r ;
	
	// hw buttons
	wire [1:0] hw_btn ;
	
	// soft switches
	wire sw_reset ;
	
	// RTC
	wire [7:0] rtc_addr, rtc_di, rtc_do ;
	wire rtc_wr, rtc_rd ;
	
	// UART
	wire [7:0] uart_rx_data, uart_rx_idx, uart_tx_data, uart_dlm, uart_dll ;
	wire uart_dll_wr, uart_dlm_wr ;
	wire uart_tx_mode = 1'b1 ;
	reg  uart_tx_wr = 1'b0 ;
	
	// ROM Loader
	wire loader_act, loader_wr ;
	wire [31:0] loader_addr ;
	wire [7:0] loader_data ;
	
	// OSD cmd
	wire [15:0] softsw_command, osd_command ;
	
	wire mcu_ft_spi_on, mcu_ft_vga_on, mcu_ft_sck, mcu_ft_mosi, mcu_ft_cs_n ;
	wire mcu_busy ;
	
	// DEBUG
	reg [15:0] debug_addr  ;
	reg [15:0] debug_data ;
	
	mcu mcu(
		.CLK(clk_p),
		.N_RESET(~areset),

		.MCU_MOSI(MCU_MOSI),
		.MCU_MISO(MCU_MISO),
		.MCU_SCK(MCU_SCK),
		.MCU_SS(MCU_CS_N),

		.MCU_SPI_FT_SS(MCU_SPI_FT_CS_N),
		.MCU_SPI_SD2_SS(MCU_SPI_SD2_CS_N),	

		.MS_X(ms_x),
		.MS_Y(ms_y),
		.MS_Z(ms_z),
		.MS_B(ms_b),
		.MS_UPD(ms_upd),

		.KB_STATUS(hid_kb_status),
		.KB_DAT0(hid_kb_dat0),
		.KB_DAT1(hid_kb_dat1),
		.KB_DAT2(hid_kb_dat2),
		.KB_DAT3(hid_kb_dat3),
		.KB_DAT4(hid_kb_dat4),
		.KB_DAT5(hid_kb_dat5),

		.KB_SCANCODE(ps2_scancode),
		.KB_SCANCODE_UPD(ps2_scancode_upd),

		.JOY_L(joy_l),
		.JOY_R(joy_r),

		.BTNS(hw_btn),

		.RTC_A(rtc_addr),
		.RTC_DI(rtc_di),
		.RTC_DO(rtc_do),
		.RTC_CS(1'b1),
		.RTC_WR_N(~rtc_wr),

		.UART_RX_DATA(uart_rx_data),
		.UART_RX_IDX(uart_rx_idx),	 
		.UART_TX_DATA(uart_tx_data),
		.UART_TX_WR(uart_tx_wr),
		.UART_TX_MODE(uart_tx_mode),
		.UART_DLL(uart_dll),
		.UART_DLM(uart_dlm),
		.UART_DLL_WR(uart_dll_wr),
		.UART_DLM_WR(uart_dlm_wr),

		.ROMLOADER_ACTIVE(loader_act),
		.ROMLOAD_ADDR(loader_addr),
		.ROMLOAD_DATA(loader_data),
		.ROMLOAD_WR(loader_wr),

		.SOFTSW_COMMAND(softsw_command),	
		.OSD_COMMAND(osd_command),

		.FT_SPI_ON(mcu_ft_spi_on),
		.FT_VGA_ON(mcu_ft_vga_on),
		.FT_SCK(mcu_ft_sck),
		.FT_MISO(FT_SPI_MISO),
		.FT_MOSI(mcu_ft_mosi),
		.FT_CS_N(mcu_ft_cs_n),
		
		.DEBUG_ADDR(debug_addr),
		.DEBUG_DATA(debug_data),

		.BUSY(mcu_busy)
	) ;
	
	// VIDEO
	
	assign FT_OE_N = 1'b1 ; // disable FT
	
	wire vga_hsync, vga_vsync ;
	wire [7:0] vgar, vgag, vgab ;
	
	assign VGA_HS = vga_hsync ;
	assign VGA_VS = vga_vsync ;

	overlay overlay(
		.CLK(clk_p),
		.RGB_I({vgar, vgag, vgab}),
		.RGB_O({VGA_R, VGA_G, VGA_B}),
		.HSYNC_I(vga_hsync),
		.VSYNC_I(vga_vsync),
		.OSD_COMMAND(osd_command)
	) ;
	
	wire tx, rx ;
	wire ps2k_c, ps2k_d ;
	
//	assign rx = tx ;

	vt100_top vt100(
		.clkin(clk_p),
		.c0(clk10),
		.resetbtn(~sw_reset || ~hw_btn[1]),
		.tx(tx),
		.rx(rx),
		.vgar(vgar),
		.vgag(vgag),
		.vgab(vgab),
		.vgah(vga_hsync),
		.vgav(vga_vsync),
		.vgaclk(V_CLK),
		.ps2k_c(ps2k_c),
		.ps2k_d(ps2k_d),
		.audio(BEEPER)
	) ;

	usb_ps2_convertor usb2ps2(
		.clk(clk_p),
		.kb_scancode(ps2_scancode),
		.kb_scancode_upd(ps2_scancode_upd),
		.PS2data(ps2k_d),
		.PS2clock(ps2k_c)
	) ;
	
	// MCU --> VT100
	
	reg [7:0] tx_data = 8'd0 ;
	reg tx_dv = 1'b0 ;
	wire tx_act, tx_done ;
	
	UART_TX utx(
		.i_Clk(clk_p),
		.i_TX_DV(tx_dv),
		.i_TX_Byte(tx_data),
		.o_TX_Active(tx_act),
		.o_TX_Serial(rx),
		.o_TX_Done(tx_done)
	) ;
	
	reg [7:0] old_idx = 8'd0 ;
	
	always @(posedge clk_p) begin
		if ((uart_rx_idx != old_idx) && ~tx_act) begin
			old_idx <= uart_rx_idx ;
			tx_data <= uart_rx_data ;
			tx_dv <= 1'b1 ;
		end else begin
			tx_dv <= 1'b0 ;
		end
	end
	
	// VT100 --> MCU
	
	wire rx_dv ;
	
	UART_RX urx(
		.i_Clk(clk_p),
		.i_RX_Serial(tx),
		.o_RX_DV(rx_dv),
		.o_RX_Byte(uart_tx_data)
	) ;
	
	always @(posedge clk_p) begin
		if (rx_dv == 1'b1) begin
			uart_tx_wr <= 1'b1 ;
//			debug_data <= {8'b0, uart_tx_data} ;
		end else begin
			uart_tx_wr <= 1'b0 ;
		end
	end
	
	// SOFT SWITCHES
	
	soft_switches sosw(
		.clk(clk_p),
		.sw_command(softsw_command),
		.sw_reset(sw_reset)
	) ;
	
endmodule
