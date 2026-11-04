// tb_adder_top: khung testbench (Verilog-2001) cho adder, cấu hình N = `NBIT (4, 8, 16, 32, 64).
// Phiên bản DUT chọn khi biên dịch (Makefile: V=1..4), testbench không đổi.
// Sinh viên bổ sung: tạo kích thích, mô hình tham chiếu, so sánh, đếm mismatch, in kết quả.
// Không dùng cú pháp SystemVerilog (logic, always_ff, int, class, program, mảng động, hàng đợi).
`timescale 1ns/1ps
`ifndef NBIT
`define NBIT 8
`endif
module tb_adder_top;
  parameter N = `NBIT;
  reg  [N-1:0] a, b;
  reg          cin;
  wire [N-1:0] sum;
  wire         cout;

  adder #(.N(N)) dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

  initial begin
    a = 0; b = 0; cin = 0;
    #1;
    // TODO: kích thích directed, giá trị góc, $random(seed), $readmemh; kiểm tra {cout, sum} = a + b + cin
    $display("R N=%0d done", N);
    $finish;
  end
endmodule
