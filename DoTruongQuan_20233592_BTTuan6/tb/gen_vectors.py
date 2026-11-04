#!/usr/bin/env python3
"""
gen_vectors.py: Script sinh test vector cho adder, mult_serial va mult_booth
Luu duoi dang file hex doc bang $readmemh trong Verilog-2001.
"""

import os
import random

def format_hex(val, width_bits):
    mask = (1 << width_bits) - 1
    val &= mask
    width_hex = (width_bits + 3) // 4
    return f"{val:0{width_hex}X}"

def gen_adder_vectors(n_bits, filename, num_random=60):
    vectors = []
    # 1. Corner cases
    # a, b, cin
    corners = [
        (0, 0, 0),
        (0, 0, 1),
        ((1 << n_bits) - 1, 0, 0),
        ((1 << n_bits) - 1, 0, 1),
        (0, (1 << n_bits) - 1, 0),
        (0, (1 << n_bits) - 1, 1),
        ((1 << n_bits) - 1, 1, 0),
        ((1 << n_bits) - 1, (1 << n_bits) - 1, 1),
        (0x5555555555555555 & ((1 << n_bits) - 1), 0xAAAAAAAAAAAAAAAA & ((1 << n_bits) - 1), 0),
        (0x5555555555555555 & ((1 << n_bits) - 1), 0xAAAAAAAAAAAAAAAA & ((1 << n_bits) - 1), 1),
    ]
    for a, b, cin in corners:
        vectors.append((a, b, cin))

    # 2. Block boundary propagation tests (steps of 4 bits)
    for shift in range(0, n_bits, 4):
        a = ((1 << 4) - 1) << shift
        b = 1 << shift
        vectors.append((a & ((1 << n_bits) - 1), b & ((1 << n_bits) - 1), 0))

    # 3. Random vectors
    random.seed(42 + n_bits)
    for _ in range(num_random):
        a = random.randint(0, (1 << n_bits) - 1)
        b = random.randint(0, (1 << n_bits) - 1)
        cin = random.randint(0, 1)
        vectors.append((a, b, cin))

    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "w") as f:
        # Dinh dang moi dong: a b cin
        for a, b, cin in vectors:
            f.write(f"{format_hex(a, n_bits)} {format_hex(b, n_bits)} {cin}\n")
    print(f"Generated {len(vectors)} vectors -> {filename}")

def gen_mult_vectors(n_bits, filename, num_random=80):
    vectors = []
    max_u = (1 << n_bits) - 1
    min_s = 1 << (n_bits - 1) # bu 2 am nho nhat: -2^(N-1)
    max_s = (1 << (n_bits - 1)) - 1
    minus_1 = (1 << n_bits) - 1

    # Corner cases
    corners = [
        (0, 0),
        (1, 1),
        (0, max_u),
        (max_u, 0),
        (max_u, max_u),
        (1, max_u),
        (min_s, min_s),       # -2^(N-1) * -2^(N-1) (critical Booth)
        (min_s, max_s),       # -2^(N-1) * (2^(N-1)-1)
        (min_s, 1),
        (min_s, minus_1),     # -2^(N-1) * -1
        (minus_1, minus_1),   # -1 * -1
        (minus_1, 1),         # -1 * 1
        (max_s, max_s),
    ]
    for a, b in corners:
        vectors.append((a & max_u, b & max_u))

    # Random vectors
    random.seed(100 + n_bits)
    for _ in range(num_random):
        a = random.randint(0, max_u)
        b = random.randint(0, max_u)
        vectors.append((a, b))

    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "w") as f:
        for a, b in vectors:
            f.write(f"{format_hex(a, n_bits)} {format_hex(b, n_bits)}\n")
    print(f"Generated {len(vectors)} vectors -> {filename}")

if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__), "vectors")
    for n in [4, 8, 16, 32, 64]:
        gen_adder_vectors(n, os.path.join(out_dir, f"adder_vec_{n}.hex"))
    for n in [4, 8, 16]:
        gen_mult_vectors(n, os.path.join(out_dir, f"mult_vec_{n}.hex"))
