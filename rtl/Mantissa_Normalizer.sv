module Mantissa_Normalizer (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [23:0] mantissa_in,     // 24-bit mantissa input (with hidden 1)
    output logic [23:0] mantissa_out,    // normalized mantissa output
    output logic [4:0]  shift_count,     // number of left shifts applied
    output logic        valid            // output valid flag
);

    logic [4:0]  shift_count_comb;
    logic        valid_comb;

    always_comb begin
        valid_comb = 1'b1;

        if (mantissa_in == 24'b0) begin
            shift_count_comb = 5'd0;
            valid_comb       = 1'b0;
        end
        else if (mantissa_in[23]) shift_count_comb = 0;
        else if (mantissa_in[22]) shift_count_comb = 1;
        else if (mantissa_in[21]) shift_count_comb = 2;
        else if (mantissa_in[20]) shift_count_comb = 3;
        else if (mantissa_in[19]) shift_count_comb = 4;
        else if (mantissa_in[18]) shift_count_comb = 5;
        else if (mantissa_in[17]) shift_count_comb = 6;
        else if (mantissa_in[16]) shift_count_comb = 7;
        else if (mantissa_in[15]) shift_count_comb = 8;
        else if (mantissa_in[14]) shift_count_comb = 9;
        else if (mantissa_in[13]) shift_count_comb = 10;
        else if (mantissa_in[12]) shift_count_comb = 11;
        else if (mantissa_in[11]) shift_count_comb = 12;
        else if (mantissa_in[10]) shift_count_comb = 13;
        else if (mantissa_in[9])  shift_count_comb = 14;
        else if (mantissa_in[8])  shift_count_comb = 15;
        else if (mantissa_in[7])  shift_count_comb = 16;
        else if (mantissa_in[6])  shift_count_comb = 17;
        else if (mantissa_in[5])  shift_count_comb = 18;
        else if (mantissa_in[4])  shift_count_comb = 19;
        else if (mantissa_in[3])  shift_count_comb = 20;
        else if (mantissa_in[2])  shift_count_comb = 21;
        else if (mantissa_in[1])  shift_count_comb = 22;
        else if (mantissa_in[0])  shift_count_comb = 23;
        else begin
            shift_count_comb = 0;
            valid_comb = 0;
        end
    end
		
		assign mantissa_out 														= mantissa_in << shift_count_comb;
		assign shift_count 															= shift_count_comb;
		assign valid 																		= valid_comb;

endmodule
