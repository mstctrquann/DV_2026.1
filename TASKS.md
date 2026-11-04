# TASKS: CHECKLIST TRIỂN KHAI BÀI TẬP TUẦN 6 (ET4356)

- [x] **Giai đoạn 1: Chuẩn bị & Phân tích đặc tả**
  - [x] Đọc `De_BT_Tuan6_Cong_Nhan.md`, `thuat_toan.py`, `tb_skeleton/`.
  - [x] Tạo thư mục bài nộp `DoTruongQuan_20233592_BTTuan6/`.
  - [x] Trích xuất đặc tả vào `SPEC_DIGEST.md`.
  - [x] Rà soát rủi ro, edge cases vào `SPEC_FEEDBACK.md`.
  - [x] Chốt kế hoạch kiến trúc kỹ thuật vào `ARCH_PLAN.md`.

- [ ] **Giai đoạn 2: Lập Kế hoạch kiểm chứng (Nhiệm vụ 1)**
  - [ ] Tạo file `DoTruongQuan_20233592_BTTuan6/testplan.md` đầy đủ ma trận test cho `adder` (RCA, CLA, CSLA) và bộ nhân tuần tự (`mult_serial`, `mult_booth`).
  - [ ] Thiết lập bảng quy tắc G1 - G8, các giá trị góc, và tiêu chí kết thúc (exit criteria).

- [ ] **Giai đoạn 3: Sinh Vector kiểm thử ngoại vi ($readmemh)**
  - [ ] Viết script `DoTruongQuan_20233592_BTTuan6/tb/gen_vectors.py`.
  - [ ] Tạo file vectors hex: `adder_vec_4.hex`, `adder_vec_8.hex`, `adder_vec_16.hex`, `adder_vec_32.hex`, `adder_vec_64.hex`.
  - [ ] Tạo file vectors hex: `mult_vec_4.hex`, `mult_vec_8.hex`, `mult_vec_16.hex`.

- [ ] **Giai đoạn 4: Xây dựng Testbench Verilog-2001 (Nhiệm vụ 2)**
  - [ ] Xây dựng `DoTruongQuan_20233592_BTTuan6/tb/tb_adder_top.v` hỗ trợ mọi $N \in \{4, 8, 16, 32, 64\}$.
  - [ ] Xây dựng `DoTruongQuan_20233592_BTTuan6/tb/tb_mult_top.v` hỗ trợ mọi $N \in \{4, 8, 16\}$ cho cả `mult_serial` và `mult_booth`.
  - [ ] Cập nhật/viết `DoTruongQuan_20233592_BTTuan6/tb/Makefile`.
  - [ ] Chạy `make lint` kiểm tra chuẩn cú pháp Verilog-2001 (Icarus Verilog `-g2001`).

- [ ] **Giai đoạn 5: Thực thi mô phỏng và Xác định lỗi (Nhiệm vụ 3)**
  - [ ] Mô phỏng 4 phiên bản của `adder` (`v1` đến `v4`) qua các cấu hình $N$.
  - [ ] Mô phỏng 4 phiên bản của `mult_serial` (`v1` đến `v4`) qua các cấu hình $N$.
  - [ ] Mô phỏng 4 phiên bản của `mult_booth` (`v1` đến `v4`) qua các cấu hình $N$.
  - [ ] Ghi lại toàn bộ log chạy vào `DoTruongQuan_20233592_BTTuan6/log/`.
  - [ ] Lập bảng kết luận phiên bản không lỗi (Bảng a) và Bảng danh mục lỗi & khoanh vùng vi kiến trúc (Bảng b).
