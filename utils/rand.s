@ William Hatcher
@ Generate a random byte into r0

    .include "constants.s"
    .syntax  unified
    .section .rodata    @ Read only data
    .align  2

urandom:
    .asciz  "/dev/urandom"

    @ Uninitialized Data
    .bss
@ Where to store the buffer for read()
buffer:
    .skip   1 @ Skip 1 byte to use a a buffer
@ Where to store the file handle from open()
handle:
    .word

    .text
    .align  2
    .global rand
    .type   rand, %function

rand:
    push    {r7}
    @ Syscall to open '/dev/urandom'
    mov     r2, 0   @ Mode - Not sure what this is exactly?
    mov     r1, 0   @ Read Only Flag
    ldr     r0, =urandom
    mov     r7, OPEN    @ Syscall to be made
    svc     0
    ldr     r1, =handle
    str     r0, [r1]

    @ Read one byte from the file
    ldr     r1, =buffer
    mov     r2, 1       @ Num bytes to read
    mov     r7, READ
    svc     0

    @ Close urandom
    ldr     r0, =handle @ Load Address of byte of handle
    ldr     r0, [r0]    @ Load first byte of Value at this address
    mov     r7, CLOSE
    svc     0
    
    @ Put rand int into r0
    ldr     r0, =buffer
    ldrb    r0, [r0]

    pop     {r7}
    bx      lr
