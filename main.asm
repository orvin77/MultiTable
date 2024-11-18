
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


#extra data
space:			.asciiz " "
endLine:		.asciiz	" |" 
line:			.asciiz "|"
prompt_row:    		.asciiz "Enter row (0-3): "
prompt_col:    		.asciiz "Enter column (0-3): "
not_a_match:		.asciiz	"No match found. Keep trying!"
msg_match:		.asciiz	"You found a match. Keep it up!"
matched_crd:		.asciiz	"  =  |"

#t6, t3, t9, t7, t8, t5
#t3, t5, t6, t7, t8, t9
#s0, s4, s3, s6, s7
.text

.globl main, board, equations, solutions, offsets

main:
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
    	
    	#increment choice counter
    	addi	$s0, $s0, 1
    	
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
    	beq	$t6, 17, printCards
    	li	$t5, -1		
    	mult 	$t6, $t5	#turn index negative to indicate it is now revealed
    	mflo	$t6		#store back into $t6 and then board
    	sw	$t6, board($t2)
    	
    	jal 	printCards
    	set_zero_revealed:
    		#-18 indicates that the user chose (0,0)
    		#uses this when displaying the equation at (0,0)
    		lw	$t6, board($t2)
    		#check if (0,0) has already been matched
    		beq	$t6, 17, printCards
    		li	$t6, -18
    		sw	$t6, board
    		jal 	printCards
    	
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
	#print found match message
	li	$v0, 4
	la	$a0, msg_match
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
	#print found match message
	li	$v0, 4
	la	$a0, not_a_match
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
	
	j 	game_loop
 	
printCards:
	li    	$t0, 0                # $t0 will be our loop counter (i = 0)
    	li    	$t1, 16               # $t1 will be our loop end condition (16 cards)
    	li    	$t2, 4                # $t2 will be our column counter (4 cols)
  
   	 # Print top border
    	li    	$v0, 4
   	la    	$a0, border
    	syscall
    	li    	$v0, 4
    	la    	$a0, nextLine
    	syscall
    	
print_row:
	beq	$t1, $t0, print_end
 	sll	$t3, $t0, 2		#shift left 2 bits to get offset
 	
 	lw	$t6, board($t3)		#$t6 holds value at the offset
 	beq	$t6, 17, print_match
 	bgt	$t6, -1, display_hidden	#if index is positive, display hidden symbol
 	
 	neg	$t6, $t6		#get positive index
 	
 	li	$t9, 2
 	div	$t6, $t9
 	mfhi	$s7
 	
 	beq	$s7, 0, display_equation	#if index is even, display equation
 	beq	$s7, 1, display_solution	#if index is odd, display solution
 
display_equation:
	bne	$t6, 18, normal_eq 	#if user did not choose (0,0), proceed as normal
	#set the index in $t6 to hold zero instead of 18(Which is the indicator for (0,0)
	add	$t6, $zero, $zero	
normal_eq:
	sll 	$t7, $t6, 2	#get offset from curr index
	lw	$t8, offsets($t7)	#get correct offset for that index from offset array
	la	$t5, equations
	add	$t5, $t5, $t8	#$t5 holds base address + offset 
	lw	$a0, 0($t5)		 #get multiplicand and print
	li	$v0, 1
	syscall			 #prints multiplicand
	#keep track of multiplicand to be compared
	#sw	$a0, user_choice($s2)
	#addi	$s2, $s2, 4
	
	li	$v0, 4
	la	$a0, symbol
	syscall
	
	li	$v0, 1
	lw 	$a0, 4($t5) #get multiplier
	syscall
	
	#checks if we've already stored 2 choices
	beq	$s6, 2, return_eq
	
	#if this is user's 1st choice, store the equation as the first choice, otherwise as the second choice
	beq	$s0, 1, store_1st_eq
	beq	$s0, 2, store_2nd_eq
	#keep track of multiplier to be compared
	#sw	$a0, user_choice($s2)
	#addi	$s2, $s2, 4
	#addi	$s2, $zero, $zero
	
	k:
	#this is to avoid incrementing the store counter when we didnt store anything
	j	skip
	
	return_eq:
	#after storing user's choice, increment by 1 to keep track of how many choices were stored
	addi	$s6, $s6, 1
	skip:
	li	$v0, 4
	la	$a0, line
	syscall
	
	addi	$t0, $t0, 1
	
	j	end_display

