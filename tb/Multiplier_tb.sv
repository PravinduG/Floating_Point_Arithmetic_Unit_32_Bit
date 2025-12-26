`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2025 03:38:55 PM
// Design Name: 
// Module Name: Multiplier_tb
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


module Multiplier_tb;

	// Multiplier signals 
	logic                                             clk;
	logic 																						reset;
	logic [31:0]																			A;
	logic [31:0]																			B;
	logic																							En;
	logic [31:0]																			Result;
	logic																							Ready;
	logic 																						NaN;
	logic [31:0]																			Expected_Sum;
	logic 																						Correct;
	
	// Clock
	always #5 clk = ~clk;
	
	// Dut
	Multiplier DUT(
			.clk   (clk)
		,	.reset (reset)
		,	.A     (A)
		, .B     (B)
		,	.En    (En)
		,	.Result(Result)
		, .Ready (Ready)
		, .NaN	 (NaN)
		);
		
		
		initial begin
		// Init 
		clk		  = 0;
		reset 	= 1;
		En 		  = 0;
		A       = 0;
		B       = 0;
		Correct = 0;
		
		// Remove reset
	#50 reset = 0;

	// Example 0: 1.0 x 2.0 = 2.0
	#100;
	A            = 32'h3F800000;   // 1.0
	B            = 32'h40000000;   // 2.0
	Expected_Sum = 32'h40000000;   // 2.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Result) begin
		Correct		 = 1;
	end else begin Correct = 0; end
	
	// =========================
	// POSITIVE * POSITIVE
	// Example: 1.5 × 2.5 = 3.75
	// =========================
	#100;
	A            = 32'h3FC00000;   // 1.5
	B            = 32'h40200000;   // 2.5
	Expected_Sum = 32'h40700000;   // 3.75
	En           = 1;
	#20 En       = 0;

	wait (Ready == 1);
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end

	// =========================
	// POSITIVE * NEGATIVE
	// Example: 3.0 × -1.25 = -3.75
	// =========================
	#100;
	A            = 32'h40400000;   // 3.0
	B            = 32'hBFA00000;   // -1.25
	Expected_Sum = 32'hC0700000;   // -3.75
	En           = 1;
	#20 En       = 0;

	wait (Ready == 1);
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end

	// =========================
	// NEGATIVE * POSITIVE
	// Example: -2.0 × 0.75 = -1.5
	// =========================
	#100;
	A            = 32'hC0000000;   // -2.0
	B            = 32'h3F400000;   // 0.75
	Expected_Sum = 32'hBFC00000;   // -1.5
	En           = 1;
	#20 En       = 0;

	wait (Ready == 1);
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end

	// =========================
	// NEGATIVE * NEGATIVE
	// Example: -1.5 × -2.0 = 3.0
	// =========================
	#100;
	A            = 32'hBFC00000;   // -1.5
	B            = 32'hC0000000;   // -2.0
	Expected_Sum = 32'h40400000;   // 3.0
	En           = 1;
	#20 En       = 0;

	wait (Ready == 1);
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end

	// =========================
	// MULTIPLY WITH ZERO
	// Example: 0 × -5.0 = 0
	// =========================
	#100;
	A            = 32'h00000000;   // 0.0
	B            = 32'hC0A00000;   // -5.0
	Expected_Sum = 32'h80000000;   // 0.0
	En           = 1;
	#20 En       = 0;

	wait (Ready == 1);
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end

	// =========================
	// MULTIPLY WITH INFINITY
	// Example: +inf × -1.5 = -inf
	// =========================
	#100;
	A            = 32'h7F800000;   // +inf
	B            = 32'h3FC00000;   // 1.5
	Expected_Sum = 32'hFF800000;   // -inf
	En           = 1;
	#20 En       = 0;

	#200
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end

	// =========================
	// MULTIPLY WITH NaN
	// Example: NaN × 2.0 = NaN
	// =========================
	#100;
	A            = 32'h7FC00000;   // NaN
	B            = 32'h40000000;   // 2.0
	Expected_Sum = 32'h7FC00000;   // NaN
	En           = 1;
	#20 En       = 0;

#100
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end

	// =========================
	// EXPONENT OVERFLOW → RESULT = INF
	// Example: max finite float × 2 → +inf
	// =========================
	#100;
	A            = 32'h7F7FFFFF;   // Max finite float (~3.4028235e38)
	B            = 32'h40000000;   // 2.0
	Expected_Sum = 32'h7F800000;   // +inf
	En           = 1;
	#20 En       = 0;

	wait (Ready == 1);
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end

	// =========================
	// EXPONENT UNDERFLOW → RESULT = 0
	// Example: smallest normal × smallest normal → 0
	// =========================
	#100;
	A            = 32'h00800000;   // Smallest normal positive (~1.17549435e-38)
	B            = 32'h00800000;   // Smallest normal positive (~1.17549435e-38)
	Expected_Sum = 32'h00000000;   // Underflow → 0.0
	En           = 1;
	#20 En       = 0;

	wait (Ready == 1);
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin Correct = 0; end
	
		#100;
	A            = 32'h41100000;   // 9
	B            = 32'h40000000;   // 2
	Expected_Sum = 32'h41900000;   // 18
	En           = 1;
	#20 En       = 0;
	
	#100;
	A            = 32'h47C35000;   // 100,000.0
	B            = 32'h41100000;   // 9.0
	Expected_Sum = 32'h495BBA00;   // 900,000.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Result) begin
			Correct = 1;
	end else begin 
			Correct = 0; 
	end



	
	end
	
endmodule
