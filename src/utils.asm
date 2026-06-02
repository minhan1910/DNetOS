
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