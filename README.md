# RISC-V RV32IM 5-Stage Pipelined Processor

A highly optimized, fully synthesizable **5-stage pipelined RISC-V RV32IM processor** implemented in synthesizable Verilog. It features a spatial 5-stage pipeline, a combinational control unit, a dynamic hazard detection and forwarding unit to resolve data hazards, a hardware-realistic iterative M-extension (multiplication and division) with pipeline stall support, a cycle-accurate Python golden model for co-simulation, a dynamic verification harness, and a robust CI regression test pipeline.

The hallmark of this repository is the complete hardware-realistic integration of the **RISC-V M-Extension** (Multiplication and Division) featuring 32-cycle iterative execution and dynamic pipeline stalling within a classic pipelined datapath.

---

## Key Features

1. **5-Stage Spatial Pipeline**: Overlaps instruction execution across five distinct stages: Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), and Write-Back (WB) for maximum throughput.
2. **Hazard Detection & Forwarding Unit**:
   - **Data Forwarding**: Resolves EX-to-EX and MEM-to-EX data hazards without stalling, routing intermediate results directly to the ALU inputs.
   - **Load-Use Stall**: Detects load-use hazards (for all base and sub-word loads) and automatically inserts a 1-cycle pipeline bubble (stall).
   - **Control Hazard Flush**: Flushes instructions in the IF and ID stages upon resolving taken branches or jumps in the EX stage, minimizing branch penalty.
3. **Combinational Control Unit (`control_unit.v`)**: Generates all instruction control signals combinationaly during the Decode (ID) stage, which propagate downstream through sequential pipeline registers.
4. **Iterative M-Extension (`mul_div.v`)**:
   - **Multiplication**: A hardware-realistic 32-cycle shift-and-add multiplier supporting `MUL`, `MULH`, `MULHSU`, and `MULHU`.
   - **Division / Remainder**: A hardware-realistic 32-cycle restoring divider supporting `DIV`, `DIVU`, `REM`, and `REMU`.
   - **Pipeline Stall**: Stalls the pipeline in the EX stage while the iterative multiplier/divider is active, resuming execution smoothly upon completion.
5. **Full Sub-word Load/Store Support**: Integrates selective write byte-enables (`byte_en[3:0]`) for byte and halfword writes in `data_mem.v`, paired with dynamic processor-side alignment and sign/zero-extensions for sub-word reads (`LB`, `LBU`, `LH`, `LHU`, `SB`, `SH`).
6. **Co-Simulation SVT Framework**: Dynamic register and memory validation comparing the physical RTL simulation directly against an automated Python Instruction Set Simulator (ISS) golden model.
7. **CI Regression Tests**: 7 different operation-specific categories running parallel test injections using runtime `$readmemh` parameter mapping (`+TEST_DIR`).
8. **Continuous Integration**: GitHub Actions workflow (.github/workflows/makefile.yml) automatically compiles, verifies SVT, and runs regressions on all push and pull requests.

---

## Architectural Details

### 5-Stage Pipeline Overview
Architecture diagram [WIP]. 

### Hazard Summary

| Hazard Type | Detection | Resolution | Penalty |
|---|---|---|---|
| **EX-to-EX Data** | `ex_mem_rd == id_ex_rs{1,2}` | MUX A/B forward `ex_mem_alu_result` | **0 cycles** |
| **MEM-to-EX Data** | `mem_wb_rd == id_ex_rs{1,2}` | MUX A/B forward `wb_write_data` | **0 cycles** |
| **Load-Use** | `id_ex_MemRead && rd matches rs` | Stall PC + IF/ID, inject bubble into ID/EX | **1 cycle** |
| **Control (Taken Branch/Jump)** | `take_branch_or_jump` in EX | Flush IF/ID and ID/EX (NOP injection) | **2 cycles** |
| **M-Extension (MUL/DIV)** | `is_mul_div && ~done` | Hold all pipeline registers; inject EX/MEM bubble | **32 cycles** |

### Instruction Performance Characterization

