# SPEC_FEEDBACK: PHẢN BIỆN KIẾN TRÚC VÀ RÀ SOÁT LỖ HỔNG TIỀM ẨN

## 1. RÀ SOÁT CÁC LỖ HỔNG & EDGE CASES QUAN TRỌNG

### 1.1. Race Condition và Giao thức Bắt tay (G1 - G8) trong Testbench
- **Bẫy điều khiển tín hiệu (Clock/Data Race):**
  - Trong Verilog-2001, nếu kích thích `start`, `a`, `b` thay đổi đồng thời trên `@(posedge clk)` bằng blocking assignment (`=`) hoặc timing không có trễ/offset, có nguy cơ gây race condition giữa TB và DUT (DUT lấy mẫu giá trị mới hay cũ).
  - *Giải pháp:* TB phải kích thích sau cạnh clock (ví dụ `#(PERIOD/4)` hoặc `@(negedge clk)`) và lấy mẫu kiểm tra tại thời điểm ổn định.
- **Quy tắc G7 (Bỏ qua start khi bận):**
  - Cần test bơm xung `start = 1` ở chu kỳ 1, 2, ..., N-1 khi `busy = 1` kèm thay đổi giá trị `a, b`. Nếu DUT bị reset bộ đếm hoặc nạp đè dữ liệu mới, kết quả sẽ sai lệch hoặc độ trễ thay đổi.
- **Quy tắc G8 (Back-to-back transfer):**
  - Đưa `start = 1` ngay tại chu kỳ `busy` vừa hạ xuống (ngay sau `done = 1`). Phải kiểm tra DUT có bị dính trạng thái cũ hoặc mất chu kỳ hay không.
- **Quy tắc G6 (Giữ kết quả):**
  - Chờ nhiều chu kỳ idle sau `done = 1`, kiểm tra `p` có bị nhảy về 0 hoặc rác trước khi có cạnh nạp mới hay không.

### 1.2. Phép nhân Booth Radix-2: Các ca cực trị (Signed Extremes)
- **Điểm mù toán học bù 2:**
  - Ca $a = -2^{N-1}$ (giá trị âm cực tiểu, ví dụ với $N=4$ là `-8` = `1000b`) và $b = -2^{N-1}$. Khi lấy bù 2 $-(-8) = +8$, nếu thanh ghi cộng/trừ trong DUT không có bit mở rộng dấu thứ $N+1$ (như hình 5 chỉ rõ thanh ghi M có $N+1$ bit), phép trừ $A - M$ sẽ bị tràn số nghiêm trọng.
  - Phép nhân với 0, với -1, với $+2^{N-1}-1$.
  - Nhân giữa hai số âm: $(-A) \times (-B) = +P$, kiểm tra bit dấu $p[2N-1]$ có luôn chuẩn 0.

### 1.3. Phép cộng Adder: Vấn đề lan truyền nhớ và biên khối
- **RCA (N=4, 8):**
  - Xích lan truyền dài nhất (Critical Carry Propagation): $a = 2^N - 1$, $b = 0$, $cin = 1$ hoặc $a = 111...1b, b = 000...1b$. Bit nhớ phải lan truyền từ bit 0 tới bit $N$.
- **CLA (N=16, 32):**
  - Các lỗi thiết kế CLA thường nằm ở phương trình tạo nhớ giữa các khối 4-bit (ví dụ nhầm $g_i$ và $p_i$, hoặc lỗi tại $c_4, c_8, c_{12}$). Cần kiểm tra kỹ các mẫu mang tính kích hoạt toàn bộ propagate ($p=1$) trên từng block 4-bit để bit nhớ xuyên qua khối.
- **CSLA (N=64):**
  - Lỗi thường nằm ở MUX chọn ngõ ra của từng khối $j$ (chọn sai kênh khi $cin=1$ hoặc $cin=0$, hoặc nhầm bit carry-out của khối sang carry-in khối kế). Cần test các vector gây carry toggle qua từng ranh giới 4-bit ($4, 8, 12, ..., 60$).

### 1.4. Tính độc lập của mô hình tham chiếu (Golden Model)
- Bộ tham chiếu trong Testbench phải được viết tường minh:
  - Adder: `sum_exp = a + b + cin`, `cout_exp = (a + b + cin) >> N`.
  - Mult Serial: phép nhân không dấu chính xác $2N$-bit `p_exp = a * b`.
  - Mult Booth: phép nhân có dấu 2's complement bằng toán tử `$signed` của Verilog:
    `p_exp = $signed({{N{a[N-1]}}, a}) * $signed({{N{b[N-1]}}, b})` để đảm bảo 100% chuẩn xác ngay cả với các trường hợp mở rộng bit.

---

## 2. KẾT LUẬN & KHUYẾN NGHỊ
- Testbench cần chia nhỏ thành các pha kiểm tra rõ rệt (Phân pha: Reset check -> Directed Corners -> G1-G8 Protocol compliance -> Readmemh vector -> Exhaustive/Randomized stress).
- Bộ đếm Watchdog timeout là bắt buộc đối với bộ nhân (nếu sau $N+5$ chu kỳ mà không thấy `done`, timeout báo FAIL thay vì treo mô phỏng).
- **Trạng thái:** APPROVED - Đủ cơ sở để Architect Lead lập bản thiết kế kỹ thuật tổng thể [ARCH_PLAN.md](ARCH_PLAN.md).
