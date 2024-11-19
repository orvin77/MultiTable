
.data	
equations: 		.space	64	#64 bytes to store both multiplicand and multiplier
solutions:		.space	32	#32 bytes to store solutions
offsets:		.space	64	#64 bytes to store correct offset positions to access corresponding equations and solutions
board:			.space 	64	#64 bytes for 16 cells
choice_one:		.space	8	#8 bytes to store user's 1st choice (either the equation operands or a solution)
choice_two:		.space	8	#8 bytes to store user's 2nd choice (either the equation operands or a solution)
indicator:		.space	8	#8 bytes to store an indicator of what type of choice user made
stored_indicies:	.space 	12	#8 bytes to store which index was stored into the choice arrays
user_sols:		.space	12	#8 bytes to store max of 2 solutions from user's choices
user_eqs:		.space 	12	#8 bytes to store max of 2 equation results from user's choices
card_count:		.word	16


#extra data
prompt_row:    		.asciiz "Enter row (0-3): "
prompt_col:    		.asciiz "Enter column (0-3): "
not_a_match:		.asciiz	"No match found. Keep trying!\n"
msg_match:		.asciiz	"You found a match. Keep it up!\n"
matched_crd:		.asciiz	"  =  |"
alr_matched:		.asciiz	"Atleast 1 of these cards have already been matched. Try again.\n"
end:			.asciiz	"\nCongratulations! You matched all the cards! Good Job!\n"
elaps_time:		.asciiz	"Time elapsed: "
mili:			.asciiz " milliseconds.\n"
startTime:		.word	0
endTime:		.word 	0

#t6, t3, t9, t7, t8, t5
#t3, t5, t6, t7, t8, t9
#s0, s4, s3, s6, s7
.text

.globl main, board, equations, solutions, offsets, indicator, choice_one, choice_two, stored_indicies, user_sols, user_eqs, card_count, matched_crd, check_match, game_loop

main:
	# Read start time
   	li 	$v0, 30     #System call to get current time
   	syscall
   	sw 	$a0, startTime  #Store start time
   	
	jal 	rand_vals		#initialize random equations and corresponding solutions
	addi	$t0, $zero, 0		#set $t1 back to 0
	addi	$t1, $zero, 0		#set $t1 back to 0
	
	jal	init_offsets		#initialize the offsets to get corresponding equations and solutions
	jal 	display_remaining
	addi	$t0, $zero, 0		#set $t1 back to 0
	addi	$t1, $zero, 0		#set $t1 back to 0
	li	$t4, 0
init_board:
    	beq   	$t0, 16, init_end    # End initialization after 16 cells
   	sw    	$t0, board($t1)       # Store card index in board
    	addi  	$t1, $t1, 4           # Move to the next cell
    	addi  	$t0, $t0, 1
    	j     	init_board
init_end:
	li	$s0, 0

	jal 	printCards
game_loop:
    	# Prompt for row
    	li    	$v0, 4
    	la    	$a0, prompt_row
    	syscall
	
    	li    	$v0, 5               # Read integer syscall
   	syscall
    	move  	$t0, $v0             # Store row in $t0
	
	blt	$t0, 0, game_loop
	bgt	$t0, 3, game_loop
	
enter_col:
    	# Prompt for column
    	li    	$v0, 4
    	la   	$a0, prompt_col
    	syscall
	
    	li    	$v0, 5               # Read integer syscall
    	syscall
    	move  	$t1, $v0             # Store column in $t1
    	blt	$t1, 0, enter_col
    	bgt	$t1, 3, enter_col
    	
    	add	$t3, $t1, $t0	    #add coordinates and determine if even or odd
    	li 	$t9, 2
    	div 	$t3, $t9
    	mfhi 	$s7  		# if remainder is 0, summed coordinates are even and an equation, cell is a solution otherwise
    	
    	
    	
    	# Calculate the 1D index(offset based on coordinates) in a 4x4 board using row and column
   	mul   	$t2, $t0, 16          # $t2 = row * 16
   	sll	$t1, $t1, 2		# col * 4
    	add   	$t2, $t2, $t1        # $t2 = row * 16 + column * 4, index of selected card
    	
    	beq 	$t2, $zero, set_zero_revealed
    	
    	lw	$t6, board($t2)		#$t2 holds offset
    	#check if the card has already been matched
    	beq	$t6, 17, already_matched
    	li	$t5, -1		
    	mult 	$t6, $t5	#turn index negative to indicate it is now revealed
    	mflo	$t6		#store back into $t6 and then board
    	sw	$t6, board($t2)
    	#increment choice counter
    	addi	$s0, $s0, 1
    	jal 	printCards
    	set_zero_revealed:
    		addi	$s0, $s0, 1
    		#-18 indicates that the user chose (0,0)
    		#uses this when displaying the equation at (0,0)
    		lw	$t6, board($t2)
    		#check if (0,0) has already been matched
    		beq	$t6, 17, already_matched
    		li	$t6, -18
    		sw	$t6, board
    		jal 	printCards
    	already_matched:
    		li	$v0, 4
    		la	$a0, alr_matched
    		syscall
    		j	game_loop
    	
