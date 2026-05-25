all: os.bin

build/boot.bin: src/boot/boot.asm
	nasm -f bin src/boot/boot.asm -o build/boot.bin

build/stage2.bin: src/boot/stage2.asm
	nasm -f bin src/boot/stage2.asm -o build/stage2.bin

build/stage3.bin: src/boot/stage3.asm
	nasm -f bin src/boot/stage3.asm -o build/stage3.bin

build/kernel.bin: src/kernel/kernel.c src/kernel/gdt.c src/kernel/gdt.asm src/kernel/vga.c linker.ld
	nasm -f elf64 src/kernel/gdt.asm -o build/gdt_asm.o
	gcc -m64 -ffreestanding -fno-pie -nostdlib -nostdinc -mno-red-zone -fno-stack-protector -I src/kernel -c src/kernel/kernel.c -o build/kernel.o
	gcc -m64 -ffreestanding -fno-pie -nostdlib -nostdinc -mno-red-zone -fno-stack-protector -I src/kernel -c src/kernel/gdt.c -o build/gdt.o
	gcc -m64 -ffreestanding -fno-pie -nostdlib -nostdinc -mno-red-zone -fno-stack-protector -I src/kernel -c src/kernel/vga.c -o build/vga.o
	ld -m elf_x86_64 -T linker.ld --oformat binary -o build/kernel.bin build/kernel.o build/vga.o build/gdt.o build/gdt_asm.o

os.bin: build/boot.bin build/stage2.bin build/stage3.bin build/kernel.bin
	cat build/boot.bin build/stage2.bin build/stage3.bin build/kernel.bin > build/os.bin
	truncate -s 32K build/os.bin

run: os.bin
	qemu-system-x86_64 -drive format=raw,file=build/os.bin,index=0,media=disk -boot c

clean:
	rm -f build/*.bin build/*.o

.PHONY: all run clean