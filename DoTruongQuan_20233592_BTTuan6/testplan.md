# KẾ HOẠCH KIỂM CHỨNG (TESTPLAN) — BÀI TẬP TUẦN 6 (ET4356)

**Học phần:** Kiểm chứng chức năng (ET4356)  
**Sinh viên thực hiện:** Đỗ Trường Quân — MSSV: 20233592  
**Đối tượng kiểm chứng:**
1. Bộ cộng $N$-bit `adder` ($N \in \{4, 8, 16, 32, 64\}$)
2. Bộ nhân tuần tự không dấu $N$-bit `mult_serial` ($N \in \{4, 8, 16\}$)
3. Bộ nhân tuần tự có dấu $N$-bit `mult_booth` ($N \in \{4, 8, 16\}$)

---

## PHẦN 1: KẾ HOẠCH KIỂM CHỨNG BỘ CỘNG `adder`

### 1.1. Bảng ma trận tính năng và trường hợp kiểm thử

| Mã Test | Tính năng (Trích đặc tả) | Tên Test | Loại Test | Kích thích cụ thể | Tiêu chí PASS | Cấu hình $N$ |
|---|---|---|---|---|---|---|
| **ADD_EXH_01** | Toàn vẹn chức năng $\{cout, sum\} = a + b + cin$ | `test_adder_exhaustive` | Vét cạn (Exhaustive) | Quét toàn bộ không gian: $a \in [0, 2^N-1]$, $b \in [0, 2^N-1]$, $cin \in \{0, 1\}$. Tổng cộng $2 \times 2^N \times 2^N$ mẫu. | `{cout, sum} === a + b + cin` với mọi vector. | $N = 4$ (512 mẫu), $N = 8$ (131,072 mẫu) |
| **ADD_COR_01** | Giá trị 0 và vai trò $cin$ | `test_zero_cin` | Góc (Directed Corner) | $a = 0, b = 0, cin = 0$ và $cin = 1$. | $sum = cin$, $cout = 0$. | Mọi $N \in \{4, 8, 16, 32, 64\}$ |
| **ADD_COR_02** | Giá trị cực đại không tràn cờ nhớ | `test_max_no_cout` | Góc | $a = 2^N - 1, b = 0, cin = 0$; $a = 0, b = 2^N - 1, cin = 0$. | $sum = 2^N - 1$, $cout = 0$. | Mọi $N$ |
| **ADD_COR_03** | Tràn cờ nhớ cực đại | `test_max_overflow` | Góc | $a = 2^N - 1, b = 2^N - 1, cin = 1$. | $sum = 2^N - 1$, $cout = 1$. | Mọi $N$ |
| **ADD_RCA_01** | Xích lan truyền bit nhớ dài nhất (RCA ripple chain) | `test_ripple_carry_chain` | Góc | $a = 2^N - 1, b = 0, cin = 1$ và $a = 2^N - 1, b = 1, cin = 0$. | $sum = 0$, $cout = 1$. Bit nhớ đi qua đủ $N$ tầng FA. | $N \in \{4, 8\}$ |
| **ADD_CLA_01** | Lan truyền nhớ xuyên cụm 4-bit (CLA carry propagate) | `test_cla_propagate_blocks` | Directed | $a = 0xAAAA..., b = 0x5555..., cin = 1$ ($a_i \oplus b_i = 1, \forall i \Rightarrow p_i=1$). | $sum = 0$, $cout = 1$. Cờ nhớ lan truyền qua các tầng nhìn trước. | $N \in \{16, 32\}$ |
| **ADD_CLA_02** | Sinh nhớ nội bộ từng cụm 4-bit (CLA carry generate) | `test_cla_generate_blocks` | Directed | Kích thích từng cụm bit $k \in [0, N/4-1]$ với $a[4k+3:4k] = 0xF, b[4k+3:4k] = 0x1$. | Cờ nhớ sinh ra chính xác tại ranh giới cụm $4k+4$. | $N \in \{16, 32\}$ |
| **ADD_CSLA_01** | Kiểm tra ranh giới khối 4-bit và MUX chọn nhớ CSLA | `test_csla_mux_selection` | Directed | $a = 0x0123456789ABCDEF, b = 0x0000000000000F11, cin \in \{0, 1\}$. Đảo bit nhớ đầu vào từng khối 1..15. | MUX chọn đúng nhánh $cin=0$ hoặc $cin=1$; $sum$ và $cout$ khớp tuyệt đối. | $N = 64$ |
| **ADD_FILE_01** | Đọc vector kiểm thử ngoại vi | `test_adder_readmemh` | Đọc tệp | Đọc 100 mẫu chọn lọc từ file `adder_vec_<N>.hex` thông qua `$readmemh`. | `{cout, sum} === a + b + cin`. | Mọi $N$ |
| **ADD_RND_01** | Ứng suất ngẫu nhiên giả lập (Pseudo-random stress) | `test_adder_random` | Ngẫu nhiên | $10,000$ mẫu ngẫu nhiên `$random(seed)` với seed cố định. | `{cout, sum} === a + b + cin`. | $N \in \{16, 32, 64\}$ |

