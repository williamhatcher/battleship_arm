@ William Hatcher
@ Divide function
@ Source: http://www.mcs.sdsmt.edu/lpyeatt/courses/314/Chapter_07.pdf Page 28
@ Dividen in r0 (the x in x/y)
@ Divisor in r1 (the y in x/y)

@ Returns quotient (result) in r0
@ Returns modulus in r1

    .text
    .align  2
    .syntax  unified
    .global divide
    .type   divide, %function
divide:
    mov     r2, r1
    mov     r1, r0
    mov     r0, 0
    mov     r3, 1
divstrt:
    cmp     r2, 0
    blt     divloop
    cmp     r2, r1
    lslls   r2,r2,1
    lslls   r3,r3,1
    bls     divstrt
divloop:
    cmp     r1,r2
    subhs   r1,r1,r2
    addhs   r0,r0,r3
    lsr     r2,r2,1
    lsrs    r3,r3,1
    bcc     divloop

    bx      lr
