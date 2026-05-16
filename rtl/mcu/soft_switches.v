`timescale 1ns / 1ps
module soft_switches(
	input				clk,
	input [15:0]	sw_command,
	
	output reg		sw_reset
) ;

	always @(posedge clk) begin
		case (sw_command)
			16'b0		: sw_reset <= 1'b1 ;
			default	: begin
				sw_reset <= 1'b0 ;
			end
		endcase
	end

endmodule
