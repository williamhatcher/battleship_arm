@ William Hatcher
@ Functions to draw the game board

    .equ    row_offset, 4
    .equ    column_offset, 5
    .align  2

    .section .rodata    @ Read only data
    .align  2
title:
    .ascii  "\x1b]0;Battleship ARM\x07"
    .ascii  "\033[2J\033[1;1H"
    .ascii  "      Battleship ARM\n"
    .ascii  "      William Hatcher\n"
header:
    .ascii  "\033[38;2;164;164;164m\033[48;2;0;0;64m"
    .asciz  "  ╔═════════════════════╗\n"
row:
    .ascii  "\033[38;2;164;164;164m"
    .asciz  "\033[48;2;0;0;64m"
    @ Will manually include the character here
row2:
    .ascii	" \342\225\221 · · · · · · · · · · \342\225\221"
    .asciz	"\033[0m\n"
footer:
    .ascii  "\033[38;2;164;164;164m\033[48;2;0;0;64m"
    .ascii  "  ╚═════════════════════╝"
    .ascii  "\n    0 1 2 3 4 5 6 7 8 9  "
    .ascii  "\033[0m\n"
instructions: 
    .asciz  "\033[1mPress space or enter to fire!\nUse arrow keys to move, q to quit\033[0m\n"
blinking_cursor:
    .asciz "\033[1 q"
move_pre:
    .ascii "\0337"
    .asciz "\033["
move_pre2:
    .asciz ";"
move_pre3:
    .ascii "H\033[48;2;0;0;64m"
    .asciz "\033[31m"
hit:
    .asciz "💥"
miss:
    .ascii "\033[31m"
    .asciz "✗"
move_post:
    .ascii "\033[0m" 
    .asciz "\0338"

    .text
    .align  2
    .syntax unified
    .global draw_board
    .type   draw_board, %function

draw_board:
    push    {lr}

    @ Turn on blinking cursor
    ldr     r0, =blinking_cursor
    bl      write

    @ Draw title + header
    ldr     r0, =title
    bl      write

    @ Init char variable
    mov     r0, 'A'
    str     r0, [sp, -8]!
    mov     r0, 0   @ Store null terminator
    str     r0, [sp, -4]

    @ Draw Row
draw_row:
    @ Draw Start of Row
    ldr     r0, =row
    bl      write

    @ Draw character
    mov     r0, sp  @ Address of character is at sp
    bl      write

    @ Draw rest of row
    ldr     r0, =row2
    bl      write

    @ Test if Character is J
    ldr     r0, [sp]
    cmp     r0, 'J'
    @ If not; Increment Character
    addlt   r0, r0, 1
    strlt   r0, [sp]
    blt     draw_row

    @ End of loop
    @ Deallocate stack
    add     sp, sp, 8

    @ Draw Footer
    ldr     r0, =footer
    bl      write

    @ Bye!
    pop     {pc}


to_board_pos:
    @ 2 args
    @ r0 raw row/line
    @ r1 raw column
    @ Returns proper offsets
    @ r0 <- proper row/line
    @ r1 <- proper column
    sub     r0, r0, row_offset
    mov     r3, column_offset
    lsr     r1, r1, 1
    sub     r1, r1, 2
    bx      lr


mark_board:
    @ 3 args
    @ r0 row
    @ r1 column
    @ r2 character
    @ 0 = miss, 1 = hit
    push    {fp, lr}

    @ calculae term values
    add     r0, r0, row_offset
    mov     r3, column_offset
    add     r1, r3, r1, lsl 1 @ column (*2, +5)
    push    {r0, r1}
    @ r0 at sp, r1 at sp +4
    add     fp, sp, 4
    @ row r0 at [fp, -4]
    @ col r1 at [fp]
    
    @ Write start of control sequence
    ldr     r0, =move_pre
    bl      write

    @ Write line in ascii
    @ Load row from stack
    ldr     r1, [sp]
    add     r1, r1, '0'
    mov     r0, 0
    str     r0, [sp, 4]
    mov     r0, sp
    bl      write

    ldr     r0, =move_pre2
    bl      write

    ldr     r1, [sp]
    add     r1, r1, '0'
    mov     r0, 0
    str     r0, [sp, 4]
    mov     r0, sp
    bl      write

    ldr     r0, =move_pre3
    bl      write

    ldr     r0, =hit
    bl      write

    ldr     r0, =move_post
    bl      write

    add     sp, sp, 8
    pop     {fp, pc}
