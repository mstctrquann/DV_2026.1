// tb_mult_top: khung testbench (Verilog-2001) cho hai bộ nhân tuần tự, cấu hình N = `NBIT (4, 8, 16).
// Sinh viên bổ sung: task thực hiện một phép nhân theo giao thức start/busy/done, mô hình tham chiếu
// (mult_serial: không dấu; mult_booth: có dấu bù 2), kiểm tra giá trị, độ trễ, giữ kết quả, chống treo.
// Không dùng cú pháp SystemVerilog (logic, always_ff, int, class, program, mảng động, hàng đợi).
`timescale 1ns/1ps
`ifndef NBIT
`define NBIT 8
`endif
module tb_mult_top;
  parameter N = `NBIT;
  reg              clk, rst_n, start;
  reg  [N-1:0]     a, b;
  wire             busy_s, done_s, busy_b, done_b;
  wire [2*N-1:0]   p_s, p_b;

  mult_serial #(.N(N)) u_s (.clk(clk), .rst_n(rst_n), .start(start), .a(a), .b(b), .busy(busy_s), .done(done_s), .p(p_s));
  mult_booth  #(.N(N)) u_b (.clk(clk), .rst_n(rst_n), .start(start), .a(a), .b(b), .busy(busy_b), .done(done_b), .p(p_b));

  initial clk = 1'b0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 1'b0; start = 1'b0; a = 0; b = 0;
    repeat (3) @(negedge clk);
    rst_n = 1'b1;
    @(negedge clk);
    // TODO: các phép nhân directed, giá trị góc, ngẫu nhiên, chuỗi liên tiếp, start khi busy = 1
    $display("R N=%0d done", N);
    $finish;
  end
endmodule