| Condition / Instruction Type | Wasted Cycles | Effective CPI | Pipeline Behavior |
|---|---|---|---|
| **Ideal Arithmetic / Logic** | 0 | **1** | Fully overlapped; forwarding covers all data hazards. |
| **Data Hazard (ALU-to-ALU)** | 0 | **1** | EX/MEM or MEM/WB result forwarded directly to ALU inputs. |
| **Load-Use Hazard** | 1 | **2** | 1-cycle bubble inserted so memory read reaches EX via forwarding. |
| **Taken Branch / Jump** | 2 | **3** | 2 wrongly-fetched instructions flushed with NOP bubbles. |
| **M-Extension MUL/DIV** | 32 | **33** | Pipeline stalled for 32 iterations; resumes after `done` pulses. |

---

## Supported Instruction Set

### RV32I Base Integer Instructions
- **R-Type**: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU`
- **I-Type**: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU`
- **Load/Store**: `LW`, `LH`, `LHU`, `LB`, `LBU`, `SW`, `SH`, `SB` (fully supporting byte-enable selective writes and dynamic sign/zero-extended sub-word loads)
- **Branch**: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- **Jumps**: `JAL`, `JALR` (clears the LSB of the target address to 0 to ensure strict 32-bit instruction alignment)
- **Upper Immediate**: `LUI`, `AUIPC`

### RV32M Extension Instructions
- **Multiplication**: `MUL` (low 32-bits), `MULH` (signed x signed high), `MULHU` (unsigned x unsigned high), `MULHSU` (signed x unsigned high)
- **Division / Remainder**: `DIV` (signed division), `DIVU` (unsigned division), `REM` (signed remainder), `REMU` (unsigned remainder)

---

## Directory Structure

```
RISCV_RV32IM_Pipelined/
├── src/
│   ├── core/
│   │   ├── rv32im_pipelined.v    # Top-level datapath, hazard unit & pipeline registers
│   │   ├── control_unit.v        # Combinational control unit
│   │   ├── alu_control.v         # Decodes ALU operation (standard and M-type)
│   │   ├── imm_gen.v             # Immediate generator (R/I/S/B/U/J formats)
│   │   └── register_file.v       # 32x32 register file with internal forwarding
│   ├── alu/
│   │   ├── ALU_n_bit.v           # Base N-bit parameterized ALU
│   │   ├── full_adder_n_bit.v    # Ripple-carry adder
│   │   └── mul_div.v             # 32-cycle iterative multiplication and division module
│   └── memory/
│       ├── instruction_memory.v  # Dynamic runtime memory injection (readmemh)
│       └── data_mem.v            # Data memory
├── tb/
│   ├── rv32im_tb.v               # Main testbench (module: rv32im_tb)
│   ├── svt_tb.v                  # Co-simulation verification testbench
│   └── test_lw_sw.v              # Simple memory access sanity testbench
├── scripts/
│   └── golden_model.py           # Cycle-accurate python instruction set simulator (ISS)
├── regression_tests/
│   ├── I-Type/                   # Hex tests for immediate arithmetic
│   ├── R-Type/                   # Hex tests for register arithmetic
│   ├── U-Type/                   # Hex tests for LUI and AUIPC
│   ├── J-Type/                   # Hex tests for unconditional jumps
│   ├── Mul/                      # Hex tests for MUL, MULH, MULHU, MULHSU
│   ├── Div/                      # Hex tests for DIV, DIVU, REM, REMU
│   ├── Mem_Access/               # Hex tests for sub-word and word loads and stores (LB, LH, LW, LBU, LHU, SB, SH)
│   └── Edge_Cases/               # Hex tests for Divide by Zero, Overflow, etc.
├── .github/
│   └── workflows/
│       └── makefile.yml          # GitHub Actions CI Workflow config
├── Makefile                      # Build automation script
└── README.md
```

---

## Verification & Testing

### 1. Verification Framework (SVT)
The **Software Verification Testbench (SVT)** uses a co-simulation approach where the cycle-accurate Python ISS compiles the target program and extracts a cycle-by-cycle golden reference state of all Registers, PC, and Memory. 

The Verilog RTL simulates the program, and at the end of execution, `svt_tb.v` automatically runs absolute asserts to compare the hardware registers/memory against the golden `.hex` results.

### 2. Spike ISA Trace Co-Simulation
For an even higher level of verification, the RTL trace can be bit-accurately compared against the official RISC-V **Spike ISA Simulator**. 
- A custom parser (`scripts/spike_log_to_trace_csv.py`) normalizes Spike's memory map (`0x80000000`) to match the RTL (`0x00000000`).
- The parser intelligently decodes PC-relative instructions (`JAL`, `JALR`, `AUIPC`) on-the-fly to subtract the base offset from the destination register writeback, eliminating false trace mismatches caused by pointer arithmetic differences across address spaces.
- The RTL trace is similarly parsed (`scripts/rtl_log_to_trace_csv.py`) and passed to an `instr_trace_compare.py` script.

