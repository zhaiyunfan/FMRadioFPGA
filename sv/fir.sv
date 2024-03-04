module fir #(
    parameter DATA_WIDTH = 32,
    parameter [0:31][31:0] COEFF =
'{
	(32'hffffffff), (32'h00000000), (32'h00000000), (32'h00000002), (32'h00000004), (32'h00000008), (32'h0000000b), (32'h0000000c), 
	(32'h00000008), (32'hffffffff), (32'hffffffee), (32'hffffffd7), (32'hffffffbb), (32'hffffff9f), (32'hffffff87), (32'hffffff76), 
	(32'hffffff76), (32'hffffff87), (32'hffffff9f), (32'hffffffbb), (32'hffffffd7), (32'hffffffee), (32'hffffffff), (32'h00000008), 
	(32'h0000000c), (32'h0000000b), (32'h00000008), (32'h00000004), (32'h00000002), (32'h00000000), (32'h00000000), (32'hffffffff)
},
    parameter TAPS = 32,
    parameter DECIMATION = 8
)
(
    input  logic                    clock,
    input  logic                    reset,
    
    input  logic [DATA_WIDTH-1:0]   x_in,
    output logic                    x_rd_en,
    input  logic                    x_empty,

    output logic [DATA_WIDTH-1:0]   y_out,
    output logic                    y_wr_en
    input  logic                    y_out_full,

);





endmodule