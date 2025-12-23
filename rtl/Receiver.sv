`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2025 06:53:33 PM
// Design Name: 
// Module Name: Receiver
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


module Receiver # (
			parameter logic [15:0] BAUD_DIVISOR = 16'h1458
		)(
			input	logic 																	clk,
			input logic 																	reset,					// Active high
			input logic																		rx,							// Input data bit stream
			input logic																		data_en,				// Pull high to get received data out -- not used here.
			output logic 																	tx_error,				// When there's an error (incoming data doesn't adhere UART protocol)
			output logic																	rx_busy,				// High when receiving
			output logic														[7:0] data_out				// Output data 8 bit
    );



		// For slow clock
		logic [15:0]	baud_counter = 16'b0;															// Initialise counter for slow clock
		logic					rx_clk;                                            
		logic 				rx_clk_bk;																				// Clock backup for reliable detection of rising edge
		
		// Slow clock FSM
		typedef enum logic {								
			CLK_IDLE,																											// Rx clock is idling
			CLK_ONGOING																										// Rx clock is ongoing when Receiver is receiving
		} state_clk;
		
		state_clk clk_state;
		
		// For Rx 
		logic [7:0] received_data;																		
		logic [2:0] rx_bit;
		logic				rx_sync;																						// Used to sync rx changes to clk to prevent glitches/metastable states
		
		// Rx FSM
		typedef enum logic [1:0] {
			RX_IDLE,
			RX_DATA,
			RX_END
		} state_r;
		
		state_r rx_state;
		
		
		// Generate the slow speed clock for the Receiver
		// rx_clk must start low to be 180 deg out of phase with tx_clk to enable sampling at bit centers
		// When rx_clk is in CLK_IDLE, no counting or toggling
		// rx line is pulled down at rising edge of tx_clk. rx_clk is 0 at this point, making it 180 deg out of phase

		always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			baud_counter 																	<= 16'b0;
		  rx_clk																				<= 1'b0; 			 // Rx clock starts at 0 for 180 degree phase shift wrt tx clock
			rx_clk_bk																			<= 1'b0;
			clk_state																			<= CLK_IDLE;
		end
		else begin
			if (rx_busy == 1'b0) begin
				clk_state																		<= CLK_IDLE;   // clk_state reset when receiveing is complete
			end 
			
			case (clk_state)
				CLK_IDLE : begin
					baud_counter 															<= 16'b0;
					rx_clk																		<= 1'b0; 				
					rx_clk_bk																	<= 1'b0;
					
					if(rx_busy == 1'b1) begin																	// becomes high when rx line is pulled low
						clk_state																<= CLK_ONGOING;	// rx_clk begins when rx line is pulled low
					end
				end
				
				CLK_ONGOING : begin
					rx_clk_bk																	<= rx_clk;			// rx_clk_bk follows rx_clk one clock cycle later
					if (baud_counter >= BAUD_DIVISOR) begin
						baud_counter 														<= 16'b0;				// Reset counter when it reaches BAUD_DIVISOR
						rx_clk																	<= ~ rx_clk;
					end
					
					else 
						baud_counter <= baud_counter + 1;												// Increment counter
					end
				
				default: begin
						clk_state 																 <= CLK_IDLE;
        end
			
			endcase
			

		end
		end
		
		
		// REMEMBER TO CHANGE CLOCK STATE TO ONGOING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11
		
		// Receiver logic
		always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			rx_sync																				<= 1'b1;
			received_data																	<= 8'b0;
			data_out																			<= 8'b0;
			tx_error																			<= 1'b0;
			rx_busy																				<= 1'b0;
			rx_state																			<= RX_IDLE;
			rx_bit																				<= 3'b0;
		end
		else begin
			rx_sync <= rx;																							 	// Sync rx to clk
			case (rx_state) 
				RX_IDLE : begin
					received_data															<= 8'b0;
					tx_error																	<= 1'b0;				// tx_erroror is 0 
					rx_busy																		<= 1'b0;				// rx_busy is low when not receiving
					rx_bit 																		<= 3'b0;
					
					if (rx_sync == 1'b0) begin														  	// Rx line pulled low
						rx_busy																	<= 1'b1;				// rx_busy is set to high as receiver is now receiving
					end
					
					if (rx_clk == 1'b1 && rx_clk_bk == 1'b0) begin						// State change happens with slow clock
						rx_state																<= RX_DATA;
					end
					
				end
				
				RX_DATA : begin
					if (rx_clk == 1'b1 && rx_clk_bk == 1'b0) begin
						if (rx_bit == 8'd7) begin
							rx_state															<= RX_END;			// Move to RX_END state after all 8 bits have been received
						end
						
						received_data[rx_bit]										<= rx_sync;			// Store the sampled rx bit in the relevant position of received_data
						rx_bit 																	<= rx_bit + 1;
					end
				
				end
				
				RX_END : begin
					if (rx_clk == 1'b1 && rx_clk_bk == 1'b0) begin
						if (rx_sync != 1'b1) begin															// If stop bit isn't high -> error
							tx_error 															<= 1'b1;				// Error indicated
							rx_state															<= RX_IDLE;			
						end
						else begin
							data_out															<= received_data;	// Output gets data
							rx_busy																<= 1'b0;					// Pulled down to indicate that receiving is complete. 
							rx_state															<= RX_IDLE;				// Next state is RX_IDLE
						end
					end
				end
				
				default : begin
					rx_state																	<= RX_IDLE;
				end
			endcase
		
		end	
		end 
		
		
		endmodule