`timescale 1ns / 1ps
`default_nettype wire

/*
 VT100 terminal core for Karabas Mini rev.G (HDMI, PCM5102): the VT100 of Sytse van Slooten's
 PDP2011 (vt100_top: a PDP-11 running the vt10x firmware, 640 x 480 at 60 Hz; the karabas fixes of
 the rc2014 core in kl11 / vt) on the core serial port of the board, and the board glue of
 karabas-go-modules (MCU link v2, kg_mcu2).

 Clocks (vt_clocks, one PLL): clk_50 (the MCU link, the serial line, the DAC, the video timing of
 the terminal), clk_25 (640 x 480 pixels, the OSD, HDMI), clk_125 / clk_125_n (the serialiser),
 clk_10 (the PDP-11 of the terminal), clk_8 (FT_CLK_OUT).

 Serial line: kg_mcu2 port 0 = the core serial port of the firmware (CDC 1, Linux
 /dev/serial/by-id/usb-Karabas_Go_*-if02, "Karabas core serial", or a USB-UART adapter on the USB
 host) <-> vt_uart (8N1, 115200) <-> kl11 of the terminal. The terminal holds the line with rts
 (its receive silo of 16 bytes); the bytes wait in the out fifo of the port and the USB fifo.
 XON / XOFF of the terminal hold the line in the core and are not sent to the PC.

 Keyboard: the PS/2 set 2 bytes of kg_mcu2 (USB or PS/2 keyboards of the MCU).
 Picture: vgao (all text, bold drawn thicker) in the colour of the OSD item (amber / green /
 white); vgai (vga_ht, the shading of the VT105 graphs, never set with vttype 100) at half of it. Audio: the bell to the PCM5102 and HDMI (48 kHz).

 Soft switches (the index of the item in the osd of core.json): 0 Colour (Amber / Green / White),
 1 Reset (the terminal; also board button 1, as before).
*/

module karabas_minig_top (
	input wire CLK_50MHZ,

	inout wire UART_RX,
	inout wire UART_TX,
	inout wire UART_CTS,

	output wire [20:0] MA,
	inout wire [15:0] MD,
	output wire [1:0] MWR_N,
	output wire [1:0] MRD_N,

	output wire [1:0] SDR_BA,
	output wire [12:0] SDR_A,
	output wire SDR_CLK,
	output wire [1:0] SDR_DQM,
	output wire SDR_WE_N,
	output wire SDR_CAS_N,
	output wire SDR_RAS_N,
	inout wire [15:0] SDR_DQ,

	output wire SD_CS_N,
	output wire SD_CLK,
	output wire SD_DI,
	input wire SD_DO,
	input wire SD_DET_N,

	input wire [7:0] VGA_R,
	input wire [7:0] VGA_G,
	input wire [7:0] VGA_B,
	input wire VGA_HS,
	input wire VGA_VS,

	output wire [3:0] TMDS_P,
	output wire [3:0] TMDS_N,

	output wire FT_SPI_CS_N,
	output wire FT_SPI_SCK,
	input wire FT_SPI_MISO,
	output wire FT_SPI_MOSI,
	input wire FT_INT_N,
	input wire FT_CLK,
	input wire FT_DE,
	output wire FT_CLK_OUT,

	output wire [2:0] WA,
	output wire [1:0] WCS_N,
	output wire WRD_N,
	output wire WWR_N,
	output wire WRESET_N,
	inout wire [15:0] WD,

	output wire TAPE_OUT,
	input wire TAPE_IN,

	output wire DAC_BCK,
	output wire DAC_WS,
	output wire DAC_DAT,

	output wire ADC_CLK,
	inout wire ADC_BCK,
	inout wire ADC_LRCK,
	input wire ADC_DOUT,

	input wire MCU_CS_N,
	input wire MCU_SCK,
	inout wire MCU_MOSI,
	output wire MCU_MISO,
	inout wire [5:0] MCU_IO, // [0] burst cs_n, [1] burst ready, [2] sd2 cs_n, [3] ft cs_n

	output wire MIDI_TX,

	output wire ESP32_SPI_CS_N,
	input wire ESP32_PCM_BCK,
	input wire ESP32_PCM_RLCK,
	input wire ESP32_PCM_DAT,

	output wire FLASH_CS_N,
	input wire FLASH_DO,
	output wire FLASH_DI,
	output wire FLASH_SCK,
	output wire FLASH_WP_N,
	output wire FLASH_HOLD_N
);

// ------------------------------------------------------------------ unused

