BIOS_DIR    := src/arch/x86_64/bios
CPU_DIR     := src/arch/x86_64/cpu
KERNEL_DIR  := src/kernel
DRIVERS_DIR := src/drivers

CFLAGS := -m64 -ffreestanding -fno-pie -nostdlib -nostdinc \
          -mno-red-zone -fno-stack-protector \
          -I $(KERNEL_DIR) -I $(CPU_DIR) -I $(DRIVERS_DIR)

LINKER := src/arch/x86_64/linker.ld

BUILD     := build
OBJ_DIR   := $(BUILD)/obj
BIN_DIR   := $(BUILD)/bin

BIOS_SRCS := $(wildcard $(BIOS_DIR)/*.asm)
BIOS_BINS := $(patsubst $(BIOS_DIR)/%.asm, $(BIN_DIR)/%.bin, $(BIOS_SRCS))

C_SRCS    := $(wildcard $(KERNEL_DIR)/*.c $(DRIVERS_DIR)/*.c $(CPU_DIR)/*.c)
C_OBJS    := $(patsubst %.c, $(OBJ_DIR)/%.o, $(notdir $(C_SRCS)))

ASM_SRCS  := $(wildcard $(CPU_DIR)/*.asm)
ASM_OBJS  := $(patsubst $(CPU_DIR)/%.asm, $(OBJ_DIR)/%_asm.o, $(ASM_SRCS))

ALL_OBJS  := $(C_OBJS) $(ASM_OBJS)

vpath %.c   $(KERNEL_DIR) $(DRIVERS_DIR) $(CPU_DIR)
vpath %.asm $(CPU_DIR)

all: $(BUILD)/os.bin

$(OBJ_DIR) $(BIN_DIR):
	mkdir -p $@

$(BIOS_BINS): $(BIN_DIR)/%.bin: $(BIOS_DIR)/%.asm | $(BIN_DIR)
	nasm -f bin $< -o $@

$(C_OBJS): $(OBJ_DIR)/%.o: %.c | $(OBJ_DIR)
	gcc $(CFLAGS) -c $< -o $@

$(ASM_OBJS): $(OBJ_DIR)/%_asm.o: %.asm | $(OBJ_DIR)
	nasm -f elf64 $< -o $@

$(BIN_DIR)/kernel.bin: $(ALL_OBJS) | $(BIN_DIR)
	ld -m elf_x86_64 -T $(LINKER) --oformat binary -o $@ $^

$(BUILD)/os.bin: $(BIOS_BINS) $(BIN_DIR)/kernel.bin
	cat $(BIOS_BINS) $(BIN_DIR)/kernel.bin > $@
	truncate -s 32K $@

run: $(BUILD)/os.bin
	qemu-system-x86_64 -drive format=raw,file=$(BUILD)/os.bin,index=0,media=disk -boot c

clean:
	rm -rf $(BUILD)

.PHONY: all run clean