### 3. Automated 1000-Instruction Stress Testing
To heavily stress the pipeline, data hazards, and iterative math unit, a python test generator (`gen_1000.py`) is included. It randomly generates a 1000-instruction `.S` program exercising R-type, I-type, Branches, Jumps, U-Type, and M-extension instructions.
- Instruction memory (`IMEM`) and Data memory (`DMEM`) are parameterized up to 2048 words to handle large tests.
- The SVT golden model supports up to `100,000` cycles to easily absorb the massive iterative pipeline stalls (34 cycles per `mul`/`div`) triggered during aggressive randomization.

### 4. Regression Testing (`make regression`)
To run the automated, categorized regression suite across all 8 test categories:
```bash
make regression
```

This target runs a shell loop over the `regression_tests/` directory, invoking the golden model for each test to generate directory-specific outputs, runs the RTL simulation passing `+TEST_DIR=<test>`, and logs the overall status:

```text
=======================================================
              RUNNING REGRESSION SUITE                 
=======================================================
Running regression_tests/Div...
[PASS] Div
Running regression_tests/Edge_Cases...
[PASS] Edge_Cases
Running regression_tests/I-Type...
[PASS] I-Type
Running regression_tests/J-Type...
[PASS] J-Type
Running regression_tests/Mem_Access...
[PASS] Mem_Access
Running regression_tests/Mul...
[PASS] Mul
Running regression_tests/R-Type...
[PASS] R-Type
Running regression_tests/Svt_custom_tests...
[PASS] Svt_custom_tests
Running regression_tests/U-Type...
[PASS] U-Type
=======================================================
```

If even one test category reports a mismatch, `make regression` exits with a non-zero code (`exit 1`) to fail the continuous integration pipeline.

### 5. Continuous Integration (CI)
GitHub Actions are fully integrated via `.github/workflows/makefile.yml`. Every single commit and pull request triggers a runner that:
1. Spins up an Ubuntu container.
2. Installs `iverilog` and `python3` dependencies.
3. Runs `make svt` to verify the baseline CPU integrity.
4. Runs `make regression` to verify all 8 isolated hardware operations.

### 6. Performance Counters & CPI Analysis
The processor includes hardware performance counters that track cycles, instruction retirement, and various pipeline hazards. The cycle counter `total_cycles` automatically freezes once the processor reaches a halt condition and the pipeline has completely drained.

At the end of any SVT run, the simulation prints a detailed characterization of the processor's execution:
- **Core Metrics:** Total clock cycles, retired instructions, and the overall CPI (Cycles Per Instruction).
- **Instruction Mix:** Percentage breakdown of ALU, Mul/Div, Load, Store, Branch, and Jump instructions.
- **Branch Predictor Metrics:** Taken and not-taken branches to analyze static predictor efficiency.
- **Pipeline Stall & Overhead Analysis:** Exact cycle contribution of load-use stalls, multiplier stalls, and branch flushes.

Example CPI scenarios on the custom test program:

#### Scenario A: Mixed RV32IM Workload (with 32-cycle iterative MUL/DIV)
When executing the custom test suite (`Svt_custom_tests`) which contains a mix of standard instructions and MUL/DIV operations, the math unit's iterative execution introduces significant stalls:
- **Instructions Retired:** 320
- **Total Clock Cycles:** 1500
- **Overall CPI:** **4.688**
- **Overhead Analysis:** **Multiplier stalls dominate the execution**, consuming **70.80%** (1,062 cycles) of all clock cycles.

```text
=======================================================
             PROCESSOR PERFORMANCE REPORT
=======================================================
  [Core Metrics]
    Total Clock Cycles       : 1500
    Instructions Retired     : 320
    Overall CPI              : 4.688 (Ideal = 1.000)

  [Pipeline Stall & Overhead Analysis]
    Load-Use Stall Cycles    : 0 (0.00% of cycles)
    Multiplier Stall Cycles  : 1062 (70.80% of cycles)
    Control Hazard Flushes   : 58 (3.87% of cycles)
    Total Wasted Cycles      : 1120 (74.67% overhead)
=======================================================
```

