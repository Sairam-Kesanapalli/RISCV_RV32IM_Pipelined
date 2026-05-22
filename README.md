# RISC-V RV32IM Multi-Cycle Processor

A highly optimized, fully synthesizable **multi-cycle RISC-V RV32IM processor** implemented in synthesizable Verilog. It features a complete Finite State Machine (FSM) control unit, cycle-accurate Python golden model for co-simulation, dynamic verification harness, and a robust CI regression test pipeline.

The hallmark of this repository is the complete hardware-realistic integration of the **RISC-V M-Extension** (Multiplication and Division) featuring 32-cycle iterative execution and dynamic pipeline stalling.

---

## Key Features

1. **RV32I Core**: Full support for all base integer instructions (R-type, I-type, Load/Store, Branch, Jumps, Upper Immediate).
2. **Iterative M-Extension (`mul_div.v`)**:
   - **Multiplication**: A hardware-realistic 32-cycle shift-and-add multiplier supporting `MUL`, `MULH`, `MULHSU`, and `MULHU`.
   - **Division / Remainder**: A hardware-realistic 32-cycle restoring divider supporting `DIV`, `DIVU`, `REM`, and `REMU`.
3. **Pipeline Stall Protocol**: Main processor controller FSM stalls the execution phase (`EXEC_R_OR_MUL`) until the math module sets the `alu_done` signal, avoiding pipeline flushes.
4. **Co-Simulation SVT Framework**: Dynamic register and memory validation comparing the physical RTL simulation directly against an automated Python Instruction Set Simulator (ISS) golden model.
5. **CI Regression Tests**: 7 different operation-specific categories running parallel test injections using runtime `$readmemh` parameter mapping (`+TEST_DIR`).
6. **Continuous Integration**: GitHub Actions workflow (.github/workflows/makefile.yml) automatically compiles, verifies SVT, and runs regressions on all push and pull requests.

---

## Architectural Details

### FSM Execution Stages

| State | Cycle | Description |
|---|---|---|
| `FETCH` | 1 | Fetch instruction from instruction memory into IR |
| `DECODE` | 2 | Decode opcode, read register file, compute immediate, calculate PC+Imm |
| `EXEC_R_OR_MUL` | 3–35 | Execute standard ALU operation (1 cycle) OR stall for Multi-cycle Math (32 cycles) |
| `EXEC_I` | 3 | Execute immediate ALU operation |
| `MEM_ADDR` | 3 | Compute memory address for Load/Store |
| `BRANCH_EX` | 3 | Evaluate branch condition |
| `JUMP_EX / JALR_EX` | 3 | Compute jump target |
| `MEM_READ` | 4 | Read data from memory (Load) |
| `MEM_WRITE` | 4 | Write data to memory (Store) |
| `MEM_WB` | 5 | Write loaded data back to register file |
| `PC_INC` | 3–4 | Increment PC and write ALU result to register file |

### Cycle Count Per Instruction

| Instruction Type | Cycles | FSM Stages Traversed |
|---|---|---|
| R-Type (Standard) | 4 | FETCH → DECODE → EXEC_R_OR_MUL → PC_INC |
| **M-Extension Math** | **37** | FETCH → DECODE → EXEC_R_OR_MUL (Stalls for 32 cycles) → PC_INC |
| I-Type | 4 | FETCH → DECODE → EXEC_I → PC_INC |
| LUI / AUIPC | 3 | FETCH → DECODE → PC_INC |
| Load (LW) | 5 | FETCH → DECODE → MEM_ADDR → MEM_READ → MEM_WB |
| Store (SW) | 4 | FETCH → DECODE → MEM_ADDR → MEM_WRITE |
| Branch (taken) | 3 | FETCH → DECODE → BRANCH_EX |
| Branch (not taken) | 4 | FETCH → DECODE → BRANCH_EX → PC_INC |
| JAL / JALR | 3 | FETCH → DECODE → JUMP_EX / JALR_EX |

