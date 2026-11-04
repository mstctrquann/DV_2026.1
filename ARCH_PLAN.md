# ARCH_PLAN: KẾ HOẠCH KIẾN TRÚC VÀ PHƯƠNG ÁN KỸ THUẬT TESTBENCH BÀI TẬP TUẦN 6

## 1. TỔNG QUAN KIẾN TRÚC & MỤC TIÊU
- Tuân thủ 100% chuẩn **Verilog-2001** (`iverilog -g2001` không có lỗi cú pháp/cảnh báo, tương thích chạy với QuestaSim cho DUT IEEE 1735 `.vp`).
- Xác định chính xác phiên bản không lỗi của từng DUT (`adder`, `mult_serial`, `mult_booth`) và phát hiện, khoanh vùng mọi lỗi trong các phiên bản còn lại.
- Xử lý triệt để 5 nhóm rủi ro: Protocol race condition, Signed extremes ($a=-2^{N-1}, b=-2^{N-1}$), Carry boundary propagation, Dynamic latency watchdog, và Golden Model precision.

---

## 2. KIẾN TRÚC PHÂN TẦNG TESTBENCH (LAYERED TB ARCHITECTURE)

### 2.1. Timing & Driver (Chống Race Condition)
- **Clock:** Chu kỳ `PERIOD = 10` ($100\text{ MHz}$), clock dập đều đặn bằng `always #(PERIOD/2) clk = ~clk;`.
- **Stimulus Drive:**
  - Để tránh xung đột race condition giữa TB và DUT tại `posedge clk`, toàn bộ kích thích nạp (`start`, `a`, `b`) được gán tại `@(negedge clk)` hoặc sau `#(PERIOD/4)` tính từ `posedge`.
  - Giữ `start = 1` đúng 1 chu kỳ clock rồi hạ về `0` (trừ test case G7).
- **Monitor & Sample:**
  - Lấy mẫu tín hiệu ngõ ra (`busy`, `done`, `p`, `sum`, `cout`) tại `@(posedge clk)` có thêm trễ delta nhỏ `#1` để bảo đảm tín hiệu DUT đã ổn định hoàn toàn.

### 2.2. Golden Model & Scoreboard
- **Adder Model:**
  ```verilog
  function [N:0] exp_adder(input [N-1:0] a_val, input [N-1:0] b_val, input cin_val);
    exp_adder = a_val + b_val + cin_val;
  endfunction
  ```
- **Mult Serial Model (Unsigned):**
  ```verilog
  function [2*N-1:0] exp_mult_serial(input [N-1:0] a_val, input [N-1:0] b_val);
    exp_mult_serial = a_val * b_val;
  endfunction
  ```
