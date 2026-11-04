# HƯỚNG DẪN THỰC THI MÔ PHỎNG & NỘP BÀI TẬP TUẦN 6 (ET4356)

**Sinh viên:** Đỗ Trường Quân — MSSV: 20233592  
**Thư mục làm bài:** `DoTruongQuan_20233592_BTTuan6/`

---

## 1. CẤU TRÚC GÓI BÀI LÀM
- `testplan.md`: Kế hoạch kiểm chứng chi tiết (Nhiệm vụ 1) bao gồm ma trận tính năng, các trường hợp góc, kiểm chứng quy tắc G1 - G8, phân tích tính khả thi exhaustive, và tiêu chí kết thúc.
- `tb/`:
  - `tb_adder_top.v`: Testbench chuẩn Verilog-2001 cho bộ cộng (`N = 4, 8, 16, 32, 64`), kiểm tra exhaustive ($N=4, 8$), directed ripple carry chain, CLA/CSLA 4-bit boundary transitions, và random stress.
  - `tb_mult_top.v`: Testbench chuẩn Verilog-2001 cho `mult_serial` và `mult_booth` (`N = 4, 8, 16`), kiểm tra giao thức bắt tay G1–G8, các ca cực trị bù 2 (đặc biệt $-2^{N-1} \times -2^{N-1}$), khử race condition với timing offset (`negedge clk`), và Watchdog timer chống treo.
  - `gen_vectors.py`: Script Python sinh vector ngoại vi định dạng hex cho `$readmemh`.
  - `vectors/`: Danh mục các file `.hex` cho adder và multiplier.
  - `Makefile`: Script tự động hóa biên dịch, linting và chạy mô phỏng.
- `log/`: Thư mục chứa các tệp nhật ký mô phỏng khi chạy trên QuestaSim.

---

## 2. CÁCH THỨC CHẠY TRÊN HỆ THỐNG MÁY CHỦ / PHÒNG THÍ NGHIỆM

Do các tệp DUT trong thư mục `dut/` được bảo mật và mã hoá theo chuẩn **IEEE 1735 (`.vp`)**, việc mô phỏng bắt buộc thực hiện trên môi trường có trình mô phỏng **QuestaSim / ModelSim** (lệnh `vlog` và `vsim`).

### Bước 1: Kiểm tra Linting chuẩn Verilog-2001 (Icarus Verilog)
Chạy trong thư mục `DoTruongQuan_20233592_BTTuan6/tb/`:
```bash
make lint
```

### Bước 2: Chạy kiểm chứng từng cấu hình cụ thể
- **Bộ cộng (Adder):**
  ```bash
  make add NBIT=16 V=2
  # Chạy adder phiên bản v2 với N = 16 bit, kết quả log lưu tại ../log/add16_v2.log
  ```
- **Bộ nhân (Multipliers):**
  ```bash
  make mul NBIT=8 V=3 SEED=42
  # Chạy mult_serial_v3 và mult_booth_v3 với N = 8 bit, kết quả log lưu tại ../log/mul8_v3.log
  ```

### Bước 3: Chạy toàn bộ (Make All) để phát hiện và khoanh vùng lỗi
```bash
make all
```
Lệnh này sẽ tự động chạy toàn bộ ma trận:
- 4 phiên bản $\times$ 5 cấu hình $N$ của `adder` ($N \in \{4, 8, 16, 32, 64\}$)
- 4 phiên bản $\times$ 3 cấu hình $N$ của bộ nhân ($N \in \{4, 8, 16\}$)
Toàn bộ log kết quả sẽ được ghi vào thư mục `log/`.

---

## 3. CÁC LỖI DỰ KIẾN KHOANH VÙNG TRONG DUTs

Dựa trên vi kiến trúc và phản biện [SPEC_FEEDBACK.md](../SPEC_FEEDBACK.md):
1. **Đối với `adder`:**
   - Phiên bản có 1 lỗi: Thường gặp lỗi sai tại bộ chọn MUX CSLA 64-bit hoặc sai bit cờ nhớ `cout` ở RCA/CLA.
   - Phiên bản có 2-3 lỗi: Thường xuất hiện sai lệch trong hàm sinh nhớ $g_i = a_i \cdot b_i$ hoặc lan truyền $p_i = a_i \oplus b_i$ tại ranh giới các block 4-bit.
2. **Đối với bộ nhân:**
   - **`mult_serial`:** Lỗi thường ở điều kiện rẽ nhánh LO[0] hoặc việc dịch bit nhớ từ phép cộng $s$ vào HI.
   - **`mult_booth`:** Lỗi phổ biến nhất là tràn số khi nhân hai số âm cực tiểu $(-2^{N-1}) \times (-2^{N-1})$ do thanh ghi $M$ không đủ $N+1$ bit; hoặc lỗi FSM không nhận diện đúng quy tắc G7 (bị ghi đè toán hạng khi `busy = 1`).
