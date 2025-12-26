`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 08:41:18 PM
// Design Name: 
// Module Name: Divider
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


module Divider(
			input																					clk
		,	input																					reset
		,	input [31:0]																	A
		, input [31:0]																	B
		,	input 																				En
		,	output [31:0]																	Result
		, output																				Ready
		, output 																				NaN
    );
		
	// Lut signals 
	logic [9:0]																				lut_idx;
	logic [31:0]																			lut_out;
	logic [31:0]																			lut_out_next;
		
	// Reciprocal LUT
	reciprocal_lut LUT(
			.lut_idx (lut_idx)
		,	.X0			 (lut_out)
		);
		
	// Components of FP32
	logic																							S_A;
	logic																							S_B;
	logic [7:0]																				E_A;
	logic [7:0]																				E_B;
	logic [23:0]																			M_A;	 											// Extra bit for implicit 1
	logic [23:0]																			M_B;   											// Extra bit for implicit 1  
	
	// Internal Signals 
	reg signed [9:0]																	E_Div;											// Signed to detect underflow (E_Div <= 0)
	logic																							S_Div;	
	logic [23:0]																			M_Div; 											// Extra bit for implicit 1	
	logic [31:0]																			Result_reg;
	logic 																						Ready_reg;
	logic 																						NaN_reg;
	logic 																						G;
	logic 																						R; 
	logic 																						S;
	
	// NR-specific regs
	logic [31:0]    																	R_q;           							// reciprocal in Q2.30
	logic [31:0]    																	Dq;            							// divisor mantissa in Q2.30
	logic [31:0]    																	MAq;           							// numerator mantissa in Q2.30
	logic [31:0]    																	x;             							// iterative Q2.30
	logic [63:0]    																	tmp64;							
	logic [63:0]    																	prod64;
	logic [1:0]																				iter;
	logic [1:0]																				iter_count = 2'd2;
	//logic [7:0]     																	lut_idx;       							// index width depends on LUT bits
	
	
	//FSM 
	typedef enum logic[4:0]{
			Idle
		,	Compare
		,	Init
		,	NR1_1
		, NR_Wait_1
		, NR_Wait_2
		,	NR1_2
		,	NR1_3
		,	NR1_4
		, NR_Wait_3
		, NR_Wait_4
		,	NR1_5
		, Multiply
		, Multiply_Wait_1
		, Multiply_Wait_2
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
	logic [31:0] mult_a, mult_b;
	logic [63:0] mult_res;

	// Force DSP
	(* use_dsp = "yes" *) 
	always_ff @(posedge clk) begin
			// No reset here for maximum performance
			mult_res 																			<= mult_a * mult_b;
	end
	
	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			next_state																		<= Idle;
			S_Div																					<= 1'b0;
			E_Div																					<= 10'b0;
			M_Div																			  	<= 24'b0; 			
			Result_reg																		<= 32'b0;
			Ready_reg																			<= 1'b0;
			NaN_reg																				<= 1'b0;
			G																							<= 1'b0;
			R																							<= 1'b0; 
			S																							<= 1'b0;
			lut_idx																				<= 10'b0;
			lut_out_next																	<= 32'b0;
			Dq																						<= 32'b0;   
			x   																					<= 32'b0;    
			tmp64 																				<= 64'b0;
			prod64																				<= 64'b0;
			iter																					<= 2'b0;
			mult_a																				<= 32'b0;
			mult_b																				<= 32'b0;
		
		end
		else begin
			cur_state																			<= next_state;
			case (next_state)
			Idle : begin
				Ready_reg																		<= 1'b0;  
				NaN_reg																			<= 1'b0;
				lut_idx																			<= 10'b0;
				lut_out_next																<= 32'b0;
				R_q																					<= 32'b0;  
				Dq																					<= 32'b0;   
				MAq 																				<= 32'b0;  
				x   																				<= 32'b0;    
				tmp64 																			<= 64'b0;
				prod64																			<= 64'b0;
				iter																				<= 2'b0;
				mult_a																			<= 32'b0;
			  mult_b																			<= 32'b0;
				
				if (En) begin 
					next_state																<= Compare;
					S_A																				<= A[31];
					S_B																				<= B[31];
					E_A																				<= A[30:23];
					E_B																				<= B[30:23];
					M_A																				<= {1'b1, A[22:0]}; 	 
					M_B																				<= {1'b1, B[22:0]}; 
					lut_idx																		<= B[22:13]; 										// Initial guess will be available in lut_out
					
				end
				
			end
			Compare : begin
				
				// Check NaN first
				if (A == 32'h7FC00000 || B == 32'h7FC00000) begin
					NaN_reg		 																<= 1'b1; 
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
					Result_reg 																<= {1'b0, 8'hFF, 23'h400000}; // canonical NaN
				end
				
				else if ((E_A == 8'hFF && M_A != 0) && (E_B == 8'hFF && M_B != 0)) begin
					NaN_reg		 																<= 1'b1; 
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
					Result_reg 																<= {1'b0, 8'hFF, 23'h400000}; // canonical NaN
				end
				
				// Check 0/0
				else if (A[30:0] == 31'b0 && B[30:0] == 31'b0) begin
					NaN_reg		 																<= 1'b1;  
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
					Result_reg 																<= {1'b0, 8'hFF, 23'h400000}; // canonical NaN
				end
				
				// B = 0, A non zero
				else if (B[30:0] == 31'b0) begin
					Result_reg 																<= {A[31]^B[31], 8'hFF, 23'b0}; // Inf
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
				end

				// A = Inf
				else if (E_A == 8'hFF) begin
					Result_reg 																<= {S_A ^ S_B, 8'hFF, 23'b0}; // Inf
					Ready_reg 																<= 1'b1; 
					next_state  															<= Idle;
				end
				
				// B = inf
				else if (E_B == 8'hFF) begin
					Result_reg 																<= {S_A ^ S_B, 8'd0, 23'b0}; // Zero
					Ready_reg  																<= 1'b1; 
					next_state 																<= Idle;
				end
				else if (A[30:0] == 31'b0 ) begin
					Result_reg 																<= {S_A ^ S_B, 8'd0, 23'b0}; // Zero
					Ready_reg  																<= 1'b1; 
					next_state 																<= Idle;
				end
				// CHECK IF DIRECTLY GOING TO IDLE WIHTOUT GOING THROUGH OTHER STAGES WILL AFFECT PIPELINE FEEDING
				
				else begin 
					next_state																<= Init;
				end
			end
			
			Init : begin
				E_Div																				<= E_A - E_B + 127;
				Dq																					<= {M_B, 8'b0};   							// M_B is 24 bits
				next_state																	<= NR1_1;
			end	
			
			NR1_1: begin
				if (iter < iter_count) begin
					iter 																			<= iter + 1;
					next_state																<= NR_Wait_1;
					if (iter == 0) begin
						lut_out_next														<= lut_out; 										 // Initial update of lut_out_next
						mult_a																	<= Dq;
						mult_b																	<= lut_out;
						//tmp64																		<= Dq * lut_out;		 						 // Initially mult by lut_out
					end
					else begin
						// tmp64																		<= Dq * lut_out_next;						 // Now lut_out_next is updated
						mult_a																	<= Dq;
						mult_b																	<= lut_out_next;
					end
				end 
				else if (iter == iter_count) begin
					next_state																<= Multiply;
				end
			end
			
			NR_Wait_1 : begin
				// Wait
				next_state																	<= NR_Wait_2;
			end	
			
			NR_Wait_2 : begin
				// Result available
				tmp64																				<= mult_res;
				next_state																	<= NR1_2;
			end
			
			NR1_2: begin
				tmp64																				<= tmp64 >> 31;				
				next_state																	<= NR1_3;
			end
			
			NR1_3: begin
				tmp64																				<= (2 << 31) - tmp64;				
				next_state																	<= NR1_4;
			end
			
			NR1_4: begin
				//tmp64																				<= lut_out_next * tmp64;
				mult_a																			<= lut_out_next;
				mult_b																			<= tmp64;
				
				next_state																	<= NR_Wait_3;
			end
			
			NR_Wait_3: begin	
			  // Wait
				next_state																	<= NR_Wait_4;
			end
			
			NR_Wait_4: begin
				tmp64																				<= mult_res;
				next_state																	<= NR1_5;
			end
			
			NR1_5: begin
				lut_out_next																<= tmp64 >> 31; 								// Eventually becomes the final Reciprocal
				next_state																	<= NR1_1;
			end

			
			Multiply: begin
				mult_a																			<= M_A;
				mult_b																			<= lut_out_next;
				//prod64																			<= M_A * lut_out_next;				  // Multiply by reciprocal => Division
				S_Div																				<= S_A ^ S_B;										// Sign of Result 
				next_state																	<= Multiply_Wait_1;
			end
			
			Multiply_Wait_1: begin
				// Wait
				next_state																  <= Multiply_Wait_2;
			end
			
			Multiply_Wait_2: begin
				prod64																			<= mult_res;
				next_state																	<= Normalization;
			end

			
			Normalization : begin
				if (prod64[54] == 0) begin																									// underflow detected
					prod64																		<= prod64 << 1;							    // left shit to correct
					E_Div																			<= E_Div - 1;										// Update exponent
				end 
				// else begin
				// 	prod64																		<= prod64 >> 31;
				// end
				
				next_state																	<= Rounding_and_final_Exp_Check;
				
			end
			
			Rounding_and_final_Exp_Check : begin
			
				// Final check for overflow and underflow
				if (E_Div[9] == 1) begin
					Result_reg 																<= {S_Div, 31'b0};        			// Zero (underflow)
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
				end
				else if (E_Div[8] == 1 || E_Div[7:0] == 8'd255) begin
					Result_reg 																<= {A[31]^B[31], 8'hFF, 23'b0}; // Inf
					Ready_reg																	<= 1'b1;
					next_state																<= Idle;
				end
				else begin
					M_Div																			<= prod64[54:31];					// First 23 bits (from MSB) are the Mantissa (Includes implied 1)
					next_state																<= Done;
				end
				

				
			end
			
			// Rounding_Apply : begin
			// 	if (G == 1) begin
			// 		if (R == 1 || S == 1) begin
			// 			M_Div_temp[27:5]
			// 		end
			// 	end
			// end		
			
			Done : begin
				Ready_reg																		<= 1'b1;
				Result_reg																	<= {S_Div, E_Div[7:0], M_Div[22:0]}; // Take 22 bits from Mantissa. MSB is implied 1.
				next_state																	<= Idle;
			end
			
			default : begin
				next_state																	<= Idle;
			end
			
			endcase
		end
	end
	

		
		
		
endmodule
