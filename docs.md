Make debug with GDB
    
gdb
(gdb) target remote :1234
(gdb) set architecture i8086
(gdb) break *0x7c00
(gdb) continue