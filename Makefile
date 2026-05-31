all:
	nasm -f bin ./boot.asm -o boot.bin
	dd if=./message.txt >> ./boot.bin
	dd if=/dev/zero bs=512 count=1 >> ./boot.bin

run: 
	qemu-system-x86_64 -drive format=raw,file=boot.bin