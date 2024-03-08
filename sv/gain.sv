
module gain #(
	DATA_WIDTH = 32
)
(
	input	logic	[DATA_WIDTH-1:0]	din,
	input	logic	[31:0]				gain,
	output	logic	[DATA_WIDTH-1:0]	dout
);

function logic signed [31:0] QUANTIZE_I; 
input logic signed [31:0] i;
    begin
        return i <<< 10;
    end
endfunction

function logic signed [31:0] DEQUANTIZE; 
input logic signed [31:0] i;
    logic signed [31:0] offset_i;
    begin
		offset_i =  i[31] == 1 ? (i + ((1 << 10) - 1)): i;

		return offset_i >>> 10;
    end
endfunction


function logic signed [31:0] mul;
input  logic signed [31:0] x_in;
input  logic signed [31:0] y_in;
    begin
        return DEQUANTIZE(x_in * y_in);
    end
endfunction

logic [31:0] quantized_gain;
	always_comb begin
		quantized_gain = gain <<< 10;
		dout = mul(din, quantized_gain) << (14 - 10);
	end

endmodule