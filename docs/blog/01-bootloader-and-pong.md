# Part 1 — The Bootloader

This series builds a small operating system from scratch. Before we can talk about
kernels and threads, we have to answer a more basic question: how does a computer go
from powered-off to running our own code? That is the job of the bootloader, and it is
where this first post lives.

The goal for this post is concrete: understand the boot process, then write a bootloader
that the BIOS loads and runs, and have it print "Hello, World!" to the screen. Once that
works, we have a foothold — a place where our own code runs on a bare machine — and
everything later in the series builds on it.

By the end you should understand:

- What happens between pressing power and your code running
- What real mode is, and why memory addressing works the way it does
- How the BIOS finds and loads a boot sector
- How to write, assemble, and boot a minimal bootloader that prints text

---

## 1. What happens when you press the power button

When a PC powers on, the CPU doesn't know about your operating system or your files. It
only knows to start executing firmware code from a fixed location. From there, control
passes through a sequence of stages:

```
  Power on  ->  BIOS (POST)  ->  Boot sector (512 bytes)  ->  Bootloader  ->  Kernel
```

### The CPU wakes up

The processor starts in a 16-bit compatibility state called **real mode** and begins
executing the system firmware — the **BIOS**. (Modern machines use UEFI, but we use the
classic BIOS path because it is simpler to learn from.)

### BIOS and POST

The BIOS runs **POST** (Power-On Self-Test): it checks RAM, initializes the keyboard,
display, and disk controllers. When POST finishes, the BIOS needs to hand off control. It
goes through the configured boot devices in order, and for each one it reads the **first
sector** — 512 bytes — into memory.

### The boot sector

The contract the BIOS offers is simple: it loads the first 512 bytes of the disk to memory
address `0x7C00` and jumps to it, but only if the last two bytes of that sector are
`0x55 0xAA`. That magic number is how the BIOS distinguishes a bootable disk from random
data.

Those 512 bytes are the **boot sector**, and the program in them is the **bootloader**.
This is the first code we write and the first code we control.

### The bootloader

A normal bootloader's job is small but important: switch the CPU into a more capable mode,
load a larger kernel from disk, and jump to it. We'll build that in later posts. For now,
our bootloader has one job: print a line of text, to prove our code is running on the
machine.

---

## 2. Setting up the environment

We need two tools:

| Tool | Role |
|------|------|
| **NASM** | Assembles `.asm` source into raw machine-code bytes |
| **QEMU** | Emulates a PC so we can boot our binary safely |

Install:

```bash
# Debian / Ubuntu
sudo apt install nasm qemu-system-x86
```

### Building

We assemble to a **flat binary** — no executable headers or metadata, just the raw bytes
the BIOS expects:

```bash
nasm -f bin src/boot/boot.asm -o bin/boot.bin -i src/
```

- `-f bin` — output a flat binary
- `-i src/` — where to find `%include`d files

### Makefile

The project's `Makefile` wraps this up:

```make
all:
	nasm -f bin src/boot/boot.asm -o bin/boot.bin -i src/

run: all
	qemu-system-i386 -drive file=bin/boot.bin,format=raw,if=floppy -monitor stdio -no-reboot

clean:
	rm -f bin/boot.bin
```

`make run` assembles and boots the binary. The `if=floppy` option tells QEMU to treat the
file as a floppy disk — the simplest boot device, with no partition table to deal with.

---

## 3. Real mode and segments

Real mode is the original 8086 environment that every x86 CPU still boots into for
backward compatibility. Its main properties:

- It is **16-bit**: registers like `AX`, `BX`, `CX` hold 16-bit values.
- It can address only **1 MB** of memory.
- It has **no memory protection** — any code can access any address. Removing this is the
  reason protected mode exists, which we'll get to in Part 2.
- It provides **BIOS interrupt services** for video, disk, and keyboard access. We'll use
  these to print text without writing a single display driver.

### Segment and offset

Registers are 16-bit, so they reach at most `0xFFFF` (64 KB). But real mode can address
1 MB. The way it bridges that gap is **segmentation**: a physical address is built from two
16-bit values.

```
  physical address = segment * 16 + offset
                   = (segment << 4) + offset
```

So the address `0x7C00`, where the BIOS loads us, can be expressed more than one way:

```
  segment 0x0000 : offset 0x7C00  ->  0      + 0x7C00      = 0x7C00
  segment 0x07C0 : offset 0x0000  ->  0x07C0 * 16 + 0      = 0x7C00
```

Both are valid. The flexibility is useful but it is a common source of bugs. The rule to
remember: always know which segment your data lives in. This matters in a moment, because
printing a string means pointing at it, and pointing means choosing a segment.

---

## 4. The minimal bootloader: Hello World

Here is a complete bootloader that prints a line and then halts:

```asm
[ORG 0x7C00]          ; the BIOS loads us here, so assume offsets start at 0x7C00
[BITS 16]             ; generate 16-bit instructions (real mode)

start:
    xor ax, ax
    mov ds, ax        ; DS = 0, so DS:SI addresses map straight to physical memory
    mov si, message   ; SI points at our string
    call print        ; print it
    jmp $             ; halt: jump to self, forever

%include "src/utils.asm"

message: db "Hello, World!", 0   ; null-terminated string

times 510 - ($ - $$) db 0        ; pad with zeros up to byte 510
dw 0xAA55                        ; bytes 511-512: the boot signature
```

