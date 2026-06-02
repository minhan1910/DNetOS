[ORG 0]
[BITS 16]

%include "src/constants.asm"

; No BPB: we boot under QEMU floppy, so we skip the BIOS Parameter Block
; entirely and jump straight to code to save room in the 512-byte sector.
start:
    jmp 0x7c0:step2

step2:
    ; Setup segment registers. No CLI needed: `mov ss` carries a hardware
    ; interrupt-shadow that makes the ss:sp load atomic on its own.
    mov ax, 0x7c0
    mov ds, ax
    ; mov es, ax
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    ; Set video mode
    mov ax, VIDEO_MODE_13H ; Set video mode 13h (320x200, 256 colors)
    int BIOS_VIDEO

    mov ax, VGA_SEGMENT
    mov es,ax
    
; ============================================================
;  GAME LOOP
; ============================================================
game_loop:
    ; --- Erase old positions ---
    mov cl, COLOR_BLACK
    mov ax, PADDLE_LEFT_X
    mov bx, paddle_left_y
    call draw_paddle
    mov ax, PADDLE_RIGHT_X
    mov bx, paddle_right_y
    call draw_paddle

    call draw_ball              ; cl still = COLOR_BLACK (draw_rect preserves cx)

    ; --- Update game state ---
    call read_input
    call update_ball

   ; --- Draw new positions ---
    mov cl, COLOR_WHITE
    mov ax, PADDLE_LEFT_X
    mov bx, paddle_left_y
    call draw_paddle
    mov ax, PADDLE_RIGHT_X
    mov bx, paddle_right_y
    call draw_paddle
    call draw_ball              ; cl still = COLOR_WHITE (draw_rect preserves cx)

    call delay

    jmp game_loop

; ============================================================
;  draw_paddle - AX=x, BX=&paddle_y, CL=color
; ============================================================
draw_paddle:
    mov [rect_x], ax
    mov ax, [bx]
    mov [rect_y], ax
    mov word [rect_w], PADDLE_WIDTH
    mov word [rect_h], PADDLE_HEIGHT
    mov [rect_color], cl
    call draw_rect
    ret

; ============================================================
;  draw_ball - CL=color
; ============================================================
draw_ball:
    mov ax, [ball_x]
    mov [rect_x], ax
    mov ax, [ball_y]
    mov [rect_y], ax
    mov word [rect_w], BALL_W
    mov word [rect_h], BALL_H
    mov [rect_color], cl
    call draw_rect
    ret

; ============================================================
;  read_input - đọc keyboard, cập nhật paddle_*_y
; ============================================================
read_input:
    ; Check có phím nào trong buffer không
    mov ah, 0x01
    int BIOS_KEYBOARD
    jz .done                    ; không có phím → thoát

    ; Có phím → đọc và remove khỏi buffer
    mov ah, 0x00
    int BIOS_KEYBOARD
    ; AH = scancode

    cmp ah, KEY_W                ; W → paddle trái lên
    je .left_up
    cmp ah, KEY_S                ; S → paddle trái xuống
    je .left_down
    cmp ah, KEY_UP                ; ↑ → paddle phải lên
    je .right_up
    cmp ah, KEY_DOWN                ; ↓ → paddle phải xuống
    je .right_down
    jmp .done

.left_up:
    sub word [paddle_left_y], PADDLE_SPEED
    jmp .done
.left_down:
    add word [paddle_left_y], PADDLE_SPEED
    jmp .done
.right_up:
    sub word [paddle_right_y], PADDLE_SPEED
    jmp .done
.right_down:
    add word [paddle_right_y], PADDLE_SPEED
.done:
    ret

; ============================================================
;  delay - đợi một chút bằng vòng lặp rỗng
; ============================================================
delay:
    mov dx, 0x0020              ; outer-loop count — larger = slower game
.outer:
    mov cx, 0xFFFF
.inner:
    dec cx
    jnz .inner
    dec dx
    jnz .outer
    ret

