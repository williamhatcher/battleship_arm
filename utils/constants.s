@ William Hatcher
@ Useful constants to be included in programs with .include "constants.s"

@ Syscalls
.equ    EXIT,   1
.equ    READ,   3
.equ    WRITE,  4
.equ    OPEN,   5
.equ    CLOSE,  6

    @ @ Exit 
    @ mov     r0, 0
    @ mov     r7, 1
    @ svc     0
