`timescale 1ns / 1ps

module second_counter_tb;

    localparam SIM_CLK_FREQ = 5;
    localparam CLK_PERIOD   = 10; // Chu kỳ clock = 10ns (100 MHz)

    reg        clk;
    reg        rst_n;
    reg        en;
    wire [5:0] sec;
    wire       tick_1s;

    // Khởi tạo Device Under Test (DUT)
    second_counter #(
        .CLK_FREQ(SIM_CLK_FREQ)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .sec(sec),
        .tick_1s(tick_1s)
    );

    // Tạo xung clock
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        // Khởi tạo giá trị ban đầu
        clk   = 0;
        rst_n = 0;
        en    = 0;

        // Reset hệ thống trong 20ns
        #20;
        rst_n = 1;
        #10;
        en    = 1;

        // Chạy qua hơn 60 xung tick_1s để quan sát sec tăng từ 0 -> 59 và quay về 0
        // Mỗi giây mô phỏng = 5 chu kỳ clock = 50ns
        // 62 giây mô phỏng = 62 * 50ns = 3100ns
        #(62 * SIM_CLK_FREQ * CLK_PERIOD);

        // Kiểm tra tính năng dừng khi en = 0
        en = 0;
        #(10 * SIM_CLK_FREQ * CLK_PERIOD);

        // Bật lại en
        en = 1;
        #(5 * SIM_CLK_FREQ * CLK_PERIOD);

        $finish;
    end

    // Monitor kiểm tra các mốc chuyển trạng thái, đặc biệt là 58 -> 59 -> 0
    always @(posedge clk) begin
        if (tick_1s) begin
            $display("[Time = %0t ns] tick_1s pulsed -> sec = %0d", $time, sec);
            if (sec == 59) begin
                $display(">>> Chuan bi chuyen trang thai: sec = 59 -> 0 o chu ky ke tiep <<<");
            end
        end
    end

endmodule