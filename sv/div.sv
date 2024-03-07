function automatic logic [5:0] msb;
	localparam MAX_DATA_WIDTH = 64;
    input logic [5:0] DATA_WIDTH;
    input logic [MAX_DATA_WIDTH-1:0] div_num;
    logic [5:0] idx;
    begin
        // 初始化最高有效位的索引为0，表示还没有找到
        msb = 0;
        // 从最高位到最低位遍历div_num的每一位
        for (idx = DATA_WIDTH-1; idx >= 0; idx = idx - 1) begin
            // 检查当前位是否不为0
            if (div_num[idx] != 0) begin
                // 更新最高有效位的索引
                msb = idx;
                // 找到最高非零位后退出循环
                break;
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

typedef enum logic [2:0] { IDLE, INIT, B_EQ_1, LOOP, EPILOGUE, DONE } state_t;
state_t state, state_c;

logic [DIVIDEND_WIDTH-1:0] a, a_c;
logic [DIVISOR_WIDTH-1:0] b, b_c;
logic [DIVIDEND_WIDTH-1:0] q, q_c;

logic sign;
logic [DIVIDEND_WIDTH-1:0] ab; //a-b
logic [DIVIDEND_WIDTH-1:0] remainder_condition;
logic [7:0] p;


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

always_comb begin
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
			a_c = (dividend[63] == 1'b0) ? $signed(dividend) : $signed(-dividend);
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
			//b_c = b; // 
			q_c = dividend;
			a_c = '0;
		end

		LOOP: begin
			b_c = b; 
			p = msb(DIVIDEND_WIDTH,a) - msb(DIVISOR_WIDTH,b);
			if (($signed(b) << p) > $signed(a)) begin
				p = p - 1;
			end	

			q_c = DIVIDEND_WIDTH'(q) + (1 << p);

			if (b != 0 && $signed(b) <= $signed(a)) begin
				state_c = LOOP;
				ab = $signed(a) - $signed($signed(b) << p);
				a_c = ab;
			end else begin
				state_c = EPILOGUE;
				//q_c = q;
				//a_c = a;
			end
		end

		EPILOGUE: begin
			sign = dividend[DIVIDEND_WIDTH-1] ^ divisor[DIVISOR_WIDTH-1];

			quotient = (sign == 1'b0) ? q : -q;

			remainder_condition = $signed(dividend) >>> (DIVIDEND_WIDTH - 1);
            remainder = (remainder_condition != 1) ? a : -a;

            valid_out = 1'b1;
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