display_solution:
	
	li	$v0, 4
	la	$a0, space
	syscall
	syscall
	
	sll 	$t7, $t6, 2	#get offset from curr index
	lw	$t8, offsets($t7)
	lw	$a0, solutions($t8) #get solution and print
	li	$v0, 1
	syscall			 #prints solution
	
	bgt 	$s6, 2, return_sol
	#if this is user's 1st choice, store the solution as the first choice, otherwise as the second choice
	beq	$s0, 1, store_1st_sol
	beq	$s0, 2, store_2nd_sol
	#store the current solution to compare
	#sw	$a0, user_choice($s2)
	#addi	$s2, $s2, 4
	
	h:
	j skip2
	
	return_sol:
	#after storing user's choice, increment by 1 to keep track of how many choices were stored
	addi	$s6, $s6, 1
	skip2:
	li	$v0, 4
	la	$a0, space
	syscall
	
	lw	$t9, solutions($t8)
	li	$t8, 10
	div	$t9, $t8
	mflo	$t9
	bge	$t9, 1, line_spaced
	line_double_spaced:
		la	$a0, endLine
		syscall
		addi	$t0, $t0, 1
		j	end_display
	line_spaced:
		la	$a0, line
		syscall
		addi	$t0, $t0, 1
		j	end_display

store_1st_eq:
	la	$a1, choice_one
	#store the multiplicand
	lw	$a0, 0($t5)
	sw	$a0, 0($a1)
	#store the multiplier
	lw	$a0, 4($t5)
	sw	$a0, 4($a1)
	
	#store a -1 to indicate that user chose an equation
	li	$a0, -1
	sw	$a0, indicator($s3)
	addi	$s3, $s3, 4
	
	#store the current index to keep track of which index we have already encountered
	la	$s1, stored_indicies
	sw	$t6, 0($s1)
	
	j	return_eq
	
store_2nd_eq:
	#compare current index with index from stored_indicies
	la	$s1, stored_indicies
	lw	$s2, 0($s1)
	beq	$s2, $t6, k
	
	addi	$s1, $s1, 4
	sw	$t6, 0($s1)

	la	$a1, choice_two
	#store the multiplicand
	lw	$a0, 0($t5)
	sw	$a0, 0($a1)
	#store the multiplier
	lw	$a0, 4($t5)
	sw	$a0, 4($a1)	
	
	#store a -1 to indicate that user chose an equation
	li	$a0, -1
	sw	$a0, indicator($s3)
	addi	$s3, $s3, 4
	
	j	return_eq
	
store_1st_sol:
	la	$a1, choice_one
	#store the solution as 1st 
	sw	$a0, 0($a1)
	
	#store a 1 to indicate user chose a solution
	li	$s4, 1
	sw	$s4, indicator($s3)
	addi	$s3, $s3, 4
	
	addi	$t4, $t4, 1
	
	#store the current index to keep track of which index we have already encountered
	la	$s1, stored_indicies
	sw	$t6, 0($s1)
	
	j	return_sol
	
store_2nd_sol:
	#compare current index with index from stored_indicies
	la	$s1, stored_indicies
	lw	$s2, 0($s1)
	beq	$s2, $t6, h
	
	addi	$s1, $s1, 4
	sw	$t6, 0($s1)
	
	la	$a1, choice_two
	#store the solution as 2nd
	sw	$a0, 0($a1)	
	
	#store a 1 to indicate user chose a solution
	li	$s4, 1
	sw	$s4, indicator($s3)
	addi	$s3, $s3, 4
	
	j	return_sol
print_match:
	#display "=" for matched cards
	li    	$v0, 4
    	la    	$a0, matched_crd    # matched card symbol with spacing
    	syscall
    	
    	addi	$t0, $t0, 1
    	
    	j 	end_display	
display_hidden:
    	# Display "x" for hidden cards
    	li    	$v0, 4
    	la    	$a0, card    # Hidden card symbol with spacing
    	syscall
    	
    	addi	$t0, $t0, 1
    	
    	j 	end_display
end_display:
    	# Update the row format: print a newline after every 4 cards
    	addi  	$t2, $t2, -1          # Decrement column counter
   	beqz  	$t2, new_line          # If column counter is zero, start new row
    	j     	print_row 	
		
new_line:
	li    	$v0, 4
    	la    	$a0, nextLine
    	syscall  	
    	li	$t2, 4
	j	print_row

print_end:
    	# Print bottom border
    	li    	$v0, 4
    	la    	$a0, border
    	syscall
    	li    	$v0, 4
    	la    	$a0, nextLine
    	syscall
    	beq	$s0, 2, check_match
    	j	game_loop	

	
	
