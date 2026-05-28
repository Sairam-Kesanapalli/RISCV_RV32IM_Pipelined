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

```mermaid
%%{ init: { "theme": "base", "themeVariables": { "fontSize": "14px" } } }%%

flowchart TB

    %% ═══════════════════════════════════════════════════════════════════════════
    %% STAGE 1: INSTRUCTION FETCH (IF)
    %% ═══════════════════════════════════════════════════════════════════════════
    subgraph IF_STAGE ["🟦 STAGE 1 — INSTRUCTION FETCH (IF)"]
        direction LR
        PCMUX{"🔀 PC Mux\n─────────\n0: PC+4\n1: Target Addr"}
        PCREG["📌 PC Register\n(Sequential)"]
        PCADD["➕ PC + 4\nAdder"]
        IMEM[("💾 Instruction\nMemory\n(ROM + readmemh)")]
        HALT{"🛑 Halt\nDetect\n(instr === x)"}

        PCMUX --> PCREG
        PCREG -->|"addr[31:0]"| IMEM
        PCREG --> PCADD
        IMEM --> HALT
    end

    %% ── IF/ID Pipeline Register ─────────────────────────────────────────────
    IF_ID_REG["IF/ID Pipeline Register\nif_id_pc · if_id_instr · if_id_valid"]

    %% ═══════════════════════════════════════════════════════════════════════════
    %% STAGE 2: INSTRUCTION DECODE (ID)
    %% ═══════════════════════════════════════════════════════════════════════════
    subgraph ID_STAGE ["🟩 STAGE 2 — INSTRUCTION DECODE (ID)"]
        direction LR
        DECODE["🔍 Instruction\nField Decoder\n─────────\nopcode · rd · funct3\nrs1 · rs2 · funct7"]
        CU["⚙️ Control Unit\n(Combinational)\n─────────\nALUSrcA · ALUSrcB\nALU_OP · RegWrite\nMemRead · MemWrite\nMemToReg · Branch · Jump"]
        RF["📋 Register File\n(32 × 32-bit)\n─────────\nRead: rs1 → read_data1\nRead: rs2 → read_data2\nWrite: wb ← WB stage"]
        IMMGEN["🔢 Immediate\nGenerator\n─────────\nR / I / S / B\nU / J formats"]

        DECODE --> CU
        DECODE --> RF
        DECODE --> IMMGEN
    end

    %% ── ID/EX Pipeline Register ─────────────────────────────────────────────
    ID_EX_REG["ID/EX Pipeline Register\nid_ex_pc · read_data1/2 · imm · rd · rs1 · rs2\nfunct3 · funct7 · ALU_OP · ALUSrcA/B · control signals"]

    %% ═══════════════════════════════════════════════════════════════════════════
    %% STAGE 3: EXECUTE (EX)
    %% ═══════════════════════════════════════════════════════════════════════════
    subgraph EX_STAGE ["🟧 STAGE 3 — EXECUTE (EX)"]
        direction TB

        subgraph FWD_UNIT ["Forwarding Unit"]
            direction LR
            FWDA["forwardA\nMux Select\n(2-bit)"]
            FWDB["forwardB\nMux Select\n(2-bit)"]
        end

        subgraph EX_DATAPATH ["Execution Datapath"]
            direction TB
            MUXA{"🔀 MUX A\n─────────\n00: PC\n01: rs1 (fwd)\n10: zero"}
            MUXB{"🔀 MUX B\n─────────\n00: rs2 (fwd)\n01: 4\n10: imm"}
            ALU_CTRL["ALU Control\n─────────\nalu_op[3:0]\nis_mul_div\nmd_op[2:0]"]
            ALU["⚡ ALU\n(32-bit)\n─────────\nadd · sub · and\nor · xor · sll\nsrl · sra · slt"]
            MD["✖️ MUL / DIV\n(32-cycle Iterative)\n─────────\nMUL · MULH · MULHSU · MULHU\nDIV · DIVU · REM · REMU"]
            RESMUX{"🔀 Result Mux\n─────────\n0: alu_result\n1: mul_div_result"}

            MUXA --> ALU
            MUXB --> ALU
            MUXA --> MD
            MUXB --> MD
            ALU_CTRL -->|"alu_op"| ALU
            ALU_CTRL -->|"md_op + start"| MD
            ALU --> RESMUX
            MD -->|"done"| RESMUX
        end

        subgraph BRANCH_UNIT ["Branch Resolution"]
            direction LR
            BREVAL["🔱 Branch Evaluator\n─────────\nBEQ · BNE · BLT\nBGE · BLTU · BGEU"]
            TADD["📍 Target Adder\n─────────\nJAL/B: PC + imm\nJALR: rs1 + imm"]
        end

        subgraph BYTE_ALIGN ["Store Alignment"]
            STOREMUX["📦 Byte-Enable\nGenerator\n─────────\nSB → 1-byte en\nSH → 2-byte en\nSW → 4-byte en"]
        end

        FWD_UNIT --> MUXA
        FWD_UNIT --> MUXB
    end

    %% ── EX/MEM Pipeline Register ────────────────────────────────────────────
    EX_MEM_REG["EX/MEM Pipeline Register\nex_mem_alu_result · write_data · rd\nbyte_en · funct3 · MemRead/Write · RegWrite"]

    %% ═══════════════════════════════════════════════════════════════════════════
    %% STAGE 4: MEMORY ACCESS (MEM)
    %% ═══════════════════════════════════════════════════════════════════════════
    subgraph MEM_STAGE ["🟪 STAGE 4 — MEMORY ACCESS (MEM)"]
        direction LR
        DMEM[("💾 Data Memory\n(Byte-Addressable)\n─────────\nbyte_en[3:0]\nselective writes")]
        LOADALIGN["📦 Load Alignment\n& Sign Extension\n─────────\nLB · LBU · LH\nLHU · LW"]

        DMEM --> LOADALIGN
    end

    %% ── MEM/WB Pipeline Register ────────────────────────────────────────────
    MEM_WB_REG["MEM/WB Pipeline Register\nmem_wb_alu_result · read_data · rd\nfunct3 · MemToReg · RegWrite"]

    %% ═══════════════════════════════════════════════════════════════════════════
    %% STAGE 5: WRITE-BACK (WB)
    %% ═══════════════════════════════════════════════════════════════════════════
    subgraph WB_STAGE ["🟥 STAGE 5 — WRITE-BACK (WB)"]
        direction LR
        WBMUX{"🔀 WB Mux\n─────────\n0: alu_result\n1: mem_data"}
    end

    %% ═══════════════════════════════════════════════════════════════════════════
    %% HAZARD DETECTION UNIT (Spans across stages)
    %% ═══════════════════════════════════════════════════════════════════════════
    subgraph HDU ["🛡️ HAZARD DETECTION UNIT"]
        direction LR
        LOADUSE["Load-Use\nDetector\n─────────\nid_ex_MemRead &&\nid_ex_rd == rs1/rs2"]
        MDSTALL["MUL/DIV\nStall\n─────────\nis_mul_div &\n~done"]
        FLUSH_CTRL["Flush\nControl\n─────────\ntake_branch_or_jump"]
    end

    %% ═══════════════════════════════════════════════════════════════════════════
    %% MAIN PIPELINE FLOW (top-to-bottom through stages)
    %% ═══════════════════════════════════════════════════════════════════════════
    IF_STAGE ==> IF_ID_REG ==> ID_STAGE ==> ID_EX_REG ==> EX_STAGE ==> EX_MEM_REG ==> MEM_STAGE ==> MEM_WB_REG ==> WB_STAGE

    %% ═══════════════════════════════════════════════════════════════════════════
    %% BACKWARD DATA PATHS (Write-back, Forwarding, Branch resolution)
    %% ═══════════════════════════════════════════════════════════════════════════

    %% Write-back to Register File (WB → ID)
    WBMUX -.->|"wb_write_data\n→ register file"| RF

    %% PC Next selection (EX → IF)
    BREVAL -.->|"take_branch_or_jump"| PCMUX
    TADD -.->|"target_address"| PCMUX

    %% EX-to-EX Forwarding (EX/MEM → EX muxes)
    EX_MEM_REG -.->|"EX→EX fwd\nex_mem_alu_result"| FWDA
    EX_MEM_REG -.->|"EX→EX fwd\nex_mem_alu_result"| FWDB

    %% MEM-to-EX Forwarding (MEM/WB → EX muxes)
    MEM_WB_REG -.->|"MEM→EX fwd\nwb_write_data"| FWDA
    MEM_WB_REG -.->|"MEM→EX fwd\nwb_write_data"| FWDB

    %% ═══════════════════════════════════════════════════════════════════════════
    %% HAZARD CONTROL SIGNALS (Stall & Flush paths)
    %% ═══════════════════════════════════════════════════════════════════════════

    %% Pipeline stall freezes IF and ID stages
    LOADUSE -.->|"stall PC\n+ freeze IF/ID"| IF_ID_REG
    MDSTALL -.->|"stall pipeline\n(hold all regs)"| ID_EX_REG

    %% Flush injects NOPs into IF/ID and ID/EX
    FLUSH_CTRL -.->|"flush → NOP"| IF_ID_REG
    FLUSH_CTRL -.->|"flush → NOP"| ID_EX_REG

    %% ═══════════════════════════════════════════════════════════════════════════
    %% STYLING
    %% ═══════════════════════════════════════════════════════════════════════════
    classDef stageIF fill:#dbeafe,stroke:#2563eb,stroke-width:2px,color:#1e3a5f
    classDef stageID fill:#d1fae5,stroke:#059669,stroke-width:2px,color:#064e3b
    classDef stageEX fill:#fed7aa,stroke:#ea580c,stroke-width:2px,color:#7c2d12
    classDef stageMEM fill:#e9d5ff,stroke:#7c3aed,stroke-width:2px,color:#3b0764
    classDef stageWB fill:#fecaca,stroke:#dc2626,stroke-width:2px,color:#7f1d1d
    classDef pipeReg fill:#f1f5f9,stroke:#475569,stroke-width:3px,color:#0f172a,font-weight:bold
    classDef hazard fill:#fef3c7,stroke:#d97706,stroke-width:2px,color:#78350f

    class IF_STAGE stageIF
    class ID_STAGE stageID
    class EX_STAGE stageEX
    class MEM_STAGE stageMEM
    class WB_STAGE stageWB
    class IF_ID_REG,ID_EX_REG,EX_MEM_REG,MEM_WB_REG pipeReg
    class HDU hazard
```

> **Pipeline Register Key** — `IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB` are sequential edge-triggered registers that boundary-separate each stage and carry both datapath values and control signals downstream.

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