assign WA = 3'b000;
assign WCS_N = 2'b11;
assign WRD_N = 1'b1;
assign WWR_N = 1'b1;
assign WRESET_N = 1'b1;
assign WD = 16'bz;

assign ESP32_SPI_CS_N = 1'b1;
assign UART_RX = 1'bz;
assign UART_TX = 1'bz;
assign UART_CTS = 1'bz;

assign ADC_CLK = 1'b0;
assign ADC_BCK = 1'bz;
assign ADC_LRCK = 1'bz;
assign MIDI_TX = 1'b1;
assign TAPE_OUT = 1'b0;

// SRAM: not used
assign MA = 21'd0;
assign MD = 16'bz;
assign MWR_N = 2'b11;
assign MRD_N = 2'b11;

// SD2: not used
assign SD_CS_N = 1'b1;
assign SD_CLK = 1'b0;
assign SD_DI = 1'b1;

// SDRAM: not used (NOP: RAS / CAS / WE high)
assign SDR_BA = 2'b00;
assign SDR_A = 13'd0;
assign SDR_CLK = 1'b0;
assign SDR_DQM = 2'b11;
assign SDR_WE_N = 1'b1;
assign SDR_CAS_N = 1'b1;
assign SDR_RAS_N = 1'b1;
assign SDR_DQ = 16'bz;

// FLASH_CS_N (T3) is the SDRAM /CS of Mini G2 (rev G: tied low on the board): always selected
assign FLASH_CS_N = 1'b0;
assign FLASH_DI = 1'b1;
assign FLASH_SCK = 1'b0;
assign FLASH_WP_N = 1'b1;
assign FLASH_HOLD_N = 1'b1;

// ------------------------------------------------------------------ clocks

wire clk_50, clk_125, clk_125_n, clk_25, clk_10, clk_8, pll_locked;
vt_clocks clocks (
	.clk_in(CLK_50MHZ),
	.clk_50(clk_50),
	.clk_125(clk_125),
	.clk_125_n(clk_125_n),
	.clk_25(clk_25),
	.clk_10(clk_10),
	.clk_8(clk_8),
	.locked(pll_locked)
);
(* KEEP = "TRUE" *) wire areset_async = ~pll_locked;
wire areset, areset_25;
kg_sync #(.W(1), .STAGES(2), .INIT(1'b1)) sync_areset (.clk(clk_50), .d(areset_async), .q(areset));
kg_sync #(.W(1), .STAGES(2), .INIT(1'b1)) sync_areset_25 (.clk(clk_25), .d(areset_async), .q(areset_25));

