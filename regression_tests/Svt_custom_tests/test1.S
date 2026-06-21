.section .text
.globl _start
_start:
    # =============================================================
    # 200-INSTRUCTION RISC-V RV32IM CO-SIMULATION TEST
    # =============================================================
    # Design rule: No absolute address values stored in compared
    # registers (JAL/JALR use x0 as link register). All compared
    # register values are pure data, identical in both address spaces.
    # =============================================================
    # ----- Phase 1: Register Setup (12 instructions) -----
    addi x1, x0, 15         # x1  = 15
    addi x2, x0, -7         # x2  = -7 (0xFFFFFFF9)
    addi x3, x0, 25         # x3  = 25
    lui  x4, 0x12345        # x4  = 0x12345000
    addi x4, x4, 0x678      # x4  = 0x12345678
    addi x5, x0, 100        # x5  = 100
    addi x6, x0, -1         # x6  = -1 (0xFFFFFFFF)
    addi x7, x0, 1          # x7  = 1
    addi x8, x0, 31         # x8  = 31
    lui  x9, 0xDEADB        # x9  = 0xDEADB000
    addi x9, x9, -239       # x9  = 0xDEADAF11 (adjusted)
    addi x10, x0, 0         # x10 = 0
    # ----- Phase 2: R-Type ALU (20 instructions) -----
    add  x11, x1, x2        # 15 + (-7) = 8
    add  x12, x3, x5        # 25 + 100 = 125
    sub  x13, x1, x2        # 15 - (-7) = 22
    sub  x14, x5, x3        # 100 - 25 = 75
    and  x15, x4, x1        # 0x12345678 & 15 = 8
    and  x16, x9, x6        # 0xDEADAF11 & 0xFFFFFFFF = 0xDEADAF11
    or   x17, x4, x1        # 0x12345678 | 15 = 0x1234567F
    or   x18, x7, x10       # 1 | 0 = 1
    xor  x19, x1, x2        # 15 ^ -7 = 0xFFFFFFF6
    xor  x20, x6, x6        # -1 ^ -1 = 0
    sll  x21, x7, x1        # 1 << 15 = 0x8000
    sll  x22, x1, x7        # 15 << 1 = 30
    srl  x23, x4, x1        # 0x12345678 >> 15 = 0x2468
    srl  x24, x6, x8        # 0xFFFFFFFF >> 31 = 1
    sra  x25, x2, x7        # -7 >> 1 = -4 (arith)
    sra  x26, x6, x8        # -1 >> 31 = -1
    slt  x27, x2, x1        # -7 < 15 = 1 (signed)
    slt  x28, x1, x2        # 15 < -7 = 0 (signed)
    sltu x29, x2, x1        # (unsigned)-7 < (unsigned)15 = 0
    sltu x30, x1, x2        # (unsigned)15 < (unsigned)-7 = 1
    # ----- Phase 3: I-Type ALU (16 instructions) -----
    addi x11, x1, 100       # 15 + 100 = 115
    addi x12, x2, 7         # -7 + 7 = 0
    andi x13, x4, 0xFF      # 0x12345678 & 0xFF = 0x78
    ori  x14, x10, 0x123    # 0 | 0x123 = 0x123
    xori x15, x6, 0x55      # -1 ^ 0x55 = 0xFFFFFFAA
    slti x16, x1, 20        # 15 < 20 = 1
    slti x17, x1, 10        # 15 < 10 = 0
    sltiu x18, x1, 20       # 15 < 20 = 1 (unsigned)
    sltiu x19, x2, 1        # (unsigned)-7 < 1 = 0
    slli x20, x1, 4         # 15 << 4 = 240
    slli x21, x7, 31        # 1 << 31 = 0x80000000
    srli x22, x4, 12        # 0x12345678 >> 12 = 0x12345
    srli x23, x6, 16        # 0xFFFFFFFF >> 16 = 0xFFFF
    srai x24, x2, 2         # -7 >> 2 = -2 (arith)
    srai x25, x4, 8         # 0x12345678 >> 8 = 0x123456
    addi x26, x0, 42        # x26 = 42
    # ----- Phase 4: LUI / AUIPC tests (4 instructions) -----
    lui  x27, 0xABCDE       # x27 = 0xABCDE000
    lui  x28, 0x00001       # x28 = 0x1000
    lui  x29, 0x7FFFF       # x29 = 0x7FFFF000
    lui  x30, 0x00000       # x30 = 0
    # ----- Phase 5: M-Extension Multiply (20 instructions) -----
    mul    x11, x1, x3      # 15 * 25 = 375
    mul    x12, x2, x3      # -7 * 25 = -175
    mul    x13, x6, x6      # -1 * -1 = 1
    mul    x14, x1, x10     # 15 * 0 = 0
    mul    x15, x7, x5      # 1 * 100 = 100
    mulh   x16, x2, x4      # upper32 of signed(-7 * 0x12345678)
    mulh   x17, x1, x3      # upper32 of signed(15 * 25) = 0
    mulh   x18, x6, x6      # upper32 of signed(-1 * -1) = 0
    mulhu  x19, x2, x4      # upper32 of unsigned
    mulhu  x20, x1, x3      # upper32 of unsigned(15 * 25) = 0
    mulhsu x21, x2, x4      # upper32 of signed*unsigned (-7 * 0x12345678)
    mulhsu x22, x1, x3      # upper32 of signed*unsigned (15 * 25) = 0
    mul    x23, x8, x8      # 31 * 31 = 961
    mul    x24, x5, x3      # 100 * 25 = 2500
    mul    x25, x3, x2      # 25 * -7 = -175
    mul    x26, x1, x1      # 15 * 15 = 225
    mul    x27, x2, x2      # -7 * -7 = 49
    mul    x28, x4, x7      # 0x12345678 * 1 = 0x12345678
    mul    x29, x6, x7      # -1 * 1 = -1
    mul    x30, x7, x6      # 1 * -1 = -1
    # ----- Phase 6: M-Extension Divide (20 instructions) -----
    div    x11, x3, x1      # 25 / 15 = 1
    div    x12, x5, x3      # 100 / 25 = 4
    div    x13, x1, x2      # 15 / -7 = -2
    div    x14, x2, x1      # -7 / 15 = 0
    div    x15, x6, x7      # -1 / 1 = -1
    divu   x16, x3, x1      # 25 / 15 = 1 (unsigned)
    divu   x17, x5, x7      # 100 / 1 = 100
    divu   x18, x4, x1      # 0x12345678 / 15 = 0x01369D50
    rem    x19, x3, x1      # 25 % 15 = 10
    rem    x20, x5, x3      # 100 % 25 = 0
    rem    x21, x1, x2      # 15 % -7 = 1
    remu   x22, x3, x1      # 25 % 15 = 10 (unsigned)
    remu   x23, x5, x3      # 100 % 25 = 0
    div    x24, x1, x10     # 15 / 0 = -1 (div by zero spec)
    divu   x25, x1, x10     # 15 / 0 = 0xFFFFFFFF (unsigned div by zero)
    rem    x26, x1, x10     # 15 % 0 = 15 (rem by zero spec)
    remu   x27, x1, x10     # 15 % 0 = 15 (unsigned rem by zero)
    div    x28, x6, x6      # -1 / -1 = 1
    rem    x29, x6, x6      # -1 % -1 = 0
    divu   x30, x6, x6      # 0xFFFFFFFF / 0xFFFFFFFF = 1
    # ----- Phase 7: Branches - all types (24 instructions) -----
    # BEQ taken
    beq  x1, x1, beq_taken
    addi x31, x0, 99
