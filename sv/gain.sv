
module gain #(
	DATA_WIDTH = 32
)
(
	input	logic	[DATA_WIDTH-1:0]	din,
	input	logic	[31:0]				gain,
	output	logic	[DATA_WIDTH-1:0]	dout
);

function automatic logic signed [31:0] mul;
input  logic signed [31:0] x_in;
input  logic signed [31:0] y_in;
    begin
        logic signed [63:0] temp_y = x_in * y_in;
        logic signed [31:0] out_y = temp_y >>> 10;
        return out_y;
    end
endfunction

logic [31:0] quantized_gain;
	always_comb begin
		quantized_gain = gain <<< 10;
		dout = mul(din, quantized_gain) << (14 - 10);
	end

endmodule