- **Mult Booth Model (Signed 2's Complement):**
  ```verilog
  function [2*N-1:0] exp_mult_booth(input [N-1:0] a_val, input [N-1:0] b_val);
    reg signed [N-1:0] sa, sb;
    reg signed [2*N-1:0] sp;
    begin
      sa = a_val;
      sb = b_val;
      sp = sa * sb;
      exp_mult_booth = sp;
    end
  endfunction
  ```
- **Scoreboard:**
  - So sánh trực tiếp bằng toán tử `!==` (bắt cả bit `x` và `z`).
  - Ghi log chi tiết mỗi lỗi: Thời gian (`$time`), DUT, Version, N, Toán hạng vào, Nhận được, Kỳ vọng.
  - Tự động thống kê `total_tests` và `error_count`.

### 2.3. Watchdog Timer (Chống Treo Mô Phỏng)
- Trong bộ nhân, nếu DUT bị lỗi FSM không bao giờ trả về `done = 1`, testbench sẽ bị kẹt vĩnh viễn trong vòng lặp `@(posedge clk)` chờ `done`.
- Kiến trúc Watchdog: Thiết lập biến đếm chu kỳ `watchdog_cnt`. Nếu số chu kỳ vượt quá $N + 10$ mà `done` vẫn bằng 0, kích hoạt báo lỗi timeout, ghi log và ép buộc kết thúc test case để chuyển sang mẫu kế tiếp.

---

## 3. CHIẾN LƯỢC KIỂM THỬ (TEST STRATEGY)

### 3.1. Đối với Bộ cộng `adder`
- **N = 4, 8 (RCA):**
  - Chạy **Exhaustive testing** (vét cạn 100% không gian vector):
    - $N=4$: $2^4 \times 2^4 \times 2 = 512$ mẫu (chạy tích tắc).
    - $N=8$: $2^8 \times 2^8 \times 2 = 131,072$ mẫu (chạy ~1-2 giây).
- **N = 16, 32 (CLA):**
  - Directed Corners: $0+0+0$, $0+0+1$, $MAX+MAX+1$, $MAX+1+0$.
  - Carry-Propagation across 4-bit CLA blocks: Kiểm tra các vector kích thích lan truyền nhớ qua từng cụm 4 bit ($p_i=1 \Rightarrow a_i \neq b_i$, $g_i=1 \Rightarrow a_i=b_i=1$).
  - Random testing: $10,000$ mẫu ngẫu nhiên với seed cố định.
- **N = 64 (CSLA):**
  - Boundary toggle cho từng block 4-bit (16 blocks): kiểm tra việc chuyển đổi bit nhớ giữa các block (đặc biệt các block 1..15 sử dụng MUX).
  - Random testing: $10,000$ mẫu ngẫu nhiên với seed cố định.
- **Đọc vector `$readmemh`:** Tích hợp file vector hex sinh từ Python để kiểm tra khả năng đọc tệp.

### 3.2. Đối với Bộ nhân tuần tự `mult_serial` & `mult_booth`
- **Pha 1: Tuân thủ quy tắc G1 - G8:**
  - G1: Kích hoạt reset giữa chừng, kiểm tra `busy, done, p` lập tức về 0.
  - G2 & G3: Kiểm tra `busy` lên 1 đúng cạnh nạp và `done` lên đúng chu kỳ thứ $N$.
  - G5: Kiểm tra `done` chỉ ở mức 1 duy nhất trong đúng 1 chu kỳ.
  - G6: Chờ 5 chu kỳ idle sau `done`, kiểm tra `p` giữ nguyên vẹn.
  - G7: Đưa `start = 1` kèm thay đổi $a, b$ tại chu kỳ $1..N-1$, kiểm tra DUT có giữ nguyên phép tính cũ và không đổi độ trễ.
  - G8: Nạp liên tiếp (Back-to-back transfer) ngay chu kỳ sau `done = 1`.
- **Pha 2: Corner cases đặc thù:**
  - Serial: $0 \times 0, 0 \times MAX, MAX \times MAX, 1 \times MAX$.
  - Booth:
    - Cực tiểu âm: $(-2^{N-1}) \times (-2^{N-1})$.
    - Cực tiểu âm nhân cực đại dương: $(-2^{N-1}) \times (2^{N-1}-1)$.
    - Nhân với $-1$, nhân với $0$.
    - Âm nhân dương, âm nhân âm, dương nhân dương.
- **Pha 3: Pseudo-random testing:**
  - Tối thiểu 1000 mẫu ngẫu nhiên trên mỗi cấu hình $N \in \{4, 8, 16\}$ với seed cố định.

---

## 4. TỔ CHỨC THƯ MỤC VÀ TỰ ĐỘNG HÓA

```
DoTruongQuan_20233592_BTTuan6/
├── testplan.md             # Bản kế hoạch chi tiết ma trận tính năng -> test case
├── tb/
│   ├── tb_adder_top.v      # Testbench hoàn chỉnh cho adder (RCA/CLA/CSLA)
│   ├── tb_mult_top.v       # Testbench hoàn chỉnh cho mult_serial & mult_booth
│   ├── gen_vectors.py      # Script sinh vector kiểm tra corner và random
│   ├── Makefile            # Makefile biên dịch lint và mô phỏng QuestaSim
│   └── vectors/            # Thư mục chứa vector hex cho $readmemh
│       ├── adder_vec.hex
│       └── mult_vec.hex
├── log/                    # Thư mục lưu trữ log chạy thực tế
├── run/                    # Thư mục thực thi tạm thời
└── bao_cao.md              # Dự thảo báo cáo kết quả và khoanh vùng lỗi
```

---

## 5. BÀN GIAO CHO @CODE-WORKER
- @code-worker tiến hành băm nhỏ kế hoạch trên vào [TASKS.md](TASKS.md).
- Bắt đầu triển khai testbench, testplan và scripts hỗ trợ theo danh mục công việc.
