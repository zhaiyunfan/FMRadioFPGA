
module fir_cmplx# (
	parameter [0:19][31:0] H_REAL =
{
	32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
	32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
	32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001
},
	parameter [0:19][31:0] H_IMAG =
{
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
},
	parameter TAPS = 20,
	parameter DECIMATION = 1
)
(
	input  logic        clock,
	input  logic        reset,

	input  logic [31:0] i_in,
	input  logic [31:0] q_in,
	output logic        i_rd_en,
	output logic        q_rd_en,
	input  logic        i_empty,
	input  logic        q_empty,

	output logic [31:0] y_real_out,
	output logic [31:0] y_imag_out,
	output logic        y_real_wr_en,
	output logic        y_imag_wr_en,
	input  logic        y_real_full,
	input  logic        y_imag_full
);

typedef enum logic[1:0] {shift, compute, write} state_t;
state_t state, state_c;

logic [0:TAPS-1][31:0] x_real, x_real_c;
logic [0:TAPS-1][31:0] x_imag, x_imag_c;

	
always_ff @( posedge clock or posedge reset ) begin
	    if (reset == 1'b1) begin
        x_real <= '0;
        x_imag <= '0;
        count <= '0;
        state <= s0;
        sum_real <= '0;
        sum_imag <= '0;
    end else begin
        x_real <= x_real_c;
        x_imag <= x_imag_c;
        count <= count_c;
        state <= state_c;
        sum_real <= sum_real_c;
        sum_imag <= sum_imag_c;
    end
	
end

always_comb begin
	case (state)
		shift: begin
			x_imag_c[]
		end 
		default: 
	endcase
	
end



endmodule