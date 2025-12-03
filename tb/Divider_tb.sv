`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 10:48:53 PM
// Design Name: 
// Module Name: Divider_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Divider_tb;

	// Divider signals
	logic clk;
	logic reset;
	logic [31:0] A;
	logic [31:0] B;
	logic En;
	logic [31:0] Result;
	logic Ready;
	logic NaN;
	logic [31:0] Expected_Result;
	logic Correct;
	
	// Clock
	always #5 clk = ~clk;
	
	// DUT
	Divider DUT(
		.clk   (clk),
		.reset (reset),
		.A     (A),
		.B     (B),
		.En    (En),
		.Result(Result),
		.Ready (Ready),
		.NaN   (NaN)
	);
	
	initial begin
		// Init
		clk     = 0;
		reset   = 1;
		En      = 0;
		A       = 0;
		B       = 0;
		Correct = 0;
		
		#50 reset = 0;

		// =========================
		// Basic: 2.0 / 1.0 = 2.0
		// =========================
		#100;
		A = 32'h40000000; // 2.0
		B = 32'h3F800000; // 1.0
		Expected_Result = 32'h40000000; // 2.0
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// Positive / Positive: 3.75 / 1.5 = 2.5
		// =========================
		#100;
		A = 32'h40700000; // 3.75
		B = 32'h3FC00000; // 1.5
		Expected_Result = 32'h40200000; // 2.5
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// Positive / Negative: 3.0 / -1.5 = -2.0
		// =========================
		#100;
		A = 32'h40400000; // 3.0
		B = 32'hBFC00000; // -1.5
		Expected_Result = 32'hC0000000; // -2.0
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// Negative / Positive: -2.0 / 0.75 = -2.6666667
		// =========================
		#100;
		A = 32'hC0000000; // -2.0
		B = 32'h3F400000; // 0.75
		Expected_Result = 32'hC02AAAAA; // -2.6666667
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// Negative / Negative: -1.5 / -2.0 = 0.75
		// =========================
		#100;
		A = 32'hBFC00000; // -1.5
		B = 32'hC0000000; // -2.0
		Expected_Result = 32'h3F400000; // 0.75
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// Division by zero: 5.0 / 0 = +Inf
		// =========================
		#100;
		A = 32'h40A00000; // 5.0
		B = 32'h00000000; // 0.0
		Expected_Result = 32'h7F800000; // +Inf
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// Zero / something: 0 / 3.0 = 0
		// =========================
		#100;
		A = 32'h00000000; // 0.0
		B = 32'h40400000; // 3.0
		Expected_Result = 32'h00000000; // 0.0
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// 0 / 0 = NaN
		// =========================
		#100;
		A = 32'h00000000;
		B = 32'h00000000;
		Expected_Result = 32'h7FC00000; // canonical NaN
		En = 1;
		#20 En = 0;
		#100;
		Correct = (Result == Expected_Result);

		// =========================
		// Inf / finite = Inf
		// =========================
		#100;
		A = 32'h7F800000; // +Inf
		B = 32'h3F800000; // 1.0
		Expected_Result = 32'h7F800000; // +Inf
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// finite / Inf = 0
		// =========================
		#100;
		A = 32'h40000000; // 2.0
		B = 32'h7F800000; // +Inf
		Expected_Result = 32'h00000000; // 0.0
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// NaN / finite = NaN
		// =========================
		#100;
		A = 32'h7FC00000; // NaN
		B = 32'h40000000; // 2.0
		Expected_Result = 32'h7FC00000;
		En = 1;
		#20 En = 0;
		#100;
		Correct = (Result == Expected_Result);

		// =========================
		// Overflow: max finite / 0.5 = +Inf
		// =========================
		#100;
		A = 32'h7F7FFFFF; // Max finite
		B = 32'h3F000000; // 0.5
		Expected_Result = 32'h7F800000; // +Inf
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		// =========================
		// Underflow: smallest normal / largest finite = 0
		// =========================
		#100;
		A = 32'h00800000; // smallest normal
		B = 32'h7F7FFFFF; // largest finite
		Expected_Result = 32'h00000000; // 0.0
		En = 1;
		#20 En = 0;
		wait (Ready == 1);
		Correct = (Result == Expected_Result);

		#100;
	end

endmodule
