################################
# UNIT pixel WIDTH = 8
# UNIT pixel WIDTH = 8
# Display width in pixels = 512
# Display height in pixels = 256
# 512 x 256 display
################################

.data	
equations: 		.space	64	#64 bytes to store both multiplicand and multiplier
solutions:		.space	32	#32 bytes to store solutions
offsets:		.space	64	#64 bytes to store correct offset positions to access corresponding equations and solutions
board:			.space 	64	#64 bytes for 16 cells
taken_spots:		.word	0
nums:			.word 	1, 2, 3, 4, 5	#choice of numbers for easy mode

#extra data
space:			.asciiz " "
endLine:		.asciiz	" |" 
line:			.asciiz "|"
prompt_row:    		.asciiz "Enter row (0-3): "
prompt_col:    		.asciiz "Enter column (0-3): "

.text

.globl main, board, equations, solutions, offsets, nums, taken_spots

main:
	jal 	rand_vals		#initialize random equations and corresponding solutions
	addi	$t0, $zero, 0		#set $t1 back to 0
	addi	$t1, $zero, 0		#set $t1 back to 0
	
	jal	init_offsets		#initialize the offsets to get corresponding equations and solutions
	jal 	display_remaining
	addi	$t0, $zero, 0		#set $t1 back to 0
	addi	$t1, $zero, 0		#set $t1 back to 0
init_board:
    	beq   	$t0, 16, init_end    # End initialization after 16 cells
   	sw    	$t0, board($t1)       # Store card index in board
    	addi  	$t1, $t1, 4           # Move to the next cell
    	addi  	$t0, $t0, 1
    	j     	init_board
init_end:
	jal printCards
game_loop:
    	# Prompt for row
    	li    	$v0, 4
    	la    	$a0, prompt_row
    	syscall
	
    	li    	$v0, 5               # Read integer syscall
   	syscall
    	move  	$t0, $v0             # Store row in $t0

    	# Prompt for column
    	li    	$v0, 4
    	la   	$a0, prompt_col
    	syscall

    	li    	$v0, 5               # Read integer syscall
    	syscall
    	move  	$t1, $v0             # Store column in $t1
    
    	add	$t3, $t1, $t0	    #add coordinates and determine if even or odd
    	li 	$t9, 2
    	div 	$t3, $t9
    	mfhi 	$s7  		# if remainder is 0, summed coordinates are even and an equation, cell is a solution otherwise
    	
    	
    	
    	# Calculate the 1D index in a 4x4 board using row and column
   	mul   	$t2, $t0, 16          # $t2 = row * 16
   	sll	$t1, $t1, 2		# col * 4
    	add   	$t2, $t2, $t1        # $t2 = row * 16 + column * 4, index of selected card
    	
    	lw	$t6, board($t2)
    	li	$t5, -1
    	mult 	$t6, $t5	#turn index negative to indicate it is now revealed
    	mflo	$t6		#store back into $t6 and then board
    	sw	$t6, board($t2)
    	
    	jal 	printCards
    	
check_match:	
 	j 	game_loop
 	
printCards:
	li    $t0, 0                # $t0 will be our loop counter (i = 0)
    	li    $t1, 16               # $t1 will be our loop end condition (16 cards)
    	li    $t2, 4                # $t2 will be our column counter (4 cols)

   	 # Print top border
    	li    $v0, 4
   	la    $a0, border
    	syscall
    	li    $v0, 4
    	la    $a0, nextLine
    	syscall
    	
print_row:
	beq	$t1, $t0, print_end
 	sll	$t3, $t0, 2		#shift left 2 bits to get offset
 	
 	lw	$t6, board($t3)		#$t6 holds value at the offset
 	bgt	$t6, -1, display_hidden	#if index is positive, display hidden symbol
 	
 	neg	$t6, $t6		#get positive index
 	
 	li	$t9, 2
 	div	$t6, $t9
 	mfhi	$s7
 	
 	beq	$s7, 0, display_equation	#if index is even, display equation
 	beq	$s7, 1, display_solution	#if index is odd, display solution
 
display_equation:
	sll 	$t7, $t6, 2	#get offset from curr index
	lw	$t8, offsets($t7)	#get correct offset for that index from offset array
	la	$t5, equations
	add	$t5, $t5, $t8	#$t5 holds base address + offset 
	lw	$a0, 0($t5)		 #get multiplicand and print
	li	$v0, 1
	syscall			 #prints multiplicand
	
	li	$v0, 4
	la	$a0, symbol
	syscall
	
	li	$v0, 1
	lw 	$a0, 4($t5) #get multiplier
	syscall
	
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
    	j	check_match	

	
	