check_match:
	addi	$s0, $zero, 0
	addi	$s6, $zero, 0
	li	$s3, 0
	li	$s2, 0	#offset for choice_one and choice_two if they have equations
	li	$s5, 1	#Choice number program is currently at
	li	$t8, 0	#offset for choice_one or choice_two
	li	$t4, 0	#offset for user_sols
	li	$t5, 0	#offset for user_eqs
	li	$t6, 0	#number of equation results
	li	$t7, 0	#number of solutions
match_checker:	
	#get the first indicator stored and check what type
	beq	$s5, 3,	 compare
	lw	$s4, indicator($s3)
	addi	$s3, $s3, 4	#increment by 4
	beq	$s4, -1, calc_eq
	
	#if indicator is not zero, get the solution
	get_sol:
		beq	$s5, 2, get_2nd_sol
		lw	$t3, choice_one($t8)
		addi	$s5, $s5, 1	#keep track of how many choices we've gone through
		sw	$t3, user_sols($t4)
		addi	$t4, $t4, 4
		addi	$t7, $t7, 1	#keep track of how many solutions we've gone through
		j	match_checker
	get_2nd_sol:
		lw	$t3, choice_two($t8)
		addi	$s5, $s5, 1	#keep track of how many choices we've gone through
		sw	$t3, user_sols($t4)
		addi	$t4, $t4, 4
		addi	$t7, $t7, 1	#keep track of how many solutions we've stored
		j	match_checker
		
	calc_eq:
		beq	$s5, 2, calc_2nd_eq
		#get the multiplicand
		lw	$t0, choice_one($s2)
		#get multiplier
		addi	$s2, $s2, 4
		lw	$t1, choice_one($s2)
		
		#multiply and get solution
		mult	$t0, $t1
		mflo	$t2
		sw	$t2, user_eqs($t5)
		addi	$t5, $t5, 4
		
		addi	$s5, $s5, 1
		addi	$t6, $t6, 1	#keep track of how many eqs we've gone through
		#set back to zero in case second choice is also equation
		li	$s2, 0
		j	match_checker
	calc_2nd_eq:
		#get the multiplicand
		lw	$t0, choice_two($s2)
		#get multiplier
		addi	$s2, $s2, 4
		lw	$t1, choice_two($s2)
		
		#multiply and get solution
		mult	$t0, $t1
		mflo	$t2
		sw	$t2, user_eqs($t5)
		addi	$t5, $t5, 4
		
		addi	$s5, $s5, 1
		addi	$t6, $t6, 1	#keep track of how many eqs we've gone through
		j	match_checker
	
compare:
	#check if user chose two equations
	beq	$t6, 2, compare_eq
	#check if use chose two solutions
	beq	$t7, 2, compare_sol
	
	#for 1 solution and 1 equation
	la	$t4, user_eqs
	lw	$t0, 0($t4)
	
	la	$t4, user_sols
	lw	$t1, 0($t4)
	
	beq	$t0, $t1, found_match
	j	no_match
	
	compare_eq:
		la	$t4, user_eqs
		lw	$t0, 0($t4)
		lw	$t1, 4($t4)
		beq	$t1, $t0, found_match
		j	no_match
	
	compare_sol:
		la	$t4, user_sols
		lw	$t0, 0($t4)
		lw	$t1, 4($t4)
		beq	$t1, $t0, found_match
		j	no_match

