module div #(
    parameter DIVIDEND_WIDTH = 64,
    parameter DIVISOR_WIDTH = 32
)
(
    input  logic 						clk,
    input  logic 						reset,
    input  logic 						valid_in,
    input  logic [DIVIDEND_WIDTH-1:0] 	dividend,
    input  logic [DIVISOR_WIDTH-1:0] 	divisor,
    output logic [DIVIDEND_WIDTH-1:0] 	quotient,
    output logic [DIVISOR_WIDTH-1:0] 	remainder,
    output logic 						valid_out,
    output logic 						overflow
);

typedef enum logic [2:0] { IDLE, LOAD, SUBTRACT, TEST_RE, CHECK, B_EQ_1, FINISH } state_t;
state_t state, next_state;

logic [DIVIDEND_WIDTH-1:0] a, a_next;
logic [(DIVIDEND_WIDTH/2)-1:0] temp_left_a;
logic [DIVISOR_WIDTH-1:0] b, b_next;
logic [DIVIDEND_WIDTH-1:0] q, q_next;
logic [DIVIDEND_WIDTH:0] shifted_divisor; // Extended for possible shift
integer n, n_next;
integer bit_pos; //  shut down setting should be set for ? wait for remainder(unsigned) < divisor(unsigned)

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        a <= 0;
        b <= 0;
        q <= 0;
    end else begin
        state <= next_state;
        a <= a_next;
        b <= b_next;
        q <= q_next;
		n <= n_next;
    end
end

always_comb begin
    // Default values
    a_next = a;
    b_next = b;
    q_next = q;
	n_next = 0;
    next_state = state;
    valid_out = 0;
    overflow = 0;

    case(state)
		IDLE: begin
			if (valid_in) begin
				next_state = LOAD;
			end else begin
				next_state = IDLE;
			end
		end

        LOAD: begin
            // Load the values and start the division
			overflow = 1'b0;
			a_next = dividend << 1; // shift or not during load in
            b_next = divisor;
			q_next = '0;

			if (divisor == '1) begin
				next_state = B_EQ_1;
			end else if (divisor == '0) begin
				next_state = B_EQ_1;
				overflow = 1'b1;
			end else begin
				next_state = SUBTRACT;
			end			
        end

        SUBTRACT: begin
            // Perform the subtraction if the shifted divisor is less than or equal to the remainder
            a_next[63:32] = a[63:32] - b;
            next_state = TEST_RE;
			n_next = n + 1;
        end

		TEST_RE: begin
			if(a[63] == 0) begin
				a_next = a << 1;
				a_next[0] = 1;
			end else begin
				temp_left_a = a[63:32] + b;
				a_next[63:33] = temp_left_a[30:0];
				a_next[32:1]  = a[31:0];
				a_next[1]	  = '0;
			end
			next_state = CHECK;
		end

        CHECK: begin
            // Check if we are done with all the bits
			// a[n-1:0] is quotient
			// a[63:n]  is remainder

			
			if (a[63:n] < b) begin
				q_next = a[n-1:0];
				b_next = a[63:n];
                next_state = FINISH;
			end else begin
                next_state = SUBTRACT; // Go back to SHIFT to process the next bit
            end
			
		/*
            if (bit_pos == 0) begin
                next_state = FINISH;
			end else begin
                bit_pos = bit_pos - 1;
                next_state = SUBTRACT; // Go back to SHIFT to process the next bit
            end */
        end
		
		B_EQ_1: begin
			next_state = FINISH;
			//b_c = b; // 
			q_next = dividend;
			b_next = '0;
		end

        FINISH: begin
            // Finalize the outputs
            quotient = q;
            remainder = b;
            valid_out = 1;
            next_state = IDLE;
        end

        default: begin
            next_state = IDLE;
        end
    endcase

end

endmodule
