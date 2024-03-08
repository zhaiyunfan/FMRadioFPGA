

module multiply #(
    DATA_WIDTH = 32
)
(
    input  logic [DATA_WIDTH-1:0] x_in,
    input  logic [DATA_WIDTH-1:0] y_in,
    output logic [DATA_WIDTH-1:0] dout
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

assign dout = DEQUANTIZE(x_in * y_in);

endmodule