// tb_mult_top.v: Testbench chuan Verilog-2001 cho mult_serial va mult_booth
// Kiem tra day du quy tac G1 - G8, corner cases va watchdog chong treo
`timescale 1ns/1ps

`ifndef NBIT
`define NBIT 8
`endif

`ifndef SEED
`define SEED 1
`endif

module tb_mult_top;
  parameter N = `NBIT;
  reg              clk;
  reg              rst_n;
  reg              start;
  reg  [N-1:0]     a, b;

  // DUT outputs
  wire             busy_s, done_s;
  wire [2*N-1:0]   p_s;
  wire             busy_b, done_b;
  wire [2*N-1:0]   p_b;

  // Instances
  mult_serial #(.N(N)) u_s (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .a(a),
    .b(b),
    .busy(busy_s),
    .done(done_s),
    .p(p_s)
  );

  mult_booth #(.N(N)) u_b (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .a(a),
    .b(b),
    .busy(busy_b),
    .done(done_b),
    .p(p_b)
  );

  // Clock generation (Chu ky 20ns, 50MHz)
  initial clk = 1'b0;
  always #10 clk = ~clk;

  // Thong ke testbench
  integer total_tests_s, error_s;
  integer total_tests_b, error_b;
  integer seed;
  integer k;

  // Golden Reference Models
  function [2*N-1:0] exp_serial;
    input [N-1:0] in_a, in_b;
    begin
      exp_serial = in_a * in_b;
    end
  endfunction

  function [2*N-1:0] exp_booth;
    input [N-1:0] in_a, in_b;
    reg signed [N-1:0] sa, sb;
    reg signed [2*N-1:0] sp;
    begin
      sa = in_a;
      sb = in_b;
      sp = sa * sb;
      exp_booth = sp;
    end
  endfunction

  // Task kiem tra mot phep nhan tuan tu thong thuong (G2, G3, G4, G5, G6)
  task run_mult_test;
    input [N-1:0] in_a, in_b;
    reg [2*N-1:0] exp_s_val, exp_b_val;
    reg [2*N-1:0] held_p_s, held_p_b;
    integer latency_s, latency_b;
    integer watchdog;
    begin
      exp_s_val = exp_serial(in_a, in_b);
      exp_b_val = exp_booth(in_a, in_b);
      total_tests_s = total_tests_s + 1;
      total_tests_b = total_tests_b + 1;

      // 1. Nap stimulus tai negedge clk de DUT lay mau on dinh tai posedge clk
      @(negedge clk);
      a = in_a;
      b = in_b;
      start = 1'b1;

      @(posedge clk); #1;
      // G2 Check: Busy phai lap tuc bang 1 sau canh nap
      if (busy_s !== 1'b1) begin
        error_s = error_s + 1;
        $display("[FAIL][G2] mult_serial N=%0d: busy khong bang 1 sau canh nap!", N);
      end
      if (busy_b !== 1'b1) begin
        error_b = error_b + 1;
        $display("[FAIL][G2] mult_booth N=%0d: busy khong bang 1 sau canh nap!", N);
      end

      // Ha start xuong 0 o negedge tiep theo, thay doi a va b de kiem tra G2
      @(negedge clk);
      start = 1'b0;
      a = ~in_a;
      b = ~in_b;

      // 2. Cho ket qua va kiem tra do tre G3 (dung N chu ky), kem Watchdog chong treo
      latency_s = 1;
      latency_b = 1;
      watchdog = 0;

      while ((done_s !== 1'b1 || done_b !== 1'b1) && (watchdog < N + 10)) begin
        @(posedge clk); #1;
        watchdog = watchdog + 1;
        if (done_s !== 1'b1) latency_s = latency_s + 1;
        if (done_b !== 1'b1) latency_b = latency_b + 1;
      end

      // Kiem tra Timeout Watchdog
      if (watchdog >= N + 10) begin
        if (done_s !== 1'b1) begin
          error_s = error_s + 1;
          $display("[FAIL][TIMEOUT] mult_serial N=%0d: Qua %0d chu ky khong thay done!", N, watchdog);
        end
        if (done_b !== 1'b1) begin
          error_b = error_b + 1;
          $display("[FAIL][TIMEOUT] mult_booth N=%0d: Qua %0d chu ky khong thay done!", N, watchdog);
        end
      end else begin
        // G3 Check: Do tre dung N chu ky
        if (latency_s !== N) begin
          error_s = error_s + 1;
          $display("[FAIL][G3] mult_serial N=%0d: Do tre sai: %0d chu ky (ky vong %0d)!", N, latency_s, N);
        end
        if (latency_b !== N) begin
          error_b = error_b + 1;
          $display("[FAIL][G3] mult_booth N=%0d: Do tre sai: %0d chu ky (ky vong %0d)!", N, latency_b, N);
        end

        // G4 Check: Ket qua tinh toan
        if (p_s !== exp_s_val) begin
          error_s = error_s + 1;
          $display("[FAIL][G4][MATH] mult_serial N=%0d | a=%h b=%h | REC=%h EXP=%h", N, in_a, in_b, p_s, exp_s_val);
        end
        if (p_b !== exp_b_val) begin
          error_b = error_b + 1;
          $display("[FAIL][G4][MATH] mult_booth N=%0d | a=%h b=%h | REC=%h EXP=%h", N, in_a, in_b, p_b, exp_b_val);
        end

        held_p_s = p_s;
        held_p_b = p_b;

        // G5 Check: done chi bang 1 dung 1 chu ky
        @(posedge clk); #1;
        if (done_s !== 1'b0) begin
          error_s = error_s + 1;
          $display("[FAIL][G5] mult_serial N=%0d: done khong ha xuong 0 o chu ky ke tiep!", N);
        end
        if (done_b !== 1'b0) begin
          error_b = error_b + 1;
          $display("[FAIL][G5] mult_booth N=%0d: done khong ha xuong 0 o chu ky ke tiep!", N);
        end

        // G6 Check: p giu nguyen gia tri
        repeat (2) @(posedge clk); #1;
        if (p_s !== held_p_s) begin
          error_s = error_s + 1;
          $display("[FAIL][G6] mult_serial N=%0d: p khong duoc giu nguyen!", N);
        end
        if (p_b !== held_p_b) begin
          error_b = error_b + 1;
          $display("[FAIL][G6] mult_booth N=%0d: p khong duoc giu nguyen!", N);
        end
      end
    end
  endtask

  // Task kiem tra G7: start = 1 khi busy = 1 bi bo qua
  task test_protocol_g7;
    input [N-1:0] orig_a, orig_b;
    input [N-1:0] bad_a, bad_b;
    reg [2*N-1:0] exp_s_val, exp_b_val;
    integer cnt;
    begin
      exp_s_val = exp_serial(orig_a, orig_b);
      exp_b_val = exp_booth(orig_a, orig_b);
      total_tests_s = total_tests_s + 1;
      total_tests_b = total_tests_b + 1;

      @(negedge clk);
      a = orig_a; b = orig_b; start = 1'b1;
      @(negedge clk);
      // Bom xung start = 1 khi dang busy o chu ky dau tien
      a = bad_a; b = bad_b; start = 1'b1;
      @(negedge clk);
      start = 1'b0;

      // Cho den khi xong
      cnt = 0;
      while ((done_s !== 1'b1 || done_b !== 1'b1) && cnt < N + 10) begin
        @(posedge clk); #1;
        cnt = cnt + 1;
      end

      if (p_s !== exp_s_val) begin
        error_s = error_s + 1;
        $display("[FAIL][G7] mult_serial N=%0d: start khi busy lam hong ket qua!", N);
      end
      if (p_b !== exp_b_val) begin
        error_b = error_b + 1;
        $display("[FAIL][G7] mult_booth N=%0d: start khi busy lam hong ket qua!", N);
      end
      @(posedge clk);
    end
  endtask

  initial begin
    total_tests_s = 0; error_s = 0;
    total_tests_b = 0; error_b = 0;
    seed = `SEED;

    rst_n = 1'b0;
    start = 1'b0;
    a = 0; b = 0;
    #30;

    // G1 Check: Reset bat dong bo
    if (busy_s !== 1'b0 || done_s !== 1'b0 || p_s !== 0) begin
      error_s = error_s + 1;
      $display("[FAIL][G1] mult_serial N=%0d: Reset bat dong bo khong sach se!", N);
    end
    if (busy_b !== 1'b0 || done_b !== 1'b0 || p_b !== 0) begin
      error_b = error_b + 1;
      $display("[FAIL][G1] mult_booth N=%0d: Reset bat dong bo khong sach se!", N);
    end

    @(negedge clk);
    rst_n = 1'b1;
    @(posedge clk); #1;

    $display("================================================================");
    $display("[START] TB MULT (SERIAL & BOOTH) N=%0d | SEED=%0d", N, seed);
    $display("================================================================");

    // 1. CORNER CASES
    $display("--- 1. Testing Corner Cases ---");
    run_mult_test({N{1'b0}}, {N{1'b0}});
    run_mult_test({{(N-1){1'b0}}, 1'b1}, {{(N-1){1'b0}}, 1'b1});
    run_mult_test({N{1'b1}}, {N{1'b1}});
    run_mult_test({1'b1, {(N-1){1'b0}}}, {1'b1, {(N-1){1'b0}}}); // -2^(N-1) * -2^(N-1)
    run_mult_test({1'b1, {(N-1){1'b0}}}, {1'b0, {(N-1){1'b1}}}); // -2^(N-1) * MAX_POS
    run_mult_test({1'b1, {(N-1){1'b0}}}, {{(N-1){1'b0}}, 1'b1}); // -2^(N-1) * 1
    run_mult_test({N{1'b1}}, {{(N-1){1'b0}}, 1'b1});             // -1 * 1

    // 2. PROTOCOL G7 CHECK
    $display("--- 2. Testing G7 (Start when busy) ---");
    test_protocol_g7({{(N-2){1'b0}}, 2'b11}, {{(N-2){1'b0}}, 2'b10}, {N{1'b1}}, {N{1'b1}});

    // 3. PSEUDO-RANDOM STRESS
    $display("--- 3. Testing Pseudo-Random Vectors ---");
    for (k = 0; k < 50; k = k + 1) begin
      reg [N-1:0] rand_a, rand_b;
      rand_a = $random(seed);
      rand_b = $random(seed);
      run_mult_test(rand_a, rand_b);
    end

    // TONG KET
    #20;
    $display("================================================================");
    $display("[SUMMARY] MULT_SERIAL N=%0d | TOTAL=%0d | ERRORS=%0d", N, total_tests_s, error_s);
    $display("[SUMMARY] MULT_BOOTH  N=%0d | TOTAL=%0d | ERRORS=%0d", N, total_tests_b, error_b);
    $display("================================================================");

    $finish;
  end

endmodule
