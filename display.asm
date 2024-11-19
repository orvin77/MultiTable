.data
#extra data
space:			.asciiz " "
endLine:		.asciiz	" |" 
line:			.asciiz "|"

.text

.globl	printCards
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
