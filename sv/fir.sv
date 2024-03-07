
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
	output logic                    x_in_rd_en,
	input  logic                    x_in_empty,

	output logic [DATA_WIDTH-1:0]   y_out,
	output logic                    y_out_wr_en,
	input  logic                    y_out_full

);

// function automatic logic signed [31:0] mul;
// input  logic signed [31:0] x_in;
// input  logic signed [31:0] y_in;
//     begin
//         logic signed [63:0] temp_y = x_in * y_in;
//         logic signed [31:0] out_y = temp_y >>> 10;
//         return out_y;
//     end
// endfunction

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



typedef enum logic[1:0] {shift, compute, read, write} state_t;
state_t state, state_c;
logic [31:0] count, count_c;
logic [0:TAPS-1][31:0] x, x_c;
logic [DATA_WIDTH:0] cal_y, cal_y_c;



always_ff @( posedge clock or posedge reset ) begin
		if (reset == 1'b1) begin
		count <= '0;
		state <= shift;
		cal_y <= '0;
		x <= '0;
	end else begin
		count <= count_c;
		state <= state_c;
		cal_y <= cal_y_c;
		x <= x_c;
	end
	
end

always_comb begin

	state_c = state;
	count_c = count;
	cal_y_c = cal_y;
	x_c = x;
	x_in_rd_en = '0;
	y_out_wr_en = '0;
	
	case (state)
		shift: begin
			cal_y_c = '0;
			count_c = '0;
			if (x_in_empty == 1'b0) begin
				x_c[DECIMATION:TAPS-1] = x[0:TAPS-1-DECIMATION];
				count_c = DECIMATION - 1;
				state_c = read;
			end
			else begin
				state_c = shift;
			end

		end 
		
		read: begin
			if (x_in_empty == 1'b0) begin
				x_in_rd_en = 1'b1;
				x_c[count] = x_in;
				count_c = (count - 1) % DECIMATION;
				if (count == 0) begin
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
			cal_y_c = cal_y + mul(COEFF[TAPS - count - 1], x[count]);
			count_c = (count + 1) % TAPS;
			if (count == TAPS - 1) begin
				count_c = '0;
				state_c = write;
			end else begin
				state_c = compute;
			end			
		end

		write: begin
			if (y_out_full == 1'b0) begin
				y_out_wr_en = 1'b1;
				y_out = cal_y;
				state_c = shift;
			end
			else begin
				state_c = write;
			end
		end
		default: begin
			cal_y_c = 'x;
			count_c = 'x;
			x_c = 'x;
			count_c = 'x;
			state_c = shift;
			x_in_rd_en = '0;
			cal_y_c = 'x;
			y_out_wr_en = '0;
			y_out = 'x;
		end
	endcase
	
end

endmodule
