NASM = nasm
QEMU = qemu-system-i386

BOOT_SRC = src/boot/boot.asm
BOOT_BIN = bin/boot.bin

all: $(BOOT_BIN)

$(BOOT_BIN): $(BOOT_SRC) src/graphics.asm
	$(NASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN) -i src/

clean:
	rm -rf bin/*

debug: $(BOOT_BIN)
	$(QEMU) -drive file=$(BOOT_BIN),format=raw,if=floppy \
	        -s -S

run: $(BOOT_BIN)
	$(QEMU) -drive file=$(BOOT_BIN),format=raw,if=floppy \
			-monitor stdio \
	        -no-reboot

.PHONY: all run clean