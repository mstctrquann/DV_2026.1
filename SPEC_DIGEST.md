# SPEC_DIGEST: ĐẶC TẢ VÀ YÊU CẦU BÀI TẬP TUẦN 6 (ET4356)

## 1. TỔNG QUAN DỰ ÁN
- **Môn học:** Kiểm chứng chức năng (ET4356).
- **Mục tiêu:** Xây dựng testbench Verilog-2001 (chuẩn Lint Icarus Verilog `-g2001`, mô phỏng QuestaSim trên DUT mã hoá IEEE 1735 `.vp`).
- **DUTs:**
  1. `adder` (tổ hợp, N = 4, 8 [RCA], 16, 32 [CLA], 64 [CSLA]).
  2. `mult_serial` (tuần tự không dấu, N = 4, 8, 16).
  3. `mult_booth` (tuần tự có dấu Booth Radix-2 bù 2, N = 4, 8, 16).
- **Mục đích kiểm chứng:**
  - Xác định 1 phiên bản không lỗi duy nhất cho mỗi DUT trong 4 phiên bản (`v1` đến `v4`).
  - Phát hiện, khoanh vùng và lập luận nguyên nhân lỗi cho 3 phiên bản còn lại (lần lượt chứa 1, 2, 3 lỗi chức năng).

---

## 2. ĐẶC TẢ CHI TIẾT CÁC THIẾT KẾ (DUT)

### 2.1. Bộ cộng `adder`
- **Giao diện:**
  - `input [N-1:0] a, b`
  - `input cin`
  - `output [N-1:0] sum`
  - `output cout`
- **Chức năng:** `{cout, sum} = a + b + cin` (số học không dấu N+1 bit). Mạch tổ hợp hoàn toàn.
- **Vi kiến trúc:**
  - $N \in \{4, 8\}$: **Ripple-Carry Adder (RCA)**. Full-adder nối tiếp. Đường trễ nhớ N tầng.
  - $N \in \{16, 32\}$: **Carry-Lookahead Adder (CLA)**. Nhóm 4-bit CLA, generate $g_i = a_i b_i$, propagate $p_i = a_i \oplus b_i$. Carry giữa các nhóm nối tiếp.
  - $N = 64$: **Carry-Select Adder (CSLA)**. Block 0: RCA 4-bit nhận `cin`. Các block 1..15: 2 nhánh RCA 4-bit tính trước ($cin=0$ và $cin=1$), ghép tầng bằng MUX 2:1 chọn carry và sum.

### 2.2. Bộ nhân tuần tự `mult_serial` & `mult_booth`
- **Giao diện chung:**
  - `input clk` (cạnh lên), `input rst_n` (asynchronous active-low reset).
  - `input start` (xung kích hoạt).
  - `input [N-1:0] a, b` (toán hạng).
  - `output reg busy` (báo bận).
  - `output reg done` (báo hoàn thành).
  - `output reg [2*N-1:0] p` (kết quả tích).
- **Giao thức chuẩn (G1 – G8):**
  - **G1 (Reset):** Khi `rst_n = 0`, ngay lập tức `busy = 0, done = 0, p = 0`.
  - **G2 (Nạp):** Cạnh lên `clk` có `start = 1` và `busy = 0` là cạnh nạp. DUT lấy mẫu `a, b`, nâng `busy = 1`. Sau cạnh nạp, `a, b` có thể thay đổi mà không ảnh hưởng kết quả.
  - **G3 (Độ trễ):** Đúng sau $N$ chu kỳ clock kể từ cạnh nạp, DUT hạ `busy = 0` và kéo `done = 1`.
  - **G4 (Kết quả):** Khi `done = 1`:
    - `mult_serial`: $p = a \times b$ (unsigned $2N$-bit).
    - `mult_booth`: $p = \$signed(a) \times \$signed(b)$ (signed 2's complement $2N$-bit).
  - **G5 (`done` pulse):** `done = 1` duy nhất trong 1 chu kỳ xung nhịp.
  - **G6 (Giữ kết quả):** `p` giữ nguyên giá trị từ chu kỳ `done = 1` cho đến cạnh nạp kế tiếp.
  - **G7 (`start` khi bận):** Nếu `start = 1` trong khi `busy = 1`, DUT bắt buộc bỏ qua `start`, tiếp tục phép nhân cũ với toán hạng và độ trễ không đổi.
  - **G8 (Liên tiếp):** Phép nhân mới có thể nạp ngay chu kỳ sau `done = 1` (`busy = 0`). Kết quả độc lập hoàn toàn với phép nhân trước.

---

## 3. YÊU CẦU TESTBENCH VÀ TESTPLAN
- **Quy chuẩn mã nguồn:** Chuẩn Verilog-2001 (`make lint` không có cảnh báo/lỗi, không dùng cú pháp SystemVerilog).
- **Cấu trúc TB:**
  - Tạo clock, async reset.
  - Task stimulus giao thức, task test corner cases, loop exhaustive (với $N=4, 8$ adder), random với seed cố định `$random(seed)`.
  - Tính năng đọc vector `$readmemh` (sinh file hex từ python/script).
  - Scoreboard tự kiểm tra (`!==`), in log chi tiết từng mismatch (thời điểm, DUT, version, N, inputs, actual, expected).
  - In tổng kết (Total tests, Total errors). Cơ chế timeout chống treo (watchdog).
- **Deliverables:**
  - Folder nộp bài: `DoTruongQuan_20233592_BTTuan6/`
  - `testplan.md`
  - `tb/` (chứa testbench, vectors, generator script, Makefile)
  - `log/`
  - Báo cáo kết quả và khoanh vùng lỗi.
