#!/bin/bash
# Helper script to compile assembly/C files for RV32IM
set -e

# Default values
ARCH="rv32im"
ABI="ilp32"
BASE_ADDR="0x80000000"

if [ -z "$1" ]; then
    echo "Usage: $0 <source_file.S | source_file.c>"
    exit 1
fi

SRC_FILE="$1"
FILENAME=$(basename -- "$SRC_FILE")
EXTENSION="${FILENAME##*.}"
BASENAME="${FILENAME%.*}"
DIRNAME=$(dirname -- "$SRC_FILE")

ELF_FILE="$DIRNAME/$BASENAME.elf"
BIN_FILE="$DIRNAME/$BASENAME.bin"
HEX_FILE="$DIRNAME/$BASENAME.hex"

echo "=== [1/3] Compiling $SRC_FILE for RV32IM ==="
riscv64-unknown-elf-gcc -march=$ARCH -mabi=$ABI -nostdlib -Wl,-N -Ttext=$BASE_ADDR "$SRC_FILE" -o "$ELF_FILE"
echo "  Created ELF: $ELF_FILE"

echo "=== [2/3] Generating $BIN_FILE and $HEX_FILE for RTL ==="
riscv64-unknown-elf-objcopy -O binary --only-section=.text "$ELF_FILE" "$BIN_FILE"
hexdump -v -e '1/4 "%08x\n"' "$BIN_FILE" > "$HEX_FILE"
echo "  Created Binary: $BIN_FILE"
echo "  Created Hex (RTL format): $HEX_FILE"

echo "=== [3/3] Setup complete ==="
echo "To run this on your RTL processor, copy $HEX_FILE to regression_tests/Svt_custom_tests/program.hex"
echo "and run: make svt"