beq_taken:
    # BEQ not taken
    beq  x1, x2, beq_skip
    addi x11, x0, 1         # executed
beq_skip:
    # BNE taken
    bne  x1, x2, bne_taken
    addi x31, x0, 99
bne_taken:
    # BNE not taken
    bne  x1, x1, bne_skip
    addi x12, x0, 2         # executed
bne_skip:
    # BLT taken (signed: -7 < 15)
    blt  x2, x1, blt_taken
    addi x31, x0, 99
blt_taken:
    # BLT not taken
    blt  x1, x2, blt_skip
    addi x13, x0, 3         # executed
blt_skip:
    # BGE taken (signed: 15 >= -7)
    bge  x1, x2, bge_taken
    addi x31, x0, 99
bge_taken:
    # BGE not taken (signed: -7 >= 15 is false)
    bge  x2, x1, bge_skip
    addi x14, x0, 4         # executed
bge_skip:
    # BLTU taken (unsigned: 15 < 0xFFFFFFF9)
    bltu x1, x2, bltu_taken
    addi x31, x0, 99
bltu_taken:
    # BLTU not taken (unsigned: 0xFFFFFFF9 < 15 is false)
    bltu x2, x1, bltu_skip
    addi x15, x0, 5         # executed
bltu_skip:
    # BGEU taken (unsigned: 0xFFFFFFF9 >= 15)
    bgeu x2, x1, bgeu_taken
    addi x31, x0, 99
bgeu_taken:
    # BGEU not taken (unsigned: 15 >= 0xFFFFFFF9 is false)
    bgeu x1, x2, bgeu_skip
    addi x16, x0, 6         # executed
bgeu_skip:
    # ----- Phase 8: Jumps (4 instructions) -----
    jal  x0, jump1
    addi x31, x0, 99
jump1:
    jal  x0, jump2
    addi x31, x0, 99
