`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/08/2025 11:43:51 PM
// Design Name: 
// Module Name: Adder_tb
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


module Adder_tb;

	
	
	// Adder signals 
	logic                                             clk;
	logic 																						reset;
	logic [31:0]																			A;
	logic [31:0]																			B;
	logic																							En;
	logic [31:0]																			Sum;
	logic																							Ready;
	logic [31:0]																			Expected_Sum;
	logic 																						Correct;
	
	// Clock
	always #5 clk = ~clk;
	
	// DUT
	Adder DUT(
			.clk   (clk)
		,	.reset (reset)
		,	.A     (A)
		, .B     (B)
		,	.En    (En)
		,	.Sum   (Sum)
		, .Ready (Ready)
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

	// Example 0: 1.0 + 2.0 = 3.0
	#100;
	A            = 32'h3F800000;   // 1.0
	B            = 32'h40000000;   // 2.0
	Expected_Sum = 32'h40400000;   // 3.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 1: 3.0 + 4.0 = 7.0
	#100;
	A            = 32'h40400000;   // 3.0
	B            = 32'h40800000;   // 4.0
	Expected_Sum = 32'h40E00000;   // 7.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 2: 0.5 + 0.5 = 1.0
	#100;
	A            = 32'h3F000000;   // 0.5
	B            = 32'h3F000000;   // 0.5
	Expected_Sum = 32'h3F800000;   // 1.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 3: 10.0 + 5.0 = 15.0
	#100;
	A            = 32'h41200000;   // 10.0
	B            = 32'h40A00000;   // 5.0
	Expected_Sum = 32'h41700000;   // 15.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 4: 0.25 + 0.75 = 1.0
	#100;
	A            = 32'h3E800000;   // 0.25
	B            = 32'h3F400000;   // 0.75
	Expected_Sum = 32'h3F800000;   // 1.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 5: 100.0 + 28.0 = 128.0
	#100;
	A            = 32'h42C80000;   // 100.0
	B            = 32'h41E00000;   // 28.0
	Expected_Sum = 32'h43000000;   // 128.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 6: -2.0 + -3.0 = -5.0
	#100;
	A            = 32'hC0000000;   // -2.0
	B            = 32'hC0400000;   // -3.0
	Expected_Sum = 32'hC0A00000;   // -5.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 7: -1.5 + 2.5 = 1.0 (mixed signs)
	#100;
	A            = 32'hBFC00000;   // -1.5
	B            = 32'h40200000;   // 2.5
	Expected_Sum = 32'h3F800000;   // 1.0 
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 8: -10.0 + -6.0 = -16.0
	#100;
	A            = 32'hC1200000;   // -10.0
	B            = 32'hC0C00000;   // -6.0
	Expected_Sum = 32'hC1800000;   // -16.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 9: 0.125 + 0.375 = 0.5
	#100;
	A            = 32'h3E000000;   // 0.125
	B            = 32'h3EC00000;   // 0.375
	Expected_Sum = 32'h3F000000;   // 0.5
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Example 10: 0 + 25.0 = 25.0
	#100;
	A            = 32'h00000000;   // 0
	B            = 32'h41C80000;   // 25.0
	Expected_Sum = 32'h41C80000;   // 25.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Overflow case 1: Large + Large → result > max normal exponent
	#100;
	A            = 32'h7F000000;   // 2.127e38
	B            = 32'h7F000000;   // 2.127e38
	Expected_Sum = 32'h7F800000;   // Would overflow if implemented properly
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Overflow case 2: Large + smaller large → still exceeds max exponent
	#100;
	A            = 32'h7E800000;   // 1.064e38
	B            = 32'h7F000000;   // 2.127e38
	Expected_Sum = 32'h7F400000;   // Would overflow
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Underflow case 1: Small number + much smaller number → smaller lost
	#100;
	A            = 32'h3F800000;   // 1.0
	B            = 32'h1F000000;   // 4.5e-48 (tiny)
	Expected_Sum = 32'h3F800000;   // Effectively 1.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Underflow case 2: Negative large + tiny negative → tiny lost
	#100;
	A            = 32'hC0000000;   // -2.0
	B            = 32'h1F000000;   // 4.5e-48
	Expected_Sum = 32'hC0000000;   // Effectively -2.0
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Underflow case 3: Very small numbers, same order → normalization detects sum
	#100;
	A            = 32'h02000000;   // 2.9802322e-38
	B            = 32'h01000000;   // 1.4901161e-38
	Expected_Sum = 32'h02200000;   // 4.470348e-38 
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Underflow case 4: Small number + smaller but opposite sign → subtraction
	#100;
	A            = 32'h3F800000;   // 1.0
	B            = 32'h1F000000;   // 4.5e-48
	Expected_Sum = 32'h3F800000;   // Tiny B completely lost, result = A
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end

	// Underflow case 5: Negative small + tiny negative → smaller lost
	#100;
	A            = 32'hBF800000;   // -1.0
	B            = 32'h1F000000;   // 4.5e-48
	Expected_Sum = 32'hBF800000;   // B lost
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end
	
	// +X and -X
	#100;
	A            = 32'h40B80000;  
	B            = 32'hC0B80000;  
	Expected_Sum = 32'h00000000;   
	En           = 1;
	#20 En       = 0;
	
	wait (Ready == 1);
	if (Expected_Sum == Sum) begin
		Correct		 = 1;
	end else begin Correct = 0; end




	end


endmodule
