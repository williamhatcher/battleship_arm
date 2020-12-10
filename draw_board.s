@ Draw the entire board
@ William Hatcher
    .cpu    cortex-a53
    .fpu    neon-fp-armv8
    .syntax unified

    .equ    row_offset, 4
    .equ    column_offset, 5

@ Board display strings
    .text
title:      .ascii "\x1b]0;Battleship GE\x07"
            .ascii "\033[2J\033[1;1H"
            .ascii "       Battleship GE\n"
            .ascii "      William Hatcher"
            .ascii "\000"
boardTop:   .ascii "\033[38;2;164;164;164m\033[48;2;0;0;64m"
            .asciz "  ╔═════════════════════╗"

row:        .ascii "\033[38;2;164;164;164m"
            .ascii "\033[48;2;0;0;64m"
            .ascii	"%c \342\225\221 · · · · · · · · · · \342\225\221"
	          .asciz	"\033[0m\n"

boardBot:   .ascii "\033[38;2;164;164;164m\033[48;2;0;0;64m"
            .ascii "  ╚═════════════════════╝"
            .ascii "\n    0 1 2 3 4 5 6 7 8 9  "
            .asciz "\033[0m"
hit:        .ascii "\0337"
            .ascii "\033[%d;%dH" 
            .ascii "\033[48;2;0;0;64m"
            @ .ascii "\033[38;2;242;125;12m"
            .ascii "\033[31m"
            .ascii "\033[1D"
            .ascii "💥"
            .ascii "\033[0m" 
            .asciz "\0338"
miss:       .ascii "\0337"
            .ascii "\033[%d;%dH" 
            .ascii "\033[48;2;0;0;64m"
            .ascii "\033[31m" 
            .ascii "✗"
            .ascii "\033[0m" 
            .asciz "\0338"
s_move_to:  .asciz "\033[%d;%dH"
set_blinking:.asciz "\033[1 q"
md_1:.asciz "in: l: %d, c: %d\n"
md_2:.asciz "new values: line: %d, col: %d\n"
@ hide_cur:   .asciz "\033[?25l"
@ show_cur:   .asciz "\033[?25h"

    @ Program
    .text
    .align  2
    .global draw_board
    .type   draw_board, %function
    .global mark_board
    .type   mark_board, %function
    .global move_to
    .type   move_to, %function
    .global to_board_pos
    .type   to_board_pos, %function

draw_board:
    push    {r4, fp, lr}

    @ set blinking cursor
    ldr   r0, a_set_blinking
    bl    printf

    @ print title
    ldr   r0, a_title
    bl    puts

    @ print top
    ldr   r0, a_boardTop
    bl    puts

    @ print rows
    mov   r4, 'A'
loop:
    mov   r1, r4
    ldr   r0, a_row
    bl    printf
    add   r4, r4, 1
    cmp   r4, 'J'
    ble   loop

    @ print bottom
    ldr     r0, a_boardBot
    bl      puts

    pop     {r4, fp, pc}

a_title:    .word title
a_boardTop: .word boardTop
a_row:      .word row
a_boardBot: .word boardBot

to_board_pos:
  @ 2 args
  @ r0 raw row/line
  @ r1 raw column
  @ Returns proper offsets
  @ r0 <- proper row/line
  @ r1 <- proper column
  push  {fp, lr}
  sub   r0, r0, row_offset
  mov   r3, column_offset
  lsr   r1, r1, 1
  sub   r1, r1, 2
  pop   {fp, pc}

move_to:
  @ moves CURSOR to location (based on board)
  @ 2 args
  @ r0 row/line -> r1
  @ r1 column   -> r2
  push  {fp, lr}
  
  @ move registers up one to make room for printf string
  mov   r2, r1
  mov   r1, r0

  @ calculate true positions
  add   r1, r1, row_offset
  mov   r3, column_offset
  add   r2, r3, r2, lsl 1 @ column (*2, +5)

  ldr   r0, a_move_to
  bl    printf

  pop   {fp, pc}

mark_board:
  @ 3 args
  @ r0 row
  @ r1 column
  @ r2 character
  @ 0 = miss, 1 = hit

  push  {r4, fp, lr}

  @ calculae term values
  add   r0, r0, row_offset
  mov   r3, column_offset
  add   r1, r3, r1, lsl 1 @ column (*2, +5)

  @ move everything up a register to call printf
  mov   r3, r2
  mov   r2, r1
  mov   r1, r0

  @ check which character to print
  cmp   r3, 0  @ miss
  ldreq r0, a_miss
  ldrne r0, a_hit
  bl    printf
  pop   {r4, fp, pc}

a_miss:   .word miss
a_hit:    .word hit
a_move_to:  .word s_move_to
a_set_blinking: .word set_blinking

a_md_1:.word md_1
a_md_2:.word md_2
