@ write function using syscalls
@ copyright 2020 William Hatcher

@ write
@ Writes a zero-terminated string to stdout.
@ Assumes stdout as file output
@ r0 <- Address of string

    .include "constants.s"
    .section .rodata    @ Read only data
    .align  2

line_feed:  .ascii "\n"

    .text
    .align  2
    .syntax unified
    .global write
    .type   write, %function

write:
    push    {r7}
    @ Calculate length of string
    mov     r2, 0   @ Stored in r2
calc_len:
    ldrb    r3, [r0, r2]    @ Load byte with offset
    cmp     r3, 0           @ Quit if Null termination
    addne   r2, r2, 1       @ Else add 1 to counter
    bne     calc_len        @ And loop
    @ At this point
    @ r0 <- Address of string
    @ r2 <- length of string
    mov     r1, r0          @ move address to r1
    mov     r0, 0           @ STDOUT
    @ Call os function (syscall) write(file, char* string, length)
    mov     r7, WRITE
    svc     0

    pop     {r7}
    bx      lr
