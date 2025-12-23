`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Pravindu Goonetilleke
// 
// Create Date: 12/17/2025 10:23:17 PM
// Design Name: 
// Module Name: FPU23Bit
// Project Name: Floating Point Arithmetic Unit 32 Bit
// Target Devices: Zybo
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


module FPU23Bit(
    input clk,
    input reset,
    // input [31:0] A,
    // input [31:0] B,
    // input En,
    // input [1:0] OpSel,       // 00: Add, 01: Mult, 10: Div 11: Sub
		input rx, 							 // Uart Signals 
		output tx 							 // Uart Signals  
    // output reg [31:0] Result,
    //output reg Ready,
    // output reg NaN
);
		
		
		// FPU Signals
		logic	[31:0] 															A;
		logic	[31:0] 															B;
		logic  [1:0]															OpSel;
		logic																			En;
    logic [31:0]  														Result;
    logic  																		Ready;
    logic  																		NaN;
		
    // Internal signals to connect modules
    logic 																					[31:0] sum_out, mult_out, div_out;
    logic 																					ready_add, ready_mult, ready_div;
    logic 																					nan_mult, nan_div;
		logic 																					[31:0] B_adjusted;
		assign																					B_adjusted = { (OpSel == 2'b11) ? ~B[31] : B[31], B[30:0] };
		
		// UART Signals
		logic [7:0] 																		data_in;
		logic																						tx_en;
		logic																						data_en;
		logic																						tx_busy;
		logic																						tx_error;
		logic																						rx_busy;
		logic	[7:0]																			data_out;
		
		parameter logic [15:0] BAUD_DIVISOR = 16'h1458;
		
		// Received data (post parsing)
		logic [31:0]																		A_reg;
		logic [31:0]																		B_reg;
		logic  [1:0]																		operand_reg;
		logic  [7:0]																		temp_rec_reg;
		
		// Data to send (pre parsing)
		logic [31:0]																		data_out_reg;
		
		// Debug Signals
		logic 																					debug;
		
		// Parsing states
		typedef enum logic [4:0] {
			IDLE 																					= 5'd0, 
			OPERAND 																			= 5'd1, 		
			A_7_0 																				= 5'd2, 	// Parse A
			A_15_8 																				= 5'd3, 	// Parse A
			A_31_24 																			= 5'd4, 	// Parse A	
			A_23_16 																			= 5'd5, 	// Parse A	
			B_7_0 																				= 5'd6, 	// Parse B
			B_15_8 	  																		= 5'd7, 	// Parse B
			B_31_24 																			= 5'd8, 	// Parse B	
			B_23_16 																			= 5'd9, 	// Parse B
			EXECUTE																				= 5'd10,	// Execute operation 
			DATA_OUT_31_24 																= 5'd11,	// Parse Output						
			DATA_OUT_23_16 																= 5'd12,  // Parse Output	
			DATA_OUT_15_8 																= 5'd13,	// Parse Output						
			DATA_OUT_7_0 																	= 5'd14,	// Parse Output					
			WAIT_FOR_UART																  = 5'd15,	// Waits for rx or tx to stop to handle byte / send next byte
			WAIT_FOR_OP																	  = 5'd16,	// Waits for end of operation to move onto next state
			DONE																					= 5'd17							
		} states;
		
		states state;
		states next_state;
		
		// Instantiate UART
		UART #(
				.BAUD_DIVISOR(BAUD_DIVISOR)
			)uart_module(
				.clk(clk),
				.reset(reset),
				.data_in(data_in),
				.tx_en(tx_en),
				.rx(rx),
				.data_en(data_en),
				.tx_busy(tx_busy),
				.tx(tx),
				.tx_error(tx_error),
				.rx_busy(rx_busy),
				.data_out(data_out)
			);

    //Instantiate the Adder
    Adder unit_add (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B_adjusted),
        .En(En && (OpSel == 2'b00 || OpSel == 2'b11)),
        .Sum(sum_out),
        .Ready(ready_add)
    );

    //Instantiate the Multiplier
    Multiplier unit_mult (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .En(En && (OpSel == 2'b01)),
        .Result(mult_out),
        .Ready(ready_mult),
        .NaN(nan_mult)
    );

    //Instantiate the Divider
    Divider unit_div (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .En(En && (OpSel == 2'b10)),
        .Result(div_out),
        .Ready(ready_div),
        .NaN(nan_div)
    );


		// UART receiving and parsing
		always_ff @(posedge clk or posedge reset) begin
			if (reset) begin
				state																				<=  IDLE;
				next_state																	<= OPERAND;
				A_reg																				<= 32'b0;
				B_reg																				<= 32'b0;
				operand_reg																	<=  2'b0;
				data_out_reg																<= 32'b0;
				temp_rec_reg																<=  8'b0;
				A																						<= 32'b0;
				B																						<= 32'b0;
				OpSel																				<=  2'b0;
				En																					<=  1'b0;
				tx_en																				<=  1'b0;
				
			end
			else begin
				case (state)
				IDLE : begin
					next_state																<= OPERAND;
					A_reg																			<= 32'b0;
					B_reg																			<= 32'b0;
					operand_reg																<=  2'b0;
					data_out_reg															<= 32'b0;
					temp_rec_reg															<=  8'b0;
					A																					<= 32'b0;
					B																					<= 32'b0;
					OpSel																			<=  2'b0;
					En																				<=  1'b0;
					tx_en																			<=  1'b0;
					debug																			<=  1'b0;
				
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
					

				end
				OPERAND : begin
					operand_reg																<= temp_rec_reg;
					
					next_state																<= A_7_0;
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
					
				end
									
				A_7_0 : begin
					A_reg[7:0]																<= temp_rec_reg;
					
					next_state																<= A_15_8;
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
							
				A_15_8 : begin
					A_reg[15:8]																<= temp_rec_reg;
					
					next_state																<= A_23_16;
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
							
							
				A_23_16 : begin
					A_reg[23:16]															<= temp_rec_reg;
					
					next_state																<= A_31_24;
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
				
				A_31_24 : begin
					A_reg[31:24]															<= temp_rec_reg;
					
					next_state																<= B_7_0;
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
							
				B_7_0 : begin
					B_reg[7:0]																<= temp_rec_reg;
					
					next_state																<= B_15_8;
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
							
				B_15_8 : begin
					B_reg[15:8]																<= temp_rec_reg;
					
					next_state																<= B_23_16;
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
							
				
				B_23_16 : begin
					B_reg[23:16]															<= temp_rec_reg;
					
					next_state																<= B_31_24;
					if (rx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
				
				B_31_24 : begin
					B_reg[31:24]															<= temp_rec_reg;
					
					state																			<= EXECUTE;
				end	

				// Give the inputs to the fpu and assert En
				EXECUTE : begin
					A																					<= A_reg;
					B																					<= B_reg;
					OpSel																			<= operand_reg[1:0];
					En																				<= 1'b1;
					
					state																			<= WAIT_FOR_OP;
				end
				
				DATA_OUT_31_24 : begin
					data_in																		<= data_out_reg[31:24];
					tx_en																			<= 1'b1;								// Begin tx
					next_state																<= DATA_OUT_23_16;
					if (tx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
				
				DATA_OUT_23_16 : begin
					data_in																		<= data_out_reg[23:16];
					tx_en																			<= 1'b1;								// Begin tx
					next_state																<= DATA_OUT_15_8;
					if (tx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
				
				DATA_OUT_15_8 : begin
					data_in																		<= data_out_reg[15:8];
					tx_en																			<= 1'b1;								// Begin tx
					next_state																<= DATA_OUT_7_0;
					if (tx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
				DATA_OUT_7_0 : begin
					data_in																		<= data_out_reg[7:0];
					tx_en																			<= 1'b1;								// Begin tx
					next_state																<= DONE;
					if (tx_busy) begin
						state																		<= WAIT_FOR_UART;
					end
				end
				WAIT_FOR_UART : begin
					tx_en																			<= 1'b0;				// Deassert tx_en for tx states 
					if (!rx_busy && !tx_busy) begin
						state																		<= next_state;	// Move to next state whenever a byte is fully received / sent
						temp_rec_reg														<= data_out;		// when rx_busy is pulled down, data avail at data_out
																																		// store data in temp_rec_reg till it can be handled
						
					end
				//	if ((!tx_busy && 
				//															(next_state == DATA_OUT_23_16) ||
				//															(next_state == DATA_OUT_15_8) ||
				//															(next_state == DATA_OUT_7_0) ||
				//															(next_state == DONE)
				//															)) begin
				//		debug																		<= 1;
				//	end 
				end
				
				WAIT_FOR_OP : begin
					En																				<= 1'b0;				// Deassert En
					if (Ready) begin
						data_out_reg														<= Result;
						state																		<= DATA_OUT_31_24;
					end
				end
					
				DONE : begin
					state																			<= IDLE;
				end
				default	: begin
					state																			<= IDLE;
				end

				
				endcase
			
			end
		end


    //Output Multiplexing Logic
    always @(*) begin
        case (OpSel)
            2'b00: begin
                Result 															= sum_out;
                Ready  															= ready_add;
                NaN    															= 1'b0; 												// Adder doesn't have a NaN port 
            end
						2'b11: begin
                Result 															= sum_out;
                Ready  															= ready_add;
                NaN    															= 1'b0; 												// Adder doesn't have a NaN port 
            end
            2'b01: begin
                Result 															= mult_out;
                Ready  															= ready_mult;
                NaN    															= nan_mult;
            end
            2'b10: begin
                Result 															= div_out;
                Ready  															= ready_div;
                NaN    															= nan_div;
            end
						
            default: begin
                Result 															= 32'h0;
                Ready  															= 1'b0;
                NaN    															= 1'b0;
            end
        endcase
    end

endmodule
