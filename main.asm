.data
    board:        .space 64                  # 4x4 board (16 cards, each 4 bytes)
    equations:    .asciiz "2 * 3", "5 - 1", "4 / 2", "3 + 3", "6 - 3"  # Sample equations
    solutions:    .word 6, 4, 2, 6, 3        # Matching solutions for equations
    prompt_row:   .asciiz "Enter row (0-3): "
    prompt_col:   .asciiz "Enter column (0-3): "
    remaining:    .asciiz "Number of cards left: "
    border:       .asciiz "-------------------------" 
    nextLine:     .asciiz "\n"
    hidden_symbol: .asciiz " | x |"            # "x" symbol for hidden cards with spacing

.text
.globl main

main:
    # Initialize the board with zeros to prevent garbage values
    li    $t0, 0               # Loop index
init_board:
    li    $t1, 16              # Total cells in the board
    la    $t2, board           # Base address of board
init_loop:
    bge   $t0, $t1, init_end   # End initialization after 16 cells
    sw    $zero, 0($t2)        # Set each cell to 0 (hidden)
    addi  $t2, $t2, 4          # Move to the next cell
    addi  $t0, $t0, 1
    j     init_loop
init_end:

    # Display initial board with all cards hidden
    li    $s1, 16              # we SAVE the total number of cards (16) for later
    jal   display_remaining    # Lets make the remaining count box
    jal   printCards           # Lets now make each card in their original state (hidden)

game_loop:
    # Prompt for row
    li    $v0, 4
    la    $a0, prompt_row
    syscall
    
    li    $v0, 5               # Read integer syscall
    syscall
    move  $t0, $v0             # Store row in $t0
    
    # Prompt for column
    li    $v0, 4
    la    $a0, prompt_col
    syscall
    
    li    $v0, 5               # Read integer syscall
    syscall
    move  $t1, $v0             # Store column in $t1

    # Calculate the 1D index in a 4x4 board using row and column
    mul   $t2, $t0, 4          # $t2 = row * 4
    add   $t2, $t2, $t1        # $t2 = row * 4 + column, index of selected card

    # Reveal the selected card by accessing board array
    la    $t3, equations       # Base address of equations array
    lw    $t4, 0($t3)          # Load the equation to reveal (as an example)

    # Store the revealed value in board array at calculated index
    sll   $t5, $t2, 2          # Multiply index by 4 (word size) for address offset
    la    $t6, board           # Base address of board
    add   $t7, $t6, $t5        # $t7 now holds the exact address of the target board cell
    sw    $t4, 0($t7)          # Store equation in the board at calculated position

    # Display updated board with revealed card
    jal printCards

    # For simplicity, loop indefinitely (implement a break condition later)
    j game_loop

# Display remaining count and the board
display_remaining:
    li    $v0, 4                # "Get ready to print a string type"
    la    $a0, remaining        #  Gets the address we stored in .data and print "Remaining cards: "
    syscall
    
    move  $a0, $s1              # Remember how we set the $s1 to the starting card count (16)? Lets go ahead and print it
    li    $v0, 1                # Recall that syscall 1 means "Lets get ready to print a integer type"
    syscall
    
    # Display the board border and move to the next line
    li    $v0, 4                
    la    $a0, nextLine         # this calls our predefined newline from .data to print it
    syscall
    
    jr    $ra

# Display board with flipped or hidden cards
printCards:
    li    $t0, 0                # $t0 will be our loop counter (i = 0)
    li    $t1, 16               # $t1 will be our loop end condition (16 cards) (i <= 16)
    li    $t2, 4                # $t2 will be our column counter (4 cols by 4 rows) 

    # Print top border
    li    $v0, 4
    la    $a0, border           # Load in the top border for our display from .data
    syscall
    li    $v0, 4
    la    $a0, nextLine
    syscall

print_row:
    # Check if we’ve reached the end of the board
    bge   $t0, $t1, print_end   # Start of our loop (While i < 16)

    # Calculate the address of the current board cell
    sll   $t3, $t0, 2           # $t3 = store the space between current and next card. SLL (or multiply) our start by 2^2 (4 bytes per word) (i * 4)
    la    $t4, board            # Load base address of board
    add   $t5, $t4, $t3         # $t5 = Our starting address + the distance (which gives us the next card address)

    # Load the value at the current cell
    lw    $t6, 0($t5)           # Load the value at the calculated address

    # Check if the card is hidden (0 represents "x")
    beq   $t6, $zero, display_hidden

    # If card is revealed, display its actual value
    li    $v0, 1                # Print integer syscall for the revealed value
    move  $a0, $t6
    syscall
    j     end_display           # Skip to the end

display_hidden:
    # Display "x" for hidden cards
    li    $v0, 4
    la    $a0, hidden_symbol    # Hidden card symbol with spacing // print 'x'
    syscall

end_display:
    # Update the row format: print a newline after every 4 cards
    addi  $t2, $t2, -1          # 4 cards (columns) - the one we just made)
    beqz  $t2, new_row          # If we made 4 cards ($t2 = 0) then we want to go to the next row. beqz = Brance equal to zero
    j     next_card

new_row:
    li    $v0, 4
    la    $a0, nextLine         # Move to next line after each row
    syscall
    li    $t2, 4                # Reset cards per row counter

next_card:
    addi  $t0, $t0, 1           # Increment our counter by 1 since we made a card ( i++)
    j     print_row             # Loop back

print_end:
    # Print bottom border
    li    $v0, 4
    la    $a0, border
    syscall
    li    $v0, 4
    la    $a0, nextLine
    syscall
    
    jr    $ra
