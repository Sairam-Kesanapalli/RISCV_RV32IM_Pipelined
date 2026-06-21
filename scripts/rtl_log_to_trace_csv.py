#!/usr/bin/env python3
"""
Convert RTL simulation trace log to standard RISCV-DV instruction trace
format (CSV) for comparison against Spike traces.

This parser reads the ALWAYS lines emitted by svt_tb.v during WB-stage
retirement and produces a CSV in the same schema used by riscv-dv's
instr_trace_compare.py.

Usage:
    python3 scripts/rtl_log_to_trace_csv.py --log rtl_trace.log --csv rtl.csv
"""

import argparse
import csv
import re
import sys

def gpr_to_abi(gpr):
    """Convert general purpose register numeric code to ABI name"""
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

def parse_rtl_log(log_path, csv_path):
    # Regex to match the ALWAYS line inside each CYCLE block:
    #   ALWAYS: pc=0x00000000 instr=0x003100b3 rd_addr=x1 rd_wdata=0x00000000 rf_wen=1 pc_next=0x00000004
    always_re = re.compile(
        r"^\s*ALWAYS:\s+pc=0x(?P<pc>[a-f0-9]+)\s+instr=0x(?P<instr>[a-f0-9]+)\s+rd_addr=x(?P<rd>\d+)\s+rd_wdata=0x(?P<wdata>[a-f0-9]+)\s+rf_wen=(?P<rf_wen>[01])\s+pc_next=0x(?P<pc_next>[a-f0-9]+)"
    )

    with open(log_path, "r") as f_in, open(csv_path, "w", newline="") as f_out:
        fields = ["pc", "instr", "gpr", "csr", "binary", "mode", "instr_str", "operand", "pad"]
        writer = csv.DictWriter(f_out, fieldnames=fields)
        writer.writeheader()

        for line in f_in:
            match = always_re.match(line)
            if match:
                pc = match.group("pc")
                instr_hex = match.group("instr")
                rd_num = int(match.group("rd"))
                wdata = match.group("wdata")
                rf_wen = int(match.group("rf_wen"))

                gpr_list = []
                # Only record GPR updates if register write enable is active and destination is not x0
                if rf_wen == 1 and rd_num != 0:
                    abi_name = gpr_to_abi(f"x{rd_num}")
                    gpr_list.append(f"{abi_name}:{wdata}")

                writer.writerow({
                    "pc": pc.lower(),
                    "instr": "",       # Optional for basic GPR comparison
                    "gpr": ";".join(gpr_list),
                    "csr": "",
                    "binary": instr_hex.lower(),
                    "mode": "3",       # Default Machine Mode privilege (3) to match Spike defaults
                    "instr_str": "",   # Optional
                    "operand": ""      # Optional
                })

def main():
    parser = argparse.ArgumentParser(description="Convert RTL log to RISCV-DV trace CSV")
    parser.add_argument("--log", required=True, help="Input RTL trace log file")
    parser.add_argument("--csv", required=True, help="Output trace CSV file")
    args = parser.parse_args()

    parse_rtl_log(args.log, args.csv)
    print(f"Successfully converted RTL trace log {args.log} to CSV {args.csv}")

if __name__ == "__main__":
    main()
