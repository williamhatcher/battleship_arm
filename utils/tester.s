@ Tester function
@ Can use GCC to compile :)

    .include "constants.s"
    .section .rodata    @ Read only data
    .align  2

    .text
    .align  2
    .syntax unified
    .global main
    .type   main, %function

main:
