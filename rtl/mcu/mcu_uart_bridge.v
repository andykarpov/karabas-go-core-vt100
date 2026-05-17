module mcu_uart_bridge(
	input wire clk,
	input wire [7:0] uart_rx_data,
	input wire [7:0] uart_rx_idx,
	output wire [7:0] uart_tx_data,
	output reg uart_tx_wr,
	output wire tx,
	input wire rx
);

	// fifo for rx data from mcu
	wire fifo_empty, fifo_full;
	reg fifo_rd, fifo_wr;
	reg [7:0] fifo_di;
	wire [7:0] fifo_do;
	fifo #(.ADDR_WIDTH(8), .DATA_WIDTH(8)) rx_fifo(
		.clk(clk),
		.reset(1'b0),
		.empty(fifo_empty),
		.full(fifo_full),
		.rd(fifo_rd),
		.dout(fifo_do),
		.wr(fifo_wr),
		.din(fifo_di)
	);
	
	// put incoming data to fifo
	reg [7:0] prev_uart_rx_idx = 127;
	always @(posedge clk) begin
		fifo_wr <= 0;
		if (~fifo_full && prev_uart_rx_idx != uart_rx_idx) begin
			fifo_wr <= 1;
			fifo_di <= uart_rx_data;
			prev_uart_rx_idx <= uart_rx_idx;
		end
	end
	
	// transmit data from fifo to serial tx pin
	reg [7:0] tx_data = 8'd0;
	reg tx_dv = 1'b0;
	wire tx_act, tx_done;
	
	UART_TX utx(
		.i_Clk(clk),
		.i_TX_DV(tx_dv),
		.i_TX_Byte(tx_data),
		.o_TX_Active(tx_act),
		.o_TX_Serial(tx),
		.o_TX_Done(tx_done)
	);
	
	reg fifo_rd_req = 0;
	always @(posedge clk) begin
		fifo_rd <= 0;
		if (~fifo_empty) begin
			fifo_rd <= 1;
			fifo_rd_req <= 1;
		end else if (~tx_act && fifo_rd_req) begin
			fifo_rd_req <= 0;
			tx_data <= fifo_do;
			tx_dv <= 1'b1;
		end else begin
			tx_dv <= 1'b0;
		end
	end
	
	// receive serial VT data and transmit it to MCU	
	wire rx_dv;	
	UART_RX urx(
		.i_Clk(clk),
		.i_RX_Serial(rx),
		.o_RX_DV(rx_dv),
		.o_RX_Byte(uart_tx_data)
	);
	
	always @(posedge clk) begin
		uart_tx_wr <= 0;
		if (rx_dv == 1'b1) begin
			uart_tx_wr <= 1'b1;
		end
	end

endmodule
