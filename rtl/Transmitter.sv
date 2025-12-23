`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2025 06:34:36 PM
// Design Name: 
// Module Name: Transmitter
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
// baud_divisor --  baud_rate
//
// x"05161";  	--    2400
// x"028b0";  	--    4800
// x"01458";  	--    9600
// x"00d90";  	--   14400
// x"00a2c";  	--   19200
// x"006c8";  	--   28800
// x"00516";  	--   38400 
// x"00364";  	--   57600
// x"0028b";  	--   76800
// x"001b2";  	--  115200
// x"000d9"; 	  --  230400
// x"0006c"; 	  --  460800
// x"00036";    --  921600
// x"001b2";    --  115200 
//////////////////////////////////////////////////////////////////////////////////


module Transmitter # (
			parameter logic [15:0] BAUD_DIVISOR = 16'h1458
		)(
			input	logic 																	clk,
			input logic 																	reset,					// Active high
			input logic															[7:0]	data_in,				// Input 8 bit Data
			input logic																		tx_en,					// Pull high to enable Tx
			output logic																	tx_busy,				// High when Tx busy
			output logic																	tx							// Output data stream
    );
		
		// For slow clock
		logic [15:0]	baud_counter = 16'b0;															// Initialise counter for slow clock
		logic					tx_clk;                                            
		logic 				tx_clk_bk;																				// Clock backup for reliable detection of rising edge
		
		// For FSM
		typedef enum logic [1:0] {
			TX_IDLE,
			TX_DATA,
			TX_END
		} state_t;
		
		state_t state;
		
		// For Tx 
		logic [7:0] data;
		logic 			tx_en_given;																				// Latches on to tx_en until the next tx_clk posedge
		logic [2:0] tx_bit;
		
		// Generate the slow speed clock for the Transmitter
		always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			baud_counter 																	<= 16'b0;
		  tx_clk																				<= 1'b0;
			tx_clk_bk																			<= 1'b0;
		end
		else begin
			tx_clk_bk																			<= tx_clk;			// tx_clk_bk follows tx_clk one clock cycle later
			if (baud_counter >= BAUD_DIVISOR) begin
				baud_counter 																<= 16'b0;				// Reset counter when it reaches BAUD_DIVISOR
				tx_clk																			<= ~ tx_clk;
			end
			
			else 
				baud_counter <= baud_counter + 1;	// Increment counter
		end
		end
		
		// Transmission
		always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			state																				 <= TX_IDLE;
			data																				 <= 8'b0;
			tx																					 <= 1'b1;					// Pull tx line high 
			tx_busy																			 <= 1'b0;
			tx_en_given																 	 <= 1'b0;
			tx_bit																			 <= 3'b0;
		end
		else begin
			case (state) 
				TX_IDLE : begin
					data 																		 <= data_in;
					tx 																			 <= 1'b1;					// Tx line high when not transmitting
					tx_busy																	 <= 1'b0; 				// Indicate that transmitter is not busy 
					tx_bit																	 <= 3'd0;					// Reset value of tx_bit 
					
					if (tx_en == 1'b1) begin
						tx_en_given 												 	 <= 1'b1;					// Latch onto tx_en even if it's only 1 clock cycle long
					end
					
					if (tx_clk == 1'b1 && tx_clk_bk == 1'b0) begin						// Denotes rising edge of tx_clk 
						if (tx_en_given == 1'b1) begin
							tx 																	 <= 1'b0;					// Pull Tx down to indicate tranmission has begun
							tx_busy															 <= 1'b1;					// Indicate tx busy
							tx_en_given												   <= 1'b0;					// Reset tx_en_given latch
							state																 <= TX_DATA;			// State changes to data on next clock cycle
						end
					end
				end
				
				TX_DATA : begin
					if (tx_clk == 1'b1 && tx_clk_bk == 1'b0) begin	
						if (tx_bit == 3'd7) begin
							state																 <= TX_END; 			// When all 8 bits are transmitted, move to TX_END state 
						end
						
						tx 																		 <= data[tx_bit]; // Transmit relevant bit 
						tx_bit															 	 <= tx_bit + 1;
					end 
				
				end
				
				TX_END : begin
					if (tx_clk == 1'b1 && tx_clk_bk == 1'b0) begin	
						tx 																		 <= 1'b1; 				// Pull Tx line high when done
						state 															   <= TX_IDLE;			// Next state is TX_IDLE
					end
				
				end
				
				default: begin
						state 																 <= TX_IDLE;
        end
				
				
			endcase
		end
		end
endmodule
