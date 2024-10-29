.data
	remaining: 	.asciiz		"Number of cards left: "
	card:		.asciiz		"  x  |"
	border:		.asciiz		"-------------------------"
	totalTime:	.asciiz		"\nTotal time: "
	nextLine:	.asciiz		"\n"

.text

.globl display_remaining, printCards



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
	la	$a0, border	#top border
	syscall
	
	li	$v0, 4
	la	$a0, nextLine
	syscall
	
	jr	$ra

fill_board:
	
	
printCards:
	li	$v0, 4
	la 	$a0, card
	syscall
	addi	$t0, $t0, -1	#decrement card amount for each row
	bnez	$t0, printCards

	li	$v0, 4
	la 	$a0, nextLine	#after printing row of 4 cards, go to next row
	syscall
	
	addi	$t1, $t1, -4	#decrement remaining cards to print by 4
	addi	$t0, $zero, 4
	bnez	$t1, printCards
	
	li	$v0, 4
	la	$a0, border	#bottom border
	syscall
	
	jr	$ra
	