// the clock of the FT812 (every core must drive it on Mini / Mini G)
ODDR2 oddr_ft_clk (.Q(FT_CLK_OUT), .C0(clk_8), .C1(~clk_8), .CE(1'b1), .D0(1'b1), .D1(1'b0), .R(1'b0), .S(1'b0));

// ------------------------------------------------------------------ MCU

wire mcu_sck_ibufg, mcu_sck;
IBUFG ibufg_mcu_sck (.I(MCU_SCK), .O(mcu_sck_ibufg));
BUFG bufg_mcu_sck (.I(mcu_sck_ibufg), .O(mcu_sck));

// MCU link v2 (karabas-go-firmware docs/link_v2.md, kg_mcu2); INT on IO1
wire mcu_int;
assign MCU_IO[1] = mcu_int;
assign MCU_IO[0] = 1'bz;
assign MCU_IO[5:2] = 4'bzzzz;

wire [7:0] ps2_code;
wire ps2_kind, ps2_wr;
wire [8*2-1:0] sw;
wire [5:0] btns;
wire dvi_only;
wire ft_cs_n, ft_mosi, ft_spi_on;
wire [15:0] dbg_addr;
reg [15:0] dbg_data = 16'd0;
wire osd_wr, osd_en, osd_zoom;
wire [11:0] osd_waddr;
wire [7:0] osd_wdata;
wire [23:0] osd_fg, osd_bg;
wire [1:0] osd_alpha, osd_place;
wire [4:0] osd_px, osd_ph;
wire [3:0] osd_py;
wire [5:0] osd_pw;

// the core serial port (port 0) <-> the terminal
wire [31:0] port_out_data;
wire [3:0] port_out_wr, port_in_full;
wire ser_out_ready, ser_in_wr;
wire [7:0] ser_in_data;

kg_mcu2 #(
	.SW_N(2),
	.CS_FILTER(3),
	.CAPS(16'h0000),
	.ENABLE_OSD(1),
	.ENABLE_IMG(0),
	.ENABLE_RTC(0),
	.ENABLE_AUX(1),      // DEBUG_*: the state of the line (AT+KARABAS=debug:1, kg_board.py log)
	.ENABLE_FT(1),
	.ENABLE_SD2(0),
	.ENABLE_PORTS(4'b0001) // port 0: the core serial port
) mcu (
	.CLK(clk_50),
	.N_RESET(~areset),

	.MCU_SCK(mcu_sck),
	.MCU_MOSI(MCU_MOSI),
	.MCU_MISO(MCU_MISO),
	.MCU_SS(MCU_CS_N),
	.MCU_INT(mcu_int),
	.MCU_SPI_FT_SS(MCU_IO[3]),
	.MCU_SPI_SD2_SS(1'b1),

	.SW(sw), .SW_WR(), .SW_INDEX(), .SW_VALUE(), .HW_ID(), .DVI_ONLY(dvi_only), .CORE_BUILD(), .FW_BUILD(),
	.BUSY(), .BTNS(btns), .RELOAD_REQ(1'b0), .RELOAD_CORE(8'd0),

	.KBD(), .KBD_WR(),
	.PS2_CODE(ps2_code), .PS2_KIND(ps2_kind), .PS2_WR(ps2_wr),
	.MS_X(), .MS_Y(), .MS_Z(), .MS_B(), .MS_WR(),
	.JOY_L(), .JOY_R(), .JOY_WR(),
	.PS2_CMD(16'h0000), .PS2_CMD_WR(1'b0),

	.LD_KIND(), .LD_SLOT(), .LD_SIZE(), .LD_EXT(), .LD_START(), .LD_ACTIVE(), .LD_END(),
	.LD_ADDR(), .LD_DATA(), .LD_WR(), .LD_READY(1'b1),

	.OSD_WR(osd_wr), .OSD_WADDR(osd_waddr), .OSD_WDATA(osd_wdata), .OSD_EN(osd_en),
	.OSD_FG(osd_fg), .OSD_BG(osd_bg), .OSD_ALPHA(osd_alpha), .OSD_PX(osd_px), .OSD_PY(osd_py),
	.OSD_PW(osd_pw), .OSD_PH(osd_ph), .OSD_PLACE(osd_place), .OSD_ZOOM(osd_zoom),

	.SDC_IMG_MOUNTED(), .SDC_IMG_SIZE(), .SDC_RD(8'd0),
	.SDC_WR(8'd0), .SDC_SECTOR(32'd0), .SDC_BUSY(), .SDC_DONE(),
	.SDC_ERROR(), .SDC_SLOT(), .SDC_BYTE_IN_STROBE(),
	.SDC_BYTE_ADDR(), .SDC_BYTE_IN_DATA(),
	.SDC_BYTE_OUT_DATA(8'd0), .IMG_WP(), .IMG_PHYS_WR(), .IMG_PHYS(), .IMG_FLUSH(), .FDD_CHNG_WR(), .FDD_CHNG(),
	.FDD_CHNG_REQ(1'b0), .FDD_CHNG_DS(2'd0),
	.BK_MOUNT(1'b0), .BK_FLUSHED(1'b0), .BK_SLOT(3'd0), .BK_SIZE(32'd0), .BK_KIND(8'd0), .BK_RESULT(8'd0), .IMG_ACTIVE(),
	.PORT_OUT_DATA(port_out_data), .PORT_OUT_WR(port_out_wr), .PORT_OUT_READY({ 3'b111, ser_out_ready }),
	.PORT_IN_DATA({ 24'd0, ser_in_data }), .PORT_IN_WR({ 3'b000, ser_in_wr }),
	.PORT_CFG(128'd0), .PORT_IN_FULL(port_in_full), .PORT_STAT(), .PORT_STAT_WR(),
	.RTC_A(8'd0), .RTC_DI(8'd0), .RTC_CS(1'b0), .RTC_WR_N(1'b1), .MATRIX_CMD(24'd0), .MATRIX_CMD_WR(1'b0),
	.DEBUG_ADDR(dbg_addr), .DEBUG_DATA(dbg_data), .RTC_DO(),

	.FT_SPI_ON(ft_spi_on), .FT_VGA_ON(), .FT_RESET(), .FT_SCK(), .FT_MOSI(ft_mosi), .FT_MISO(FT_SPI_MISO),
	.FT_CS_N(ft_cs_n),
	.SD2_SCK(), .SD2_MOSI(), .SD2_MISO(1'b1), .SD2_CS_N()
);

assign FT_SPI_CS_N = ft_spi_on ? ft_cs_n : 1'b1;
assign FT_SPI_SCK = ft_spi_on ? mcu_sck_ibufg : 1'b1;
assign FT_SPI_MOSI = ft_spi_on ? ft_mosi : 1'b1;

// ------------------------------------------------------------------ soft switches, reset

wire [1:0] sw_colour = sw[0*8 +: 2];
wire sw_reset = sw[1*8];

// the Reset item or board button 1 resets the terminal for about 1.3 ms (16 bits of clk_50)
reg [15:0] rst_cnt = 16'd0;
reg term_reset = 1'b1;
always @(posedge clk_50) begin
	if (areset || sw_reset || btns[1])
		rst_cnt <= 16'd0;
	else if (!rst_cnt[15])
		rst_cnt <= rst_cnt + 16'd1;
	term_reset <= !rst_cnt[15];
end

// ------------------------------------------------------------------ the serial line

wire term_tx, term_rx, term_rts;
reg term_xoff = 1'b0;      // XOFF of the terminal (below)
vt_uart_tx ser_tx (
	.clk(clk_50),
	.reset(areset),
	.hold(term_rts || term_xoff),
	.load(port_out_wr[0]),
	.data(port_out_data[7:0]),
	.ready(ser_out_ready),
	.tx(term_rx)
);
wire ser_rx_done;
vt_uart_rx ser_rx (
	.clk(clk_50),
	.reset(areset),
	.rx(term_tx),
	.done(ser_rx_done),
	.data(ser_in_data)
);

// XON / XOFF of the terminal, done in the line (as rc2014_xonxoff): the vt10x firmware sends XOFF
// (13h) when it cannot take more (while it scrolls) and drops what still comes; the PC reacts to an
// XOFF only after the bytes already in the USB and port fifos. So XOFF holds the line here at once,
// XON (11h) lets it go, and both are taken out of the stream to the PC (the bytes wait in the
// fifos, nothing is lost). ^S / ^Q on the keyboard pause / resume the output the same way.
reg [7:0] n_xoff = 8'd0;
always @(posedge clk_50) begin
	if (areset || term_reset)
		term_xoff <= 1'b0;
	else if (ser_rx_done && ser_in_data == 8'h13) begin
		term_xoff <= 1'b1;
		n_xoff <= n_xoff + 8'd1;
	end
	else if (ser_rx_done && ser_in_data == 8'h11)
		term_xoff <= 1'b0;
end
assign ser_in_wr = ser_rx_done && ser_in_data != 8'h13 && ser_in_data != 8'h11;

// bytes of the line, for the debug values
reg [7:0] n_out = 8'd0, n_in = 8'd0, n_drop = 8'd0;
always @(posedge clk_50) begin
	if (port_out_wr[0]) n_out <= n_out + 8'd1;
	if (ser_in_wr) n_in <= n_in + 8'd1;
	if (ser_in_wr && port_in_full[0]) n_drop <= n_drop + 8'd1;
end

// ------------------------------------------------------------------ the terminal

wire vt_o, vt_i, vt_hs, vt_vs, vt_blank, vt_bell;
vt100_top terminal (
	.clkin(clk_50),
	.c0(clk_10),
	.resetbtn(~term_reset),
	.tx(term_tx),
	.rx(term_rx),
	.rts(term_rts),
	.vgao(vt_o),
	.vgai(vt_i),
	.vgah(vt_hs),
	.vgav(vt_vs),
	.vgaclk(),
	.vga_blank(vt_blank),
	.ps2k_upd(ps2_wr && !ps2_kind),
	.ps2k_dat(ps2_code),
	.audio(vt_bell)
);

// the picture: clk_50 -> clk_25 (both registered; the terminal holds a pixel for two clk_50)
reg [4:0] vt_q = 5'b11000;
always @(posedge clk_50)
	vt_q <= { vt_hs, vt_vs, vt_blank, vt_i, vt_o };
reg [4:0] vt_p = 5'b11000;
always @(posedge clk_25)
	vt_p <= vt_q;

//                    Amber            Green            White
wire [23:0] fg = sw_colour == 2'd0 ? 24'hFFB700 : sw_colour == 2'd1 ? 24'h33FF33 : 24'hFFFFFF;
wire [23:0] fg_half = { 1'b0, fg[23:17], 1'b0, fg[15:9], 1'b0, fg[7:1] };
reg [23:0] vid_rgb = 24'd0;
reg vid_hs = 1'b0, vid_vs = 1'b0, vid_de = 1'b0;
always @(posedge clk_25) begin
	vid_rgb <= vt_p[2] ? 24'd0 : vt_p[0] ? fg : vt_p[1] ? fg_half : 24'd0;
	vid_hs <= !vt_p[4];     // positive inside, negative to HDMI
	vid_vs <= !vt_p[3];
	vid_de <= !vt_p[2];
end

// the bitmap OSD of link v2 (kg_l2_osd_overlay): centred in de, 2 clocks of latency with its syncs and de
wire [23:0] osd_rgb;
wire osd_hs, osd_vs, osd_de;
kg_l2_osd_overlay osd (
	.wclk(clk_50),
	.osd_wr(osd_wr), .osd_waddr(osd_waddr), .osd_wdata(osd_wdata), .osd_en(osd_en),
	.osd_fg(osd_fg), .osd_bg(osd_bg), .osd_alpha(osd_alpha), .osd_px(osd_px), .osd_py(osd_py),
	.osd_pw(osd_pw), .osd_ph(osd_ph), .osd_place(osd_place), .osd_zoom(osd_zoom),
	.icon_on(8'd0), .icon_act(8'd0),
	.clk(clk_25),
	.rgb_i(vid_rgb), .hs_i(vid_hs), .vs_i(vid_vs), .de_i(vid_de),
	.rgb_o(osd_rgb), .hs_o(osd_hs), .vs_o(osd_vs), .de_o(osd_de)
);

// ------------------------------------------------------------------ audio

// the bell of the terminal: a square wave, an eighth of full scale
reg [15:0] audio = 16'd0;
always @(posedge clk_50)
	audio <= vt_bell ? 16'h0800 : 16'hF800;

kg_pcm5102 #(.DIV_BITS(3)) dac (  // bck 3.1 MHz, 97.7 kHz
	.clk(clk_50),
	.reset(areset),
	.left(audio),
	.right(audio),
	.din(DAC_DAT),
	.bck(DAC_BCK),
	.lrck(DAC_WS)
);

// 48 kHz for HDMI: a phase accumulator on clk_50 (48000 / 50e6 * 2^20 = 1006.6), the sample held
// and taken in clk_25 on the toggle (clk_25 is synchronous to clk_50, stable for ~1000 clocks)
reg [20:0] aud_acc = 21'd0;
reg aud_tgl = 1'b0;
reg [15:0] aud_s = 16'd0;
always @(posedge clk_50) begin
	aud_acc <= { 1'b0, aud_acc[19:0] } + 21'd1007;
	if (aud_acc[20]) begin
		aud_s <= audio;
		aud_tgl <= ~aud_tgl;
	end
end

reg [1:0] aud_tgl_s = 2'b00;
reg aud_stb = 1'b0;
reg [23:0] hdmi_a = 24'd0;
always @(posedge clk_25) begin
	aud_tgl_s <= { aud_tgl_s[0], aud_tgl };
	aud_stb <= aud_tgl_s[1] ^ aud_tgl_s[0];
	if (aud_tgl_s[1] ^ aud_tgl_s[0])
		hdmi_a <= { aud_s, 8'd0 };
end

// ------------------------------------------------------------------ HDMI

reg dvi_only_p = 1'b0;
always @(posedge clk_25)
	dvi_only_p <= dvi_only;

// negative syncs
reg hdmi_hs = 1'b1, hdmi_vs = 1'b1, hdmi_de = 1'b0;
reg [23:0] hdmi_rgb = 24'd0;
always @(posedge clk_25) begin
	hdmi_hs <= ~osd_hs;
	hdmi_vs <= ~osd_vs;
	hdmi_de <= osd_de;
	hdmi_rgb <= osd_rgb;
end

hdmi_tx #(.SAMPLE_FREQ(48000)) hdmi (
	.clk(clk_25),
	.sclk(clk_125),
	.sclk_n(clk_125_n),
	.reset(areset_25),
	.rgb(hdmi_rgb),
	.vsync(hdmi_vs),
	.hsync(hdmi_hs),
	.de(hdmi_de),
	.audio_en(~dvi_only_p),
	.audio_l(hdmi_a),
	.audio_r(hdmi_a),
	.audio_clk(aud_stb),
	.tx_clk_n(TMDS_N[3]),
	.tx_clk_p(TMDS_P[3]),
	.tx_d_n(TMDS_N[2:0]),
	.tx_d_p(TMDS_P[2:0])
);

// ------------------------------------------------------------------ debug

// DEBUG_ADDR: { bytes PC -> terminal, bytes terminal -> PC }; DEBUG_DATA: { rts, xoff, out ready, in full, XOFF count (4 bits), bytes dropped }
assign dbg_addr = { n_out, n_in };
always @(posedge clk_50)
	dbg_data <= { term_rts, term_xoff, ser_out_ready, port_in_full[0], n_xoff[3:0], n_drop };

endmodule
