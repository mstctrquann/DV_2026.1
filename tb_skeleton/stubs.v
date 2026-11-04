// stubs.v: khai báo cổng của 3 DUT (không có chức năng), chỉ dùng cho `make lint` với Icarus -g2001.
module adder #(parameter N = 8) (input [N-1:0] a, b, input cin, output [N-1:0] sum, output cout);
  assign {cout, sum} = {(N+1){1'bx}};
endmodule
module mult_serial #(parameter N = 8) (input clk, rst_n, start, input [N-1:0] a, b,
                                       output busy, done, output [2*N-1:0] p);
  assign {busy, done, p} = {(2*N+2){1'bx}};
endmodule
module mult_booth  #(parameter N = 8) (input clk, rst_n, start, input [N-1:0] a, b,
                                       output busy, done, output [2*N-1:0] p);
  assign {busy, done, p} = {(2*N+2){1'bx}};
endmodule
