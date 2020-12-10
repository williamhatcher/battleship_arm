@ check_guess function for battleship program
@ William Hatcher
    .cpu    cortex-a53
    .fpu    neon-fp-armv8
    .syntax unified

    @ Stack offsets from fp
    .equ    stack_top,  24
    .equ    h_start,   -24
    .equ    direction, -20
    .equ    v_guess,   -16
    .equ    h_guess,   -12
    .equ    v_start,    4

@ Program
    .text
    .align  2
    .global check_guess
    .type   check_guess, %function

check_guess:
    @ returns 0/1 in r0
    @ 5 parameters
    @ r0 = h_guess
    @ r1 = v_guess
    @ r2 = direction
    @ r3 = h_start
    @ stack = v_start

    @ Prologue
    push    {fp}
    add     fp, sp, 0
    sub     sp, sp, stack_top

    @ Save args to stack
    str     r0, [fp, h_guess]
    str     r1, [fp, v_guess]
    str     r2, [fp, direction]
    str     r3, [fp, h_start]

    @ hit will be stored in r0
    mov     r0, 0

    @ recall direction intto r1
    ldr     r1, [fp, direction]
    
    @ Test if direction == 0 (North/South)
    cmp     r1, 0
    beq     ns_test
    bne     ew_test

ns_test:
    @ Horizontal guess must exactly match horizontal start
    ldr     r1, [fp, h_guess]   @ r1 -> h_guess
    ldr     r2, [fp, h_start]   @ r2 -> h_start
    cmp     r1, r2              @ h_guess == h_start
    moveq   r0, 1               @ hit = ^
    movne   r0, 0
    bne     end_test

    @ Vertical guess can be within v_start .. v_start + 3
    @ Test v_guess >= v_start
    ldr     r1, [fp, v_guess]   @ r1 -> v_guess
    ldr     r2, [fp, v_start]   @ r2 -> v_start
    cmp     r1, r2              @ v_guess >= v_start
    @ no need to update hit as it wont change, but we do
    movge   r0, 1
    movlt   r0, 0
    blt     end_test    @ yummy blt sandwich

    @ Test v_guess <= v_start + 3
    add     r2, r2, 3
    cmp     r1, r2      @ v_guess <= v_start
    movle   r0, 1
    movgt   r0, 0       @ set hit to 0 if this fails
    b       end_test

ew_test:
    @ Vertical guess must exactly match vertical start
    ldr     r1, [fp, v_guess]   @ r1 -> v_guess
    ldr     r2, [fp, v_start]   @ r2 -> v_start
    cmp     r1, r2              @ v_guess == v_start
    moveq   r0, 1               @ hit = ^
    movne   r0, 0
    bne     end_test

    @ Horizontal guess can be within h_start .. h_start + 3
    @ Test h_guess >= h_start
    ldr     r1, [fp, h_guess]   @ r1 -> h_guess
    ldr     r2, [fp, h_start]   @ r2 -> h_start
    cmp     r1, r2          @ hit = h_guess >= h_start
    @ no need to update hit as it wont change, but we do
    movge   r0, 1
    movlt   r0, 0
    ble     end_test

    @ Test h_guess <= h_start + 3
    add     r2, r2, 3
    cmp     r1, r2      @ h_guess <= h_start
    movle   r0, 1
    movgt   r0, 0
    b       end_test

end_test:
    add     sp, sp, stack_top
    pop     {fp}
    bx      lr
