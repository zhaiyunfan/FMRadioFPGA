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
        // 判断i是否为负数
        if (i < 0) begin
            // 对负数进行调整以避免舍入错误
            offset_i = (i + 1023) >>> 10;
        end else begin
            // 正数或零不需要调整
            offset_i = i >>> 10;
        end
        return offset_i;
    end
endfunction


function logic signed [31:0] mul;
input  logic signed [31:0] x_in;
input  logic signed [31:0] y_in;
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