There are only a few moving parts, so let's go through them.

### `[ORG 0x7C00]`

This tells NASM to assume our code is located at address `0x7C00`. Since that is exactly
where the BIOS loads the boot sector, every label (like `message`) resolves to its correct
runtime address. Using `0x7C00` as the origin and `DS = 0` is the simplest setup, because
an offset and its physical address are then the same number, which is easy to reason about.

(The project's full `boot.asm` instead uses `[ORG 0]` with a far jump that sets the segment
to `0x07C0`. That is the same `0x7C00` address expressed with a non-zero segment. Both work;
we use the `0x7C00` form here because it is easier to follow for a first bootloader.)

### Pointing at the string

`print` walks a string through the `SI` register, and the instruction it uses to read each
byte (`lodsb`) reads from `DS:SI`. So before calling it we set `DS = 0` and `SI = message`.
With `DS = 0`, `DS:SI` points directly at the string's physical location.

### Printing with the BIOS

We don't write to video memory directly here. Instead we use a BIOS service. The printing
code lives in [utils.asm](../../src/utils.asm):

```asm
print:
    lodsb               ; load the byte at [DS:SI] into AL, advance SI
    cmp al, 0
    je done             ; a 0 byte marks the end of the string
    call print_char
    jmp print
done:
    ret

print_char:
    mov ah, 0x0e        ; BIOS teletype output
    mov bx, 0           ; page 0
    int 0x10            ; BIOS video interrupt
    ret
```

`int 0x10` with `AH = 0x0E` is the BIOS "teletype" call: it prints the character in `AL`
at the cursor and advances the cursor, handling line wrap for us. `print` simply feeds it
one character at a time until it hits the terminating `0` byte.

This is the payoff of real mode's BIOS services: putting text on screen takes a handful of
instructions and no driver.

### The padding and the signature

```asm
times 510 - ($ - $$) db 0
dw 0xAA55
```

- `$ - $$` is the number of bytes emitted so far.
- `times 510 - ($ - $$) db 0` fills the rest of the sector with zeros, up to 510 bytes.
- `dw 0xAA55` adds the 2-byte magic signature, for 512 bytes total.

Without that signature the BIOS would refuse to boot the disk. If your code grows past 510
bytes, the `times` count goes negative and NASM errors out — a limit we'll run into more
seriously later.

---

## 5. Booting it

Build and run:

```bash
make run
```

QEMU opens, the BIOS loads our sector, and "Hello, World!" appears.

<!-- TODO: add screenshot of the Hello World bootloader running in QEMU -->
![Hello World booting in QEMU](./images/hello-world.png)

That window is running our 512 bytes directly on an emulated machine, with no operating
system underneath. At this point our code is the only program on the computer.

---

## 6. Summary

- A PC boots through stages: CPU, BIOS/POST, boot sector, bootloader, kernel.
- The BIOS loads the first sector to `0x7C00` and jumps to it, if it ends in `0xAA55`.
- Real mode is 16-bit and unprotected, and addresses memory as `segment * 16 + offset`.
- BIOS interrupt services (here, `int 0x10`) let us print text with no driver.
- A bootloader is just raw bytes: code, a string, padding, and the boot signature.

---

## 7. Optional: from Hello World to a game

Once text printing works, the same foundation — real mode, the BIOS, and 512 bytes — is
enough to build something interactive. As a bonus, this project also fits a small **Pong
game** into the boot sector: two paddles, a bouncing ball, and collisions, with no
operating system involved.

It reuses everything above and adds three pieces:

- **Graphics.** Instead of BIOS teletype, it switches to VGA **Mode 13h** (320x200, 256
  colors) with `int 0x10`, where video memory at segment `0xA000` is one byte per pixel.
  Paddles and the ball are filled rectangles drawn by a single `draw_rect` routine.
- **Input.** It reads the keyboard with `int 0x16` — W/S for the left paddle, the arrow
  keys for the right.
- **A game loop.** Each frame it erases the moving objects, reads input, updates the ball,
  redraws, and waits briefly before repeating.

<!-- TODO: add screenshot of the Pong game running in QEMU -->
![Pong running in QEMU](./images/pong.png)

The interesting constraint is space. The full game came to 562 bytes — 50 over the
512-byte limit — and had to be trimmed to fit (removing the BIOS Parameter Block, using
shorter instruction encodings, dropping redundant register loads, and so on). Fitting a
whole game into one sector is a good exercise in understanding exactly what each byte costs.

The complete game source is in [src/boot/boot.asm](../../src/boot/boot.asm). A full
walkthrough of the graphics, collision detection, and the byte-trimming is a possible topic
for a later post — but it isn't needed for the bootloader work this series is built on.

---

## What's next

Our bootloader prints text, but it is still boxed in: 512 bytes total, and stuck in 16-bit
real mode. Part 2 covers:

- A two-stage bootloader that reads more sectors from disk
- Setting up the GDT and switching to 32-bit protected mode
- Enabling the A20 line to reach memory above 1 MB

From there the series moves on to interrupts, drivers, and the threads and scheduler the
series is named for.
