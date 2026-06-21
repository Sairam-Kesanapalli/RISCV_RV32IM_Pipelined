#!/usr/bin/env python3
"""
Convert Spike ISA simulator commit log to standard RISCV-DV instruction trace
format (CSV) for comparison against RTL traces.

This is a LOCAL, project-specific parser. The upstream riscv-dv file
(riscv-dv/scripts/spike_log_to_trace_csv.py) is left UNMODIFIED.

Why a local parser?
  - The upstream parser expects a boot-ROM trampoline (starting at 0x1000) that
    our bare-metal tests do not have.
  - Spike's default RAM base is 0x80000000, but our RTL starts at PC=0.
    We subtract --base from PC values so the traces align.
  - Register write-back values are left UNTOUCHED — test programs should be
    written to avoid address-dependent register values (use relative branches,
    avoid storing PC-derived values that will be compared).

Usage:
    python3 scripts/spike_log_to_trace_csv.py --log spike.log --csv spike.csv
                                               [--base 0x80000000]
"""

import argparse
import csv
import re
import sys


# ---------------------------------------------------------------------------
# Regexes matching Spike's -l --log-commits output
# ---------------------------------------------------------------------------
# Instruction line (disassembly):
#   core   0: 0x80000000 (0x00f00093) li      ra, 15
INSTR_RE = re.compile(
    r"core\s+\d+:\s+0x(?P<pc>[a-f0-9]+)\s+"
    r"\(0x(?P<bin>[a-f0-9]+)\)\s+"
    r"(?P<disasm>.+)$"
)

# Commit / register-writeback line:
#   core   0: 3 0x80000000 (0x00f00093) x1  0x0000000f
RD_RE = re.compile(
    r"(core\s+\d+:\s+)?(?P<pri>\d)\s+0x(?P<addr>[a-f0-9]+)\s+"
    r"\(0x(?P<bin>[a-f0-9]+)\)\s+"
    r"(?P<reg>[xf]\s*\d+)\s+0x(?P<val>[a-f0-9]+)"
)


# ---------------------------------------------------------------------------
# ABI name lookup
# ---------------------------------------------------------------------------
def gpr_to_abi(gpr):
    """Convert xN register name to ABI name (e.g. x1 -> ra)."""
    switcher = {
        "x0" : "zero", "x1" : "ra", "x2" : "sp", "x3" : "gp", "x4" : "tp",
        "x5" : "t0",   "x6" : "t1", "x7" : "t2", "x8" : "s0", "x9" : "s1",
        "x10": "a0",   "x11": "a1", "x12": "a2", "x13": "a3", "x14": "a4",
        "x15": "a5",   "x16": "a6", "x17": "a7", "x18": "s2", "x19": "s3",
        "x20": "s4",   "x21": "s5", "x22": "s6", "x23": "s7", "x24": "s8",
        "x25": "s9",   "x26": "s10","x27": "s11","x28": "t3", "x29": "t4",
        "x30": "t5",   "x31": "t6"
    }
    return switcher.get(gpr, gpr)


# ---------------------------------------------------------------------------
# Main parser
# ---------------------------------------------------------------------------
def parse_spike_log(log_path, csv_path, base=0x80000000):
    """Parse a Spike commit log and emit a RISCV-DV compatible trace CSV.

    The --base offset is subtracted ONLY from PC values (which are always code
    addresses). Register writeback values are emitted verbatim — the test
    assembly must be written so that register values are identical in both
    environments (i.e. avoid storing absolute code addresses into registers
    that will be compared).
    """

    with open(log_path, "r") as f_in, open(csv_path, "w", newline="") as f_out:
        fields = ["pc", "instr", "gpr", "csr", "binary", "mode",
                  "instr_str", "operand", "pad"]
        writer = csv.DictWriter(f_out, fieldnames=fields)
        writer.writeheader()

        pending = None          # instruction waiting for its commit line

        for line in f_in:
            # Skip non-core lines (warnings, ISA banner, etc.)
            instr_match = INSTR_RE.match(line)
            if instr_match:
                # If we already have a pending instruction without commit data,
                # flush it (branch / store with no rd writeback).
                if pending is not None:
                    writer.writerow(pending)

                # Normalise PC: subtract base address
                pc_int = int(instr_match.group("pc"), 16) - base
                pc_hex = format(pc_int & 0xFFFFFFFF, '08x')

                pending = {
                    "pc":        pc_hex,
                    "instr":     "",
                    "gpr":       "",
                    "csr":       "",
                    "binary":    instr_match.group("bin"),
                    "mode":      "3",
                    "instr_str": "",
                    "operand":   "",
                }
                continue

            # Commit line (register writeback)
            rd_match = RD_RE.match(line)
            if rd_match and pending is not None:
                reg = rd_match.group("reg").replace(" ", "")
                val_str = rd_match.group("val")
                val_int = int(val_str, 16)
                
                # Fix PC-relative writebacks (JAL, JALR, AUIPC)
                # These instructions store PC-derived addresses into registers.
                # We subtract the base offset so they match the RTL traces.
                binary = int(pending["binary"], 16)
                opcode = binary & 0x7F
                if opcode in (0x6F, 0x67, 0x17): # JAL (0x6F), JALR (0x67), AUIPC (0x17)
                    val_int = (val_int - base) & 0xFFFFFFFF
                    val_str = format(val_int, '08x')
                    
                abi = gpr_to_abi(reg)
                if reg != "x0":
                    pending["gpr"] = f"{abi}:{val_str}"
                continue

            # Exception/trap lines — discard the pending instruction
            if "exception" in line or "trap" in line:
                pending = None
                continue

        # Flush last pending instruction
        if pending is not None:
            writer.writerow(pending)


def main():
    parser = argparse.ArgumentParser(
        description="Convert Spike commit log to RISCV-DV trace CSV (local)")
    parser.add_argument("--log", required=True,
                        help="Input Spike simulation log")
    parser.add_argument("--csv", required=True,
                        help="Output trace CSV file")
    parser.add_argument("--base", type=lambda x: int(x, 0), default=0x80000000,
                        help="Spike RAM base address to subtract from PCs "
                             "(default: 0x80000000). Set to 0 to disable.")
    args = parser.parse_args()
    parse_spike_log(args.log, args.csv, args.base)
    print(f"Successfully converted Spike log {args.log} to CSV {args.csv}")


if __name__ == "__main__":
    main()