---

## Supported Instruction Set

### RV32I Base Integer Instructions
- **R-Type**: `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU`
- **I-Type**: `ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU`
- **Load/Store**: `LW`, `SW`
- **Branch**: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
- **Jumps**: `JAL`, `JALR`
- **Upper Immediate**: `LUI`, `AUIPC`

### RV32M Extension Instructions
- **Multiplication**: `MUL` (low 32-bits), `MULH` (signed x signed high), `MULHU` (unsigned x unsigned high), `MULHSU` (signed x unsigned high)
- **Division / Remainder**: `DIV` (signed division), `DIVU` (unsigned division), `REM` (signed remainder), `REMU` (unsigned remainder)

---

## Directory Structure

```
RISCV_RV32IM_Multi_Cycle/
├── src/
│   ├── core/
│   │   ├── rv32im_multi_cycle.v  # Top-level datapath & control signals
│   │   ├── control_unit.v        # Main 12-state FSM (handles M-extension stalls)
│   │   ├── alu_control.v         # Decodes ALU operation (standard and M-type)
│   │   ├── imm_gen.v             # Immediate generator (R/I/S/B/U/J formats)
│   │   └── register.v            # 32x32 register file
│   ├── alu/
│   │   ├── ALU_n_bit.v           # Base N-bit parameterized ALU
│   │   ├── full_adder_n_bit.v    # Ripple-carry adder
│   │   └── mul_div.v             # 32-cycle iterative multiplication and division module
│   └── memory/
│       ├── instruction_mem.v     # Dynamic runtime memory injection (readmemh)
│       └── data_mem.v            # Data memory
├── tb/
│   ├── rv32im_tb.v               # Base testbench
│   └── svt_tb.v                  # Co-simulation verification testbench
├── scripts/
│   └── golden_model.py           # Cycle-accurate python instruction set simulator (ISS)
├── tests/
│   ├── I-Type/                   # Hex tests for immediate arithmetic
│   ├── R-Type/                   # Hex tests for register arithmetic
│   ├── U-Type/                   # Hex tests for LUI and AUIPC
│   ├── J-Type/                   # Hex tests for unconditional jumps
│   ├── Mul/                      # Hex tests for MUL, MULH, MULHU, MULHSU
│   ├── Div/                      # Hex tests for DIV, DIVU, REM, REMU
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

### 2. Regression Testing (`make regression`)
To run the automated, categorized regression suite across all 7 test categories:
```bash
make regression
```

This target runs a shell loop over the `tests/` directory, invoking the golden model for each test to generate directory-specific outputs, runs the RTL simulation passing `+TEST_DIR=<test>`, and logs the overall status:

```text
=======================================================
              RUNNING REGRESSION SUITE                 
=======================================================
Running tests/Div...
[PASS] Div
Running tests/Edge_Cases...
[PASS] Edge_Cases
Running tests/I-Type...
[PASS] I-Type
Running tests/J-Type...
[PASS] J-Type
Running tests/Mul...
[PASS] Mul
Running tests/R-Type...
[PASS] R-Type
Running tests/U-Type...
[PASS] U-Type
=======================================================
```

If even one test category reports a mismatch, `make regression` exits with a non-zero code (`exit 1`) to fail the continuous integration pipeline.

### 3. Continuous Integration (CI)
GitHub Actions are fully integrated via `.github/workflows/makefile.yml`. Every single commit and pull request triggers a runner that:
1. Spines up an Ubuntu container.
2. Installs `iverilog` and `python3` dependencies.
3. Runs `make svt` to verify the baseline CPU integrity.
4. Runs `make regression` to verify all 7 isolated hardware operations.

---

## Quick Start (Usage Guide)

### Install Prerequisites (Ubuntu/Linux)
```bash
sudo apt-get update
sudo apt-get install -y iverilog python3
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