found_match:
	#check if these have already been matched
	#la	$a0, stored_indicies
	#lw	$t0, 0($a0)
	#lw	$t1, 4($a0)
	
	#if one of the cards have been matched, return to game_loop
	#sll	$t0, $t0, 2
	#sll	$t1, $t1, 2
	
	#lw	$t0, board($t0) #get the index value at that position
	#lw	$t1, board($t1)
	
	#compare value to 17(value for match found)
	#beq	$t0, 17, already_matched
	#beq	$t1, 17, already_matched
	
	#play sound to indicate they got the match
	li      $v0, 31
    	li      $a0, 84       # Higher pitch for success
    	li      $a1, 300      # Longer duration
    	li      $a2, 9        # Glockenspiel
    	li      $a3, 127      # Full volume
    	syscall

	#print found match message
	li	$v0, 4
	la	$a0, msg_match
	syscall
	la	$a0, nextLine
	syscall
	
	
	#print remaining cards count
	li	$v0, 4
	la	$a0, remaining
	syscall
	la	$a1, card_count
	lw	$a0, 0($a1)
	addi	$a0, $a0, -2
	sw	$a0, 0($a1)
	li	$v0, 1
	syscall
	ble	$a0, 0, end_game
	#print new line
	li	$v0, 4
	la	$a0, nextLine
	syscall
	
	
	#turn the indicies on the board that were revealed into -17 to indicate they have been matched
	la	$a0, stored_indicies
	lw	$t0, 0($a0)
	lw	$t1, 4($a0)
	
	#find the offset to store 17 in the right spot in the board array
	sll	$t0, $t0, 2
	sll	$t1, $t1, 2
	
	li	$a1, 17
	sw	$a1, board($t0)
	sw	$a1, board($t1)
	
	j reset
	
	
no_match:
	#check if these have already been matched
	#la	$a0, stored_indicies
	#lw	$t0, 0($a0)
	#lw	$t1, 4($a0)
	
	#if one of the cards have been matched, return to game_loop
	#sll	$t0, $t0, 2
	#sll	$t1, $t1, 2
	
	#lw	$t0, board($t0) #get the index value at that position
	#lw	$t1, board($t1)
	
	#compare value to 17(value for match found)
	#beq	$t0, 17, already_matched
	#beq	$t1, 17, already_matched
	li      $v0, 31
    	li      $a0, 60       # Lower pitch for failure
    	li      $a1, 200      # Medium duration
    	li      $a2, 9        # Glockenspiel
    	li      $a3, 100      # Medium volume
    	syscall
	
	#print no match message
	li	$v0, 4
	la	$a0, not_a_match
	syscall
	la	$a0, nextLine
	syscall
	#print remaining cards count
	la	$a0, remaining
	syscall
	la	$a1, card_count
	lw	$a0, 0($a1)
	li	$v0, 1
	syscall
	
	#print new line
	li	$v0, 4
	la	$a0, nextLine
	syscall
	
	#turn the indicies on the board that were revealed back into positive indicies to hide them again
	la	$a0, stored_indicies
	lw	$t0, 0($a0)
	lw	$t1, 4($a0)
	
	#find the offset to store the positive index in the right spot in the board array
	sll	$t0, $t0, 2
	sll	$t1, $t1, 2
	
	lw	$a1, board($t0)
	#get positive index
	neg	$a1, $a1
	sw	$a1, board($t0)
	
	lw	$a1, board($t1)
	#get positive index
	neg	$a1, $a1
	sw	$a1, board($t1)

reset:
	#reset registers used back to zero
	addi	$s0, $zero, 0
	addi	$s6, $zero, 0
	li	$s3, 0
	li	$s2, 0	#offset for choice_one and choice_two if they have equations
	li	$s5, 0	#Choice number program is currently at
	li	$t8, 0	#offset for choice_one or choice_two
	li	$t4, 0	#offset for user_sols
	li	$t5, 0	#offset for user_eqs
	li	$t6, 0	#number of equation results
	li	$t7, 0	#number of solutions
	
	jal	printCards
 	
end_game:
	li	$v0, 4
	la	$a0, end
	syscall
	# Read end time
    	li 	$v0, 30
    	syscall
   	sw 	$a0, endTime
   	
   	li 	$v0, 4
   	la	$a0, elaps_time
   	syscall
   	
   	
   	lw	$t0, startTime
   	lw	$t1, endTime
   	sub 	$a0, $t1, $t0
   	li	$v0, 1
   	syscall
   	
   	li	$v0, 4
   	la	$a0, mili
   	syscall
   	
	
	li	$v0, 10
	syscall
	
	
