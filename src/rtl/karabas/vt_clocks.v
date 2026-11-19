`timescale 1ns / 1ps
`default_nettype wire
/*
 vt_clocks.v

 The clocks of the VT100 core, one PLL from CLK_50MHZ (/1 x10, VCO 500 MHz), as rc2014_clocks:
   clk_50     /10  50 MHz: the MCU link, the serial line (vt_uart), the DAC, the video timing of the
                   terminal (vt10x clk50mhz)
   clk_125    /4   125 MHz and clk_125_n (180 degrees): the TMDS serialiser
   clk_25     /20  25 MHz: the pixel clock (640 x 480), the OSD, HDMI
   clk_10     /50  10 MHz: the PDP-11 of the terminal (vt10x cpuclk)
   clk_8      /60  8.33 MHz: FT_CLK_OUT
 All from the one PLL: clk_25 is in phase with every other edge of clk_50.
*/
module vt_clocks (
	input wire clk_in,
	output wire clk_50,
	output wire clk_125,
	output wire clk_125_n,
	output wire clk_25,
	output wire clk_10,
	output wire clk_8,
	output wire locked
);

wire [5:0] clk;
kg_pll #(
	.CLKIN_PERIOD(20.0),
	.DIVCLK_DIVIDE(1),
	.CLKFBOUT_MULT(10),
	.CLKOUT0_DIVIDE(10),
	.CLKOUT1_DIVIDE(4),
	.CLKOUT2_DIVIDE(4),
	.CLKOUT2_PHASE(180.0),
	.CLKOUT3_DIVIDE(20),
	.CLKOUT4_DIVIDE(50),
	.CLKOUT5_DIVIDE(60),
	.IBUFG(1),
	.BUFG_MASK(6'b111111)
) pll (
	.clk_in(clk_in),
	.rst(1'b0),
	.clk_out(clk),
	.locked(locked)
);

assign clk_50 = clk[0];
assign clk_125 = clk[1];
assign clk_125_n = clk[2];
assign clk_25 = clk[3];
assign clk_10 = clk[4];
assign clk_8 = clk[5];

endmodule
