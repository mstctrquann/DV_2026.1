module digital_lock (
    input clk,
    input rst_n,
    input key_valid,
    input [3:0] key,
    input reset_lock,
    output reg unlock,
    output reg locked_out, // tích cực sau khi nhập sai 3 lần 
    output reg [1:0] attempts
);
localparam [15:0] PASSWORD = {4'd1, 4'd2, 4'd3, 4'd4} ; // Mỗi số 4 bit
// Định nghĩa các trạng thái của FSM
localparam S_IDLE = 3'd0;
localparam S_GET_KEYS = 3'd1;
localparam S_CHECK = 3'd2;
localparam S_UNLOCKED = 3'd3;
localparam S_LOCKED_OUT = 3'd4;

reg [2:0] state, next_state;
reg [1:0] key_cnt; // Đếm số lượng phím đã nhập
reg [15:0] shift_reg; // Thanh ghi dịch chứa 4 phím bấm 
// Thanh ghi dịch nạp phím khi có key_valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 16'd0;
            key_cnt   <= 2'd0;
        end else if (state == S_IDLE) begin
            key_cnt <= 2'd0;
        end else if (state == S_GET_KEYS && key_valid) begin
            shift_reg <= {shift_reg[11:0], key}; // Dịch trái nạp phím mới vào 4 bit thấp
            key_cnt   <= key_cnt + 1'b1;
        end
    end

    // ==========================================
    // KHỐI 1: Chuyển đổi trạng thái (Sequential)
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // ==========================================
    // KHỐI 2: Logic xác định trạng thái kế tiếp (Combinational)
    // ==========================================
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (attempts == 2'd3) begin
                    next_state = S_LOCKED_OUT;
                end else if (key_valid) begin
                    next_state = S_GET_KEYS;
                end
            end

            S_GET_KEYS: begin
                // Khi đã đủ 4 phím (key_cnt = 3 và đang nhận phím thứ 4)
                if (key_valid && (key_cnt == 2'd3)) begin
                    next_state = S_CHECK;
                end
            end

            S_CHECK: begin
                if (shift_reg == PASSWORD) begin
                    next_state = S_UNLOCKED;
                end else if (attempts + 1'b1 >= 2'd3) begin
                    next_state = S_LOCKED_OUT;
                end else begin
                    next_state = S_IDLE;
                end
            end

            S_UNLOCKED: begin
                // Tự động quay về IDLE sau 1 chu kỳ để chờ đợt mở khóa tiếp theo
                next_state = S_IDLE;
            end

            S_LOCKED_OUT: begin
                // Chỉ mở lại khi có tín hiệu reset_lock
                if (reset_lock) begin
                    next_state = S_IDLE;
                end
            end

            default: next_state = S_IDLE;
        endcase
    end

    // ==========================================
    // KHỐI 3: Logic ngõ ra & đếm số lần sai (Sequential / Registered Output)
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unlock     <= 1'b0;
            locked_out <= 1'b0;
            attempts   <= 2'd0;
        end else begin
            // Mặc định hạ unlock sau 1 chu kỳ tích cực
            unlock <= 1'b0;

            case (next_state)
                S_IDLE: begin
                    if (state == S_LOCKED_OUT && reset_lock) begin
                        attempts   <= 2'd0;
                        locked_out <= 1'b0;
                    end
                end

                S_UNLOCKED: begin
                    unlock   <= 1'b1;
                    attempts <= 2'd0; // Nhập đúng thì xóa đếm số lần sai về 0
                end

                S_CHECK: begin
                    if (shift_reg != PASSWORD) begin
                        attempts <= attempts + 1'b1;
                    end
                end

                S_LOCKED_OUT: begin
                    locked_out <= 1'b1;
                end

                default: ;
            endcase
        end
    end

endmodule
