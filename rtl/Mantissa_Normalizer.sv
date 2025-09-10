`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/08/2025 11:31:12 PM
// Design Name: 
// Module Name: Mantissa_Normalizer_23bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Mantissa normalizer for 23-bit mantissa (FP32)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Extended from 10-bit to 23-bit mantissa
// 
//////////////////////////////////////////////////////////////////////////////////

module Mantissa_Normalizer (
		input 																					clk,
		input 																					reset,
    input  [23:0] 																	mantissa_in,  						 // 24-bit mantissa input
    output [23:0] 																	mantissa_out, 						 // 24-bit mantissa output
    output [4:0]  																	shift_count,  						 // 5-bit shift count (0-23)
    output        																	valid         						 // Valid output flag
);


	logic	[4:0]																				shift_count_reg;
	assign shift_count																= shift_count_reg;
	logic																							valid_reg;
	assign valid																			= valid_reg;
	logic																							mantissa_out_reg;
	assign mantissa_out 															= mantissa_out_reg;
	
	integer 																					i;
	logic 																						shift_disable;
	
// Step 1: Find leading zeros (combinational)
always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		valid_reg																				<= 1'b0;
		shift_count_reg																	<= 5'b0;
		shift_disable																		<= 1'b0;
	end
	else begin
		shift_count_reg																	<= 5'd0;
		shift_disable																		<= 1'b0;
		valid_reg																				<= |mantissa_in; 						// OR reduction. 1 is any bit is 0
		
		for (i = 23; i>0; i = i - 1) begin
			if (mantissa_in[i] && !shift_disable) begin
				shift_count_reg															<= 23 - i;
			end
		end
		
		
		mantissa_out_reg																<= mantissa_in << shift_count_reg;
	end
end




endmodule