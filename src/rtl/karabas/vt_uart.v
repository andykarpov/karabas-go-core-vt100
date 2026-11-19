`timescale 1ns / 1ps
`default_nettype none
/*
 vt_uart.v

 The serial line between the USB serial port of the MCU (kg_mcu2 port 0, the core serial port
 "Karabas core serial" of the firmware) and the kl11 of the terminal: 8N1, a bit of DIV clocks
 (50 MHz / 434 = 115207 bps, the rate of kl11 at 115200: 50 MHz / 31 / 14).

 vt_uart_tx: the bytes of the PC to the terminal (its rx). out_ready to kg_l2_port: idle, the
   terminal does not hold the line (rts: its receive silo has more than 11 bytes) and no byte of
   the port in flight (kg_l2_port gives out_wr one clock after it saw out_ready, so ready drops
   with out_wr, before busy). The bytes the terminal cannot take wait in the out fifo of the port
   and in the USB fifo of the MCU: nothing is lost.
 vt_uart_rx: the bytes of the terminal (its tx) to the PC: done one clock with data, a start bit
   checked in its middle, the data bits taken in their middles.
*/

module vt_uart_tx #(
	parameter DIV = 434
) (
	input wire clk,
	input wire reset,
	input wire hold,          // the terminal: wait
	input wire load,          // out_wr of the port
	input wire [7:0] data,
	output wire ready,        // out_ready of the port
	output reg tx = 1'b1
);

reg [9:0] sh = 10'h3FF;       // { stop, data, start } still to send, LSB first
reg [3:0] bits = 4'd0;        // bits left (0 = idle)
reg [8:0] cnt = 9'd0;
wire busy = bits != 4'd0;
assign ready = !reset && !busy && !hold && !load;

always @(posedge clk) begin
	if (reset) begin
		bits <= 4'd0;
		tx <= 1'b1;
	end
	else if (!busy) begin
		tx <= 1'b1;
		if (load) begin
			sh <= { 1'b1, data, 1'b0 };
			bits <= 4'd10;
			cnt <= 9'd0;
		end
	end
	else begin
		if (cnt == 9'd0) begin
			tx <= sh[0];
			sh <= { 1'b1, sh[9:1] };
		end
		if (cnt == DIV - 1) begin
			cnt <= 9'd0;
			bits <= bits - 4'd1;
		end
		else
			cnt <= cnt + 9'd1;
	end
end

endmodule

module vt_uart_rx #(
	parameter DIV = 434
) (
	input wire clk,
	input wire reset,
	input wire rx,
	output reg done = 1'b0,
	output reg [7:0] data = 8'd0
);

reg [2:0] rx_s = 3'b111;
always @(posedge clk)
	rx_s <= { rx_s[1:0], rx };
wire rxd = rx_s[2];

reg [3:0] bit = 4'd0;         // 0 idle, 1 start, 2..9 data, 10 stop
reg [8:0] cnt = 9'd0;
reg [7:0] sh = 8'd0;

always @(posedge clk) begin
	done <= 1'b0;
	if (reset)
		bit <= 4'd0;
	else if (bit == 4'd0) begin
		if (!rxd) begin
			bit <= 4'd1;
			cnt <= 9'd0;
		end
	end
	else if (cnt == (bit == 4'd1 ? DIV / 2 : DIV - 1)) begin
		cnt <= 9'd0;
		if (bit == 4'd1)
			bit <= rxd ? 4'd0 : 4'd2;     // a glitch, not a start bit
		else if (bit == 4'd10) begin
			bit <= 4'd0;
			done <= rxd;                  // a frame with a stop bit 0 is dropped
			data <= sh;
		end
		else begin
			sh <= { rxd, sh[7:1] };
			bit <= bit + 4'd1;
		end
	end
	else
		cnt <= cnt + 9'd1;
end

endmodule
