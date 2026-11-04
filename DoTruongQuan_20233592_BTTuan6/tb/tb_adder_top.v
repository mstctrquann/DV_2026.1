// tb_adder_top.v: Testbench chuan Verilog-2001 cho bo cong adder (RCA/CLA/CSLA)
// Ho tro moi cau hinh NBIT in {4, 8, 16, 32, 64}
`timescale 1ns/1ps

`ifndef NBIT
`define NBIT 8
`endif

`ifndef SEED
`define SEED 1
`endif

module tb_adder_top;
  parameter N = `NBIT;
  reg  [N-1:0] a, b;
  reg          cin;
  wire [N-1:0] sum;
  wire         cout;

  // DUT Instance
  adder #(.N(N)) dut (
    .a(a),
    .b(b),
    .cin(cin),
    .sum(sum),
    .cout(cout)
  );

  // Thong ke testbench
  integer total_tests;
  integer error_count;
  integer seed;
  integer i, j, k;

  // Golden model
  function [N:0] exp_adder;
    input [N-1:0] in_a;
    input [N-1:0] in_b;
    input         in_cin;
    begin
      exp_adder = in_a + in_b + in_cin;
    end
  endfunction

  // Task check 1 mau
  task check_sample;
    input [N-1:0] in_a;
    input [N-1:0] in_b;
    input         in_cin;
    reg   [N:0]   expected;
    begin
      a = in_a;
      b = in_b;
      cin = in_cin;
      #5; // Thoi gian cho mach to hop on dinh
      expected = exp_adder(a, b, cin);
      total_tests = total_tests + 1;

      if ({cout, sum} !== expected) begin
        error_count = error_count + 1;
        $display("[FAIL][TIME=%0t] adder N=%0d | a=%h b=%h cin=%b | REC={cout=%b sum=%h} EXP={cout=%b sum=%h}",
                 $time, N, a, b, cin, cout, sum, expected[N], expected[N-1:0]);
      end
    end
  endtask

  // Mang de doc vector bang $readmemh (toan bo du lieu bieu dien dang hex)
  // Moi mau luu vao bo nho vector
  reg [N-1:0] vec_a [0:255];
  reg [N-1:0] vec_b [0:255];
  reg         vec_cin [0:255];
  integer vec_count;

  initial begin
    total_tests = 0;
    error_count = 0;
    seed = `SEED;
    a = 0; b = 0; cin = 0;
    #10;

    $display("================================================================");
    $display("[START] TB ADDER N=%0d | SEED=%0d", N, seed);
    $display("================================================================");

    // 1. DIRECTED CORNER CASES
    $display("--- 1. Testing Corner Cases ---");
    check_sample({N{1'b0}}, {N{1'b0}}, 1'b0);
    check_sample({N{1'b0}}, {N{1'b0}}, 1'b1);
    check_sample({N{1'b1}}, {N{1'b0}}, 1'b0);
    check_sample({N{1'b1}}, {N{1'b0}}, 1'b1);
    check_sample({N{1'b0}}, {N{1'b1}}, 1'b0);
    check_sample({N{1'b0}}, {N{1'b1}}, 1'b1);
    check_sample({N{1'b1}}, {N{1'b1}}, 1'b0);
    check_sample({N{1'b1}}, {N{1'b1}}, 1'b1);
    check_sample({N{1'b1}}, {{(N-1){1'b0}}, 1'b1}, 1'b0);

    // 2. CRITICAL CARRY PROPAGATION (Xich lan truyen bit nho dai nhat)
    $display("--- 2. Testing Critical Carry Chains ---");
    // a = 1111...1, b = 0, cin = 1 -> sum = 0, cout = 1
    check_sample({N{1'b1}}, {N{1'b0}}, 1'b1);
    // a = 0101...01, b = 1010...10, cin = 1 -> sum = 0, cout = 1 (toan bo pi = 1)
    check_sample({(N/2){2'b01}}, {(N/2){2'b10}}, 1'b1);
    check_sample({(N/2){2'b01}}, {(N/2){2'b10}}, 1'b0);

    // 3. BOUNDARY TESTING CHO CLA & CSLA (N >= 16)
    if (N >= 16) begin
      $display("--- 3. Testing 4-bit Boundary Transitions ---");
      for (i = 0; i < N; i = i + 4) begin
        check_sample(4'hF << i, 4'h1 << i, 1'b0);
        check_sample(4'hF << i, 4'h0 << i, 1'b1);
      end
    end

    // 4. EXHAUSTIVE TESTING CHO N = 4, 8
    if (N == 4) begin
      $display("--- 4. Running Exhaustive Test for N=4 (512 vectors) ---");
      for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
          check_sample(i[3:0], j[3:0], 1'b0);
          check_sample(i[3:0], j[3:0], 1'b1);
        end
      end
    end else if (N == 8) begin
      $display("--- 4. Running Exhaustive Test for N=8 (131,072 vectors) ---");
      for (i = 0; i < 256; i = i + 1) begin
        for (j = 0; j < 256; j = j + 1) begin
          check_sample(i[7:0], j[7:0], 1'b0);
          check_sample(i[7:0], j[7:0], 1'b1);
        end
      end
    end else begin
      // 5. RANDOM TESTING CHO N >= 16
      $display("--- 5. Running Pseudo-Random Stress Test (5,000 vectors) ---");
      for (k = 0; k < 5000; k = k + 1) begin
        reg [N-1:0] rand_a, rand_b;
        reg rand_c;
        // Sinh so ngau nhien cho du bit N
        rand_a = {$random(seed), $random(seed)};
        rand_b = {$random(seed), $random(seed)};
        rand_c = $random(seed) & 1'b1;
        check_sample(rand_a, rand_b, rand_c);
      end
    end

    // TONG KET
    #10;
    $display("================================================================");
    $display("[SUMMARY] ADDER N=%0d | TOTAL=%0d | ERRORS=%0d", N, total_tests, error_count);
    if (error_count == 0)
      $display("[RESULT] ADDER N=%0d: PASS", N);
    else
      $display("[RESULT] ADDER N=%0d: FAIL", N);
    $display("================================================================");

    $finish;
  end

endmodule
