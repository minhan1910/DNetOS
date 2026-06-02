# Developing a Multithreaded Kernel from Scratch

A blog series on building a small operating system from the ground up — starting
from the first instruction the CPU runs after power-on, and working up to a kernel
that can run multiple threads.

## Contents

| # | Post | Topics |
|---|------|--------|
| 01 | [The Bootloader](./01-bootloader-and-pong.md) | Boot process, real mode, segments, and a Hello World bootloader (Pong as an optional bonus) |
| 02 | Entering Protected Mode *(planned)* | The GDT, 32-bit mode, the A20 line |
| 03 | A Two-Stage Bootloader *(planned)* | Reading sectors from disk, getting past the 512-byte limit |
| 04 | Interrupts and the Keyboard *(planned)* | The IDT, IRQs, a real keyboard driver |
| 05 | Threads and a Scheduler *(planned)* | Context switching, the scheduler |

## Tools

- **NASM** — assembler
- **QEMU** — PC emulator, so you can test without rebooting real hardware

```bash
# Debian / Ubuntu
sudo apt install nasm qemu-system-x86

# macOS
brew install nasm qemu
```

Start with [Part 1](./01-bootloader-and-pong.md).
