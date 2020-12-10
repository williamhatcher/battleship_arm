@ battleship program
@ William Hatcher
    .cpu    cortex-a53
    .fpu    neon-fp-armv8
    .syntax unified

    @ Term attrs constants
    .equ    STDIN,      0
    .equ    TCSAFLUSH,  2
    .equ    TCSANOW,    0

@ Stack offsets from fp
    .equ    stack_top,  152
    .equ    m_row_pos, -148
    .equ    m_col_pos, -144
    .equ    buffer,    -140 @ 16 byte buffer
    .equ    board,     -124
    .equ    board_end,  -24
    .equ    v_start,    -20
    .equ    h_start,    -16
    .equ    row_pos,    -12
    .equ    col_pos,    -8
    .equ    direction,   -4

    .text
    .section  .rodata
instructions: .asciz  "\033[1mPress space or enter to fire!\nUse arrow keys to move, q to quit\033[0m\n"
win:          .asciz "\033[1A\033[K         You Win!!"
cheatOut:     .ascii "\0337"
              .ascii "\033[20H"
              .ascii "r=%C c=%d dir=%d"
              .asciz "\0338"
boardEndStr:  .asciz "\033[20H"

enable_mouse: .asciz "\033[?1003h\033[?1015h\033[?1006h"
disable_mouse:.asciz "\033[?1000l"

mouse_dbg:.asciz "%d, %d\n"

@ Program
    .text
    .align  2
    .global main
    .type   main, %function

main:
    push    {r4, fp, lr}
    add     fp, sp, 0
    sub     sp, sp, stack_top

    @ Game Setup

setup_ships:
    @ Seed random number
    @ Get time
    mov     r0, 0
    bl      time
    bl      srand    @ srand(time(0))

    @ Get random direction (0 = n/s, 1 = e/w)
    bl      rand
    and     r0, r0, 1
    str     r0, [fp, direction]

    @ Determine max starting points
    cmp     r0, 0   @ north/south
    moveq   r1, 9   @ value to store in h_start
    moveq   r2, 6   @ value to store in v_start
    @ east/west
    movne   r1, 6   @ h_start
    movne   r2, 9   @ v_start

    str     r1, [fp, h_start]
    str     r2, [fp, v_start]

    @ Generate starting points
    @ h_start = rand() % h_start + 1
    bl      rand
    ldr     r1, [fp, h_start]
    @ rand() % h_start
	  bl	    __aeabi_idivmod
    add     r1, r1, 1
    str     r1, [fp, h_start]

    @ v_start = rand() % v_start + 1
    bl      rand
    ldr     r1, [fp, v_start]
    bl      __aeabi_idivmod
    add     r1, r1, 1
    str     r1, [fp, v_start]

display_board:
    @ enable mouse tracking
    ldr   r0, a_enable_mouse
    bl    printf
    @ display board
    bl  draw_board

    @ Instructions
    ldr   r0, a_instructions
    bl    printf

    @ Initial mark
    mov   r0, 0
    str   r0, [fp, row_pos]
    str   r0, [fp, col_pos]
    mov   r1, 0
    mov   r2, 2
    @ bl    mark_board

    mov   r0, 0
    mov   r1, 0
    bl    move_to

    @ Guessing Loop
    mov r0, 0
    bl fflush
    bl term_setup
loop:
    mov r0, 0 
    bl fflush
    mov   r2, 1
    add   r1, fp, buffer
    mov   r0, STDIN
    bl    read