; ============================================================
;  update_ball - move ball, bounce off walls + paddles
; ============================================================
update_ball:
    ; --- Move ball ---
    mov ax, [ball_dx]
    add [ball_x], ax
    mov ax, [ball_dy]
    add [ball_y], ax

.check_top:
    ; --- Top wall: ball_y <= 0 → bounce down ---
    cmp word [ball_y], 0
    jg .check_bottom
    neg word [ball_dy]
    mov word [ball_y], 0

.check_bottom:
    ; --- Bottom wall: ball_y >= SCREEN_HEIGHT - BALL_H → bounce up ---
    cmp word [ball_y], SCREEN_HEIGHT - BALL_H
    jl .check_left_paddle
    neg word [ball_dy]
    mov word [ball_y], SCREEN_HEIGHT - BALL_H

; ------------------------------------------------------------
;  Left paddle collision
;  Only when ball is moving LEFT (dx < 0) — prevents sticking
; ------------------------------------------------------------
.check_left_paddle:
    ; only test the LEFT paddle if moving LEFT
    cmp word [ball_dx], 0
    jge .check_right_paddle              ; moving right, skip

    ; X overlap: ball_x <= PADDLE_LEFT_X + PADDLE_W ?
    mov ax, [ball_x]
    cmp ax, PADDLE_LEFT_X + PADDLE_WIDTH
    jg .check_right_paddle               ; ball past paddle's right edge

    ; Y overlap: ball.bottom > paddle.top AND ball.top < paddle.bottom
    mov ax, [ball_y]
    add ax, BALL_H                       ; ax = ball.bottom
    cmp ax, [paddle_left_y]
    jle .check_right_paddle              ; ball above paddle

    mov ax, [paddle_left_y]
    add ax, PADDLE_HEIGHT                ; ax = paddle.bottom
    cmp [ball_y], ax
    jge .check_right_paddle              ; ball below paddle

    ; HIT — bounce and push out of paddle
    neg word [ball_dx]
    mov word [ball_x], PADDLE_LEFT_X + PADDLE_WIDTH
    jmp .check_score

; ------------------------------------------------------------
;  Right paddle collision
;  Only when ball is moving RIGHT (dx > 0)
; ------------------------------------------------------------
.check_right_paddle:
    cmp word [ball_dx], 0
    jle .check_score                     ; moving left, skip

    ; X overlap: ball_x + BALL_W >= PADDLE_RIGHT_X ?
    mov ax, [ball_x]
    add ax, BALL_W
    cmp ax, PADDLE_RIGHT_X
    jl .check_score                      ; ball before paddle

    ; Y overlap
    mov ax, [ball_y]
    add ax, BALL_H
    cmp ax, [paddle_right_y]
    jle .check_score

    mov ax, [paddle_right_y]
    add ax, PADDLE_HEIGHT
    cmp [ball_y], ax
    jge .check_score

    ; HIT
    neg word [ball_dx]
    mov word [ball_x], PADDLE_RIGHT_X - BALL_W

; ------------------------------------------------------------
;  Score check: ball left the field → reset to center
; ------------------------------------------------------------
.check_score:
    cmp word [ball_x], 0
    jl .reset
    mov ax, [ball_x]
    add ax, BALL_W
    cmp ax, SCREEN_WIDTH
    jg .reset
    ret

.reset:
    mov word [ball_x],  BALL_START_X
    mov word [ball_y],  BALL_START_Y
    ; Optionally flip dx so it serves toward whoever scored against
    neg word [ball_dx]
    ret

; ============================================================
;  Game State - lưu vị trí của paddle trái và phải (y coordinate)
; ============================================================
paddle_left_y:   dw 80
paddle_right_y:  dw 80
ball_x:   dw BALL_START_X
ball_y:   dw BALL_START_Y
ball_dx:  dw 1            ; +1 = moving right, -1 = moving left
ball_dy:  dw 1            ; +1 = moving down,  -1 = moving up

%include "src/graphics.asm"

times 510 - ($ - $$) db 0

dw 0xAA55