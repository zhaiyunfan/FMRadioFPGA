module demodulate (
    input   logic           clk,
    input   logic           reset,
    input   logic           input_fifos_empty,
    output  logic           input_rd_en,
    input   logic [31:0]    real_in,
    input   logic [31:0]    imag_in,
    output  logic [31:0]    demod_out,
    output  logic           wr_en_out,
    input   logic           out_fifo_full
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

function logic signed [31:0] mul;
input  logic signed [31:0] x_in;
input  logic signed [31:0] y_in;
    begin
        return DEQUANTIZE(x_in * y_in);
    end
endfunction

const logic [31:0] gain = 32'h000002f6;

typedef enum logic [2:0] {EDGE_1, EDGE_2, IDLE, MULT, DEQU, WAITING, OUTPUT} state_t;
state_t state, state_c;

logic [31:0] real_curr, real_curr_c, imag_curr, imag_curr_c, real_prev, real_prev_c, imag_prev, imag_prev_c, qarctan_out, qarctan_out_times_gain;
logic [63:0] real_prev_times_curr, imag_prev_times_curr, neg_imag_prev_times_imag, neg_imag_prev_times_real;
logic [63:0] real_prev_times_curr_c, imag_prev_times_curr_c, neg_imag_prev_times_imag_c, neg_imag_prev_times_real_c;
logic [31:0] short_real, short_real_c, short_imag, short_imag_c;
logic [31:0] demod_temp, demod_temp_c;
logic qarctan_ready, qarctan_done;
logic demod_data_valid, demod_data_valid_c;

qarctan qarctan_inst (
    .clk(clk), 
    .reset(reset),
    .demod_data_valid(demod_data_valid),
    .divider_ready(qarctan_ready),
    .x(short_real),
    .y(short_imag),
    .data_out(qarctan_out),
    .qarctan_done(qarctan_done)
);

always_ff @(posedge clk or posedge reset) begin
    if (reset == 1'b1) begin
        state <= EDGE_1;
        real_curr <= '0;
        imag_curr <= '0;
        real_prev <= '0;
        imag_prev <= '0;
        demod_temp <= '0;
        demod_data_valid <= '0;
		real_prev_times_curr <= '0;
    	imag_prev_times_curr <= '0;
    	neg_imag_prev_times_imag <= '0;
    	neg_imag_prev_times_real <= '0;
		short_real <= '0;
    	short_imag <= '0;
    end else begin
        state <= state_c;
        real_curr <= real_curr_c;
        imag_curr <= imag_curr_c;
        real_prev <= real_prev_c;
        imag_prev <= imag_prev_c;
        demod_temp <= demod_temp_c;
        demod_data_valid <= demod_data_valid_c;
		real_prev_times_curr <= real_prev_times_curr_c;
    	imag_prev_times_curr <= imag_prev_times_curr_c;
    	neg_imag_prev_times_imag <= neg_imag_prev_times_imag_c;
    	neg_imag_prev_times_real <= neg_imag_prev_times_real_c;
		short_real <= short_real_c;
    	short_imag <= short_imag_c;
    end
end

always_comb begin
    real_curr_c = real_curr;
    imag_curr_c = imag_curr;
    real_prev_c = real_prev;
    imag_prev_c = imag_prev;
	real_prev_times_curr_c = real_prev_times_curr;
    imag_prev_times_curr_c = imag_prev_times_curr;
    neg_imag_prev_times_imag_c = neg_imag_prev_times_imag;
    neg_imag_prev_times_real_c = neg_imag_prev_times_real;
	short_real_c = short_real;
    short_imag_c = short_imag;
    input_rd_en = 1'b0;
    wr_en_out = 1'b0;
    qarctan_out_times_gain = '0;
    demod_temp_c = demod_temp;
    demod_out = demod_temp;
    demod_data_valid_c = '0;
    case(state)
        EDGE_1: begin
            demod_temp_c = 32'h4a6;
            wr_en_out = 1'b0;
            input_rd_en = 1'b0;
            state_c = EDGE_2;
        end
        EDGE_2: begin
            demod_temp_c = 32'h4a6;
            if (input_fifos_empty == 1'b0) begin
                wr_en_out = 1'b1;
                state_c = IDLE;
                input_rd_en = 1'b1;
                real_curr_c = real_in;
                imag_curr_c = imag_in;
                real_prev_c = real_curr;
                imag_prev_c = imag_curr;
            end else begin
                state_c = EDGE_2;
                wr_en_out = 1'b0;
                input_rd_en = 1'b0;
            end
        end
        IDLE: begin
            wr_en_out = 1'b0;
            if (input_fifos_empty == 1'b0) begin
                state_c = MULT;
                input_rd_en = 1'b1;
                
                real_curr_c = real_in;
                imag_curr_c = imag_in;
                real_prev_c = real_curr;
                imag_prev_c = imag_curr;
            end else begin
                state_c = IDLE;
            end
        end

		MULT: begin
			state_c = DEQU;
		    real_prev_times_curr_c = $signed(real_prev) * $signed(real_curr);
    		imag_prev_times_curr_c = $signed(real_prev) * $signed(imag_curr);
    		neg_imag_prev_times_imag_c = -$signed(imag_prev) * $signed(imag_curr);
    		neg_imag_prev_times_real_c = -$signed(imag_prev) * $signed(real_curr);
		end

		DEQU: begin
			state_c = WAITING;
			demod_data_valid_c = 1'b1;
			short_real_c = DEQUANTIZE(real_prev_times_curr[31:0]) - DEQUANTIZE(neg_imag_prev_times_imag);
    		short_imag_c = DEQUANTIZE(imag_prev_times_curr[31:0]) + DEQUANTIZE(neg_imag_prev_times_real);
		end

        WAITING: begin
            if (qarctan_done == 1'b1) begin
                state_c = OUTPUT;
                wr_en_out = 1'b0;
                qarctan_out_times_gain = qarctan_out * gain;
                demod_temp_c = DEQUANTIZE(qarctan_out_times_gain[31:0]);
            end else begin
                state_c = WAITING;
            end
        end
        OUTPUT: begin
            if (out_fifo_full == 1'b0) begin
                wr_en_out = 1'b1;
                state_c = IDLE;
            end else begin
                state_c = OUTPUT;
            end
        end
    endcase
end

    
// always_comb begin
//     //real_prev_times_curr = $signed(real_prev) * $signed(real_curr);
//     //imag_prev_times_curr = $signed(real_prev) * $signed(imag_curr);
//     //neg_imag_prev_times_imag = -$signed(imag_prev) * $signed(imag_curr);
//     //neg_imag_prev_times_real = -$signed(imag_prev) * $signed(real_curr);
//     //short_real = DEQUANTIZE(real_prev_times_curr[31:0]) - DEQUANTIZE(neg_imag_prev_times_imag);
//     //short_imag = DEQUANTIZE(imag_prev_times_curr[31:0]) + DEQUANTIZE(neg_imag_prev_times_real);
// end

endmodule
