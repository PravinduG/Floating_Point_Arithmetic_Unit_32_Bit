`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2025 10:09:12 PM
// Design Name: 
// Module Name: UART
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


module UART # (
		parameter logic [15:0] BAUD_DIVISOR = 16'h1458
		)(
		input logic																			clk,
		input logic																			reset,
		input logic 															[7:0]	data_in,
		input logic																			tx_en,
		input logic																			rx,
		input logic																			data_en,
		output logic																		tx_busy,
		output logic																		tx,
		output logic																		tx_error,
		output logic																		rx_busy,
		output logic															[7:0] data_out

    );
		
		
		logic [7:0] tx_data;																															// Data to be transmitted
		
		Transmitter #(
			.BAUD_DIVISOR(BAUD_DIVISOR)
		)transmitter (
			.clk(clk),
			.reset(reset),
			.data_in(data_in),
			.tx_en(tx_en),
			.tx_busy(tx_busy),
			.tx(tx)
		
		);
		
		Receiver #(
			.BAUD_DIVISOR(BAUD_DIVISOR)
		)receiver (
			.clk(clk),
			.reset(reset),
			.rx(rx),
			.data_en(data_en),																																	// Not used 
			.tx_error(tx_error),
			.rx_busy(rx_busy),
			.data_out(data_out)
		);
		
		
endmodule
