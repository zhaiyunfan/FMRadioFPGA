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

typedef enum logic[1:0] {shift, read, compute, write} state_t;
state_t state, state_c;

logic [0:TAPS-1][31:0] x_real, x_real_c;
logic [0:TAPS-1][31:0] x_imag, x_imag_c;

logic [31:0] cal_real, cal_real_c;
logic [31:0] cal_imag, cal_imag_c;

logic [31:0] count;
logic [31:0] count_c;



	
always_ff @( posedge clock or posedge reset ) begin
	    if (reset == 1'b1) begin
        x_real <= '0;
        x_imag <= '0;
        count <= '0;
        state <= shift;
        cal_real <= '0;
        cal_imag <= '0;
    end else begin
        x_real <= x_real_c;
        x_imag <= x_imag_c;
        count <= count_c;
        state <= state_c;
        cal_real <= cal_real_c;
        cal_imag <= cal_imag_c;
    end
	
end

always_comb begin
	i_rd_en = 1'b0;
    q_rd_en = 1'b0;
    y_real_wr_en = 1'b0;
    y_imag_wr_en = 1'b0;
    x_real_c = x_real; // 保持当前值，除非有特定的更新
    x_imag_c = x_imag;
    count_c = count;
    state_c = state; // 假设状态保持不变，除非明确更改
    cal_real_c = cal_real;
    cal_imag_c = cal_imag;
	
	case (state)
		shift: begin
			cal_real_c = '0;
            cal_imag_c = '0;
			count_c = '0;
			if (i_empty == 1'b0 || q_empty == 1'b0) begin
				x_real_c[DECIMATION:TAPS-1] = x_real[0:TAPS-1-DECIMATION];
				x_imag_c[DECIMATION:TAPS-1]	= x_imag[0:TAPS-1-DECIMATION];
				state_c = read;
			end
			else begin
				state_c = shift;
			end

		end 
		
		read: begin
			if (i_empty == 1'b0 || q_empty == 1'b0) begin
				i_rd_en = 1'b1;
				q_rd_en = 1'b1;
				x_real_c[count] = i_in;
				x_imag_c[count] = q_in;	

				count_c = (count + 1) % DECIMATION;
				if (count == DECIMATION - 1) begin
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
            cal_real_c = cal_real + mul(H_REAL[count], x_real[count]) - mul(H_IMAG[count], x_imag);
            cal_imag_c = cal_imag + mul(H_REAL[count], x_imag[count]) - mul(H_IMAG[count], x_real);

            count_c = (count + 1) % TAPS;
            if (count == TAPS - 1) begin
                state_c = write;
            end else begin
                state_c = compute;
            end			
		end

		write: begin
			if (y_real_full == 1'b0 || y_imag_full == 1'b0 ) begin
                y_real_wr_en = 1'b1;
                y_imag_wr_en = 1'b1;
                y_real_out = cal_real;
                y_imag_out = cal_imag;
				state_c = shift;
			end
			else begin
				state_c = write;
			end
			
		end
		default: begin
			x_real_c = 'x;
			x_imag_c = 'x;
			state_c = shift;
			i_rd_en = 'x;
			q_rd_en = 'x;
			x_real_c = 'x;
			x_imag_c = 'x;
			count_c = '0;
			state_c = shift;
			cal_real_c = 'x;
			cal_imag_c = 'x;
			y_real_wr_en = '0;
			y_imag_wr_en = '0;
			y_real_out = 'x;
			y_imag_out = 'x;
		end
	endcase
	
end



endmodule