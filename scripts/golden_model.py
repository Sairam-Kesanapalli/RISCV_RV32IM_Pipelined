import re
import sys

# 1. Parse instruction_mem.v to extract opcodes
#    Supports both 32'hXXXX hex literals and Verilog concatenation syntax
#    like {7'b0000001, 5'd2, 5'd1, 3'b000, 5'd10, 7'b0110011}
def parse_imem(path):
    instrs = {}  # Use dict keyed by index to handle duplicate assignments
    with open(path) as f:
        for line in f:
            # Try to extract the memory index
            idx_match = re.search(r'instr_memory\[(\d+)\]', line)
            if not idx_match:
                continue
            idx = int(idx_match.group(1))

            # Try hex literal first: 32'hXXXXXXXX
            hex_match = re.search(r"32'h([0-9a-fA-F]+)", line)
            if hex_match:
                instrs[idx] = int(hex_match.group(1), 16)
                continue

            # Try Verilog concatenation syntax: {width'bBITS, width'dDEC, ...}
            concat_match = re.search(r'\{(.+)\}', line)
            if concat_match:
                fields = concat_match.group(1).split(',')
                val = 0
                for field in fields:
                    field = field.strip()
                    m = re.match(r"(\d+)'b([01]+)", field)
                    if m:
                        width = int(m.group(1))
                        bits = int(m.group(2), 2)
                        val = (val << width) | bits
                        continue
                    m = re.match(r"(\d+)'d(\d+)", field)
                    if m:
                        width = int(m.group(1))
                        bits = int(m.group(2))
                        val = (val << width) | bits
                        continue
                    m = re.match(r"(\d+)'h([0-9a-fA-F]+)", field)
                    if m:
                        width = int(m.group(1))
                        bits = int(m.group(2), 16)
                        val = (val << width) | bits
                        continue
                instrs[idx] = val & 0xFFFFFFFF

    # Convert dict to sorted list
    if not instrs:
        return []
    max_idx = max(instrs.keys())
    result = []
    for i in range(max_idx + 1):
        result.append(instrs.get(i, 0x00000013))  # NOP for missing entries
    return result

# 2. Tiny RV32I simulator
#    Models the same word-indexed memory as the RTL:
#    RTL uses memory[addr[ADDR_WIDTH+1:2]], i.e. word_index = (byte_addr >> 2) & 0xFF
MEM_DEPTH = 256

IMEM_DEPTH = 256

