`timescale 1ns / 1ps

module FPU23Bit_tb();

    // --- Signals ---
    logic clk;
    logic reset;
    logic rx;
    wire  tx;
    logic debug_sample_point; 

    // --- UART Timing ---
    localparam real BIT_PERIOD = 104180; 
    
    logic [31:0] parsed_result;
    logic [7:0]  rx_byte;
    logic        done_receiving; 

    // --- UUT Instance ---
    FPU23Bit uut (
        .clk(clk), .reset(reset), .rx(rx), .tx(tx)
    );

    // --- 100MHz Clock ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- UART Tasks ---
    task automatic send_byte(input [7:0] data);
        integer i;
        begin
            rx = 0; // Start
            #(BIT_PERIOD);
            for (i = 0; i < 8; i++) begin
                rx = data[i]; 
                #(BIT_PERIOD);
            end
            rx = 1; // Stop
            #(BIT_PERIOD);
        end
    endtask

    task automatic receive_byte(output [7:0] data);
        integer i;
        logic [7:0] temp_reg;
        begin
            @(negedge tx); 
            #(BIT_PERIOD * 1.5);       
            for (i = 0; i < 8; i++) begin
                debug_sample_point = 1; 
                temp_reg[i] = tx;       
                #1000; debug_sample_point = 0; 
                #(BIT_PERIOD - 1000);   
            end
            data = temp_reg;
            #(BIT_PERIOD * 0.2); 
        end
    endtask

    // --- Concurrent Listener Process ---
    initial begin
        forever begin
            wait(!reset);
            done_receiving = 0;
            // Capture 4 bytes for every operation
            receive_byte(rx_byte); parsed_result[31:24] = rx_byte;
            receive_byte(rx_byte); parsed_result[23:16] = rx_byte;
            receive_byte(rx_byte); parsed_result[15:8]  = rx_byte;
            receive_byte(rx_byte); parsed_result[7:0]   = rx_byte;
            done_receiving = 1;
        end
    end

    // --- Test Case Driver Task ---
    task automatic run_test(
        input [7:0]  op,
        input [31:0] valA,
        input [31:0] valB,
        input [31:0] expected,
        input string name
    );
        begin
            $display("[%0t] Starting Test: %s", $time, name);
            
            // Send Op, A (LSB first), B (LSB first)
            send_byte(op);
            send_byte(valA[7:0]);   send_byte(valA[15:8]); 
            send_byte(valA[23:16]); send_byte(valA[31:24]);
            send_byte(valB[7:0]);   send_byte(valB[15:8]); 
            send_byte(valB[23:16]); send_byte(valB[31:24]);

            #5000000;
            
            if (parsed_result === expected)
                $display(">>> PASS: %s | Result: %h", name, parsed_result);
            else
                $display(">>> FAIL: %s | Got: %h, Exp: %h", name, parsed_result, expected);
            
            #50000; // Gap between tests
        end
    endtask

    // --- Main Simulation ---
    initial begin
        reset = 1; rx = 1; debug_sample_point = 0;
        #1000; reset = 0; #5000;

        // 1. ADDITION: 3.5 + 2.0 = 5.5
        run_test(8'h00, 32'h40600000, 32'h40000000, 32'h40B00000, "ADD_BASIC");

        // 2. SUBTRACTION: 5.5 - 2.0 = 3.5 (OpSel 11)
        run_test(8'h03, 32'h40B00000, 32'h40000000, 32'h40600000, "SUB_BASIC");

        // 3. MULTIPLICATION: 2.0 * 1.5 = 3.0 (OpSel 01)
        run_test(8'h01, 32'h40000000, 32'h3FC00000, 32'h40400000, "MULT_BASIC");

        // 4. DIVISION: 6.0 / 2.0 = 3.0 (OpSel 10)
        run_test(8'h02, 32'h40C00000, 32'h40000000, 32'h40400000, "DIV_BASIC");

        // --- EDGE CASES ---

        // 5. INF: 1.0 / 0.0 = Infinity (7F800000)
        run_test(8'h02, 32'h3F800000, 32'h00000000, 32'h7F800000, "DIV_BY_ZERO_INF");

        // 6. NaN: 0.0 / 0.0 = NaN (Usually 7FC00000 or similar)
        // Note: Check your Divider RTL for specific NaN output pattern
        //run_test(8'h02, 32'h00000000, 32'h00000000, 32'h7FC00000, "DIV_ZERO_BY_ZERO_NAN");

        // 7. MULT BY ZERO: 5.5 * 0.0 = 0.0
        run_test(8'h01, 32'h40B00000, 32'h00000000, 32'h00000000, "MULT_BY_ZERO");

        $display("[%0t] --- All Tests Finished ---", $time);
        #100000; $finish;
    end

endmodule