module iir #(
    parameter int DATA_WIDTH = 32
) (
    input logic clock,
    input logic reset,

    input logic [DATA_WIDTH-1:0] x_in,
    output logic x_in_rd_en,
    input logic x_in_empty,

    output logic [DATA_WIDTH-1:0] y_out,
    output logic y_out_wr_en,
    input logic y_out_full

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





endmodule