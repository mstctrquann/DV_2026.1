`timescale 1ns / 1ps

module traffic_light_tb;

    // Rút ngắn thời gian các pha để testbench chạy nhanh
    localparam T_MAIN_GREEN = 6;
    localparam T_MAIN_YEL   = 2;
    localparam T_SIDE_GREEN = 4;
    localparam T_SIDE_YEL   = 2;
    localparam T_BLINK      = 2;

    reg        clk;
    reg        rst_n;
    reg        sensor;
    reg        night_mode;

    wire [1:0] main_light;
    wire [1:0] side_light;

    traffic_light #(
        .T_MAIN_GREEN(T_MAIN_GREEN),
        .T_MAIN_YEL(T_MAIN_YEL),
        .T_SIDE_GREEN(T_SIDE_GREEN),
        .T_SIDE_YEL(T_SIDE_YEL),
        .T_BLINK(T_BLINK)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .sensor(sensor),
        .night_mode(night_mode),
        .main_light(main_light),
        .side_light(side_light)
    );

    always #5 clk = ~clk;

    // =============================================================
    // RÀNG BUỘC AN TOÀN: Bắt buộc không bao giờ hai hướng cùng xanh
    // =============================================================
    always @(posedge clk) begin
        if (rst_n) begin
            if (main_light == 2'b00 && side_light == 2'b00) begin
                $display("\n[FATAL ERROR] Vi pham an toan: Ca hai duong cung XANH tai thoi diem %0t ns!\n", $time);
                $fatal(1);
            end
        end
    end

    initial begin
        clk        = 0;
        rst_n      = 0;
        sensor     = 0;
        night_mode = 0;

        #20;
        rst_n = 1;

        // ---------------------------------------------------------
        // Kịch bản 1: Không có xe ở đường phụ (sensor = 0)
        // Đường chính phải giữ xanh liên tục
        // ---------------------------------------------------------
        $display("\n=== TEST 1: Khong co xe o duong phu -> Main giu Xanh ===");
        #100;

        // ---------------------------------------------------------
        // Kịch bản 2: Có xe ở đường phụ (sensor = 1)
        // Chạy hết một chu kỳ hoàn chỉnh: M_Green -> M_Yel -> S_Green -> S_Yel -> M_Green
        // ---------------------------------------------------------
        $display("\n=== TEST 2: Co xe duong phu -> Chu ky doi den day du ===");
        @(posedge clk);
        sensor = 1;
        #200;

        // ---------------------------------------------------------
        // Kịch bản 3: Chế độ ban đêm (night_mode = 1)
        // Đèn vàng nhấp nháy cả hai hướng
        // ---------------------------------------------------------
        $display("\n=== TEST 3: Chuyen vao che do ban dem (night_mode = 1) ===");
        @(posedge clk);
        night_mode = 1;
        #80;

        // Thoát chế độ ban đêm trở lại hoạt động bình thường
        $display("\n=== Thoat che do ban dem -> Tro ve Main Xanh ===");
        @(posedge clk);
        night_mode = 0;
        sensor     = 0;
        #100;

        // ---------------------------------------------------------
        // Kịch bản 4: Reset bất chợt giữa chu kỳ
        // ---------------------------------------------------------
        $display("\n=== TEST 4: Reset giua chung mot pha ===");
        @(posedge clk);
        sensor = 1;
        #40;
        rst_n = 0;
        #20;
        rst_n = 1;
        #60;

        $display("\n=== KET THUC MO PHONG: Moi assertion deu vuot qua ===");
        $finish;
    end

    // Hiển thị trạng thái đèn khi có thay đổi
    always @(main_light or side_light) begin
        $display("[Time %0t ns] MAIN: %s | SIDE: %s", $time,
            (main_light == 2'b00) ? "GREEN " : (main_light == 2'b01) ? "YELLOW" : (main_light == 2'b10) ? "RED   " : "OFF   ",
            (side_light == 2'b00) ? "GREEN " : (side_light == 2'b01) ? "YELLOW" : (side_light == 2'b10) ? "RED   " : "OFF   ");
    end

endmodule