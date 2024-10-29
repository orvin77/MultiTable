################################
# UNIT pixel WIDTH = 8
# UNIT pixel WIDTH = 8
# Display width in pixels = 512
# Display height in pixels = 256
# 512 x 256 display
################################

.data	
board:			.space 64
equations: 		.space	64
solutions:		.space 64
eq:		.asciiz	"5 x 3"
sol:		.word	15

.text

.globl main, board

main:
	
	jal 	display_remaining
	jal	printCards
	
	la	$t6, equations
	la	$t7, solutions
	la	$t2, eq
	sw	$t2, 0($t6)
	la	$t3, sol
	sw	$t3, 0($t7)
	
	li $a1, 16 
    	li $v0, 42
    	syscall
    	add $s0, $zero, $a0
    	sll	$s0, $s0, 2
    	sw	$t2, board($s0)
    	
    	li $a1, 16 
    	li $v0, 42
    	syscall
    	add $s0, $zero, $a0
    	sll	$s0, $s0, 2
    	sw	$t3, board($s0)
    	
	
	li	$v0, 10
	syscall
	
	
	
	
	