jump2:
    # ----- Phase 9: More ALU to reach 200 (fill up) -----
    # Reload base values
    addi x1, x0, 15
    addi x2, x0, -7
    addi x3, x0, 25
    addi x5, x0, 100
    # Chain of dependent operations (tests forwarding)
    add  x17, x1, x2        # 15 + -7 = 8
    add  x18, x17, x3       # 8 + 25 = 33
    add  x19, x18, x5       # 33 + 100 = 133
    sub  x20, x19, x18      # 133 - 33 = 100
    xor  x21, x20, x17      # 100 ^ 8 = 108
    or   x22, x21, x1       # 108 | 15 = 111
    and  x23, x22, x6       # 111 & -1 = 111
    sll  x24, x23, x7       # 111 << 1 = 222
    srl  x25, x24, x7       # 222 >> 1 = 111
    sra  x26, x25, x7       # 111 >> 1 = 55
    add  x27, x26, x26      # 55 + 55 = 110
    sub  x28, x27, x1       # 110 - 15 = 95
    xor  x29, x28, x3       # 95 ^ 25 = 70
    or   x30, x29, x7       # 70 | 1 = 71
    and  x31, x30, x5       # 71 & 100 = 68
    # More I-type variations
    addi x11, x31, 10       # 68 + 10 = 78
    addi x12, x11, -50      # 78 - 50 = 28
    andi x13, x12, 0x1F     # 28 & 31 = 28
    ori  x14, x13, 0x100    # 28 | 256 = 284
    xori x15, x14, 0xFF     # 284 ^ 255 = 35
    slti x16, x15, 100      # 35 < 100 = 1
    sltiu x17, x15, 100     # 35 < 100 = 1 (unsigned)
    slli x18, x15, 2        # 35 << 2 = 140
    srli x19, x18, 1        # 140 >> 1 = 70
    srai x20, x19, 1        # 70 >> 1 = 35
    # LUI followed by arithmetic
    lui  x21, 0x00010       # x21 = 0x10000
    addi x21, x21, -1       # x21 = 0xFFFF
    lui  x22, 0xFFFFF       # x22 = 0xFFFFF000
    addi x22, x22, -1       # x22 = 0xFFFFEFFF
    # More multiply
    mul  x23, x11, x12      # 78 * 28 = 2184
    mul  x24, x13, x14      # 28 * 284 = 7952
    mul  x25, x15, x16      # 35 * 1 = 35
    # More divide
    div  x26, x24, x23      # 7952 / 2184 = 3
    rem  x27, x24, x23      # 7952 % 2184 = 1400
    # Final chain
    add  x28, x26, x27      # 3 + 1400 = 1403
    sub  x29, x28, x25      # 1403 - 35 = 1368
    xor  x30, x29, x20      # 1368 ^ 35 = 1371
    or   x31, x30, x7       # 1371 | 1 = 1371
    # More branches to increase count
    beq  x10, x10, br1
    addi x31, x0, 99
br1:
    bne  x7, x10, br2
    addi x31, x0, 99
br2:
    blt  x2, x7, br3
    addi x31, x0, 99
br3:
    bge  x7, x2, br4
    addi x31, x0, 99
br4:
    bltu x7, x6, br5
    addi x31, x0, 99
br5:
    bgeu x6, x7, br6
    addi x31, x0, 99
br6:
    # Final arithmetic padding
    add  x11, x1, x3        # 15 + 25 = 40
    sub  x12, x5, x1        # 100 - 15 = 85
    and  x13, x11, x12      # 40 & 85 = 0
    or   x14, x11, x12      # 40 | 85 = 125
    xor  x15, x11, x12      # 40 ^ 85 = 125
    sll  x16, x7, x11       # 1 << (40 & 0x1F) = 1 << 8 = 256
    srl  x17, x4, x11       # 0x12345678 >> (40 & 0x1F) = 0x12345678 >> 8 = 0x123456
    sra  x18, x2, x7        # -7 >> 1 = -4
    slt  x19, x11, x12      # 40 < 85 = 1
    sltu x20, x11, x12      # 40 < 85 = 1 (unsigned)
    add  x21, x14, x15      # 125 + 125 = 250
    sub  x22, x21, x16      # 250 - 256 = -6
    mul  x23, x11, x7       # 40 * 1 = 40
    div  x24, x12, x11      # 85 / 40 = 2
    rem  x25, x12, x11      # 85 % 40 = 5
    add  x26, x24, x25      # 2 + 5 = 7
    mul  x27, x26, x3       # 7 * 25 = 175
    sub  x28, x27, x5       # 175 - 100 = 75
    xor  x29, x28, x1       # 75 ^ 15 = 68
    or   x30, x29, x3       # 68 | 25 = 93
    and  x31, x30, x6       # 93 & -1 = 93