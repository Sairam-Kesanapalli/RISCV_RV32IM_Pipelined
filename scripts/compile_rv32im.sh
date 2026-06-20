#!/bin/bash
# Helper script to compile assembly/C files for RV32IM and run them on Spike and RTL
set -e

# Default values
ARCH="rv32im"
ABI="ilp32"
BASE_ADDR="0x80000000"

if [ -z "$1" ]; then
    echo "Usage: $0 <source_file.S | source_file.c> [num_instructions_to_run]"
    exit 1
fi

SRC_FILE="$1"
NUM_INSTRS="${2:-10}" # default to running 10 instructions
FILENAME=$(basename -- "$SRC_FILE")
EXTENSION="${FILENAME##*.}"
BASENAME="${FILENAME%.*}"
DIRNAME=$(dirname -- "$SRC_FILE")

ELF_FILE="$DIRNAME/$BASENAME.elf"
BIN_FILE="$DIRNAME/$BASENAME.bin"
HEX_FILE="$DIRNAME/$BASENAME.hex"
TRACE_FILE="$DIRNAME/$BASENAME.spike.log"

echo "=== [1/4] Compiling $SRC_FILE for RV32IM ==="
riscv64-unknown-elf-gcc -march=$ARCH -mabi=$ABI -nostdlib -Wl,-N -Ttext=$BASE_ADDR "$SRC_FILE" -o "$ELF_FILE"
echo "  Created ELF: $ELF_FILE"

echo "=== [2/4] Generating $BIN_FILE and $HEX_FILE for RTL ==="
riscv64-unknown-elf-objcopy -O binary --only-section=.text "$ELF_FILE" "$BIN_FILE"
hexdump -v -e '1/4 "%08x\n"' "$BIN_FILE" > "$HEX_FILE"
echo "  Created Binary: $BIN_FILE"
echo "  Created Hex (RTL format): $HEX_FILE"

echo "=== [3/4] Running on Spike ISA Simulator (stopping after $NUM_INSTRS instructions) ==="
# Locate spike
SPIKE_PATH="/home/madhav/spike/bin/spike"
if [ ! -f "$SPIKE_PATH" ]; then
    SPIKE_PATH=$(which spike || echo "spike")
fi

set +e
$SPIKE_PATH --isa=$ARCH --instructions=$NUM_INSTRS -l --pc=$BASE_ADDR "$ELF_FILE" > "$TRACE_FILE" 2>&1
set -e
echo "  Execution trace saved to: $TRACE_FILE"
echo "  --- Trace Output ---"
cat "$TRACE_FILE"

echo "=== [4/4] Setup complete ==="
echo "To run this on your RTL processor, copy $HEX_FILE to regression_tests/Svt_custom_tests/program.hex"
echo "and run: make svt"
