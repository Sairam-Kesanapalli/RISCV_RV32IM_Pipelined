import random

# Registers excluding x0 (zero) and x31 (which we might reserve for special use or just use normally)
regs = [f"x{i}" for i in range(1, 31)]

r_type = ["add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and"]
i_type = ["addi", "slti", "sltiu", "xori", "ori", "andi"]
i_type_shifts = ["slli", "srli", "srai"]
m_type = ["mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu"]

def gen_instr():
    itype = random.choice(["R", "I", "I_SHIFT", "M", "LUI"])
    rd = random.choice(regs)
    rs1 = random.choice(regs)
    rs2 = random.choice(regs)
    
    if itype == "R":
        op = random.choice(r_type)
        return f"    {op:<6} {rd}, {rs1}, {rs2}"
    elif itype == "I":
        op = random.choice(i_type)
        imm = random.randint(-2048, 2047)
        return f"    {op:<6} {rd}, {rs1}, {imm}"
    elif itype == "I_SHIFT":
        op = random.choice(i_type_shifts)
        shamt = random.randint(0, 31)
        return f"    {op:<6} {rd}, {rs1}, {shamt}"
    elif itype == "M":
        op = random.choice(m_type)
        return f"    {op:<6} {rd}, {rs1}, {rs2}"
    elif itype == "LUI":
        imm = random.randint(0, 0xFFFFF)
        return f"    lui    {rd}, {imm:#x}"
    # AUIPC removed from random pool to prevent pointer arithmetic mismatches

def main():
    with open("regression_tests/Svt_custom_tests/test.S", "w") as f:
        f.write(".section .text\n")
        f.write(".globl _start\n")
        f.write("_start:\n")
        f.write("    # Setup initial registers with non-zero values\n")
        for i in range(1, 31):
            f.write(f"    addi x{i}, x0, {random.randint(-100, 100)}\n")
        
        f.write("\n    # Main sequential block (ALU, M-ext, LUI, AUIPC)\n")
        # Generate 900 sequential instructions
        for _ in range(900):
            f.write(gen_instr() + "\n")
            
        f.write("\n    # Branch and Jump block\n")
        # To avoid infinite loops or unpredictable trace length,
        # we do controlled branches that skip over 1 instruction
        
        f.write("    beq x0, x0, skip_beq\n")
        f.write("    addi x1, x1, 1\n")
        f.write("skip_beq:\n")
        
        f.write("    bne x0, x1, skip_bne\n")
        f.write("    addi x1, x1, 1\n")
        f.write("skip_bne:\n")

        f.write("    blt x0, x1, skip_blt\n")
        f.write("    addi x1, x1, 1\n")
        f.write("skip_blt:\n")

        f.write("    bge x1, x0, skip_bge\n")
        f.write("    addi x1, x1, 1\n")
        f.write("skip_bge:\n")

        f.write("    bltu x0, x1, skip_bltu\n")
        f.write("    addi x1, x1, 1\n")
        f.write("skip_bltu:\n")

        f.write("    bgeu x1, x0, skip_bgeu\n")
        f.write("    addi x1, x1, 1\n")
        f.write("skip_bgeu:\n")

        f.write("    jal x0, skip_jal\n")
        f.write("    addi x1, x1, 1\n")
        f.write("skip_jal:\n")
        
        f.write("\n    # Manual AUIPC and JALR test (safely avoiding pointer arithmetic)\n")
        f.write("    auipc x31, 0\n")
        f.write("    jalr x0, x31, 12\n") # Jump over the next 2 instructions
        f.write("    addi x1, x1, 1\n")   # Skipped
        f.write("    addi x1, x1, 1\n")   # Skipped
        f.write("skip_jalr:\n")
        
        f.write("\n    # Fill to exactly 1000 instructions total if needed\n")
        f.write("    # End of test\n")
        for i in range(20):
            f.write("    add x0, x0, x0\n") # NOPs

if __name__ == '__main__':
    main()