input_test:
    ldrb r0, [fp, buffer]
    cmp  r0, 'q'
    beq epilogue
    cmp  r0, 'c'
    beq  output_cheat
    cmp  r0, 10 @ enter
    beq guess_logic
    cmp r0, 32  @ space
    beq guess_logic

    @ Test for arrows + mouse
    @ Control signal starts with "\033[" (27) (91)
    cmp  r0, 27
    bne loop

    @ read next two bytes to compare with "[" and A|B|C|D (arrows) or "<" (mouse)
    mov   r2, 2
    add   r1, fp, buffer
    mov   r0, STDIN
    bl    read

    @ first byte
    ldrb r0, [fp, buffer]
    cmp r0, '[' @91
    bne loop

    @ second byte (arrow or mouse test)
    mov r0, buffer
    add r0, r0, 1
    ldrb r0, [fp, r0]

    cmp r0, 'A' @ up
    beq mov_up
    cmp r0, 'B' @ down
    beq move_down
    cmp r0, 'C' @ right
    beq move_right
    cmp r0, 'D' @ left
    beq move_left
    cmp r0, '<' @ mouse
    bne loop

    @ mouse control signals are:
    @ Prefixed with \033[< (We've already got these from the buffer)
    @ MOVE => 35;Col;LnM
    @ BTN DOWN => 0;Col;LnM <- note uppercase M
    @ BTN UP => 0;Col;Lnm <- note lowercase m

    @ Read next chars into buffer
    mov   r2, 16
    add   r1, fp, buffer
    mov   r0, STDIN
    bl    read

    @ first byte 3 for move, 0 for press (up/down)
    ldrb r0, [fp, buffer]
    @ we'll use r4 to keep track of our location within the buffer
    mov   r4, 1
    cmp  r0, '0'  @ press
    beq  mouse_press
    cmp  r0, '3'  @ move
    bne  loop     @ go back to loop if not 0 or 3
mouse_move:
    @ If 3 (move)
    @ Read next byte
    mov r0, buffer
    add r0, r4
    ldrb r0, [fp, r0]
    @ Should be 5
    cmp  r0, '5'
    bne  loop
    @ Read next byte
    mov r0, buffer
    add r4, r4, 1
    add r0, r4
    ldrb r0, [fp, r0]
    @ Should be ;
    cmp  r0, ';'
    bne  loop

    @ Get the column & line
    @ Have to loop through each byte until we reach another ';'
    @ We can and each byte with 001111
    @ Or subtract 48
    mov   r3, m_col_pos   @ Where to store these set of parsed characters
                          @ Will change to m_row_pos for second run through
    mov   r2, 0           @ Temp store parsed in r2
get_mouse_pos:
    @ get next char from buffer
    mov r0, buffer
    add r4, r4, 1       @ r4 is our buffer position
    add r0, r4
    ldrb r0, [fp, r0]   @ load next byte from buffer

    cmp    r3, m_col_pos
    cmpeq  r0, ';'      @ are done with col ?
    beq  mouse_col_done
    cmpne  r0, 'M'      @ or are we done with lines
    beq  mouse_line_done
    sub  r0, r0, '0'     @ '0' subtract ascii 0 value to get actual int
    mov  r1, r2
    lsl  r1, r1, 2
    add  r1, r1, r2
    lsl  r1, r1, 1
    add  r1, r0, r1
    mov  r2, r1
    b    get_mouse_pos
  
mouse_col_done:
    str   r2, [fp, m_col_pos]
    mov   r3, m_row_pos
    mov   r2, 0
    b     get_mouse_pos   @ go get the line/row
mouse_line_done:
    @ done with line
    @ get board_pos of line then store it
    str   r2, [fp, m_row_pos]
    mov   r0, r2
    ldr   r1, [fp, m_col_pos]
    bl    to_board_pos

    @ Make sure the cursor isn't out of bounds
    cmp   r0, 0
    blt   loop
    cmp   r1, 0
    blt   loop
    cmp   r0, 9
    bgt   loop
    cmp   r1, 9
    bgt   loop
    str   r0, [fp, row_pos]
    str   r1, [fp, col_pos]
    bl    move_to  @ update board
    b     loop

mouse_press:
    mov   r0, 173
    b     loop

output_cheat:
    @ Cheat Output
    ldr     r3, [fp, direction]
    ldr     r2, [fp, h_start]
    ldr     r1, [fp, v_start]
    add     r1, r1, 65
    ldr     r0, a_cheat_out
    bl      printf
    b     loop

mov_up:
    ldr   r0, [fp, row_pos]
    cmp   r0, 0
    ble   loop
    sub   r0, r0, 1
    str   r0, [fp, row_pos]
    ldr   r1, [fp, col_pos]
    bl    move_to
    b     loop
move_down:
    ldr   r0, [fp, row_pos]
    cmp   r0, 9
    bge   loop
    add   r0, r0, 1
    str   r0, [fp, row_pos]
    ldr   r1, [fp, col_pos]
    bl    move_to
    b     loop
move_left:
    ldr   r0, [fp, row_pos]
    ldr   r1, [fp, col_pos]
    cmp   r1, 0
    ble   loop
    sub   r1, r1, 1
    str   r1, [fp, col_pos]
    bl    move_to
    b     loop
move_right:
    ldr   r0, [fp, row_pos]
    ldr   r1, [fp, col_pos]
    cmp   r1, 9
    bge   loop
    add   r1, r1, 1
    str   r1, [fp, col_pos]
    bl    move_to
    b     loop

guess_logic:
    @ call check_guess
    ldr     r3, [fp, v_start]
    str     r3, [sp , -4]!
    ldr     r3, [fp, h_start]
    ldr     r2, [fp, direction]
    ldr     r1, [fp, row_pos] @ v_guess
    ldr     r0, [fp, col_pos] @ h_guess
    bl      check_guess
    add     sp, sp, 4
    mov     r4, r0

    @ Store the state
    @ 0 = unknown; 1 = miss; 2 = hit
    ldr   r0, [fp, row_pos]
    mov   r1, 10
    mul   r0, r1
    ldr   r1, [fp, col_pos]
    add   r0, r0, r1
    add   r2, fp, board
    add   r2, r0
    add   r0, r4, 1
    str   r0, [r2]

    @ Mark the board
    mov     r2, r4
    ldr     r1, [fp, col_pos]    
    ldr     r0, [fp, row_pos]
    bl      mark_board


    cmp     r4, 0
    beq     loop

    ldr     r0, a_win
    bl      puts

epilogue:
    @ disable mouse tracking
    ldr     r0, a_disable_mouse
    bl      printf
    @ Move cursor to end of board
    ldr     r0, a_board_end
    bl      printf
    @ flush & reset terminal
    mov     r0, 0
    bl      fflush
    bl      reset_term
    add     sp, sp, stack_top
    pop     {r4, fp, pc}

a_cheat_out:     .word cheatOut
a_win:           .word win
a_instructions:  .word instructions
a_enable_mouse:  .word enable_mouse
a_disable_mouse: .word disable_mouse
a_board_end:     .word boardEndStr
