
; ============================================================
;  constants.asm - Game constants
; ============================================================

BALL_W          EQU 4
BALL_H          EQU 4
BALL_START_X    EQU 158
BALL_START_Y    EQU 98

; ----- Screen (Mode 13h) -----
SCREEN_WIDTH    equ 320
SCREEN_HEIGHT   equ 200

; ----- Colors (VGA Mode 13h palette) -----
COLOR_BLACK     equ 0
COLOR_BLUE      equ 1
COLOR_GREEN     equ 2
COLOR_RED       equ 4
COLOR_GRAY      equ 8
COLOR_YELLOW    equ 14
COLOR_WHITE     equ 15

; ----- Paddle -----
PADDLE_WIDTH    equ 4
PADDLE_HEIGHT   equ 40
PADDLE_SPEED    equ 4

PADDLE_LEFT_X   equ 20
PADDLE_RIGHT_X  equ 296          ; SCREEN_WIDTH - PADDLE_WIDTH - 20

; ----- Paddle bounds (không cho paddle ra khỏi màn hình) -----
PADDLE_MIN_Y    equ 0
PADDLE_MAX_Y    equ SCREEN_HEIGHT - PADDLE_HEIGHT   ; = 160

; ----- Ball -----
BALL_SIZE       equ 4
BALL_START_X    equ 158
BALL_START_Y    equ 98

; ----- Center line -----
CENTER_LINE_X   equ 158          ; SCREEN_WIDTH/2 - 2
CENTER_LINE_W   equ 4

; ----- Keyboard scancodes -----
KEY_W           equ 0x11
KEY_S           equ 0x1F
KEY_A           equ 0x1E
KEY_D           equ 0x20
KEY_UP          equ 0x48
KEY_DOWN        equ 0x50
KEY_LEFT        equ 0x4B
KEY_RIGHT       equ 0x4D
KEY_SPACE       equ 0x39
KEY_ESC         equ 0x01
KEY_ENTER       equ 0x1C

; ----- BIOS interrupts -----
BIOS_VIDEO      equ 0x10
BIOS_KEYBOARD   equ 0x16

; ----- VGA memory segment -----
VGA_SEGMENT     equ 0xA000

; ----- Video modes -----
VIDEO_MODE_13H  equ 0x0013