### 1.2. Đánh giá tính khả thi duyệt toàn bộ (Exhaustive) theo $N$
- **$N = 4$:** Số tổ hợp $= 2 \times 2^4 \times 2^4 = 512$ mẫu $\rightarrow$ **Duyệt toàn bộ được**. Thời gian mô phỏng ước tính: $< 0.1\,\text{s}$.
- **$N = 8$:** Số tổ hợp $= 2 \times 2^8 \times 2^8 = 131,072$ mẫu $\rightarrow$ **Duyệt toàn bộ được**. Thời gian mô phỏng ước tính: $\approx 1.5\,\text{s}$.
- **$N = 16$:** Số tổ hợp $= 2 \times 2^{16} \times 2^{16} = 8.58 \times 10^9$ mẫu $\rightarrow$ **Không duyệt toàn bộ được** (cần $> 100$ giờ). Phương án: Directed + 10,000 Random.
- **$N = 32$:** Số tổ hợp $\approx 3.68 \times 10^{19}$ mẫu $\rightarrow$ **Không duyệt toàn bộ được**. Phương án: Directed + 10,000 Random.
- **$N = 64$:** Số tổ hợp $\approx 6.79 \times 10^{38}$ mẫu $\rightarrow$ **Không duyệt toàn bộ được**. Phương án: Directed boundary MUX + 10,000 Random.

---

## PHẦN 2: KẾ HOẠCH KIỂM CHỨNG BỘ NHÂN TUẦN TỰ (`mult_serial`, `mult_booth`)

### 2.1. Bảng ma trận kiểm chứng quy tắc giao thức G1 – G8

| Mã Test | Quy tắc giao thức | Tên Test | Loại Test | Kích thích cụ thể | Tiêu chí PASS | Cấu hình $N$ |
|---|---|---|---|---|---|---|
| **MUL_PROT_G1** | G1. Reset bất đồng bộ | `test_g1_async_reset` | Directed | Đang thực hiện phép nhân (chu kỳ bất kỳ), kéo `rst_n = 0`. | Ngay lập tức tại thời điểm đó: `busy === 0`, `done === 0`, `p === 0`. | $N \in \{4, 8, 16\}$ |
| **MUL_PROT_G2** | G2. Lấy mẫu cạnh nạp | `test_g2_sample_operands` | Directed | Cạnh lên clock có `start=1, busy=0`, sau đó thay đổi $a, b$ sang giá trị khác ở chu kỳ tiếp theo. | DUT giữ nguyên $a, b$ ban đầu, tính toán đúng theo toán hạng nạp. | $N \in \{4, 8, 16\}$ |
| **MUL_PROT_G3** | G3. Độ trễ chính xác $N$ chu kỳ | `test_g3_exact_latency` | Directed | Đếm số xung clock từ cạnh nạp đến khi `done=1`. | `busy = 1` kéo dài đúng $N$ chu kỳ; `done = 1` tại đúng cạnh thứ $N$. | $N \in \{4, 8, 16\}$ |
| **MUL_PROT_G4** | G4. Tính đúng đắn toán học | `test_g4_correctness` | Directed / Rnd | So sánh $p$ khi `done=1` với Golden Model. | Serial: $p = a \times b$; Booth: $p = \$signed(a) \times \$signed(b)$. | $N \in \{4, 8, 16\}$ |
| **MUL_PROT_G5** | G5. Xung `done` duy nhất | `test_g5_done_pulse` | Directed | Giám sát `done` ở chu kỳ $N$ và $N+1$. | `done === 1` đúng 1 chu kỳ clock, chu kỳ kế tiếp `done === 0`. | $N \in \{4, 8, 16\}$ |
| **MUL_PROT_G6** | G6. Giữ kết quả sau `done` | `test_g6_hold_result` | Directed | Để hệ thống idle 5 chu kỳ sau khi `done` hạ xuống. | $p$ giữ nguyên giá trị không đổi cho đến khi có cạnh nạp mới. | $N \in \{4, 8, 16\}$ |
| **MUL_PROT_G7** | G7. Bỏ qua `start` khi bận | `test_g7_start_when_busy` | Directed | Khi `busy=1` (chu kỳ $1..N-1$), cấp `start=1` với $a', b'$ mới. | Phép nhân hiện tại giữ nguyên toán hạng, độ trễ và kết quả $a \times b$. | $N \in \{4, 8, 16\}$ |
| **MUL_PROT_G8** | G8. Nạp liên tiếp (Back-to-back) | `test_g8_back_to_back` | Directed | Cấp `start=1` ngay chu kỳ kế tiếp sau `done=1` (`busy=0`). | Phép nhân thứ hai nạp thành công, chạy đúng $N$ chu kỳ, kết quả đúng. | $N \in \{4, 8, 16\}$ |

