# RISC-V RV32IM Processor Makefile

# Compiler
CC = iverilog
# Simulation
SIM = vvp

# Flags
CFLAGS = -g2012 -Wall

# Source directories
SRC_CORE = src/core
SRC_ALU = src/alu
SRC_MEM = src/memory
TB_DIR = tb

# Source files
SOURCES = $(SRC_CORE)/rv32im_pipelined.v \
          $(SRC_CORE)/control_unit.v \
          $(SRC_CORE)/alu_control.v \
          $(SRC_CORE)/imm_gen.v \
          $(SRC_CORE)/register.v \
          $(SRC_ALU)/ALU_n_bit.v \
          $(SRC_ALU)/full_adder_n_bit.v \
          $(SRC_ALU)/mul_div.v \
          $(SRC_MEM)/instruction_mem.v \
          $(SRC_MEM)/data_mem.v

# Testbenches
TB_MAIN = $(TB_DIR)/rv32im_tb.v
TB_DEBUG = $(TB_DIR)/test_lw_sw.v

# Output binaries
OUT_MAIN = rv32im_sim
OUT_DEBUG = debug_sim
OUT_SVT = svt_sim

.PHONY: all compile sim clean debug svt svt_golden

all: compile sim

# Compile the main testbench
compile:
	$(CC) $(CFLAGS) -o $(OUT_MAIN) $(TB_MAIN) $(SOURCES)

# Run the main simulation
sim: compile
	$(SIM) $(OUT_MAIN)

# Compile and run the debug testbench
debug:
	$(CC) $(CFLAGS) -o $(OUT_DEBUG) $(TB_DEBUG) $(SOURCES)
	$(SIM) $(OUT_DEBUG)

# Generate golden hex files from Python ISS
svt_golden:
	python3 scripts/golden_model.py

# Compile and run Software Verification Testbench
svt: svt_golden
	$(CC) $(CFLAGS) -o $(OUT_SVT) tb/svt_tb.v $(SOURCES)
	$(SIM) $(OUT_SVT)

# Regression Framework
regression:
	@echo "======================================================="
	@echo "              RUNNING REGRESSION SUITE                 "
	@echo "======================================================="
	@$(CC) $(CFLAGS) -o $(OUT_SVT) tb/svt_tb.v $(SOURCES)
	@failed=0; \
	for test_dir in regression_tests/* ; do \
		if [ -d "$$test_dir" ]; then \
			echo "Running $$test_dir..."; \
			python3 scripts/golden_model.py --test-dir "$$test_dir" > /dev/null; \
			if $(SIM) $(OUT_SVT) +TEST_DIR="$$test_dir" | grep -q "\[SVT PASS\]"; then \
				echo "[PASS] $$(basename $$test_dir)"; \
			else \
				echo "[FAIL] $$(basename $$test_dir)"; \
				failed=1; \
			fi; \
		fi \
	done; \
	echo "======================================================="; \
	exit $$failed

# Clean up generated files
clean:
	rm -f $(OUT_MAIN) $(OUT_DEBUG) $(OUT_SVT) golden_sim *.vcd tb/expected_*.hex regression_tests/*/expected_*.hex
