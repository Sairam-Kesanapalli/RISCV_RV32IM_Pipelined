/*********************************************************************************
 * M-EXTENSION MULTIPLIER / DIVIDER UNIT (Iterative)
 * -------------------------------------------------------------------------------
 * Implements all 8 RV32IM M-Extension operations using hardware-realistic
 * iterative algorithms:
 *   - Multiplication: Shift-and-Add algorithm (32 cycles)
 *   - Division:       Restoring division algorithm (32 cycles)
 *
 * Interface:
 *   start  -> Driven high while the operation is active
 *   busy   -> High while computation is in progress
 *   done   -> Pulses high for one cycle when Result is valid
 *********************************************************************************/
module mul_div #(
    parameter WIDTH = 32
)(
    input clk,
    input rst_n,
    input start,
    input [2:0] md_op,
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    output reg [WIDTH-1:0] Result,
    output reg busy,
    output reg done
);

    // =========================================================================
    // M-Extension funct3 operations
    // =========================================================================
    localparam MUL    = 3'b000;
    localparam MULH   = 3'b001;
    localparam MULHSU = 3'b010;
    localparam MULHU  = 3'b011;
    localparam DIV    = 3'b100;
    localparam DIVU   = 3'b101;
    localparam REM    = 3'b110;
    localparam REMU   = 3'b111;

    // =========================================================================
    // State Machine
    // =========================================================================
    localparam S_IDLE      = 3'd0;
    localparam S_MUL_ITER  = 3'd1;
    localparam S_DIV_ITER  = 3'd2;
    localparam S_FINISH    = 3'd3;
    localparam S_WAIT_DONE = 3'd4;

    reg [2:0] state;

    // =========================================================================
    // Internal Working Registers
    // =========================================================================
    reg [5:0] count;                     // Iteration counter (0..31)

    // --- Multiplier ---
    // Shift-and-Add: accumulator holds partial product in upper half,
    // multiplicand in lower half. Multiplier is shifted right each cycle.
    reg [WIDTH*2-1:0] accumulator;       // 64-bit {partial_product, multiplicand_shifted}
    reg [WIDTH-1:0]   mcand;             // Multiplicand (absolute value of A)
    reg [WIDTH-1:0]   mplier;            // Multiplier   (absolute value of B), shifted right

    // --- Divider ---
    // Restoring division: remainder is shifted left each cycle, divisor subtracted.
    reg [WIDTH-1:0]   quotient;
    reg [WIDTH:0]     remainder;         // 33-bit (extra bit for subtraction sign test)
    reg [WIDTH-1:0]   divisor_reg;

    // --- Flags ---
    reg negate_result;
    reg is_div_op;
    reg is_rem_op;
    reg is_upper;
    reg div_by_zero;
    reg div_overflow;
    reg [WIDTH-1:0] saved_dividend;

    // Helpers for absolute value
    wire [WIDTH-1:0] abs_A = A[WIDTH-1] ? (~A + 1'b1) : A;
    wire [WIDTH-1:0] abs_B = B[WIDTH-1] ? (~B + 1'b1) : B;

    // Wire for trial subtraction in divider
    //wire [WIDTH:0] trial_sub = {remainder[WIDTH-1:0], 1'b0} - {1'b0, divisor_reg};

    always @(posedge clk) begin
        if (!rst_n) begin
            state   <= S_IDLE;
            Result  <= 0;
            busy    <= 0;
            done    <= 0;
            count   <= 0;
        end else begin
            case (state)

                // =============================================================
                // IDLE: Latch inputs, handle edge cases, begin iteration
                // =============================================================
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        busy           <= 1;
                        negate_result  <= 0;
                        is_div_op      <= 0;
                        is_rem_op      <= 0;
                        is_upper       <= 0;
                        div_by_zero    <= 0;
                        div_overflow   <= 0;
                        saved_dividend <= A;
                        count          <= 0;

                        case (md_op)
                            // --- Multiplication ---
                            MUL: begin
                                accumulator <= {WIDTH*2{1'b0}};
                                mcand       <= A;
                                mplier      <= B;
                                state       <= S_MUL_ITER;
                            end
                            MULH: begin
                                is_upper      <= 1;
                                accumulator   <= {WIDTH*2{1'b0}};
                                mcand         <= abs_A;
                                mplier        <= abs_B;
                                negate_result <= A[WIDTH-1] ^ B[WIDTH-1];
                                state         <= S_MUL_ITER;
                            end
                            MULHSU: begin
                                is_upper      <= 1;
                                accumulator   <= {WIDTH*2{1'b0}};
                                mcand         <= abs_A;
                                mplier        <= B; // B is unsigned
                                negate_result <= A[WIDTH-1];
                                state         <= S_MUL_ITER;
                            end
                            MULHU: begin
                                is_upper    <= 1;
                                accumulator <= {WIDTH*2{1'b0}};
                                mcand       <= A;
                                mplier      <= B;
                                state       <= S_MUL_ITER;
                            end

                            // --- Division ---
                            DIV: begin
                                is_div_op <= 1;
                                if (B == 0) begin
                                    div_by_zero <= 1;
                                    state       <= S_FINISH;
                                end else if (A == {1'b1, {(WIDTH-1){1'b0}}} && B == {WIDTH{1'b1}}) begin
                                    div_overflow <= 1;
                                    state        <= S_FINISH;
                                end else begin
                                    remainder     <= {(WIDTH+1){1'b0}};
                                    divisor_reg   <= abs_B;
                                    quotient      <= abs_A;    // Dividend bits will be shifted out of here
                                    negate_result <= A[WIDTH-1] ^ B[WIDTH-1];
                                    state         <= S_DIV_ITER;
                                end
                            end
                            DIVU: begin
                                is_div_op <= 1;
                                if (B == 0) begin
                                    div_by_zero <= 1;
                                    state       <= S_FINISH;
                                end else begin
                                    remainder   <= {(WIDTH+1){1'b0}};
                                    divisor_reg <= B;
                                    quotient    <= A;
                                    state       <= S_DIV_ITER;
                                end
                            end
                            REM: begin
                                is_div_op <= 1;
                                is_rem_op <= 1;
                                if (B == 0) begin
                                    div_by_zero <= 1;
                                    state       <= S_FINISH;
                                end else if (A == {1'b1, {(WIDTH-1){1'b0}}} && B == {WIDTH{1'b1}}) begin
                                    div_overflow <= 1;
                                    state        <= S_FINISH;
                                end else begin
                                    remainder     <= {(WIDTH+1){1'b0}};
                                    divisor_reg   <= abs_B;
                                    quotient      <= abs_A;
                                    negate_result <= A[WIDTH-1]; // Remainder has dividend's sign
                                    state         <= S_DIV_ITER;
                                end
                            end
                            REMU: begin
                                is_div_op <= 1;
                                is_rem_op <= 1;
                                if (B == 0) begin
                                    div_by_zero <= 1;
                                    state       <= S_FINISH;
                                end else begin
                                    remainder   <= {(WIDTH+1){1'b0}};
                                    divisor_reg <= B;
                                    quotient    <= A;
                                    state       <= S_DIV_ITER;
                                end
                            end

                            default: state <= S_FINISH;
                        endcase
                    end
                end

                // =============================================================
                // MUL_ITER: Shift-and-Add Multiplication
                // =============================================================
                // Each cycle: if LSB of multiplier is 1, add multiplicand to
                // upper half of accumulator. Then shift accumulator right by 1,
                // and shift multiplier right by 1.
                // After 32 iterations, accumulator holds the 64-bit product.
                S_MUL_ITER: begin
                    if (mplier[0])
                        accumulator <= ({accumulator[WIDTH*2-1:WIDTH] + mcand,
                                         accumulator[WIDTH-1:0]}) >> 1;
                    else
                        accumulator <= accumulator >> 1;

                    mplier <= mplier >> 1;
                    count  <= count + 1;

                    if (count == WIDTH - 1)
                        state <= S_FINISH;
                end

                // =============================================================
                // DIV_ITER: Restoring Division
                // =============================================================
                // Each cycle:
                //   1. Shift remainder left, pulling MSB of quotient/dividend in
                //   2. Trial subtract divisor
                //   3. If >= 0: keep subtracted value, quotient bit = 1
                //      If <  0: restore (discard subtraction), quotient bit = 0
                S_DIV_ITER: begin
                    // Shift remainder left, pull in MSB of quotient (which holds dividend)
                    // trial_sub is computed combinationally above using the SHIFTED remainder
                    // But we need to shift first, so let's do it inline:
                    begin : div_block
                        reg [WIDTH:0] shifted_rem;
                        reg [WIDTH:0] sub_result;
                        shifted_rem = {remainder[WIDTH-1:0], quotient[WIDTH-1]};
                        sub_result  = shifted_rem - {1'b0, divisor_reg};

                        if (!sub_result[WIDTH]) begin
                            // Subtraction succeeded (result >= 0)
                            remainder <= sub_result;
                            quotient  <= {quotient[WIDTH-2:0], 1'b1};
                        end else begin
                            // Subtraction failed (result < 0), restore
                            remainder <= shifted_rem;
                            quotient  <= {quotient[WIDTH-2:0], 1'b0};
                        end
                    end

                    count <= count + 1;
                    if (count == WIDTH - 1)
                        state <= S_FINISH;
                end

                // =============================================================
                // FINISH: Compute final result
                // =============================================================
                S_FINISH: begin
                    done  <= 1;
                    busy  <= 0;
                    state <= S_WAIT_DONE;

                    if (is_div_op) begin
                        if (div_by_zero) begin
                            Result <= is_rem_op ? saved_dividend : {WIDTH{1'b1}};
                        end else if (div_overflow) begin
                            Result <= is_rem_op ? {WIDTH{1'b0}} : saved_dividend;
                        end else if (is_rem_op) begin
                            Result <= negate_result ? (~remainder[WIDTH-1:0] + 1'b1)
                                                    : remainder[WIDTH-1:0];
                        end else begin
                            Result <= negate_result ? (~quotient + 1'b1) : quotient;
                        end
                    end else begin
                        // Multiplication
                        if (negate_result) begin
                            // Negate the 64-bit product, then pick upper or lower
                            begin : neg_mul_block
                                reg [WIDTH*2-1:0] neg_prod;
                                neg_prod = ~accumulator + 1'b1;
                                Result <= is_upper ? neg_prod[WIDTH*2-1:WIDTH]
                                                   : neg_prod[WIDTH-1:0];
                            end
                        end else begin
                            Result <= is_upper ? accumulator[WIDTH*2-1:WIDTH]
                                               : accumulator[WIDTH-1:0];
                        end
                    end
                end

                // =============================================================
                // WAIT_DONE: Hold until start deasserts
                // =============================================================
                S_WAIT_DONE: begin
                    if (!start) begin
                        state <= S_IDLE;
                        done  <= 0;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
