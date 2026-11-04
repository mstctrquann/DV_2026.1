#!/usr/bin/env python3
"""thuat_toan.py: mô hình mức thuật toán của các bộ cộng và bộ nhân trong đề bài tập tuần 6 (ET4356).

In các bảng ví dụ ở mục 2 của De_BT_Tuan6_Cong_Nhan.md: bit nhớ RCA, bit nhớ nhóm CLA, bit nhớ khối CSLA,
trạng thái thanh ghi từng chu kỳ của bộ nhân cộng-dịch và bộ nhân Booth radix-2. Chạy: python3 thuat_toan.py
Định dạng dòng "T ..." trùng với trace của RTL tham chiếu để đối chiếu từng dòng.
"""


def bits(v, n):
    return format(v & ((1 << n) - 1), f"0{n}b")


def rca(a, b, cin, n):
    """c[0] = cin; c[i+1] = maj(a_i, b_i, c_i); sum_i = a_i ^ b_i ^ c_i."""
    c, s = [cin], 0
    for i in range(n):
        ai, bi = a >> i & 1, b >> i & 1
        s |= (ai ^ bi ^ c[i]) << i
        c.append((ai & bi) | (ai & c[i]) | (bi & c[i]))
    return s, c


def cla(a, b, cin, n):
    """Nhóm 4 bit: G = g3 + p3g2 + p3p2g1 + p3p2p1g0, P = p3p2p1p0, c_nhóm[k+1] = G_k + P_k c_nhóm[k]."""
    cg = [cin]
    for k in range(n // 4):
        x, y = a >> 4 * k & 0xF, b >> 4 * k & 0xF
        g, p = x & y, x ^ y
        gb = [g >> i & 1 for i in range(4)]
        pb = [p >> i & 1 for i in range(4)]
        G = gb[3] | pb[3] & gb[2] | pb[3] & pb[2] & gb[1] | pb[3] & pb[2] & pb[1] & gb[0]
        P = pb[3] & pb[2] & pb[1] & pb[0]
        cg.append(G | P & cg[k])
    s = (a + b + cin) & ((1 << n) - 1)
    return s, cg


def csla(a, b, cin, n):
    """Khối 4 bit: tính sẵn tổng với bit nhớ vào 0 và 1, bit nhớ thật của khối dưới chọn kết quả."""
    cb, s = [cin], 0
    for j in range(n // 4):
        x, y = a >> 4 * j & 0xF, b >> 4 * j & 0xF
        r0, r1 = x + y, x + y + 1
        r = r1 if cb[j] else r0
        s |= (r & 0xF) << 4 * j
        cb.append(r >> 4)
    return s, cb


def mult_serial(a, b, n):
    """hi = 0, lo = b; lặp n lần: s = hi + (lo0 ? m : 0) (n+1 bit); {hi, lo} = {s, lo} >> 1."""
    m, hi, lo, rows = a, 0, b, []
    for cnt in range(n):
        rows.append((cnt, m, hi, lo))
        s = hi + (m if lo & 1 else 0)
        both = (s << (n - 1)) | (lo >> 1)
        hi, lo = both >> n & ((1 << n) - 1), both & ((1 << n) - 1)
    return (hi << n) | lo, rows + [(n, m, hi, lo)]


def mult_booth(a, b, n):
    """A = 0 (n+1 bit), Q = b, q1 = 0, M = a mở rộng dấu; lặp n lần: {Q0,q1} = 01: A += M; 10: A -= M;
    dịch phải số học {A, Q, q1}."""
    w = n + 1
    mask = (1 << w) - 1
    M = (a | ((a >> (n - 1) & 1) << n)) & mask
    A, Q, q1, rows = 0, b, 0, []
    for cnt in range(n):
        rows.append((cnt, M, A, Q, q1))
        pair = (Q & 1, q1)
        if pair == (0, 1):
            A = (A + M) & mask
        elif pair == (1, 0):
            A = (A - M) & mask
        q1 = Q & 1
        Q = (Q >> 1) | ((A & 1) << (n - 1))
        A = (A >> 1) | (A >> (w - 1) << (w - 1))
    return ((A & ((1 << n) - 1)) << n) | Q, rows + [(n, M, A, Q, q1)]


def main():
    s, c = rca(0b10110110, 0b01001011, 1, 8)
    print(f"T rca8  a=10110110 b=01001011 cin=1 c={''.join(map(str, reversed(c)))} sum={bits(s, 8)} cout={c[8]}")
    s, c = cla(0x3A7F, 0x05C1, 0, 16)
    print(f"T cla16 a=3a7f b=05c1 cin=0 cgrp={''.join(map(str, reversed(c)))} sum={s:04x} cout={c[4]}")
    s, c = csla(0x0123456789ABCDEF, 0x0F11, 0, 64)
    print(f"T csla64 a=0123456789abcdef b=0000000000000f11 cin=0 cblk={''.join(map(str, reversed(c)))} sum={s:016x} cout={c[16]}")
    p, rows = mult_serial(0b1011, 0b1101, 4)
    for cnt, m, hi, lo in rows:
        print(f"T serial cnt={cnt} m={bits(m, 4)} hi={bits(hi, 4)} lo={bits(lo, 4)}")
    print(f"T serial p={bits(p, 8)} ({0b1011} x {0b1101} = {p})")
    p, rows = mult_booth(0b0101, 0b1101, 4)
    for cnt, M, A, Q, q1 in rows:
        print(f"T booth  cnt={cnt} M={bits(M, 5)} A={bits(A, 5)} Q={bits(Q, 4)} q1={q1}")
    print(f"T booth  p={bits(p, 8)} (5 x -3 = {p - 256 if p >> 7 else p})")


if __name__ == "__main__":
    main()
