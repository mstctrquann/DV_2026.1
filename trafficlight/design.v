`timescale 1ns / 1ps

module traffic_light #(
    parameter T_MAIN_GREEN = 30, // Thời gian xanh đường chính (s)
    parameter T_MAIN_YEL   = 5,  // Thời gian vàng đường chính (s)
    parameter T_SIDE_GREEN = 15, // Thời gian xanh đường phụ (s)
    parameter T_SIDE_YEL   = 5,  // Thời gian vàng đường phụ (s)
    parameter T_BLINK      = 1   // Chu kỳ nhấp nháy vàng ban đêm (s)
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sensor,        // 1: có xe ở đường phụ
    input  wire       night_mode,    // 1: bật chế độ nhấp nháy vàng ban đêm
    output reg  [1:0] main_light,    // 00: Xanh, 01: Vàng, 10: Đỏ
    output reg  [1:0] side_light     // 00: Xanh, 01: Vàng, 10: Đỏ
);

    // Định nghĩa mã màu đèn
    localparam COLOR_GREEN  = 2'b00;
    localparam COLOR_YELLOW = 2'b01;
    localparam COLOR_RED    = 2'b10;
    localparam COLOR_OFF    = 2'b11; // Trạng thái tắt đèn khi nháy

    // Định nghĩa các trạng thái FSM Moore
    localparam S_M_GREEN     = 3'd0; // Đường chính Xanh, Đường phụ Đỏ
    localparam S_M_YELLOW    = 3'd1; // Đường chính Vàng, Đường phụ Đỏ
    localparam S_S_GREEN     = 3'd2; // Đường chính Đỏ,   Đường phụ Xanh
    localparam S_S_YELLOW    = 3'd3; // Đường chính Đỏ,   Đường phụ Vàng
    localparam S_NIGHT_ON    = 3'd4; // Ban đêm: Đèn vàng bật
    localparam S_NIGHT_OFF   = 3'd5; // Ban đêm: Đèn vàng tắt

    reg [2:0] state, next_state;

    // -------------------------------------------------------------
    // Bộ đếm thời gian riêng biệt (Timer Unit)
    // -------------------------------------------------------------
    reg [5:0] timer;
    reg [5:0] timer_load;
    wire      timer_done = (timer == 6'd1);

    // Xác định giá trị nạp cho bộ đếm theo trạng thái kế tiếp
    always @(*) begin
        case (next_state)
            S_M_GREEN:   timer_load = T_MAIN_GREEN[5:0];
            S_M_YELLOW:  timer_load = T_MAIN_YEL[5:0];
            S_S_GREEN:   timer_load = T_SIDE_GREEN[5:0];
            S_S_YELLOW:  timer_load = T_SIDE_YEL[5:0];
            S_NIGHT_ON,
            S_NIGHT_OFF: timer_load = T_BLINK[5:0];
            default:     timer_load = 6'd1;
        endcase
    end

    // Bộ đếm lùi thời gian
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer <= T_MAIN_GREEN[5:0];
        end else if (state != next_state) begin
            timer <= timer_load;
        end else if (timer > 6'd0) begin
            timer <= timer - 1'b1;
        end
    end

    // -------------------------------------------------------------
    // KHỐI 1: Chuyển dịch trạng thái (Sequential FSM State Register)
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_M_GREEN; // Mặc định reset an toàn: Đường chính xanh
        end else begin
            state <= next_state;
        end
    end

    // -------------------------------------------------------------
    // KHỐI 2: Logic xác định trạng thái kế tiếp (Next-State Logic)
    // -------------------------------------------------------------
    always @(*) begin
        next_state = state;

        if (night_mode && (state != S_NIGHT_ON) && (state != S_NIGHT_OFF)) begin
            next_state = S_NIGHT_ON;
        end else begin
            case (state)
                S_M_GREEN: begin
                    if (night_mode) begin
                        next_state = S_NIGHT_ON;
                    end else if (timer_done && sensor) begin
                        next_state = S_M_YELLOW;
                    end
                end

                S_M_YELLOW: begin
                    if (timer_done) begin
                        next_state = S_S_GREEN;
                    end
                end

                S_S_GREEN: begin
                    if (night_mode || timer_done || !sensor) begin
                        next_state = S_S_YELLOW;
                    end
                end

                S_S_YELLOW: begin
                    if (timer_done) begin
                        next_state = S_M_GREEN;
                    end
                end

                S_NIGHT_ON: begin
                    if (!night_mode) begin
                        next_state = S_M_GREEN;
                    end else if (timer_done) begin
                        next_state = S_NIGHT_OFF;
                    end
                end

                S_NIGHT_OFF: begin
                    if (!night_mode) begin
                        next_state = S_M_GREEN;
                    end else if (timer_done) begin
                        next_state = S_NIGHT_ON;
                    end
                end

                default: next_state = S_M_GREEN;
            endcase
        end
    end

    // -------------------------------------------------------------
    // KHỐI 3: Giải mã đầu ra kiểu Moore (Registered Output Logic)
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_light <= COLOR_GREEN;
            side_light <= COLOR_RED;
        end else begin
            case (next_state)
                S_M_GREEN: begin
                    main_light <= COLOR_GREEN;
                    side_light <= COLOR_RED;
                end
                S_M_YELLOW: begin
                    main_light <= COLOR_YELLOW;
                    side_light <= COLOR_RED;
                end
                S_S_GREEN: begin
                    main_light <= COLOR_RED;
                    side_light <= COLOR_GREEN;
                end
                S_S_YELLOW: begin
                    main_light <= COLOR_RED;
                    side_light <= COLOR_YELLOW;
                end
                S_NIGHT_ON: begin
                    main_light <= COLOR_YELLOW;
                    side_light <= COLOR_YELLOW;
                end
                S_NIGHT_OFF: begin
                    main_light <= COLOR_OFF;
                    side_light <= COLOR_OFF;
                end
                default: begin
                    main_light <= COLOR_RED;
                    side_light <= COLOR_RED;
                end
            endcase
        end
    end

endmodule