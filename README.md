# RISC-V RV32IM 5-Stage Pipelined Processor

A highly optimized, fully synthesizable **5-stage pipelined RISC-V RV32IM processor** implemented in synthesizable Verilog. It features a spatial 5-stage pipeline, a combinational control unit, a dynamic hazard detection and forwarding unit to resolve data hazards, a hardware-realistic iterative M-extension (multiplication and division) with pipeline stall support, a cycle-accurate Python golden model for co-simulation, a dynamic verification harness, and a robust CI regression test pipeline.

The hallmark of this repository is the complete hardware-realistic integration of the **RISC-V M-Extension** (Multiplication and Division) featuring 32-cycle iterative execution and dynamic pipeline stalling within a classic pipelined datapath.

---

## Key Features

1. **5-Stage Spatial Pipeline**: Overlaps instruction execution across five distinct stages: Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), and Write-Back (WB) for maximum throughput.
2. **Hazard Detection & Forwarding Unit**:
   - **Data Forwarding**: Resolves EX-to-EX and MEM-to-EX data hazards without stalling, routing intermediate results directly to the ALU inputs.
   - **Load-Use Stall**: Detects load-use hazards and automatically inserts a 1-cycle pipeline bubble (stall).
   - **Control Hazard Flush**: Flushes instructions in the IF and ID stages upon resolving taken branches or jumps in the EX stage, minimizing branch penalty.
3. **Combinational Control Unit (`control_unit.v`)**: Generates all instruction control signals combinationaly during the Decode (ID) stage, which propagate downstream through sequential pipeline registers.
4. **Iterative M-Extension (`mul_div.v`)**:
   - **Multiplication**: A hardware-realistic 32-cycle shift-and-add multiplier supporting `MUL`, `MULH`, `MULHSU`, and `MULHU`.
   - **Division / Remainder**: A hardware-realistic 32-cycle restoring divider supporting `DIV`, `DIVU`, `REM`, and `REMU`.
   - **Pipeline Stall**: Stalls the pipeline in the EX stage while the iterative multiplier/divider is active, resuming execution smoothly upon completion.
5. **Co-Simulation SVT Framework**: Dynamic register and memory validation comparing the physical RTL simulation directly against an automated Python Instruction Set Simulator (ISS) golden model.
6. **CI Regression Tests**: 7 different operation-specific categories running parallel test injections using runtime `$readmemh` parameter mapping (`+TEST_DIR`).
7. **Continuous Integration**: GitHub Actions workflow (.github/workflows/makefile.yml) automatically compiles, verifies SVT, and runs regressions on all push and pull requests.

---

## Architectural Details

### 5-Stage Pipeline Overview

```mermaid
graph TD
    subgraph IF [Instruction Fetch]
        PC[PC Register] --> IMEM[Instruction Memory]
        PC --> PC_ADD[PC + 4 Adder]
    end

    IF -->|IF/ID Reg| ID

    subgraph ID [Instruction Decode]
        DEC[Combinational Control]
        RF[Register File]
        IMM[Immediate Generator]
    end

    ID -->|ID/EX Reg| EX

    subgraph EX [Execute]
        ALU[Main ALU]
        MULDIV[Iterative Multiplier/Divider]
        FWD[Forwarding & Hazard Unit]
        B_ADD[Branch Target Adder]
    end

    EX -->|EX/MEM Reg| MEM

    subgraph MEM [Memory Access]
        DMEM[Data Memory]
    end

    MEM -->|MEM/WB Reg| WB

    subgraph WB [Write-Back]
        MUX[Write-Back Mux]
    end

    WB -->|Write Data & RegWrite| RF
    FWD -.->|Forwarding Paths| ALU
```

### Instruction Performance Characterization

| Condition / Instruction Type | Throughput (CPI) | Latency | Pipeline Behavior |
|---|---|---|---|
| **Ideal Arithmetic / Logic** | **1** | 5 Cycles | Executes completely overlapped with no stalls. |
| **Data Hazard (ALU-to-ALU)** | **1** | 5 Cycles | Forwarding unit routes execution results back to ALU; no stall cycles. |
| **Load-Use Hazard** | **2** | 6 Cycles | Installs a 1-cycle bubble in the pipeline to let memory read complete. |
| **Control Hazard (Taken Branch/Jump)** | **3** | 5 Cycles | Flushes the IF/ID pipeline registers, discarding fetched instructions. |
| **M-Extension Math (MUL/DIV)** | **33** | 37 Cycles | Stalls the EX stage for 32 cycles while the math unit iterates. |

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
RISCV_RV32IM_Pipelined/
├── src/
│   ├── core/
│   │   ├── rv32im_pipelined.v    # Top-level datapath, hazard unit & pipeline registers
│   │   ├── control_unit.v        # Combinational control unit
│   │   ├── alu_control.v         # Decodes ALU operation (standard and M-type)
│   │   ├── imm_gen.v             # Immediate generator (R/I/S/B/U/J formats)
│   │   └── register.v            # 32x32 register file with internal forwarding
│   ├── alu/
│   │   ├── ALU_n_bit.v           # Base N-bit parameterized ALU
│   │   ├── full_adder_n_bit.v    # Ripple-carry adder
│   │   └── mul_div.v             # 32-cycle iterative multiplication and division module
│   └── memory/
│       ├── instruction_mem.v     # Dynamic runtime memory injection (readmemh)
│       └── data_mem.v            # Data memory
├── tb/
│   ├── rv32im_tb.v               # Main testbench (module: rv32im_tb)
│   ├── svt_tb.v                  # Co-simulation verification testbench
│   └── test_lw_sw.v              # Simple memory access sanity testbench
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
1. Spins up an Ubuntu container.
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