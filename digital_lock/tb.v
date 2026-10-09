`timescale 1ns / 1ps

module digital_lock_tb;

    reg        clk;
    reg        rst_n;
    reg        key_valid;
    reg  [3:0] key;
    reg        reset_lock;

    wire       unlock;
    wire       locked_out;
    wire [1:0] attempts;

    digital_lock dut (
        .clk(clk),
        .rst_n(rst_n),
        .key_valid(key_valid),
        .key(key),
        .reset_lock(reset_lock),
        .unlock(unlock),
        .locked_out(locked_out),
        .attempts(attempts)
    );

    // Tạo xung nhịp hệ thống 100MHz (chu kỳ 10ns)
    always #5 clk = ~clk;

    // Task hỗ trợ mô phỏng thao tác bấm phím (rộng 1 chu kỳ clk)
    task press_key(input [3:0] k);
        begin
            @(posedge clk);
            key       = k;
            key_valid = 1'b1;
            @(posedge clk);
            key_valid = 1'b0;
            key       = 4'd0;
            #(20); // Thời gian nghỉ giữa 2 lần bấm phím
        end
    endtask

    // Task nhập cả chuỗi 4 chữ số
    task enter_pin(input [3:0] d1, input [3:0] d2, input [3:0] d3, input [3:0] d4);
        begin
            press_key(d1);
            press_key(d2);
            press_key(d3);
            press_key(d4);
            #(40); // Chờ FSM xử lý xong kết quả
        end
    endtask

    initial begin
        clk        = 0;
        rst_n      = 0;
        key_valid  = 0;
        key        = 0;
        reset_lock = 0;

        #20;
        rst_n = 1;
        #30;

        // -------------------------------------------------------------
        // Case 1: Nhập đúng ngay lần đầu (1 - 2 - 3 - 4)
        // -------------------------------------------------------------
        $display("\n=== TEST 1: Nhap dung ngay lan dau (1234) ===");
        enter_pin(4'd1, 4'd2, 4'd3, 4'd4);

        // -------------------------------------------------------------
        // Case 2: Nhập sai ở từng vị trí
        // -------------------------------------------------------------
        $display("\n=== TEST 2: Nhap sai vi tri cuoi (1239) ===");
        enter_pin(4'd1, 4'd2, 4'd3, 4'd9);

        // -------------------------------------------------------------
        // Case 3: Nhập đúng sau các lần sai (Kiem tra reset attempts ve 0)
        // -------------------------------------------------------------
        $display("\n=== TEST 3: Nhap sai tiep mot lan nua roi nhap dung ===");
        enter_pin(4'd9, 4'd2, 4'd3, 4'd4); // Sai lan 2 (attempts = 2)
        enter_pin(4'd1, 4'd2, 4'd3, 4'd4); // Dung -> unlock = 1, attempts quay ve 0

        // -------------------------------------------------------------
        // Case 4: Nhập sai 3 lần liên tiếp -> Khoa cung (locked_out = 1)
        // -------------------------------------------------------------
        $display("\n=== TEST 4: Nhap sai 3 lan lien tiep de kiem tra khoa cung ===");
        enter_pin(4'd0, 4'd0, 4'd0, 4'd0); // Sai lan 1
        enter_pin(4'd0, 4'd0, 4'd0, 4'd1); // Sai lan 2
        enter_pin(4'd0, 4'd0, 4'd0, 4'd2); // Sai lan 3 -> locked_out = 1

        // Thu nhap dung trong khi bi khoa xem co duoc phep mo khong
        $display("\nThu nhap dung khi dang bi khoa cung (1234):");
        enter_pin(4'd1, 4'd2, 4'd3, 4'd4);

        // Kich hoat tin hieu reset_lock de khoi phuc he thong
        $display("\nKich hoat tin hieu reset_lock de reset khoa...");
        @(posedge clk);
        reset_lock = 1'b1;
        @(posedge clk);
        reset_lock = 1'b0;
        #(40);

        // Thu nhap lai mat khau sau khi reset
        enter_pin(4'd1, 4'd2, 4'd3, 4'd4);

        #50;
        $finish;
    end

    // Monitor quan sát kết quả trực tiếp trên Transcript
    always @(posedge clk) begin
        if (unlock) begin
            $display("[Time %0t ns] >>> UNLOCK THANH CONG! Attempts = %0d <<<", $time, attempts);
        end
        if (locked_out && !dut.locked_out) begin
            $display("[Time %0t ns] !!! HE THONG DA BI KHOA CUNG (attempts = 3) !!!", $time);
        end
    end

endmodule