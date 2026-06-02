; ============================================================
;  graphics.asm - Graphics routines cho mode 13h
; ============================================================

; ------------------------------------------------------------
;  draw_rect - Vẽ rectangle
;  Input (qua memory):
;    rect_x     - tọa độ x (word)
;    rect_y     - tọa độ y (word)
;    rect_w     - chiều rộng (word)
;    rect_h     - chiều cao (word)
;    rect_color - màu (byte)
;  Output: vẽ ra VRAM (ES phải = 0xA000)
;  Clobber: AX, BX, CX, DX, DI
; ------------------------------------------------------------
draw_rect:
    push ax
    push bx
    push cx
    push dx
    push di

    ; Tính offset = y * 320 + x
    mov di, [rect_y]
    shl di, 6               ; di = y * 64
    mov bx, [rect_y]
    shl bx, 8               ; bx = y * 256
    add di, bx              ; di = y * 320
    add di, [rect_x]        ; di = y * 320 + x

    mov dx, [rect_h]        ; DX = số rows còn lại
    mov al, [rect_color]    ; AL = màu

.next_row:
    push di                 ; lưu vị trí đầu row
    mov cx, [rect_w]        ; CX = width

.next_pixel:
    mov [es:di], al         ; vẽ pixel
    inc di                  ; di++
    dec cx                  ; width--
    jnz .next_pixel         ; nếu width > 0 thì tiếp tục vẽ pixel

    pop di
    add di, 320             ; Move to the next row (320 bytes per row)
    dec dx
    jnz .next_row

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

rect_x:     dw 0
rect_y:     dw 0
rect_w:     dw 0
rect_h:     dw 0
rect_color: db 0