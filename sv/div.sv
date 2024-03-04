function logic[5:0] msb;
input  logic [DATA_WIDTH-1:0] div_num;
input  logic [5:0] DATA_WIDTH;
    begin
		if (DATA_WIDTH >= 1) begin
        	logic [(DATA_WIDTH/2)-1:0] lhs = div_num[DATA_WIDTH-1:DATA_WIDTH/2];
			logic [(DATA_WIDTH/2)-1:0] rhs = div_num[(DATA_WIDTH/2)-1:0];

			if (lhs > 0) begin
				return msb(lhs,DATA_WIDTH/2) + (DATA_WIDTH/2);
			end else if (rhs > 0) begin
				return msb(rhs,DATA_WIDTH/2);
			end else begin
				return 0;
			end
		end
    end
endfunction

module div #(
    parameter DIVIDEND_WIDTH = 64,
    parameter DIVISOR_WIDTH = 32
)
(
    input  logic                        clk,
    input  logic                        reset,
    input  logic                        valid_in,
    input  logic [DIVIDEND_WIDTH-1:0]   dividend,
    input  logic [DIVISOR_WIDTH-1:0]    divisor,
    output logic [DIVIDEND_WIDTH-1:0]   quotient,
    output logic [DIVISOR_WIDTH-1:0]    remainder,
    output logic                        valid_out,
    output logic                        overflow
);

typedef enum logic [2:0] { INIT, IDLE, B_EQ_1, LOOP, EPILOGUE, DONE } state_t;
state_t state, state_c;

logic [DIVIDEND_WIDTH-1:0] a, a_c;
logic [DIVISOR_WIDTH-1:0] b, b_c;
logic [DIVIDEND_WIDTH-1:0] q, q_c;

always_ff @( posedge clk or posedge reset ) begin
	if (reset == 1'b1) begin
		state <= IDLE;
		a <= '0;
		b <= '0;	
		q <= '0;
	end else begin
		state <= state_c;
		a <= a_c;
		b <= b_c;	
		q <= q_c;
	end			
end

always_comb begin : 
	a_c = a;
	b_c = b;
	q_c = q;
	valid_out = '0;

	case(state)
		IDLE: begin
			if (valid_in) begin
				state_c = INIT;
			end else begin
				state_c = IDLE;
			end
		end

		INIT: begin
			overflow = 1'b0;
			a_c = (dividend[31] == 1'b0) ? $signed(dividend) : $signed(-dividend);
            b_c = (divisor[31] == 1'b0) ? $signed(divisor) : $signed(-divisor);
            q_c = '0;
            p = 0;

			if (divisor == '1) begin
				state_c = B_EQ_1;
			end else if (divisor == '0) begin
				state_c = B_EQ_1;
				overflow = 1'b1;
			end else begin
				state_c = LOOP;
			end
		end

		B_EQ_1: begin
			state_c = EPILOGUE;
			b_c = b; // 
			q_c = dividend;
			a_c = '0;
		end

		LOOP: begin
			p = msb(a,DIVIDEND_WIDTH) - msb(b,DIVISOR_WIDTH);
			
		end

		EPILOGUE: begin
			

			state_c = IDLE;
		end

		default: begin
			state_c = IDLE;
			a_c = a;
			b_c = b;
			q_c = q;
		end
	endcase
	
end

endmodule