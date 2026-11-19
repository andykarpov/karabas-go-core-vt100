`timescale 1ns / 1ps
`default_nettype none
/*
 tb_vt_uart.v (make sim): vt_uart_tx fed as kg_l2_port feeds it (o_rd = out_ready && !empty,
 out_wr registered one clock later), N bytes back to back with the hold line (rts of the
 terminal) going on and off, looped into vt_uart_rx. Checks: every byte arrives once and in
 order, the bit time is 434 clocks (115207 bps) and no byte starts while hold is on.
*/
module tb_vt_uart;

localparam N = 300;
reg clk = 1'b0;
always #10 clk = ~clk;   // 50 MHz
reg reset = 1'b1;

// the port model: a queue of N bytes
reg [7:0] q [0:N-1];
integer head = 0;
reg out_wr = 1'b0;
reg [7:0] out_data = 8'd0;
wire ready;
reg hold = 1'b0;
wire line;
wire o_rd = ready && head < N;
always @(posedge clk) begin
	out_wr <= o_rd;
	if (o_rd) begin
		out_data <= q[head];
		head <= head + 1;
	end
end

vt_uart_tx tx (.clk(clk), .reset(reset), .hold(hold), .load(out_wr), .data(out_data), .ready(ready), .tx(line));

wire done;
wire [7:0] data;
vt_uart_rx rx (.clk(clk), .reset(reset), .rx(line), .done(done), .data(data));

integer got = 0, errors = 0;
always @(posedge clk) if (done) begin
	if (got >= N || data !== q[got]) begin
		$display("ERROR: byte %0d = %02x, expected %02x", got, data, got < N ? q[got] : 8'hxx);
		errors = errors + 1;
	end
	got = got + 1;
end

reg line_q = 1'b1;
integer t = 0;
always @(posedge clk) begin
	t = t + 1;
	line_q <= line;
end

// a start bit while hold was on for longer than the byte in flight = an error
reg [15:0] hold_cnt = 0;
always @(posedge clk) begin
	hold_cnt <= hold ? hold_cnt + 1 : 0;
	if (line_q && !line && hold && hold_cnt > 4400) begin
		$display("ERROR: a start bit %0d clocks into hold", hold_cnt);
		errors = errors + 1;
	end
end

integer i;
// the frame time of back-to-back bytes: from one done of the receiver to the next (bytes 1..10,
// before the first hold): 10 bits of 434 clocks and the few clocks the port takes for the next byte
integer last_done = 0, fmin = 1000000, fmax = 0;
always @(posedge clk) if (done) begin
	if (got >= 2 && got <= 10) begin
		if (t - last_done < fmin) fmin = t - last_done;
		if (t - last_done > fmax) fmax = t - last_done;
	end
	last_done = t;
end

initial begin
	for (i = 0; i < N; i = i + 1) q[i] = (i * 37 + 11) & 8'hFF;
	repeat (5) @(posedge clk);
	reset = 1'b0;
	// back to back, then hold on / off a few times in the middle of the stream
	repeat (60000) @(posedge clk);
	hold = 1'b1; repeat (20000) @(posedge clk); hold = 1'b0;
	repeat (30000) @(posedge clk);
	hold = 1'b1; repeat (7) @(posedge clk); hold = 1'b0;
	repeat (30000) @(posedge clk);
	hold = 1'b1; repeat (50000) @(posedge clk); hold = 1'b0;
	wait (got == N);
	repeat (5000) @(posedge clk);
	if (fmin < 4340 || fmax > 4346) begin
		$display("ERROR: back-to-back frames %0d..%0d clocks, expected 4340..4346", fmin, fmax);
		errors = errors + 1;
	end
	if (got != N) begin
		$display("ERROR: %0d bytes of %0d", got, N);
		errors = errors + 1;
	end
	if (errors == 0) $display("PASS: %0d bytes in order, back-to-back frames %0d..%0d clocks", got, fmin, fmax);
	else $display("FAIL: %0d errors", errors);
	$finish;
end

initial begin
	#200000000;
	$display("FAIL: timeout, %0d of %0d bytes", got, N);
	$finish;
end

endmodule
