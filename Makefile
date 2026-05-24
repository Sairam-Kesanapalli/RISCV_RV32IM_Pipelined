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
TB_MAIN 	= $(TB_DIR)/rv32im_tb.v
TB_DEBUG 	= $(TB_DIR)/test_lw_sw.v
TB_ALU 		= src/alu/tb/ALU_n_bit_tb.v
TB_MUL_DIV  = src/alu/tb/mul_div_tb.v
TB_CTRL     = src/core/tb/control_unit_tb.v
TB_REG      = src/core/tb/register_tb.v
TB_IMM_GEN  = src/core/tb/imm_gen_tb.v

# Output binaries
OUT_MAIN 	= rv32im_sim
OUT_DEBUG 	= debug_sim
OUT_SVT 	= svt_sim
OUT_ALU 	= alu_sim
OUT_MUL_DIV = mul_div_sim
OUT_CTRL    = control_sim
OUT_REG     = register_sim
OUT_IMM_GEN = imm_gen_sim

.PHONY: all compile sim clean debug svt svt_golden wave wave-svt alu_test wave-alu mul_div_test wave-mul_div control_test wave-control_unit register_test wave-register imm_gen_test wave-imm_gen

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

# Open GTKWave waveforms
wave:
	gtkwave RV32IM_verification.vcd &

wave-svt:
	gtkwave SVT_verification.vcd &

# Compile and run ALU testbench
alu_test:
	$(CC) $(CFLAGS) -o $(OUT_ALU) $(TB_ALU) src/alu/ALU_n_bit.v src/alu/full_adder_n_bit.v
	$(SIM) $(OUT_ALU)

# Open ALU GTKWave waveform
wave-alu:
	gtkwave wave.vcd &

# Compile and run MUL_DIV testbench
mul_div_test:
	$(CC) $(CFLAGS) -o $(OUT_MUL_DIV) $(TB_MUL_DIV) src/alu/mul_div.v 
	$(SIM) $(OUT_MUL_DIV)

# Open MUL_DIV GTKWave waveform
wave-mul_div:
	gtkwave mul_div.vcd &

# Compile and run Control Unit testbench
control_test:
	$(CC) $(CFLAGS) -o $(OUT_CTRL) $(TB_CTRL) src/core/control_unit.v
	$(SIM) $(OUT_CTRL)

# Open CONTROL_UNIT GTKWave waveform
wave-control_unit:
	gtkwave control_unit.vcd &

# Compile and run Register File testbench
register_test:
	$(CC) $(CFLAGS) -o $(OUT_REG) $(TB_REG) src/core/register.v
	$(SIM) $(OUT_REG)

# Open REGISTER GTKWave waveform
wave-register:
	gtkwave register.vcd &

# Compile and run Immediate Generator testbench
imm_gen_test:
	$(CC) $(CFLAGS) -o $(OUT_IMM_GEN) $(TB_IMM_GEN) src/core/imm_gen.v
	$(SIM) $(OUT_IMM_GEN)

# Open Immediate Generator GTKWave waveform
wave-imm_gen:
	gtkwave imm_gen.vcd &

# Clean up generated files
clean:
	rm -f $(OUT_MAIN) $(OUT_DEBUG) $(OUT_SVT) $(OUT_ALU) $(OUT_MUL_DIV) $(OUT_CTRL) $(OUT_REG) $(OUT_IMM_GEN) golden_sim *.vcd tb/expected_*.hex regression_tests/*/expected_*.hex


