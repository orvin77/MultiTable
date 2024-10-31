.data
	symbol:		.asciiz		" x "
	card:		.asciiz		"  x  |"
	remaining: 	.asciiz		"Number of cards left: "
	border:		.asciiz		"-------------------------"
	totalTime:	.asciiz		"\nTotal time: "
	nextLine:	.asciiz		"\n"

.text

.globl init_offsets, display_remaining, rand_vals, symbol, card, remaining, border, nextLine

init_offsets:
	
	#store offset value for equations at even indicies: 0, 2, 4
	#offset[0] = 0, offset[2]= 8, offset[4] = 16 
	#since equations array stores both multiplicand and multiplier next to each other we need to +8 to offset instead of 4
	sw	$t0, offsets($t2)
	addi	$t2, $t2, 4
	#store offset value for solutions at odd indicies
	#offset[1] = 0, offset[3] = 4, offset[5] = 8
	#if index at the user's coordinates is odd, get index from board and get correct offset from offset array to get the corresponding solution
	sw	$t1, offsets($t2)
	
	addi	$t0, $t0, 8
	addi	$t1, $t1, 4
	addi	$t2, $t2, 4
	addi	$t3, $t3, 2
	#branch if 16 positions in offset have been initialized
	blt	$t3, 16, init_offsets
	jr	$ra

display_remaining:
	li	$v0, 4
	la	$a0, remaining	#prints number of cards left
	syscall
	
	li 	$s1, 16		#16 cards remaining in the beginning
	li 	$v0, 1
	move  	$a0, $s1
	syscall
	
	addi	$t0, $zero, 4 	#4 rows of 4 cards
	move 	$t1, $s1	#$t1 contains the number of cards to display
	
	li	$v0, 4
	la	$a0, nextLine
	syscall
	
	li	$v0, 4
	la	$a0, nextLine
	syscall
	
	add	$t5, $zero, $zero
	
	jr	$ra
	
	
rand_vals:
	addi	$s2, $zero, 32
	li 	$a1, 5		#Upper bound , 0-4 to get random index for multiplicand
    	li 	$v0, 42
    	syscall
    	add 	$s0, $zero, $a0
    	sll	$s0, $s0, 2	#shift left 2 bits to get multiple of 4
    	lw	$t5, nums($s0)
    	
    	li 	$a1, 5		#Upper bound , 0-4 to get random index for multiplier
    	li 	$v0, 42
    	syscall
    	add 	$s0, $zero, $a0
    	sll	$s0, $s0, 2	#shift left 2 bits to get multiple of 4
    	lw	$t4, nums($s0)
    	
  	sw 	$t5, equations($t0)
  	addi	$t0, $t0, 4
  	sw	$t4, equations($t0)
  	addi	$t0, $t0, 4
    	
    	mult	$t4, $t5
    	mflo	$t1
    	sw	$t1, solutions($s1)
    	addi	$s1, $s1, 4
    	bne 	$s1, $s2, rand_vals	#keep making equation-solution pairs 
    	#li 	$a1, 16 	#upper bound 16, 0-15 to get random index of where to store equation
    	#li 	$v0, 42
    	#syscall
    	#add 	$s1, $zero, $a0
    	#sll	$s1, $s1, 2
    	#sw	$t5, board($s1) #store equation in board
    	
    	#li 	$a1, 16 	
    	#li 	$v0, 42
    	#syscall
    	#add 	$s1, $zero, $a0
    	#sll	$s1, $s1, 2
    	#sw	$t6, board($s1) #store solution in board
	
	jr	$ra

	
	


	
