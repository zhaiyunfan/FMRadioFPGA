import macros::*;

module multiply_n #(
    DATA_WIDTH = 32
)
(
    input  logic [DATA_WIDTH-1:0] x_in,
    input  logic [DATA_WIDTH-1:0] y_in,
    output logic [DATA_WIDTH-1:0] dout
);

assign dout = DEQUANTIZE(x_in * y_in);

endmodule