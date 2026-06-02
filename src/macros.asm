; Vẽ rectangle với y là constant
%macro DRAW_RECT 5
    mov word [rect_x], %1
    mov word [rect_y], %2
    mov word [rect_w], %3
    mov word [rect_h], %4
    mov byte [rect_color], %5
    call draw_rect
%endmacro

; ; Vẽ paddle (y đọc từ memory)
; %macro DRAW_PADDLE 3   ; x, y_var, color
;     mov ax, [%2]
;     mov word [rect_x], %1
;     mov [rect_y], ax
;     mov word [rect_w], PADDLE_WIDTH
;     mov word [rect_h], PADDLE_HEIGHT
;     mov byte [rect_color], %3
;     call draw_rect
; %endmacro

; %macro DRAW_BALL 1
;     mov ax, [ball_x]
;     mov [rect_x], ax
;     mov ax, [ball_y]
;     mov [rect_y], ax
;     mov word [rect_w], BALL_W
;     mov word [rect_h], BALL_H
;     mov byte [rect_color], %1
;     call draw_rect
; %endmacro