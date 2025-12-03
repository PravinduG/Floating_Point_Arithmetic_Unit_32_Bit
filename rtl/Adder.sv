`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/08/2025 10:19:03 PM
// Design Name: 
// Module Name: Adder
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
// 			Throughput prioritised over latency
//////////////////////////////////////////////////////////////////////////////////


module Adder(
			input																					clk
		,	input																					reset
		,	input [31:0]																	A
		, input [31:0]																	B
		,	input 																				En
		,	output [31:0]																	Sum
		, output																				Ready
    );
		
		
	// Components of FP32
	logic																							S_A;
	logic																							S_B;
	logic [7:0]																				E_A;
	logic [7:0]																				E_B;
	logic [23:0]																			M_A;	 											// Extra bit for implicit 1
	logic [23:0]																			M_B;   											// Extra bit for implicit 1
	
	// Allocate inputs
	// assign  S_A 																			  = A[31];
	// assign  S_B																				= B[31];
	// assign  E_A																				= A[30:23];
	// assign  E_B																				= B[30:23];
	// assign  M_A																				= A[22:0]; 			
	// assign  M_B 																			  = B[22:0];   
	
	// Internal Signals 
	logic																							S_Sum;
	logic [7:0]																				E_Sum;
	logic [23:0]																			M_Sum; 											// Extra bit for implicit 1	
	logic [28:0]																			M_Sum_temp; 								// Extra bits for overflow and G R S bits
	logic [31:0]																			Sum_reg;
	logic 																						Ready_reg;
	logic 																						G;
	logic 																						R; 
	logic 																						S;
	logic [7:0]																			  exp_diff;
	
	// Signals for Mantissa_Normalizer
	logic [23:0]																			mantissa_out;
  logic [4:0] 																			shift_count;
  logic 			 																			normalizer_valid;
  logic 			 																			normalizer_en;
	
	//FSM 
	typedef enum logic[4:0]{
			Idle
		,	Compare
		,	Exponent_Diff
		,	Mantissa_Shift
		,	Operation
		,	Normalization
		, Rounding_Check
		, Rounding_Apply
		, Rounding_Overflow
		, Done
		} state_t;
	
	state_t																						next_state;
	state_t																						cur_state;
	
	
	// Mantissa_Normalizer
	Mantissa_Normalizer normalizer (
			.clk					(clk)
		,	.reset				(reset)	
		, .en  					(normalizer_en)
		,	.mantissa_in	(M_Sum_temp[27:4])
		,	.mantissa_out (mantissa_out)
		,	.shift_count	(shift_count)
		,	.valid				(normalizer_valid)
		);
	
	
	assign Sum																				= Sum_reg;
	assign Ready																			= Ready_reg;
	
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			next_state																		<= Idle;
			S_Sum																					<= 1'b0;
			E_Sum																					<= 8'b0;
			M_Sum																					<= 24'b0; 			
			M_Sum_temp																		<= 29'b0;
			Sum_reg																				<= 32'b0;
			Ready_reg																			<= 1'b0;
			G																							<= 1'b0;
			R																							<= 1'b0; 
			S																							<= 1'b0;
			exp_diff																			<= 8'b0;
			normalizer_en																	<= 0;
			
		
		end
		else begin
			cur_state																			<= next_state;
			case (next_state)
			Idle : begin
				Ready_reg																		<= 1'b0;  
				
				if (En) begin 
					next_state																<= Compare;
					S_A																				<= A[31];
					S_B																				<= B[31];
					E_A																				<= A[30:23];
					E_B																				<= B[30:23];
					M_A																				<= {1'b1, A[22:0]}; 	 
					M_B																				<= {1'b1, B[22:0]}; 
				end
				
			end
			Compare : begin
				// If A or B are zero, return the other
				if (A[30:0] == 31'b0) begin
					Sum_reg																		<= B;
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
				end
				else if (B[30:0] == 31'b0) begin
					Sum_reg																		<= A;	
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
					// CHECK IF DIRECTLY GOING TO IDLE WIHTOUT GOING THROUGH OTHER STAGES WILL AFFECT PIPELINE FEEDING
				end
				
				// Map the larger exponent to A to simplify algorithm 
				// Here built in > operator is used as vivado will optimize its synthesis as opposed to a custom method (speed, resource util)
				else 
					if (E_A < E_B || (E_A == E_B && M_A < M_B)) begin
						exp_diff																<=(E_B - E_A);							// Calculate exponent difference
						S_B																			<= S_A;
						E_B																			<= E_A;
						M_B																			<= M_A;
						S_A																			<= S_B;
						E_A																			<= E_B;
						M_A																			<= M_B;
						next_state															<= Mantissa_Shift;
					end	
					else begin
						next_state															<= Mantissa_Shift;				
						exp_diff																<=(E_A - E_B);							// Calculate exponent difference
					end
			end
			
			// MERGED INTO COMPARE STATE
			// Exponent_Diff : begin
			// 	exp_diff																		<=(E_A - E_B);							// Calculate exponent difference
			// 	next_state																	<= Mantissa_Shift;
			// end
			
			Mantissa_Shift : begin
				M_B										    									<= M_B >> exp_diff;					// Shift smaller mantissa right
				E_Sum																				<= E_A; 										// Larger exponent is the target exponent
				next_state																	<= Operation;
			end
			
			
			Operation : begin
				if (S_A == S_B) begin
					M_Sum_temp[28:4]													<= M_A + M_B; 							// Add if sign bits are equal
				end
				else begin
					M_Sum_temp[28:4]													<= M_A - M_B;							  // Subtract if not equal 
				end
				
				S_Sum																				<= S_A;											// Sign of Sum 
				next_state																	<= Normalization;
				normalizer_en																<= 1;
			end
			
			Normalization : begin
				normalizer_en																<= 0;
				if (M_Sum_temp[28] == 1) begin																					// Overflow detected
					M_Sum_temp																<= M_Sum_temp >> 1;					// Right shit to correct
					E_Sum																			<= E_Sum + 1;								// Update exponent
					next_state																<= Rounding_Check;
				end
				else 	begin
					M_Sum_temp																<= M_Sum_temp << shift_count;	// Left Shift
					E_Sum																			<= E_Sum - shift_count;				// Update exponent
					next_state																<= Rounding_Check;
				end
				
				// Handle case where sum is zero
				if(M_Sum_temp == 29'b0) begin
					E_Sum																			<= 8'b0;
					S_Sum																			<= 1'b0;
					next_state																<= Rounding_Check;
				end
				
				
			end
			
			Rounding_Check : begin
				M_Sum																				<= M_Sum_temp[27:4];				// First 23 bits (from MSB) are the Mantissa (Includes implied 1)
				G																						<= M_Sum_temp[3];						// G
				R																						<= M_Sum_temp[2];						// R
				S																						<= M_Sum_temp[1] || M_Sum_temp[0];					// S
																											
				next_state																	<= Done;
				
			end
			
			// Rounding_Apply : begin
			// 	if (G == 1) begin
			// 		if (R == 1 || S == 1) begin
			// 			M_Sum_temp[27:5]
			// 		end
			// 	end
			// end		
			
			Done : begin
				Ready_reg																		<= 1'b1;
				Sum_reg																			<= {S_Sum, E_Sum, M_Sum[22:0]}; // Take 22 bits from Mantissa. MSB is implied 1.
				next_state																	<= Idle;
			end
			
			default : begin
				next_state																	<= Idle;
			end
			
			endcase
		end
	end
	

		
		
	
endmodule
