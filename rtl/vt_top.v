`default_nettype none
module vt_top(
	input wire clk,
	output wire areset,
	output wire p_clk,
	output wire v_clk,
	output wire [23:0] rgb,
	output wire hs,
	output wire vs,
	output wire blank,
	output wire [15:0] audio_l,
	output wire [15:0] audio_r,
	output wire beeper,
	output wire dvi_only,
	input wire mcu_mosi,
	output wire mcu_miso,
	input wire mcu_sck,
	input wire mcu_cs_n	
);

	wire clk10, clkready, clk_p;
	
	pll pll_top(
		.inclk0(clk),
		.areset(1'b0),
		.locked(clkready),
		.c0(clk10), 	// 10MHz VT100
		.c1(clk_p),		// 50MHz CPU
		.c2(),			// 50Mhz CPU 180deg
		.c3()				//	12.5Mhz SD Card
	) ;
	
	assign areset = ~clkready;
	assign p_clk = clk_p;

		//---------- MCU ------------
	wire [7:0] ps2_scancode;
	wire ps2_scancode_upd;
	wire [1:0] hw_btn;
	wire [7:0] uart_rx_data, uart_rx_idx, uart_tx_data;
	wire uart_tx_wr;
	wire [15:0] softsw_command, osd_command;
	wire [7:0] hwid;
	wire mcu_busy;

	mcu mcu(
		.CLK				(clk_p),
		.N_RESET			(~areset),

		.MCU_MOSI		(mcu_mosi),
		.MCU_MISO		(mcu_miso),
		.MCU_SCK			(mcu_sck),
		.MCU_SS			(mcu_cs_n),

		.KB_SCANCODE	(ps2_scancode),
		.KB_SCANCODE_UPD(ps2_scancode_upd),

		.BTNS				(hw_btn),

		.UART_RX_DATA	(uart_rx_data),
		.UART_RX_IDX	(uart_rx_idx),	 
		.UART_TX_DATA	(uart_tx_data),
		.UART_TX_WR		(uart_tx_wr),

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
		.CLK_VGA(v_clk),
		.RGB_I({video_r, video_g, video_b}),
		.RGB_O(rgb),
		.HSYNC_I(hs),
		.VSYNC_I(vs),
		.OSD_COMMAND(osd_command)
	) ;
	
	//--------- VT100 -------------
	
	wire video_hsync, video_vsync, video_blank;
	wire [7:0] video_r, video_g, video_b;
	wire ps2k_c, ps2k_d;
	wire vt_tx, vt_rx;

	vt100_top vt100(
		.clkin(clk_p),
		.c0(clk10),
		.resetbtn(~sw_reset || ~hw_btn[1]),
		.tx(vt_tx),
		.rx(vt_rx),
		.vgar(video_r),
		.vgag(video_g),
		.vgab(video_b),
		.vgah(hs),
		.vgav(vs),
		.vga_blank(blank),
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
	
	// stereo out
	
	assign audio_l = {1'b0, beeper, 14'b0};
	assign audio_r = {1'b0, beeper, 14'b0};

endmodule
