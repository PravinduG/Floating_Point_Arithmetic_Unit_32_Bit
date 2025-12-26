`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2025 01:03:38 PM
// Design Name: 
// Module Name: Multiplier
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


module Multiplier(
			input																					clk
		,	input																					reset
		,	input [31:0]																	A
		, input [31:0]																	B
		,	input 																				En
		,	output [31:0]																	Result
		, output																				Ready
		, output 																				NaN
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
	reg signed [8:0]																	E_Mult;											// Signed to detect underflow (E_Mult <= 0)
	logic																							S_Mult;	
	logic [23:0]																			M_Mult; 										// Extra bit for implicit 1	
	logic [47:0]																			M_Mult_temp; 								// 48 bits coz multiplication
	logic [31:0]																			Result_reg;
	logic 																						Ready_reg;
	logic 																						NaN_reg;
	logic 																						G;
	logic 																						R; 
	logic 																						S;
	
	
	//FSM 
	typedef enum logic[4:0]{
			Idle
		,	Compare
		,	Operation
		, Operation_Wait_1
		, Operation_Wait_2
		,	Normalization
		, Rounding_and_final_Exp_Check
		, Rounding_Apply
		, Rounding_Overflow
		, Done
		} state_t;
	
	state_t																						next_state;
	state_t																						cur_state;
	
	
	
	assign Result																			= Result_reg;
	assign Ready																			= Ready_reg;
	assign NaN																				= NaN_reg;
	
	// For multiplications
	logic [23:0] mult_a, mult_b;
	logic [47:0] mult_res;

	// Force DSP
	(* use_dsp = "yes" *) 
	always_ff @(posedge clk) begin
			// No reset here for maximum performance
			mult_res 																			<= mult_a * mult_b;
	end
	
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			next_state																		<= Idle;
			S_Mult																				<= 1'b0;
			E_Mult																				<= 9'b0;
			M_Mult																			  <= 24'b0; 			
			M_Mult_temp																		<= 48'b0;
			Result_reg																		<= 32'b0;
			Ready_reg																			<= 1'b0;
			NaN_reg																				<= 1'b0;
			G																							<= 1'b0;
			R																							<= 1'b0; 
			S																							<= 1'b0;
			mult_a																				<= 24'b0;
			mult_b																				<= 24'b0;
			
		
		end
		else begin
			cur_state																			<= next_state;
			case (next_state)
			Idle : begin
				Ready_reg																		<= 1'b0;  
				NaN_reg																			<= 1'b0;
				
				if (En) begin 
					next_state																<= Compare;
					S_A																				<= A[31];
					S_B																				<= B[31];
					E_A																				<= A[30:23];
					E_B																				<= B[30:23];
					M_A																				<= {1'b1, A[22:0]}; 	 
					mult_a																		<= {1'b1, A[22:0]}; 	 
					M_B																				<= {1'b1, B[22:0]}; 
					mult_b																	  <= {1'b1, B[22:0]}; 

				end
				
			end
			Compare : begin
				
				// Check NaN first
				if ((E_A == 8'hFF && M_A != 0) || (E_B == 8'hFF && M_B != 0)) begin
					NaN_reg		 																<= 1'b1; 
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
					Result_reg 																<= {1'b0, 8'hFF, 23'h400000}; // canonical NaN
				end
				
				// Check zero × infinity
				else if (((E_A == 8'hFF && M_A == 0) && (E_B == 0 && M_B == 0)) ||
								 ((E_B == 8'hFF && M_B == 0) && (E_A == 0 && M_A == 0))) begin
					NaN_reg		 																<= 1'b1;  
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
					Result_reg 																<= {1'b0, 8'hFF, 23'h400000}; // canonical NaN
				end
				
				// Check infinity
				else if (E_A == 8'hFF || E_B == 8'hFF) begin
					Result_reg 																<= {A[31]^B[31], 8'hFF, 23'b0}; // Inf
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
				end

				// If A or B are zero, return zero, respecting the sign.
				else if (A[30:0] == 31'b0 || B[30:0] == 31'b0) begin
					Result_reg																<= {S_A ^ S_B, 31'b0};
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
				end
				// CHECK IF DIRECTLY GOING TO IDLE WIHTOUT GOING THROUGH OTHER STAGES WILL AFFECT PIPELINE FEEDING
				
				else begin 
					next_state																<= Operation;
				end
			end
			
			
			
			Operation : begin
				// mult_a																			<= M_A;
				// mult_b																		  <= M_B;
				//M_Mult_temp																	<= M_A * M_B;										// Uses DSP for faster, resource efficient mult
				E_Mult																			<= E_A + E_B - 127;
				S_Mult																			<= S_A ^ S_B;										// Sign of Result 
				next_state																	<= Operation_Wait_1;
			end
			
			Operation_Wait_1: begin
				// Wait
				M_Mult_temp																	<= mult_res;
				next_state																	<= Normalization;
			end
			
			Normalization : begin
				if (M_Mult_temp[47] == 1) begin																							// Overflow detected
					M_Mult_temp																<= M_Mult_temp >> 1;						// Right shit to correct
					E_Mult																		<= E_Mult + 1;									// Update exponent
				end
				
				next_state																	<= Rounding_and_final_Exp_Check;
				
			end
			
			Rounding_and_final_Exp_Check : begin
			
				// Final check for overflow and underflow
				if (E_Mult >= 9'd255) begin
					Result_reg 																<= {A[31]^B[31], 8'hFF, 23'b0}; // Inf
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
				end
				else if (E_Mult <= 0) begin
					Result_reg 																<= {S_Mult, 31'b0};        			// Zero (underflow)
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
				end
				
				M_Mult																			<= M_Mult_temp[46:23];					// First 23 bits (from MSB) are the Mantissa (Includes implied 1)
				// G																						<= M_Mult_temp[24];							// G
				// R																						<= M_Mult_temp[23];							// R
				// S																						<= ^M_Mult_temp[22:0];					// S
																											
				next_state																	<= Done;
				
			end
			
			// Rounding_Apply : begin
			// 	if (G == 1) begin
			// 		if (R == 1 || S == 1) begin
			// 			M_Mult_temp[27:5]
			// 		end
			// 	end
			// end		
			
			Done : begin
				Ready_reg																		<= 1'b1;
				Result_reg																	<= {S_Mult, E_Mult[7:0], M_Mult[22:0]}; // Take 22 bits from Mantissa. MSB is implied 1.
				next_state																	<= Idle;
			end
			
			default : begin
				next_state																	<= Idle;
			end
			
			endcase
		end
	end
	

		
		
	
endmodule
