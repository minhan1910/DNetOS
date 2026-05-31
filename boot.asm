[ORG 0]
[BITS 16]

; For booting of real computer and we need to setup BPL (BIOS Parameter Block) for the bootloader, but for the sake of simplicity, we will skip that part and directly jump to the code.
_start:
    jmp short start
    nop

times 33 db 0

start:
    jmp 0x7c0:step2

step2:
    ; Setup segment registers
    cli
    mov ax, 0x7c0
    mov ds, ax
    mov es, ax
    mov ax, 0x00
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov ah, 2 ; read section command
    mov al, 1 ; number of sectors to read
    mov ch, 0 ; cylinder number
    mov cl, 2 ; sector number (starting from 1)
    mov dh, 0 ; head number
    mov bx, buffer ; buffer to store the read data
    int 0x13 ; call BIOS interrupt to read sector
    jc load_error ; if carry flag is set, there was an error

    mov si, buffer
    call print

    jmp $

load_error:
    mov si, error_message
    call print
    jmp $

print:
    lodsb ; Load byte at [si] into al and increment si
    cmp al, 0
    je done
    call print_char
    jmp print
done:
    ret

print_char:
    mov ah, 0x0e
    mov bx, 0
    int 0x10
    ret

error_message: db 'Failed to load sector!', 0
    
times 510 - ($ - $$) db 0

dw 0xAA55

buffer: