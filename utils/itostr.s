@ William Hatcher
@ Convert an int to an ASCII string + null termination

    .text
    .align  2
    .syntax unified
    .global itostr_size
    .type   itostr_size, %function
    .global itostr
    .type   itostr, %function

itostr_size:
    @ Calculate number of bytes required for itostr
    @ Put the int to calculate in r0
    @ Returns
    @ r0 - Length in bytes
    @ r1 - Length in bytes + offset safe for stack storage
    push    {r4, fp, lr}

    @ Calculate # bytes needed for string
    mov     r4, 2   @ 2 to include first iteration and null terminator
loop:
    mov     r1, 10
    bl      divide
    cmp     r0, 10
    addge   r4, r4, 1
    bge     loop
    mov     r0, r4

    @ Calculate offset from multiple of 4 to know how much we need to allocate on the stack
    @ x + (4 - (x % 4))
    mov     r1, 4
    bl      divide
    @ r0 % r1 ; modulus returned in r1
    mov     r0, 4
    sub     r0, r0, r1
    add     r0, r0, r4

    @ r4 now holds the length of our string
    @ r0 now holds the number of bytes we need to allocate onto the stack
    mov     r1, r0
    mov     r0, r4

    pop     {r4, fp, pc}

itostr:
    @ 1 arg
    @ r0 <- int to convert to string
    @ sp is start of string 
    push    {r4, lr}
    @ Store string into stack
    @ Using r4 as address
    add     r4, sp, 8
    add     r4, r4, r1
    mov     r2, 0           @ Store null into stack string end
    strb    r2, [r4], -1    @ Move address up one byte
    @ We are filling this string from the end
int_loop:
    mov     r1, 10
    bl      divide
    add     r1, r1, '0'     @ Add '0' value to the modulus
    strb    r1, [r4], -1    @ and push onto string
    cmp     r0, 10          @ is r0 a signle digit number?
    bge     int_loop        @ No? Reduce it!
    add     r0, r0, '0'     @ Otherwise, push it onto the string
    strb    r0, [r4]
    pop     {r4, pc}



sample_usage:
    push    {r4, lr}
    mov     r0, 9

    bl      itostr_size
    @ r0 = length
    @ r1 = stack offset
    mov     r4, r1
    sub     sp, sp, r4

    mov     r0, 9
    bl      itostr

    add     r0, sp, 0
    bl      puts

    mov     r0, 0
    add     sp, sp, r4
    pop     {r4, pc}
