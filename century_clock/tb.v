`timescale 1ns / 1ps

module century_clock_tb;

    localparam SIM_CLK_FREQ = 2; // Rút ngắn còn 2 chu kỳ clock = 1 giây mô phỏng
    localparam CLK_PERIOD   = 10;

    reg        clk;
    reg        rst_n;
    reg        set_en;
    reg  [2:0] set_field;
    reg [11:0] set_value;

    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;
    wire [4:0] day;
    wire [3:0] month;
    wire [6:0] year;

    century_clock #(
        .CLK_FREQ(SIM_CLK_FREQ)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .set_en(set_en),
        .set_field(set_field),
        .set_value(set_value),
        .sec(sec),
        .min(min),
        .hour(hour),
        .day(day),
        .month(month),
        .year(year)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    // Task hỗ trợ nạp nhanh thời gian
    task set_time(
        input [6:0] y,
        input [3:0] mo,
        input [4:0] d,
        input [4:0] h,
        input [5:0] mi,
        input [5:0] s
    );
        begin
            @(posedge clk);
            set_en = 1;
            set_field = 3'd5; set_value = y;  @(posedge clk);
            set_field = 3'd4; set_value = mo; @(posedge clk);
            set_field = 3'd3; set_value = d;  @(posedge clk);
            set_field = 3'd2; set_value = h;  @(posedge clk);
            set_field = 3'd1; set_value = mi; @(posedge clk);
            set_field = 3'd0; set_value = s;  @(posedge clk);
            set_en = 0;
            @(posedge clk);
        end
    endtask

    initial begin
        clk       = 0;
        rst_n     = 0;
        set_en    = 0;
        set_field = 0;
        set_value = 0;

        #20;
        rst_n = 1;
        #20;

        // -------------------------------------------------------------
        // Case 1: Chuyển ngày 23:59:59 -> 00:00:00
        // -------------------------------------------------------------
        $display("\n=== TEST 1: 23:59:59 -> 00:00:00 chuyen sang ngay moi ===");
        set_time(7'd24, 4'd5, 5'd10, 5'd23, 6'd59, 6'd58);
        #(6 * CLK_PERIOD);

        // -------------------------------------------------------------
        // Case 2: 28/02 -> 29/02 trong năm nhuận (Year = 04)
        // -------------------------------------------------------------
        $display("\n=== TEST 2: 28/02 -> 29/02 trong nam nhuan (Year = 4) ===");
        set_time(7'd4, 4'd2, 5'd28, 5'd23, 6'd59, 6'd58);
        #(6 * CLK_PERIOD);

        // -------------------------------------------------------------
        // Case 3: 28/02 -> 01/03 trong năm không nhuận (Year = 01)
        // -------------------------------------------------------------
        $display("\n=== TEST 3: 28/02 -> 01/03 trong nam khong nhuan (Year = 1) ===");
        set_time(7'd1, 4'd2, 5'd28, 5'd23, 6'd59, 6'd58);
        #(6 * CLK_PERIOD);

        // -------------------------------------------------------------
        // Case 4: 31/12 -> 01/01 chuyển sang năm mới
        // -------------------------------------------------------------
        $display("\n=== TEST 4: 31/12 -> 01/01 chuyen sang nam moi ===");
        set_time(7'd25, 4'd12, 5'd31, 5'd23, 6'd59, 6'd58);
        #(6 * CLK_PERIOD);

        #50;
        $finish;
    end

    // Monitor in ra thời gian mỗi khi giây thay đổi
    always @(sec) begin
        $display("[%0t ns] DATE: %02d/%02d/20%02d | TIME: %02d:%02d:%02d",
                 $time, day, month, year, hour, min, sec);
    end

endmodule