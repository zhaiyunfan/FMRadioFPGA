module iir #(
    parameter int DATA_WIDTH = 32,
	parameter TAPS = 2,
	parameter DECIMATION = 1
) 
(
	input  logic                    clock,
	input  logic                    reset,
	
	input  logic [DATA_WIDTH-1:0]   x_in,
	output logic                    x_in_rd_en,
	input  logic                    x_in_empty,

	output logic [DATA_WIDTH-1:0]   y_out,
	output logic                    y_out_wr_en,
	input  logic                    y_out_full

);

localparam int signed b0 = 178;//QUANTIZE_F(W_PP / (1.0 + W_PP));
localparam int signed b1 = 178;//QUANTIZE_F(W_PP / (1.0 + W_PP));
localparam int signed a1 = 0;//QUANTIZE_F(0.0);
localparam int signed a0 = -666;//QUANTIZE_F((W_PP - 1.0)/(W_PP + 1.0));


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

typedef enum logic[1:0] {shift, compute, read, write} state_t;
state_t state, state_c;
logic [31:0] count, count_c;
logic [0:TAPS-1][31:0] x, x_c;
logic [0:TAPS-1][31:0] y, y_c;
logic [DATA_WIDTH:0] cal_y_1, cal_y_1_c;
logic [DATA_WIDTH:0] cal_y_2, cal_y_2_c;



always_ff @( posedge clock or posedge reset ) begin
		if (reset == 1'b1) begin
		count <= '0;
		state <= shift;
		cal_y_1 <= '0;
		cal_y_2 <= '0;
		x <= '0;
        y <= '0;
	end else begin
		count <= count_c;
		state <= state_c;
		cal_y_1 <= cal_y_1_c;
		cal_y_2 <= cal_y_2_c;
		x <= x_c;
        y <= y_c;
	end
	
end

always_comb begin
	state_c = state;
	count_c = count;
	cal_y_1_c = cal_y_1;
	cal_y_2_c = cal_y_2;
	x_c = x;
    y_c = y;
	x_in_rd_en = '0;
	y_out_wr_en = '0;
	case (state)
		shift: begin
			cal_y_1_c = '0;
			cal_y_2_c = '0;
			count_c = '0;
			if (x_in_empty == 1'b0) begin
				x_c[DECIMATION:TAPS-1] = x[0:TAPS-1-DECIMATION];
                y_c[1:TAPS-1] = y[0:TAPS-2];
				count_c = '0;
				state_c = read;
			end
			else begin
				state_c = shift;
			end

		end 
		
		read: begin
			if (x_in_empty == 1'b0) begin
				x_in_rd_en = 1'b1;
				x_c[DECIMATION-count-1] = x_in;
				count_c = (count + 1) % DECIMATION;
				if (count == DECIMATION - 1) begin
					count_c = '0;
					state_c = compute;
				end 
				else begin
					state_c = read;
				end				
			end
			else begin
				state_c = read;
			end
		end
		
		compute: begin
			cal_y_1_c = mul(x[0], b0) + mul(x[1], b1);
			cal_y_2_c = mul(y[0], a0) + mul(y[1], a1);
			count_c = (count + 1) % TAPS;
			state_c = write;
		end

		write: begin
			if (y_out_full == 1'b0) begin
				y_out = y[1];
				y_out_wr_en = 1'b1;
				y_c[0] = cal_y_1 + cal_y_2;
				state_c = shift;
			end
			else begin
				state_c = write;
			end
		end
		default: begin
			cal_y_1_c = 'x;
			cal_y_2_c = 'x;
			count_c = 'x;
			x_c = 'x;
			count_c = 'x;
			state_c = shift;
			x_in_rd_en = '0;
			y_out_wr_en = '0;
			y_out = 'x;
		end
	endcase
	
end

endmodule