def simulate(instrs, max_cycles=1500):
    """
    Cycle-accurate RV32IM simulator mirroring the 5-stage pipeline RTL.
    Tracks structural hazards, data hazards (forwarding/load-use stalls),
    and control hazards (flushes) exactly as rv32im_pipelined.v does.
    """
    padded_imem = instrs[:] + [0x00000013] * (IMEM_DEPTH - len(instrs))
    regs = [0] * 32
    mem  = [0] * MEM_DEPTH  # Initialize to 0 matching data_mem.v
    
    pc = 0
    cycle = 0
    
    def sign_ext(val, bits):
        if val & (1 << (bits-1)): return val - (1 << bits)
        return val

    # Stage Latches. Each is a dictionary carrying the required data.
    if_id = None
    id_ex = None
    ex_mem = None
    mem_wb = None

    # Multiplier state
    mul_active = False
    mul_cycles = 0
    mul_result = 0
    
    def decode(instr, pc):
        opcode = instr & 0x7F
        rd     = (instr >> 7)  & 0x1F
        funct3 = (instr >> 12) & 0x7
        rs1    = (instr >> 15) & 0x1F
        rs2    = (instr >> 20) & 0x1F
        funct7 = (instr >> 25) & 0x7F
        i_imm  = sign_ext((instr >> 20), 12)
        s_imm  = sign_ext(((instr>>25)<<5)|((instr>>7)&0x1F), 12)
        b_imm  = sign_ext(((instr>>31)<<12)|((instr>>7&1)<<11)|((instr>>25&0x3F)<<5)|((instr>>8&0xF)<<1), 13)
        u_imm  = sign_ext((instr >> 12) << 12, 32)
        j_imm  = sign_ext(((instr>>31)<<20)|((instr>>12&0xFF)<<12)|((instr>>20&1)<<11)|((instr>>21&0x3FF)<<1), 21)
        
        is_load = opcode == 0x03
        is_store = opcode == 0x23
        is_branch = opcode == 0x63
        is_jal = opcode == 0x6f
        is_jalr = opcode == 0x67
        is_jump = is_jal or is_jalr
        is_alu = opcode in (0x33, 0x13, 0x37, 0x17)
        is_mul_div = (opcode == 0x33 and funct7 == 0x01)
        reg_write = is_load or is_alu or is_jump or is_mul_div
        if rd == 0: reg_write = False
        
        return {
            'pc': pc, 'instr': instr, 'opcode': opcode, 'rd': rd, 'funct3': funct3,
            'rs1': rs1, 'rs2': rs2, 'funct7': funct7,
            'i_imm': i_imm, 's_imm': s_imm, 'b_imm': b_imm, 'u_imm': u_imm, 'j_imm': j_imm,
            'is_load': is_load, 'is_store': is_store, 'is_branch': is_branch,
            'is_jump': is_jump, 'is_jal': is_jal, 'is_jalr': is_jalr, 'is_mul_div': is_mul_div, 'reg_write': reg_write,
            'mem_read': is_load, 'mem_write': is_store
        }

    while cycle < max_cycles:
        # Evaluate stages in reverse order: WB, MEM, EX, ID, IF
        
        # ---------------- WB Stage ----------------
        if mem_wb:
            if mem_wb['reg_write'] and mem_wb['rd'] != 0:
                regs[mem_wb['rd']] = mem_wb['wb_data'] & 0xFFFFFFFF
                
        # ---------------- Forwarding Logic (combinational) ----------------
        def forward(rs):
            if rs == 0: return 0
            if ex_mem and ex_mem['reg_write'] and ex_mem['rd'] == rs:
                return ex_mem['alu_result']
            if mem_wb and mem_wb['reg_write'] and mem_wb['rd'] == rs:
                return mem_wb['wb_data']
            return regs[rs]

        # ---------------- MEM Stage ----------------
        next_mem_wb = None
        if ex_mem:
            wb_data = ex_mem['alu_result']
            if ex_mem['mem_read']:
                addr = ex_mem['alu_result']
                wi = (addr >> 2) & (MEM_DEPTH - 1)
                mem_word = mem[wi] if mem[wi] is not None else 0
                f3 = ex_mem['funct3']
                byte_offset = addr & 0x3
                
                if f3 == 0: # LB
                    b = (mem_word >> (byte_offset * 8)) & 0xFF
                    wb_data = sign_ext(b, 8) & 0xFFFFFFFF
                elif f3 == 1: # LH
                    hw = (mem_word >> ((byte_offset & 2) * 8)) & 0xFFFF
                    wb_data = sign_ext(hw, 16) & 0xFFFFFFFF
                elif f3 == 2: # LW
                    wb_data = mem_word
                elif f3 == 4: # LBU
                    b = (mem_word >> (byte_offset * 8)) & 0xFF
                    wb_data = b
                elif f3 == 5: # LHU
                    hw = (mem_word >> ((byte_offset & 2) * 8)) & 0xFFFF
                    wb_data = hw

            if ex_mem['mem_write']:
                addr = ex_mem['alu_result']
                wi = (addr >> 2) & (MEM_DEPTH - 1)
                mem_word = mem[wi] if mem[wi] is not None else 0
                store_val = ex_mem['store_data'] & 0xFFFFFFFF
                f3 = ex_mem['funct3']
                byte_offset = addr & 0x3
                
                if f3 == 0: # SB
                    mask = 0xFF << (byte_offset * 8)
                    shifted_val = (store_val & 0xFF) << (byte_offset * 8)
                    mem[wi] = (mem_word & ~mask) | shifted_val
                elif f3 == 1: # SH
                    mask = 0xFFFF << ((byte_offset & 2) * 8)
                    shifted_val = (store_val & 0xFFFF) << ((byte_offset & 2) * 8)
                    mem[wi] = (mem_word & ~mask) | shifted_val
                elif f3 == 2: # SW
                    mem[wi] = store_val
            
            next_mem_wb = dict(ex_mem)
            next_mem_wb['wb_data'] = wb_data
            
        # ---------------- EX Stage ----------------
        next_ex_mem = None
        ex_stall = False
        flush = False
        next_pc = pc + 4
        
        if id_ex:
            op = id_ex
            r1 = forward(op['rs1'])
            r2 = forward(op['rs2'])
            alu_result = 0
            store_data = r2
            
            if op['is_mul_div']:
                if not mul_active:
                    mul_active = True
                    mul_cycles = 34  # 34 cycles of stalling matching RTL
                    s1 = sign_ext(r1, 32)
                    s2 = sign_ext(r2, 32)
                    f3 = op['funct3']
                    if f3 == 0: alu_result = (s1 * s2) & 0xFFFFFFFF
                    elif f3 == 1: alu_result = ((s1 * s2) >> 32) & 0xFFFFFFFF
                    elif f3 == 2: alu_result = ((s1 * (r2 & 0xFFFFFFFF)) >> 32) & 0xFFFFFFFF
                    elif f3 == 3: alu_result = (((r1 & 0xFFFFFFFF) * (r2 & 0xFFFFFFFF)) >> 32) & 0xFFFFFFFF
                    elif f3 == 4: alu_result = 0xFFFFFFFF if r2 == 0 else (s1 & 0xFFFFFFFF) if s1 == -2147483648 and s2 == -1 else int(s1/s2) & 0xFFFFFFFF
                    elif f3 == 5: alu_result = 0xFFFFFFFF if r2 == 0 else ((r1 & 0xFFFFFFFF) // (r2 & 0xFFFFFFFF)) & 0xFFFFFFFF
                    elif f3 == 6: alu_result = r1 & 0xFFFFFFFF if r2 == 0 else 0 if s1 == -2147483648 and s2 == -1 else (s1 - int(s1/s2)*s2) & 0xFFFFFFFF
                    elif f3 == 7: alu_result = r1 & 0xFFFFFFFF if r2 == 0 else ((r1 & 0xFFFFFFFF) % (r2 & 0xFFFFFFFF)) & 0xFFFFFFFF
                    mul_result = alu_result
                    ex_stall = True
                else:
                    mul_cycles -= 1
                    if mul_cycles > 0:
                        ex_stall = True
                    else:
                        alu_result = mul_result
                        mul_active = False
            elif op['opcode'] == 0x33: # R-type
                f3 = op['funct3']
                f7 = op['funct7']
                if f3==0: alu_result = (r1+r2 if f7==0 else r1-r2)
                elif f3==1: alu_result = r1 << (r2 & 0x1F)
                elif f3==2: alu_result = 1 if sign_ext(r1,32) < sign_ext(r2,32) else 0
                elif f3==3: alu_result = 1 if (r1 & 0xFFFFFFFF) < (r2 & 0xFFFFFFFF) else 0
                elif f3==4: alu_result = r1 ^ r2
                elif f3==5: alu_result = (r1 >> (r2 & 0x1F)) if f7==0 else (sign_ext(r1,32) >> (r2 & 0x1F))
                elif f3==6: alu_result = r1 | r2
                elif f3==7: alu_result = r1 & r2
            elif op['opcode'] == 0x13: # I-type
                imm = op['i_imm']
                f3 = op['funct3']
                f7 = op['funct7']
                if f3==0: alu_result = r1 + imm
                elif f3==2: alu_result = 1 if sign_ext(r1, 32) < sign_ext(imm, 32) else 0
                elif f3==3: alu_result = 1 if (r1 & 0xFFFFFFFF) < (imm & 0xFFFFFFFF) else 0
                elif f3==4: alu_result = r1 ^ imm
                elif f3==6: alu_result = r1 | imm
                elif f3==7: alu_result = r1 & imm
                elif f3==1: alu_result = r1 << (imm & 0x1F)
                elif f3==5: alu_result = (r1 >> (imm & 0x1F)) if f7==0 else (sign_ext(r1,32) >> (imm & 0x1F))
            elif op['opcode'] in (0x03, 0x23): # LW, SW
                imm = op['i_imm'] if op['opcode'] == 0x03 else op['s_imm']
                alu_result = r1 + imm
            elif op['opcode'] == 0x37: # LUI
                alu_result = op['u_imm']
            elif op['opcode'] == 0x17: # AUIPC
                alu_result = op['pc'] + op['u_imm']
            elif op['is_branch']:
                f3 = op['funct3']
                taken = False
                if f3==0: taken = (r1==r2)
                elif f3==1: taken = (r1!=r2)
                elif f3==4: taken = (sign_ext(r1,32) < sign_ext(r2,32))
                elif f3==5: taken = (sign_ext(r1,32) >= sign_ext(r2,32))
                elif f3==6: taken = ((r1 & 0xFFFFFFFF) < (r2 & 0xFFFFFFFF))
                elif f3==7: taken = ((r1 & 0xFFFFFFFF) >= (r2 & 0xFFFFFFFF))
                if taken:
                    next_pc = (op['pc'] + op['b_imm']) & 0xFFFFFFFF
                    flush = True
            elif op['is_jal']:
                alu_result = op['pc'] + 4
                next_pc = (op['pc'] + op['j_imm']) & 0xFFFFFFFF
                flush = True
            elif op['is_jalr']:
                alu_result = op['pc'] + 4
                next_pc = (r1 + op['i_imm']) & 0xFFFFFFFE
                flush = True
                
            alu_result &= 0xFFFFFFFF
            if not ex_stall:
                next_ex_mem = dict(op)
                next_ex_mem['alu_result'] = alu_result
                next_ex_mem['store_data'] = store_data
                
        # ---------------- ID Stage ----------------
        next_id_ex = None
        load_use_stall = False
        if if_id:
            op = decode(if_id['instr'], if_id['pc'])
            # Load-Use Hazard Detection
            if id_ex and id_ex['mem_read'] and id_ex['rd'] != 0:
                if id_ex['rd'] == op['rs1'] or id_ex['rd'] == op['rs2']:
                    load_use_stall = True
            
            if not load_use_stall and not ex_stall:
                next_id_ex = op

        # ---------------- IF Stage ----------------
        next_if_id = None
        halt = False
        wi = (pc >> 2) & (MEM_DEPTH - 1)
        if wi >= len(instrs):
            halt = True
        
        if flush:
            next_if_id = None
            pc = next_pc
        elif not load_use_stall and not ex_stall:
            if not halt:
                instr = padded_imem[wi]
                next_if_id = {'pc': pc, 'instr': instr}
                pc = (pc + 4) & 0xFFFFFFFF
            else:
                next_if_id = None # Reads X / NOP

        # Update latches
        if not ex_stall:
            if flush or load_use_stall:
                id_ex = None
            else:
                id_ex = next_id_ex
                
        if not (load_use_stall or ex_stall):
            if flush:
                if_id = None
            else:
                if_id = next_if_id
                
        ex_mem = next_ex_mem
        mem_wb = next_mem_wb

        cycle += 1

    return regs, mem, pc

# 3. Emit expected_regs.hex for $readmemh
def emit_hex(regs, mem, pc, out_dir="."):
    import os
    with open(os.path.join(out_dir, "expected_regs.hex"), 'w') as f:
        for v in regs:
            f.write(f"{v:08x}\n")
    # Write word-indexed memory (matches RTL data_mem array indices 0..15)
    with open(os.path.join(out_dir, "expected_mem.hex"), 'w') as f:
        for i in range(16):
            val = mem[i]
            if val is None:
                f.write("00000000\n")  # Zero-initialized
            else:
                f.write(f"{val:08x}\n")
    with open(os.path.join(out_dir, "expected_pc.hex"), 'w') as f:
        f.write(f"{pc:08x}\n")
    print(f"[golden] PC={pc:#010x}  x1={regs[1]:#010x}  x2={regs[2]:#010x}")

def parse_hex(path):
    instrs = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            # Ignore empty lines and comments
            if not line or line.startswith('//'):
                continue
            instrs.append(int(line, 16))
    return instrs

if __name__ == "__main__":
    import os
    import argparse
    
    parser = argparse.ArgumentParser(description="RISC-V Golden Model")
    parser.add_argument("--test-dir", type=str, help="Directory containing program.hex")
    args = parser.parse_args()

    if args.test_dir:
        # ---- Regression Framework Flow ----
        imem_path = os.path.join(args.test_dir, "program.hex")
        out_dir = args.test_dir
        if not os.path.exists(imem_path):
            print(f"Cannot find {imem_path}")
            sys.exit(1)
        instrs = parse_hex(imem_path)
    else:
        # ---- Default `make svt` Flow (Mapped to Svt_custom_tests) ----
        imem_path = "regression_tests/Svt_custom_tests/program.hex"
        out_dir = "regression_tests/Svt_custom_tests"
        if not os.path.exists(imem_path):
            print(f"Cannot find {imem_path}")
            sys.exit(1)
        instrs = parse_hex(imem_path)

    regs, mem, pc = simulate(instrs)
    emit_hex(regs, mem, pc, out_dir)