#### Scenario B: Base RV32I Workload (MUL/DIV replaced with NOPs)
If we remove the M-type operations by replacing them with `NOP`s (`00000013`), we eliminate the iterative execution stalls:
- **Instructions Retired:** 1098
- **Total Clock Cycles:** 1500
- **Overall CPI:** **1.366**
- **Overhead Analysis:** Multiplier stalls are completely eliminated. The remaining **13.33% overhead** is entirely due to control flushes (taken branches/jumps) and pipeline fill/drain.

```text
=======================================================
             PROCESSOR PERFORMANCE REPORT
=======================================================
  [Core Metrics]
    Total Clock Cycles       : 1500
    Instructions Retired     : 1098
    Overall CPI              : 1.366 (Ideal = 1.000)

  [Pipeline Stall & Overhead Analysis]
    Load-Use Stall Cycles    : 0 (0.00% of cycles)
    Multiplier Stall Cycles  : 0 (0.00% of cycles)
    Control Hazard Flushes   : 200 (13.33% of cycles)
    Total Wasted Cycles      : 200 (13.33% overhead)
=======================================================
```

#### Scenario C: Pure ALU Workload (e.g., `R-Type` regression)
When running a program with no control/data hazards and no M-type instructions (like the 57-instruction `R-Type` regression test):
- **Instructions Retired:** 57
- **Total Clock Cycles:** 61
- **Overall CPI:** **1.070**
- **Overhead Analysis:** No stalls or flushes. The CPI of 1.070 is due to the **4-cycle pipeline fill overhead** (`57 + 4 = 61` cycles total to retire 57 instructions). As the instruction count increases, the pipeline fill overhead is amortized, and CPI converges toward the ideal **1.000**.

```text
=======================================================
             PROCESSOR PERFORMANCE REPORT
=======================================================
  [Core Metrics]
    Total Clock Cycles       : 61
    Instructions Retired     : 57
    Overall CPI              : 1.070 (Ideal = 1.000)

  [Pipeline Stall & Overhead Analysis]
    Load-Use Stall Cycles    : 0 (0.00% of cycles)
    Multiplier Stall Cycles  : 0 (0.00% of cycles)
    Control Hazard Flushes   : 0 (0.00% of cycles)
    Total Wasted Cycles      : 0 (0.00% overhead)
=======================================================
```

---

## Quick Start (Usage Guide)

### Install Prerequisites (Ubuntu/Linux)
```bash
# Standard RTL Simulation tools
sudo apt-get update
sudo apt-get install -y iverilog python3

# For custom assembly compilation and Spike Trace Co-Simulation:
# You will need the RISC-V GNU Compiler Toolchain and Spike ISA Simulator.
# Ensure `riscv64-unknown-elf-gcc` and `spike` are in your system PATH.
```

### Run Sanity Check Program
```bash
make svt
```

### Run Full Regression Suite
```bash
make regression
```

### Clean Simulation Binaries
```bash
make clean
```

### Compile & Co-Simulate Custom Assembly
To write, compile, and strictly trace-match a custom RISC-V assembly program against the Spike ISA Simulator:

```bash
# 1. Compile assembly to ELF targeting Spike's 0x80000000 memory map
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib -Wl,-N -Ttext=0x80000000 -Wl,--no-warn-rwx-segments regression_tests/Svt_custom_tests/test.S -o test.elf

# 2. Run Spike ISA Simulator to generate golden commit trace
spike --isa=rv32im -l --log-commits --pc=0x80000000 --instructions=1500 test.elf > spike.log 2>&1

# 3. Extract raw Hex program for the RTL
riscv64-unknown-elf-objcopy -O binary --only-section=.text test.elf test.bin
hexdump -v -e '1/4 "%08x\n"' test.bin > regression_tests/Svt_custom_tests/program.hex

# 4. Run RTL Simulation (SVT)
make svt +TEST_DIR=regression_tests/Svt_custom_tests

# 5. Convert Logs to standard CSV format and Compare!
python3 scripts/spike_log_to_trace_csv.py --log spike.log --csv spike.csv
python3 scripts/rtl_log_to_trace_csv.py --log rtl_trace.log --csv rtl.csv
python3 ../riscv-dv/scripts/instr_trace_compare.py --csv_file_1 spike.csv --csv_name_1 Spike --csv_file_2 rtl.csv --csv_name_2 RTL
```
