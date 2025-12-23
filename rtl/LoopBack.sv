`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2025 10:04:27 PM
// Design Name: 
// Module Name: LoopBack
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


module LoopBack(
		input logic																			clk,
		input logic																			reset, 
		input logic																			rx,
		output logic																		tx
    );
		
		logic [7:0] data_in;
		logic				tx_en;
		logic				data_en;
		logic				tx_busy;
		logic				tx_error;
		logic				rx_busy;
		logic	[7:0]	data_out;
		
		parameter logic [15:0] BAUD_DIVISOR = 16'h1458;
		
		typedef enum logic [1:0] {
			S0,
			S1,
			S2,
			S3
		} states;
		
		states state;
		
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
			
		
		// Loop back
		always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			state																					<= S0;
			tx_en																					<= 1'b0;
		end
		
		else begin
			case (state)
				S0 : begin	// IDLE
					tx_en 																		<= 1'b0;
					if (rx_busy == 1'b1) begin // Rx starting.
						state																		<= S1;
					end
				end
				
				S1 : begin	// Receiving
					if (rx_busy == 1'b0) begin // Rx done.
						state																		<= S2;
					end
				end
				
				S2 : begin	// RX done. Begin TX
					data_in																		<= data_out;
					tx_en																			<= 1'b1;
					state																			<= S3;
				end
				
				S3 : begin	// Transmitting
					if (tx_busy == 1'b0) begin	// Tx done.
						tx_en																		<= 1'b0;
						state																		<= S0;
					end 
				end
				
				default : begin
					state																			<= S0;
				end
			endcase
		
		end
		
		end // end of always_ff
		
		
endmodule
