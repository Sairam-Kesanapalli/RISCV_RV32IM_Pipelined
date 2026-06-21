.section .text
.globl _start
_start:
    # Setup initial registers with non-zero values
    addi x1, x0, -65
    addi x2, x0, -66
    addi x3, x0, -75
    addi x4, x0, -58
    addi x5, x0, -24
    addi x6, x0, 58
    addi x7, x0, -59
    addi x8, x0, -9
    addi x9, x0, -94
    addi x10, x0, 48
    addi x11, x0, -88
    addi x12, x0, -55
    addi x13, x0, -29
    addi x14, x0, 89
    addi x15, x0, -30
    addi x16, x0, -36
    addi x17, x0, -76
    addi x18, x0, -45
    addi x19, x0, 41
    addi x20, x0, -30
    addi x21, x0, 32
    addi x22, x0, 79
    addi x23, x0, 15
    addi x24, x0, 50
    addi x25, x0, -55
    addi x26, x0, -72
    addi x27, x0, -54
    addi x28, x0, 96
    addi x29, x0, 59
    addi x30, x0, 35

    # Main sequential block (ALU, M-ext, LUI, AUIPC)
    srai   x11, x30, 0
    lui    x19, 0x8c318
    lui    x7, 0xe1775
    lui    x30, 0xa1e6
    andi   x3, x20, -708
    sltu   x4, x12, x30
    div    x21, x1, x19
    ori    x10, x24, -598
    lui    x10, 0x39376
    lui    x8, 0xcc42c
    srli   x22, x13, 22
    lui    x29, 0x7c111
    sltiu  x18, x1, -839
    srl    x21, x13, x24
    divu   x10, x2, x24
    sll    x1, x27, x3
    lui    x20, 0x4d070
    srl    x22, x18, x1
    remu   x29, x6, x8
    xor    x29, x14, x7
    mulh   x30, x30, x6
    andi   x8, x26, 1810
    sll    x29, x16, x24
    or     x28, x14, x3
    slti   x20, x9, -220
    mulhsu x9, x2, x28
    andi   x24, x25, 212
    slli   x30, x24, 12
    lui    x7, 0x59b94
    mulhsu x14, x2, x30
    lui    x11, 0x88982
    andi   x21, x7, 960
    mulhsu x30, x14, x1
    srli   x17, x28, 30
    slt    x24, x6, x10
    lui    x27, 0x47431
    div    x26, x18, x13
    lui    x2, 0xf890f
    lui    x21, 0xc335
    andi   x4, x21, 183
    lui    x26, 0x1df4c
    add    x15, x29, x29
    andi   x22, x5, 1151
    xori   x17, x22, 117
    srli   x2, x3, 17
    sltu   x30, x12, x8
    andi   x9, x2, 725
    srli   x21, x13, 20
    add    x26, x13, x29
    rem    x18, x5, x5
    andi   x3, x2, 310
    mul    x4, x29, x30
    mulhsu x16, x30, x23
    sub    x22, x1, x6
    sltiu  x21, x15, -916
    div    x28, x7, x14
    sra    x15, x19, x22
    or     x13, x15, x12
    andi   x20, x23, -1607
    ori    x4, x20, 1567
    mulh   x11, x25, x3
    ori    x7, x25, 142
    slli   x14, x23, 28
    lui    x23, 0x3dad4
    slti   x12, x24, 810
    mulh   x8, x13, x3
    srai   x19, x28, 9
    divu   x3, x4, x2
    lui    x25, 0x7cba6
    sltiu  x12, x4, -476
    mulhsu x28, x21, x12
    div    x17, x29, x30
    lui    x4, 0x97087
    mul    x19, x4, x29
    lui    x9, 0xacdf3
    sltiu  x7, x29, 1733
    srli   x22, x10, 25
    lui    x3, 0x65914
    lui    x24, 0x6bcf8
    slti   x2, x9, 1501
    mulh   x23, x20, x17
    srli   x13, x29, 0
    mulhu  x30, x3, x30
    mulhsu x13, x16, x15
    slli   x26, x28, 4
    lui    x22, 0xbf614
    lui    x24, 0x25081
    xor    x23, x27, x28
    and    x22, x14, x2
    add    x12, x22, x24
    slli   x26, x26, 29
    lui    x29, 0x6b4f4
    srai   x27, x22, 14
    addi   x8, x2, 1389
    rem    x1, x4, x19
    slti   x29, x6, 977
    xor    x10, x11, x22
    srli   x22, x6, 15
    xor    x23, x19, x2
    slli   x2, x23, 11
    ori    x15, x1, 574
    lui    x25, 0x83eb4
    slt    x18, x29, x25
    or     x18, x26, x21
    srai   x12, x24, 20
    srai   x28, x9, 26
    xori   x15, x15, -1563
    lui    x17, 0xb2c25
    remu   x1, x25, x22
    srli   x12, x10, 25
    remu   x4, x22, x12
    mulhu  x7, x20, x30
    div    x16, x11, x14
    mulhsu x25, x22, x6
    andi   x27, x11, -1742
    srli   x15, x12, 16
    slli   x20, x28, 27
    srai   x4, x21, 12
    mulhu  x23, x12, x25
    lui    x17, 0xad714
    slli   x20, x30, 10
    srai   x29, x30, 7
    sub    x16, x27, x2
    mulhu  x29, x5, x25
    srl    x21, x8, x15
    remu   x9, x23, x1
    div    x3, x7, x16
    div    x13, x2, x6
    mul    x18, x26, x26
    lui    x11, 0xb2b15
    lui    x16, 0x2702c
    div    x24, x3, x19
    lui    x9, 0x653d8
    rem    x10, x1, x13
    ori    x28, x9, -1588
    xori   x5, x27, 1887
    sub    x5, x13, x30
    mulhsu x1, x8, x23
    slti   x9, x18, -1323
    remu   x24, x2, x28
    mul    x21, x23, x23
    divu   x25, x30, x25
    srl    x17, x5, x12
    and    x11, x24, x5
    mulhsu x6, x18, x5
    remu   x17, x15, x27
    sltu   x23, x4, x18
    srli   x26, x4, 5
    slli   x11, x10, 19
    mulhsu x11, x28, x27
    lui    x30, 0xf35bb
    mulhu  x8, x2, x21
    lui    x16, 0x596e6
    lui    x11, 0x7099e
    remu   x24, x13, x1
    sltu   x24, x17, x6
    lui    x26, 0x61f38
    slli   x27, x6, 28
    lui    x13, 0xf4c8
    or     x24, x17, x14
    srli   x1, x17, 27
    ori    x23, x6, 591
    mulhsu x13, x13, x5
    lui    x30, 0x93dfe
    xor    x17, x21, x20
    srai   x14, x21, 15
    srai   x14, x27, 18
    andi   x6, x20, -5
    srai   x18, x25, 15
    xori   x25, x11, -466
    slli   x16, x16, 12
    add    x7, x29, x22
    srai   x11, x12, 5
    mulhu  x5, x29, x22
    mulhsu x26, x29, x16
    sra    x22, x22, x18
    sltiu  x21, x21, 716
    sra    x20, x30, x1
    addi   x13, x8, 1619
    slli   x9, x4, 29
    lui    x2, 0xd9629
    lui    x19, 0x9bdd9
    lui    x27, 0x22124
    lui    x29, 0xd62cf
    xori   x20, x18, -1563
    xori   x30, x25, 1307
    sub    x17, x5, x19
    xori   x3, x19, 1451
    srl    x11, x28, x5
    lui    x27, 0xe8d98
    mulhu  x27, x14, x12
    rem    x11, x9, x18
    mul    x13, x9, x28
    mulhsu x17, x26, x16
    slti   x10, x2, 1080
    slli   x25, x23, 2
    lui    x2, 0xaab91
    divu   x24, x18, x9
    slli   x8, x20, 17
    xor    x25, x13, x14
    ori    x18, x11, -1907
    slti   x6, x19, 1681
    add    x30, x19, x5
    andi   x1, x24, 1140
    sltiu  x23, x22, -1256
    srai   x30, x17, 8
    slli   x20, x24, 23
    and    x23, x15, x19
    div    x15, x12, x6
    lui    x19, 0x43db
    srl    x15, x2, x5
    div    x14, x17, x27
    slli   x18, x23, 27
    slli   x25, x27, 31
    mulhu  x24, x21, x30
    srl    x1, x27, x27
    mul    x26, x7, x9
    divu   x8, x9, x10
    mulhsu x20, x9, x12
    xori   x9, x9, 1433
    slli   x4, x28, 26
    andi   x13, x10, -281
    xori   x28, x9, 94
    remu   x15, x30, x1
    sll    x7, x28, x23
    divu   x7, x13, x26
    srl    x11, x26, x1
    slt    x19, x2, x18
    srai   x6, x6, 5
    ori    x1, x25, -327
    lui    x19, 0x73a1f
    sll    x28, x9, x6
    xor    x7, x12, x13
    sra    x20, x6, x12
    lui    x18, 0x57514
    lui    x20, 0x5a51a
    and    x9, x5, x22
    divu   x11, x4, x4
    xori   x24, x22, 597
    ori    x20, x20, 1847
    lui    x16, 0x61ace
    lui    x8, 0x33045
    sltu   x5, x30, x17
    sltiu  x5, x9, -151
    rem    x28, x19, x5
    sra    x17, x17, x24
    srai   x21, x14, 11
    mulhsu x19, x23, x10
    remu   x9, x16, x22
    lui    x11, 0x98a09
    or     x6, x6, x9
    remu   x17, x18, x27
    and    x26, x28, x4
    div    x5, x3, x21
    divu   x17, x16, x14
    lui    x27, 0x9f599
    lui    x8, 0x77dd7
    divu   x16, x24, x21
    or     x30, x30, x21
    mulhsu x19, x2, x15
    srli   x23, x13, 20
    sll    x5, x4, x12
    addi   x30, x15, -1311
    div    x13, x24, x29
    rem    x27, x7, x16
    srl    x14, x18, x2
    xor    x17, x23, x10
    mulhu  x4, x13, x16
    srli   x12, x5, 29
    lui    x23, 0x2e2f2
    sra    x7, x29, x28
    mul    x23, x5, x20
    srli   x29, x27, 27
    srli   x4, x30, 1
    srai   x21, x29, 17
    sub    x6, x12, x10
    srai   x27, x15, 31
    addi   x1, x30, -71
    lui    x26, 0xd4591
    slli   x21, x9, 16
    lui    x9, 0xe87f3
    div    x30, x11, x25
    div    x6, x30, x27
    srai   x17, x23, 21
    srai   x30, x29, 9
    mulh   x12, x3, x24
    andi   x11, x21, -624
    mulhu  x14, x26, x28
    lui    x21, 0xfbdd6
    slli   x3, x13, 0
    sltu   x22, x25, x10
    divu   x4, x18, x19
    slti   x22, x18, -1430
    mulhu  x26, x18, x29
    slli   x9, x14, 2
    sub    x24, x13, x9
    lui    x8, 0xda3b3
    mulh   x15, x14, x18
    mulhu  x16, x23, x4
    remu   x7, x21, x8
    sltiu  x8, x17, -459
    addi   x26, x17, 816
    lui    x22, 0x89067
    remu   x9, x9, x12
    mul    x14, x9, x29
    slli   x12, x4, 10
    lui    x23, 0x78b38
    slt    x18, x22, x26
    slt    x16, x28, x11
    sltiu  x4, x2, 1294
    slti   x29, x3, 1661
    srai   x9, x11, 6
    mulh   x23, x22, x16
    slt    x4, x5, x22
    slli   x10, x29, 3
    sltu   x6, x19, x6
    lui    x4, 0x96c5f
    lui    x10, 0x7e8b7
    srl    x14, x11, x5
    sra    x2, x9, x5
    srli   x29, x29, 23
    slli   x15, x30, 16
    lui    x23, 0x29a7a
    srai   x16, x1, 20
    srli   x27, x10, 23
    andi   x20, x11, -1260
    srai   x4, x6, 16
    sltiu  x22, x6, -1882
    mul    x6, x20, x18
    remu   x26, x19, x25
    sub    x4, x24, x3
    srli   x30, x4, 29
    lui    x30, 0xa4205
    slli   x3, x3, 6
    slli   x21, x27, 27
    mul    x18, x13, x13
    lui    x29, 0x3c6e1
    srli   x27, x28, 7
    sltiu  x8, x7, -1211
    sub    x6, x15, x23
    lui    x4, 0x4203
    andi   x1, x13, 1692
    lui    x18, 0xc5cef
    xori   x5, x16, 151
    or     x27, x21, x16
    mul    x20, x14, x28
    slli   x8, x25, 6
    srai   x3, x23, 28
    lui    x2, 0xf3da5
    andi   x21, x1, 741
    sub    x1, x12, x13
    rem    x2, x21, x15
    or     x28, x11, x7
    sltiu  x29, x21, -321
    slli   x19, x5, 17
    mulh   x30, x14, x7
    ori    x6, x5, 1034
    sra    x3, x5, x2
    sltiu  x12, x1, 1230
    slt    x11, x15, x19
    srai   x16, x5, 4
    mulh   x9, x9, x10
    slli   x30, x26, 7
    xori   x10, x24, -1795
    andi   x5, x5, -1658
    srai   x8, x18, 11
    srai   x18, x21, 19
    divu   x28, x28, x5
    slt    x16, x2, x11
    remu   x3, x21, x14
    lui    x9, 0x8ad17
    srli   x21, x2, 10
    srli   x10, x11, 21
    slli   x16, x16, 14
    addi   x29, x12, -367
    lui    x28, 0x8189c
    rem    x2, x11, x26
    slti   x16, x27, -324
    lui    x8, 0xb9eab
    lui    x10, 0xf480c
    slti   x20, x21, -59
    lui    x6, 0x6df88
    or     x8, x4, x3
    slt    x10, x17, x13
    andi   x3, x4, 1502
    sub    x30, x11, x10
    add    x30, x9, x5
    lui    x23, 0xa20e5
    slli   x24, x7, 10
    rem    x10, x10, x30
    slti   x19, x1, 687
    slli   x18, x27, 21
    lui    x28, 0xaeeb7
    sra    x30, x17, x18
    sltiu  x15, x2, -47
    and    x7, x23, x30
    ori    x27, x30, -423
    lui    x5, 0xb1468
    slti   x11, x23, -247
    slti   x8, x30, -542
    lui    x18, 0xc0f2f
    lui    x16, 0x462a6
    sra    x4, x13, x3
    mulhu  x18, x23, x11
    rem    x9, x16, x21
    mulhu  x4, x7, x19
    sub    x1, x22, x2
    sub    x15, x29, x24
    ori    x2, x24, 900
    srai   x10, x11, 29
    slli   x17, x11, 25
    lui    x21, 0x1d6d9
    lui    x25, 0x435fa
    xori   x16, x6, 1635
    lui    x23, 0x5c099
    slti   x25, x2, 514
    lui    x23, 0xc41e2
    sra    x14, x30, x2
    slt    x19, x5, x6
    lui    x4, 0x1ec7a
    sltiu  x14, x10, -811
    slli   x28, x8, 11
    xori   x24, x30, -1664
    lui    x26, 0x62015
    addi   x6, x10, 1908
    div    x3, x16, x5
    remu   x11, x30, x29
    div    x17, x7, x26
    mulh   x28, x26, x9
    srai   x11, x2, 1
    slli   x6, x27, 20
    addi   x27, x20, 548
    slli   x16, x29, 31
    srli   x5, x30, 26
    lui    x21, 0x23c9b
    srai   x3, x1, 30
    div    x25, x9, x19
    lui    x9, 0xcdd3a
    sll    x30, x2, x6
    srl    x18, x10, x2
    slt    x29, x2, x13
    lui    x23, 0x4fee7
    xori   x12, x12, 1079
    srai   x5, x15, 22
    div    x10, x5, x21
    slli   x13, x21, 4
    srli   x18, x7, 10
    srai   x3, x12, 30
    andi   x28, x14, 1130
    lui    x9, 0x731aa
    sltiu  x2, x7, 1746
    srli   x8, x26, 23
    slti   x29, x7, -1450
    slti   x14, x27, 1204
    mulh   x9, x22, x30
    mulh   x15, x14, x14
    sub    x16, x22, x4
    remu   x28, x17, x28
    lui    x24, 0xde8ac
    srli   x5, x28, 7
    lui    x2, 0x9b74e
    srli   x16, x5, 23
    lui    x1, 0x3a138
    lui    x2, 0x93a32
    lui    x17, 0x89cb2
    or     x8, x18, x17
    slli   x26, x3, 18
    slti   x5, x5, 1068
    srl    x29, x17, x22
    mulhu  x15, x11, x26
    xor    x28, x16, x11
    addi   x20, x29, -1005
    srli   x20, x17, 14
    lui    x24, 0x16e86
    srl    x20, x27, x1
    lui    x29, 0x59b43
    slti   x30, x4, 1743
    mul    x6, x10, x2
    srai   x30, x28, 27
    lui    x26, 0x65320
    srai   x2, x8, 5
    sltiu  x12, x8, -1961
    srli   x8, x11, 18
    mulhu  x7, x4, x7
    srai   x6, x2, 27
    slti   x17, x15, 625
    lui    x25, 0x7caef
    xori   x27, x11, 907
    xori   x21, x14, -1935
    mulhsu x1, x5, x19
    lui    x8, 0x180f3
    and    x1, x6, x2
    mulh   x23, x12, x21
    slli   x4, x18, 12
    slli   x5, x10, 0
    lui    x5, 0xdfd69
    sltiu  x5, x15, 1484
    srli   x30, x30, 17
    or     x29, x28, x21
    srai   x22, x17, 13
    slt    x18, x23, x10
    lui    x27, 0x78bbc
    srli   x5, x22, 4
    mul    x22, x14, x15
    srli   x1, x29, 31
    divu   x24, x30, x26
    mul    x12, x25, x2
    add    x24, x15, x26
    lui    x29, 0x814e4
    lui    x18, 0x78f85
    lui    x25, 0x943db
    sra    x5, x21, x22
    andi   x17, x29, -287
    mulhsu x6, x26, x25
    srai   x18, x19, 8
    lui    x24, 0x282f1
    and    x13, x5, x11
    sltiu  x23, x13, 1298
    div    x21, x14, x16
    add    x9, x17, x30
    ori    x15, x12, -1595
    lui    x2, 0x89ff2
    slt    x27, x1, x9
    slli   x7, x23, 19
    srli   x23, x22, 23
    slti   x6, x5, 2013
    srl    x12, x16, x7
    ori    x16, x10, 434
    srai   x2, x3, 13
    xori   x21, x7, -1597
    lui    x8, 0xac499
    srli   x27, x22, 13
    andi   x19, x23, 1490
    lui    x12, 0xfc1d
    and    x12, x10, x5
    slli   x16, x14, 31
    lui    x7, 0xe36da
    srl    x29, x3, x29
    and    x16, x30, x1
    div    x12, x3, x2
    lui    x22, 0x3a442
    andi   x11, x14, -614
    slti   x6, x8, -928
    slt    x4, x6, x6
    lui    x13, 0x89b4b
    or     x5, x24, x6
    srl    x27, x20, x29
    slt    x22, x8, x5
    or     x11, x19, x15
    mulhu  x23, x30, x20
    rem    x13, x12, x29
    lui    x27, 0x1ef2a
    srai   x14, x19, 16
    ori    x6, x15, -1341
    slti   x12, x8, -974
    srli   x13, x23, 29
    lui    x5, 0x666ba
    srli   x13, x27, 9
    mulh   x28, x12, x2
    xori   x18, x30, 1424
    mulh   x14, x3, x22
    lui    x19, 0x72053
    lui    x27, 0x57030
    lui    x15, 0x742f0
    srai   x12, x28, 25
    lui    x7, 0x70c63
    lui    x25, 0x1aac0
    and    x17, x3, x17
    mulhsu x25, x6, x19
    lui    x3, 0x14f08
    sll    x26, x16, x22
    mulhu  x11, x11, x9
    srli   x8, x26, 9
    sra    x16, x23, x29
    sub    x27, x28, x15
    xori   x13, x3, 1543
    or     x28, x10, x21
    srli   x8, x16, 9
    lui    x7, 0x677ad
    lui    x20, 0xd094c
    div    x23, x13, x1
    sra    x16, x2, x25
    lui    x18, 0xffe82
    sll    x20, x22, x23
    srli   x23, x18, 30
    andi   x16, x18, 652
    mulhu  x4, x20, x22
    remu   x20, x6, x5
    div    x24, x2, x22
    lui    x6, 0xe363b
    sub    x3, x16, x11
    mul    x4, x1, x28
    slli   x12, x24, 15
    ori    x5, x14, 1753
    divu   x27, x23, x29
    addi   x9, x3, 942
    mulhu  x26, x9, x17
    ori    x7, x30, -1851
    sltiu  x29, x27, -1374
    ori    x26, x7, -1430
    srai   x1, x22, 31
    ori    x24, x26, -775
    xori   x6, x6, 1953
    lui    x16, 0xa5738
    rem    x11, x20, x1
    addi   x29, x13, 521
    div    x17, x8, x15
    slli   x6, x21, 28
    divu   x29, x18, x10
    sll    x10, x6, x23
    srli   x6, x15, 4
    rem    x23, x10, x21
    lui    x19, 0x15311
    ori    x7, x7, 637
    slli   x27, x3, 6
    lui    x1, 0x4e4c4
    lui    x28, 0x291f4
    lui    x11, 0x5cf0b
    ori    x6, x1, -315
    slli   x1, x6, 26
    ori    x9, x4, -1955
    and    x17, x11, x23
    xori   x13, x22, 734
    lui    x6, 0x51ee3
    slti   x19, x27, -329
    remu   x19, x27, x4
    ori    x14, x22, 1311
    sra    x21, x16, x13
    mulhu  x15, x21, x27
    div    x2, x11, x23
    srai   x12, x21, 23
    lui    x4, 0xcdad8
    div    x4, x28, x11
    remu   x15, x4, x9
    mulhsu x5, x14, x6
    sltiu  x27, x6, -405
    lui    x10, 0x67edb
    ori    x19, x16, -1389
    srli   x20, x15, 26
    remu   x15, x15, x27
    mulhu  x2, x10, x14
    lui    x25, 0x3ed90
    ori    x2, x8, 1249
    lui    x13, 0x1bfd8
    slti   x18, x23, 1926
    addi   x5, x17, -262
    xori   x18, x1, 1611
    divu   x10, x16, x10
    slli   x1, x11, 24
    lui    x29, 0xd8848
    div    x6, x1, x13
    divu   x16, x3, x17
    lui    x11, 0x50b92
    xor    x9, x4, x20
    srli   x12, x23, 17
    rem    x26, x8, x11
    srli   x5, x24, 0
    slli   x19, x5, 10
    lui    x2, 0x29aaf
    xor    x19, x11, x26
    ori    x9, x1, -1430
    addi   x22, x24, -1222
    srl    x26, x10, x7
    slli   x10, x29, 10
    srl    x22, x7, x23
    srai   x19, x26, 20
    slli   x10, x24, 21
    srli   x29, x21, 4
    andi   x17, x4, -1438
    srli   x9, x15, 5
    lui    x28, 0x15cba
    lui    x10, 0x84960
    mulhsu x26, x5, x9
    mulh   x22, x18, x22
    srli   x3, x15, 12
    srli   x24, x27, 19
    lui    x25, 0x83a91
    lui    x16, 0xe9f78
    slli   x6, x9, 14
    sll    x3, x24, x1
    and    x26, x14, x21
    rem    x21, x28, x11
    lui    x13, 0x5f2b9
    lui    x2, 0xf87af
    mulhu  x21, x26, x7
    srai   x13, x19, 0
    xor    x13, x23, x2
    ori    x12, x8, -1189
    lui    x20, 0xb9df5
    or     x9, x19, x1
    sll    x10, x3, x23
    mulhu  x4, x27, x20
    lui    x8, 0xd9ac2
    lui    x21, 0x6d6a8
    add    x21, x12, x3
    slt    x29, x5, x26
    srli   x22, x8, 20
    slli   x29, x25, 1
    lui    x11, 0x37aee
    addi   x14, x17, 297
    mulh   x27, x27, x23
    andi   x11, x2, -705
    lui    x8, 0x3960a
    add    x17, x12, x25
    divu   x30, x16, x1
    srai   x5, x2, 25
    and    x23, x29, x6
    sltiu  x20, x10, -1106
    slti   x10, x27, -1773
    srai   x10, x22, 1
    lui    x12, 0xef781
    sltu   x19, x30, x25
    srli   x25, x12, 27
    sub    x15, x2, x27
    lui    x25, 0x1a613
    xor    x5, x26, x11
    andi   x6, x16, 293
    sltiu  x27, x23, -1500
    srli   x14, x12, 12
    sra    x5, x15, x19
    slti   x8, x15, -1611
    srli   x12, x20, 8
    rem    x20, x30, x20
    lui    x15, 0x3d095
    srai   x27, x18, 19
    addi   x10, x7, 1628
    srai   x16, x26, 6
    mul    x22, x7, x29
    slli   x5, x12, 4
    andi   x22, x24, -217
    lui    x25, 0xc67c2
    add    x30, x1, x7
    xori   x10, x6, -1357
    rem    x17, x26, x22
    lui    x15, 0x2ea7c
    sra    x26, x20, x10
    remu   x10, x7, x3
    div    x10, x28, x4
    or     x28, x21, x9
    slti   x5, x9, 1783
    srli   x10, x16, 1
    andi   x23, x29, -595
    slti   x4, x6, -117
    srl    x3, x12, x10
    and    x3, x25, x24
    rem    x4, x30, x21
    lui    x15, 0x988b1
    addi   x24, x9, -1174
    remu   x30, x28, x21
    lui    x5, 0x152e5
    remu   x21, x6, x10
    sub    x11, x15, x1
    lui    x3, 0xc372c
    mulhsu x23, x11, x17
    lui    x30, 0x95a24
    sltu   x22, x30, x27
    mulhsu x11, x6, x14
    lui    x30, 0x8f690
    addi   x19, x18, -806
    sltiu  x1, x12, -1091
    lui    x23, 0x25110
    srl    x1, x5, x28
    lui    x16, 0x67511
    remu   x1, x16, x20
    srli   x9, x27, 25
    lui    x3, 0x899b3
    srai   x17, x9, 14
    srai   x9, x2, 31
    lui    x16, 0x450e6
    slti   x13, x22, -761
    srl    x12, x19, x15
    sltu   x24, x1, x24
    srli   x3, x24, 15
    mul    x22, x19, x19
    ori    x9, x8, -749
    lui    x8, 0x8bb7c
    srai   x9, x21, 0
    srai   x18, x30, 23
    srai   x10, x6, 1
    slli   x18, x24, 4
    mulh   x24, x14, x6
    rem    x2, x29, x15
    div    x27, x27, x9
    and    x22, x7, x1
    slt    x21, x8, x4
    andi   x19, x25, 1068
    srli   x26, x18, 15
    lui    x10, 0xfe7d6
    lui    x22, 0x69866
    div    x30, x14, x30
    sub    x6, x2, x12
    remu   x19, x5, x6
    slti   x22, x5, 239
    srli   x12, x1, 5
    slli   x11, x14, 5
    lui    x27, 0x19bf7
    mulhu  x11, x24, x25
    andi   x6, x19, 1417
    slti   x2, x15, 88
    lui    x26, 0x75355
    lui    x3, 0x22aea
    slti   x23, x17, -875
    lui    x13, 0xc3d4f
    lui    x28, 0x449ca
    add    x9, x28, x3
    slli   x30, x28, 8
    addi   x16, x8, 1081
    sltiu  x11, x19, -1493
    slt    x28, x23, x12
    srli   x29, x22, 29
    srli   x22, x11, 18
    sra    x27, x27, x21
    srai   x7, x16, 31
    ori    x28, x27, 533
    slli   x23, x21, 11
    lui    x28, 0xfcacd
    sra    x30, x21, x1
    and    x25, x11, x5
    addi   x2, x24, 183
    addi   x13, x27, -16
    slli   x24, x2, 30
    srai   x19, x19, 8
    srai   x6, x30, 29
    slli   x13, x28, 15
    lui    x29, 0xc052d
    div    x8, x23, x20
    mulhu  x13, x1, x19
    andi   x18, x21, 326
    add    x8, x11, x9
    xori   x1, x15, -1209
    slli   x11, x2, 11
    remu   x30, x15, x1
    sub    x26, x9, x25
    xor    x13, x20, x25
    addi   x2, x25, 856
    sltiu  x8, x19, 871
    xori   x29, x19, 1295
    sltu   x15, x15, x22
    srai   x28, x18, 4
    srl    x7, x6, x7
    divu   x12, x20, x1
    xori   x30, x2, -115
    mulhsu x28, x5, x5
    lui    x16, 0xeced9
    slli   x22, x16, 3
    lui    x9, 0x331ed
    add    x28, x2, x28
    srli   x6, x8, 22
    lui    x24, 0x409e0
    mulh   x21, x24, x10
    slli   x16, x27, 18
    mulhsu x11, x14, x1
    mulhsu x22, x26, x18
    srai   x28, x19, 16
    or     x19, x20, x30
    sltiu  x20, x14, -933
    or     x8, x23, x12
    slli   x16, x20, 7
    or     x6, x12, x19
    mul    x18, x28, x27
    srai   x24, x12, 4
    mulhsu x23, x30, x14
    sub    x20, x16, x1
    lui    x7, 0x24042
    andi   x4, x4, 982
    divu   x1, x25, x12
    xori   x1, x3, -427
    and    x3, x27, x17
    srai   x23, x11, 30
    lui    x1, 0x6d271
    divu   x4, x6, x23
    slti   x29, x6, 1569
    lui    x15, 0x7901a
    lui    x24, 0xe7887
    slli   x6, x5, 22
    srl    x2, x18, x10
    mulhsu x10, x30, x5
    rem    x7, x27, x26
    add    x23, x26, x25
    or     x5, x14, x14
    slli   x20, x1, 26
    mulhu  x13, x1, x28
    mulhsu x16, x24, x18
    xori   x27, x14, -1245
    xor    x8, x30, x28
    slti   x23, x4, -2048
    lui    x29, 0xf7507
    sub    x21, x1, x27
    slti   x12, x25, 638
    srli   x8, x6, 18
    sltu   x18, x6, x5
    remu   x27, x2, x27
    div    x16, x12, x11
    andi   x24, x9, 388
    addi   x7, x11, 1324
    srai   x21, x21, 16
    or     x8, x5, x8
    srli   x27, x4, 23
    mulhsu x11, x30, x8
    add    x7, x13, x6

    # Branch and Jump block
    beq x0, x0, skip_beq
    addi x1, x1, 1
skip_beq:
    bne x0, x1, skip_bne
    addi x1, x1, 1
skip_bne:
    blt x0, x1, skip_blt
    addi x1, x1, 1
skip_blt:
    bge x1, x0, skip_bge
    addi x1, x1, 1
skip_bge:
    bltu x0, x1, skip_bltu
    addi x1, x1, 1
skip_bltu:
    bgeu x1, x0, skip_bgeu
    addi x1, x1, 1
skip_bgeu:
    jal x0, skip_jal
    addi x1, x1, 1
skip_jal:

    # Manual AUIPC and JALR test (safely avoiding pointer arithmetic)
    auipc x31, 0
    jalr x0, x31, 12
    addi x1, x1, 1
    addi x1, x1, 1
skip_jalr:

    # Fill to exactly 1000 instructions total if needed
    # End of test
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
    add x0, x0, x0