### 2.2. Bảng ma trận các ca giá trị góc (Corner Cases) & Stress

| Mã Test | Mô tả trường hợp góc | Toán hạng ($a, b$) | Phép nhân áp dụng | Tiêu chí PASS |
|---|---|---|---|---|
| **MUL_COR_01** | Số 0 nhân số 0 | $a = 0, b = 0$ | Serial, Booth | $p = 0$. |
| **MUL_COR_02** | Nhân với phần tử đơn vị 1 | $a = 1, b = MAX$; $a = MAX, b = 1$ | Serial, Booth | $p = MAX$. |
| **MUL_COR_03** | Cực đại không dấu (Max Unsigned) | $a = 2^N-1, b = 2^N-1$ | Serial | $p = (2^N-1)^2 = 2^{2N} - 2^{N+1} + 1$. |
| **MUL_BOOTH_01** | **Cực tiểu âm nhân cực tiểu âm** (Critical) | $a = -2^{N-1}, b = -2^{N-1}$ | Booth Radix-2 | $p = +2^{2N-2}$. Kiểm tra không bị tràn bit mở rộng $N+1$. |
| **MUL_BOOTH_02** | Cực tiểu âm nhân cực đại dương | $a = -2^{N-1}, b = 2^{N-1}-1$ | Booth Radix-2 | $p = -2^{N-1}(2^{N-1}-1)$. |
| **MUL_BOOTH_03** | Nhân với -1 | $a = -1, b = -1$; $a = -1, b = MAX$ | Booth Radix-2 | Khớp hoàn toàn với toán học bù 2. |
| **MUL_FILE_01** | Đọc vector ngoại vi `$readmemh` | 100 mẫu góc chọn lọc | Serial, Booth | Khớp hoàn toàn với Golden Model. |
| **MUL_RND_01** | Ứng suất ngẫu nhiên liên tiếp | 1,000 mẫu ngẫu nhiên `$random(seed)` | Serial, Booth | 0 mismatch trên toàn bộ mẫu. |

---

## PHẦN 3: TIÊU CHÍ KẾT THÚC (EXIT CRITERIA)
Một phiên bản DUT được nhóm kết luận là **"HOÀN TOÀN KHÔNG CÓ LỖI (GOLDEN)"** khi và chỉ khi thoả mãn đồng thời:
1. Vượt qua 100% các bài kiểm tra trong Testplan trên **toàn bộ các cấu hình $N$** tương ứng.
2. Số lượng mismatch bằng $0$ (`Total Mismatches = 0`) trong toàn bộ log mô phỏng.
3. Không ghi nhận bất kỳ cảnh báo hoặc sự cố vi phạm giao thức/timeout nào từ Watchdog Monitor.
4. Kết quả có thể tái lập 100% bằng cách chạy lại với đúng giá trị `SEED` đã quy định.
