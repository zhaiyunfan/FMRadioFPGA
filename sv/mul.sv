function logic[31:0] QUANTIZE_I; 
input logic[31:0] i;
    begin
        return $signed(i) <<< 10;
    end
endfunction

function logic[31:0] DEQUANTIZE; 
input logic[31:0] i;
    begin
        return $signed(i) >>> 10;
    end
endfunction


function logic[31:0] mul;
input  logic [31:0] x_in;
input  logic [31:0] y_in;
    begin
        return DEQUANTIZE(x_in * y_in);
    end
endfunction

// module mul #(
//     DATA_WIDTH = 32
// )
// (
//     input  logic [DATA_WIDTH-1:0] x_in,
//     input  logic [DATA_WIDTH-1:0] y_in,
//     output logic [DATA_WIDTH-1:0] dout
// );

//     assign dout = DEQUANTIZE(x_in * y_in);

// endmodule