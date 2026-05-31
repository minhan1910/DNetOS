[ORG 0]
[BITS 16]

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

    mov si, message
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

message: db 'Hello, World!', 0
    
times 510 - ($ - $$) db 0

dw 0xAA55