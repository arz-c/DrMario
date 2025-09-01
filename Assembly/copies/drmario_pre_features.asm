################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student: Areez Chishtie, 1010009027
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
# - Display width in pixels:    64
# - Display height in pixels:   64
# - Base Address for Display:   0x10008000 ($gp)
#
# Note: the bitmap contains 32 rows of 128 = 32 * 4 bytes
##############################################################################

  .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
  .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
  .word 0xffff0000
# The three main colours, and two background colours
COLR_RED:
  .word 0xff3333
COLR_BLUE:
  .word 0x3399ff
COLR_YELL:
  .word 0xffff33
COLR_GREY:
  .word 0x404040
COLR_BLACK:
  .word 0x000000

##############################################################################
# Mutable Data
##############################################################################
# The current pill represented in a size 4 array of 1 word elements
# - pill[0] = position of pixel 1 in display bitmap
# - pill[1] = colour of pixel 1
# - pill[2] = position of pixel 2 in display bitmap
# - pill[3] = colour of pixel 2
pill:
  .space 16
# The bitmap of the playing field (medicine bottle + static pills)
# - the field bitmap mirrors the display bitmap, containing 32x32 pixels
# - only non-blackened portion is the playing field, which is 19x28 pixels
# - top-left pixel of the field is located at (2, 2) = ADDR_DSPL + 264
# - the interior of the field (i.e. excluding the medicine bottle) is 17x24 pixels
# - top-left pixel of intr field is located at (3, 5) = ADDR_DSPL + 652
field:
  .space 4096

##############################################################################
# Code
##############################################################################
  .text
  .globl main

  # Run the game.
main:
  # Initialize the game
  jal initialize_field        # initialize field to an empty array
  jal initialize_background   # draw medicine bottle to field
  jal create_pill             # initialize pill with random colours

  j game_loop   # jump to the game loop

# Funtion that initializes field to an empty array (of black pixels)
initialize_field:
  lw $t0, COLR_BLACK   # $t0 = black
  la $t1, field        # $t1 = base address for field
  li $t2, 0            # initialize loop variable $t2
  li $t3, 1024         # set stop variable $t3 (1024 = bytes in field / 4)

  initialize_field_start:
    sw $t0, 0($t1)     # initialize the current pixel in field to black
    addi $t2, $t2, 1   # increment loop variable
    addi $t1, $t1, 4   # move current field address to next pixel
    beq $t2, $t3, initialize_field_end   # check stopping condition
    j initialize_field_start             # repeat loop
  initialize_field_end:

# Function that draws the background medicine bottle to field
initialize_background:
  la $t0, field   # $t0 = base address for display
  lw $t1, COLR_GREY   # $t1 = background colour

  # Draw two vertical lines for the walls
  li $t2, 0            # initialize loop variable $t2
  li $t3, 26           # set stop variable $t3 (length = 26 px)
  addi $t4, $t0, 520   # initialize current bitmap position $t4 (to (2, 4))
  
  draw_wall_start:   
      sw $t1, 0($t4)       # paint along the left wall
      sw $t1, 72($t4)      # paint along the right wall (width = 17 px)
      addi $t2, $t2, 1     # increment loop variable
      addi $t4, $t4, 128   # move to next row
      beq $t2, $t3, draw_wall_end   # check stopping condition
      j draw_wall_start             # repeat loop
  draw_wall_end:

  # Draw horizontal line for the floor
  li $t2, 0             # initialize loop variable $t2
  li $t3, 17            # set stop variable $t3 (length = 17 px)
  addi $t4, $t0, 3724   # initialize current bitmap position $t4 (to (3, 29))
  
  draw_floor_start:
      sw $t1, 0($t4)     # paint the current pixel
      addi $t2, $t2, 1   # increment loop variable
      addi $t4, $t4, 4   # move to next pixel in row
      beq $t2, $t3, draw_floor_end   # check stopping condition
      j draw_floor_start             # repeat loop
  draw_floor_end:

  # Draw two horizontal lines for the ceiling
  li $t2, 0            # initialize loop variable $t2
  li $t3, 7            # set stop variable $t3 (length = 7 px)
  addi $t4, $t0, 524   # initialize current bitmap position $t4 (to (3, 4))
  
  draw_ceil_start:   
      sw $t1, 0($t4)     # paint along the left part
      sw $t1, 40($t4)    # paint along the right part (offset = 10 px)
      addi $t2, $t2, 1   # increment loop variable
      addi $t4, $t4, 4   # move to next pixel in row
      beq $t2, $t3, draw_ceil_end   # check stopping condition
      j draw_ceil_start             # repeat loop
  draw_ceil_end:

  # Draw two vertical lines for the mouth of ceiling
  li $t2, 0            # initialize loop variable $t2
  li $t3, 2            # set stop variable $t3 (length = 2 px)
  addi $t4, $t0, 292   # initialize current bitmap position $t4 (to (9, 2))
  
  draw_ceil_mouth_start:   
      sw $t1, 0($t4)       # paint along the left part
      sw $t1, 16($t4)      # paint along the right part (offset = 4 px)
      addi $t2, $t2, 1     # increment loop variable
      addi $t4, $t4, 128   # move to next row
      beq $t2, $t3, draw_ceil_mouth_end   # check stopping condition
      j draw_ceil_mouth_start             # repeat loop
  draw_ceil_mouth_end:

  jr $ra   # return

# Function that sets 'pill' to a randomly coloured pill at the starting location.
create_pill:
  la $t1, pill        # $t1 = address of pill
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push return address to stack
  
  li $t2, 300
  sw $t2, 0($t1)      # pill[0] = 300 = (11, 2)
  jal random_colour   # call helper function
  sw $v0, 4($t1)      # pill[1] = returned colour

  li $t2, 428
  sw $t2, 8($t1)      # pill[2] = 428 = (11, 3)
  jal random_colour   # call helper function
  sw $v0, 12($t1)     # pill[3] = returned colour

  lw $ra, 0($sp)     # pop return address from stack to $ra
  addi $sp, $sp, 4   # free 1 word from stack
  jr $ra             # return

# Helper function for create_pill that returns a random main colour to $v0.
random_colour:
  # generate a random integer between 0 and 2, inclusive
  li $v0, 42   # set syscall operation to RNG
  li $a0, 0    # minimum (inclusive)
  li $a1, 3    # maximum (exclusive)
  syscall      # return value is $a0

  # branch off by the random number
  beq $a0, 0, random_colour_red
  beq $a0, 1, random_colour_blue
  beq $a0, 2, random_colour_yellow

  # set $v0 to the colour determined by the random number
  random_colour_red:
    lw $v0, COLR_RED
    j random_colour_end
  random_colour_blue:
    lw $v0, COLR_BLUE
    j random_colour_end
  random_colour_yellow:
    lw $v0, COLR_YELL
    j random_colour_end
  random_colour_end:

  jr $ra   # return

game_loop:
  # 1a. Check if key has been pressed
  lw $t0, ADDR_KBRD         # t0 = base address for keyboard
  lw $t1, 0($t0)            # $t1 = first word from keyboard
  beq $t1, 1, key_pressed   # if first word is 1, a key was presed
  j update_locations_end    # else, skip input handling
  
  # 1b. Check which key has been pressed
  key_pressed:
    lw $t1, 4($t0)                # $t1 = second word from keyboard
    beq $t1, 0x73, respond_to_s   # check if 's' was pressed
    beq $t1, 0x61, respond_to_a   # check if 'a' was pressed
    beq $t1, 0x64, respond_to_d   # check if 'd' was pressed
    beq $t1, 0x77, respond_to_w   # check if 'w' was pressed
    beq $t1, 0x71, respond_to_q   # check if 'q' was pressed
    j update_locations_end        # if an unmapped key was pressed, skip input handling

  respond_to_q:
      li $v0, 10   # quit gracefully
      syscall
  
  # 2a. Update locations (capsules)
  respond_to_s:
    # move current pill to the next row
    la $t2, pill   # $t2 = address of pill

    # update pixel 1 (there is always space below)
    lw $t3, 0($t2)       # $t3 = pill[0] = position of pixel 1
    addi $t3, $t3, 128   # add one row to $t3
    sw $t3, 0($t2)       # pill[0] = $t3

    # update pixel 2 (there is always space below)
    lw $t4, 8($t2)       # $t4 = pill[2] = position of pixel 2
    addi $t4, $t4, 128   # add one row to $t4
    sw $t4, 8($t2)       # pill[2] = $t4

    j update_locations_end

  respond_to_a:
    # move current pill to the next pixel in the row
    la $t2, pill   # $t2 = address of pill

    # compute new position of pixel 1
    lw $t3, 0($t2)     # $t3 = pill[0] = position of pixel 1
    add $t3, $t3, -4   # subtract one column to $t3

    # check if new pixel 1 collided with something
    add $a0, $t3, $zero   # $a0 = position of new pixel 1
    jal is_black          # call function
    beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 1 was black, so stop

    # compute new position of pixel 2
    lw $t4, 8($t2)     # $t4 = pill[2] = position of pixel 2
    add $t4, $t4, -4   # subtract one column from $t3

    # if the pill is vertical, check if pixel 2 collided
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t2, 0($sp)      # push $t2 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t3, 0($sp)      # push $t3 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t4, 0($sp)      # push $t4 to stack
    
    jal pill_orien      # call function

    lw $t4, 0($sp)     # pop $t4 to stack
    addi $sp, $sp, 4   # free 1 word from stack
    lw $t3, 0($sp)     # pop $t3 from stack
    addi $sp, $sp, 4   # free 1 word from stack
    lw $t2, 0($sp)     # pop $t2 from stack
    addi $sp, $sp, 4   # free 1 word from stack
  
    beq $v0, 0, respond_to_a_vertical   # if 0 was returned, pill is vertical
    sw $t3, 0($t2)           # otherwise: update pixel 1,
    sw $t4, 8($t2)           # and pixel 2,
    j update_locations_end   # and finish input handling

    respond_to_a_vertical:
      # check if new pixel 2 collided with something
      add $a0, $t4, $zero   # $a0 = position of new pixel 2

      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t2, 0($sp)      # push $t2 to stack
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t3, 0($sp)      # push $t3 to stack
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t4, 0($sp)      # push $t4 to stack
      
      jal is_black   # call function

      lw $t4, 0($sp)     # pop $t4 to stack
      addi $sp, $sp, 4   # free 1 word from stack
      lw $t3, 0($sp)     # pop $t3 from stack
      addi $sp, $sp, 4   # free 1 word from stack
      lw $t2, 0($sp)     # pop $t2 from stack
      addi $sp, $sp, 4   # free 1 word from stack
      
      beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 2 was not black, so stop
      sw $t3, 0($t2)           # otherwise: update pixel 1,
      sw $t4, 8($t2)           # and pixel 2,
      j update_locations_end   # and finish input handling

  respond_to_d:
    # move current pill to the next pixel in the row
    la $t2, pill   # $t2 = address of pill
  
    # compute new position of pixel 2
    lw $t3, 8($t2)    # $t3 = pill[2] = position of pixel 2
    add $t3, $t3, 4   # add one column to $t3
  
    # check if new pixel 2 collided with something
    add $a0, $t3, $zero   # $a0 = position of new pixel 1
    jal is_black          # call function
    beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 1 was black, so stop
  
    # compute new position of pixel 1
    lw $t4, 0($t2)    # $t4 = pill[0] = position of pixel 1
    add $t4, $t4, 4   # add one column to $t3
  
    # if the pill is vertical, check if pixel 1 collided
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t2, 0($sp)      # push $t2 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t3, 0($sp)      # push $t3 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t4, 0($sp)      # push $t4 to stack
    
    jal pill_orien      # call function
  
    lw $t4, 0($sp)     # pop $t4 to stack
    addi $sp, $sp, 4   # free 1 word from stack
    lw $t3, 0($sp)     # pop $t3 from stack
    addi $sp, $sp, 4   # free 1 word from stack
    lw $t2, 0($sp)     # pop $t2 from stack
    addi $sp, $sp, 4   # free 1 word from stack
  
    beq $v0, 0, respond_to_d_vertical   # if 0 was returned, pill is vertical
    sw $t3, 8($t2)           # otherwise: update pixel 2,
    sw $t4, 0($t2)           # and pixel 1,
    j update_locations_end   # and finish input handling
  
    respond_to_d_vertical:
      # check if new pixel 1 collided with something
      add $a0, $t4, $zero   # $a0 = position of new pixel 2
  
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t2, 0($sp)      # push $t2 to stack
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t3, 0($sp)      # push $t3 to stack
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t4, 0($sp)      # push $t4 to stack
      
      jal is_black   # call function
  
      lw $t4, 0($sp)     # pop $t4 to stack
      addi $sp, $sp, 4   # free 1 word from stack
      lw $t3, 0($sp)     # pop $t3 from stack
      addi $sp, $sp, 4   # free 1 word from stack
      lw $t2, 0($sp)     # pop $t2 from stack
      addi $sp, $sp, 4   # free 1 word from stack
      
      beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 2 was not black, so stop
      sw $t3, 8($t2)           # otherwise: update pixel 2,
      sw $t4, 0($t2)           # and pixel 1,
      j update_locations_end   # and finish input handling

  respond_to_w:
    # check if pill is currently oriented vertically or horizontally
    jal pill_orien
    beq $v0, 0, rotate_vertical     # if 0 was returned, pill is vertical
    beq $v0, 1, rotate_horizontal   # if 1 was returned, pill is horizontal
    j update_locations_end   # this should never be hit (pill is always either vertical or horizontal)

    rotate_vertical:
      la $t2, pill   # $t2 = address of pill

      # compute x1++ and y1++
      lw $t3, 0($t2)       # $t3 = pill[0] = position of pixel 1
      addi $t3, $t3, 132   # $t3 = $t3 + (1, 1)

      # check if new pixel 1 collides with something
      # (it suffices to just check pixel 1 = originally top pixel)
      add $a0, $t3, $zero   # $a0 = position of new pixel 1
  
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t2, 0($sp)      # push $t2 to stack
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t3, 0($sp)      # push $t3 to stack
      
      jal is_black   # call function
  
      lw $t3, 0($sp)     # pop $t3 from stack
      addi $sp, $sp, 4   # free 1 word from stack
      lw $t2, 0($sp)     # pop $t2 from stack
      addi $sp, $sp, 4   # free 1 word from stack
      
      beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 1 was not black, so stop
      sw $t3, 0($t2)   # otherwise: update pixel 1

      # swap the roles of pixel 1 and pixel 2
      # $t3 already has position of pixel 1
      lw $t4, 4($t2)    # $t4 = pill[1] = colour of pixel 1
      lw $t5, 8($t2)    # $t5 = pill[2] = position of pixel 2
      lw $t6, 12($t2)   # $t6 = pill[3] = colour of pixel 2
      sw $t5, 0($t2)    # pill[0] = $t5
      sw $t6, 4($t2)    # pill[1] = $t6
      sw $t3, 8($t2)    # pill[2] = $t3
      sw $t4, 12($t2)   # pill[3] = $t4
      
      j update_locations_end
  
    rotate_horizontal:
      la $t2, pill   # $t2 = address of pill

      # compute y1++
      lw $t3, 0($t2)        # $t3 = pill[0] = position of pixel 1
      addi $t3, $t3, -128   # $t3 = $t3 + (0, -1)

      # compute x2--
      lw $t4, 8($t2)      # $t4 = pill[2] = position of pixel 2
      addi $t4, $t4, -4   # $t4 = $t4 + (-1, 0)

      # check if new pixel 1 collides with something
      # (it suffices to just check pixel 1 = originally right pixel)
      add $a0, $t3, $zero   # $a0 = position of new pixel 1
  
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t2, 0($sp)      # push $t2 to stack
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t3, 0($sp)      # push $t3 to stack
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $t4, 0($sp)      # push $t4 to stack
      
      jal is_black   # call function

      lw $t4, 0($sp)     # pop $t4 from stack
      addi $sp, $sp, 4   # allocate 1 word in stack
      lw $t3, 0($sp)     # pop $t3 from stack
      addi $sp, $sp, 4   # free 1 word from stack
      lw $t2, 0($sp)     # pop $t2 from stack
      addi $sp, $sp, 4   # free 1 word from stack
      
      beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 1 was not black, so stop
      sw $t3, 0($t2)           # otherwise: update pixel 1,
      sw $t4, 8($t2)           # and pixel 2,
      j update_locations_end   # and finish input handling

  update_locations_end:

  # 2b. Check if current pill landed (i.e. the pixel below the pill is not black)
  # check if pixel 2 landed
  la $t2, pill         # $t2 = address of pill
  lw $a0, 8($t2)       # $a0 = pill[2] = position of pixel 2
  addi $a0, $a0, 128   # $a0 = position of the pixel below pixel 2
  jal is_black         # call function
  beq $v0, 0, pill_landed   # if 0 was returned, pixel below pixel 2 is not black
  
  # if the pill is horizontal, also check if new pixel 1 landed
  jal pill_orien       # call function
  beq $v0, 1, check_landed_horizontal   # if 1 was returned, pill is horizontal
  j check_landed_end   # otherwise, the pill didn't land

  check_landed_horizontal:
    # check if pixel 1 landed
    la $t2, pill         # $t2 = address of pill
    lw $a0, 0($t2)       # $a0 = pill[0] = position of pixel 1
    addi $a0, $a0, 128   # $a0 = position of the pixel below pixel 1
    jal is_black
    beq $v0, 0, pill_landed   # if 0 was returned, pixel below new pixel 1 is not black
    j check_landed_end   # otherwise, the pill didn't land

  pill_landed:
    la $t2, pill   # $t2 = address of pill

    # save pixel 1 to field
    la $t3, field    # $t3 = base address for field
    lw $t4, 0($t2)   # $t4 = pill[0] = position of pixel 1

    ble $t4, 560, main   # if position of pixel 1 <= (12, 4), then game over
    
    lw $t5, 4($t2)      # $t5 = pill[1] = colour of pixel 1
    add $t3, $t3, $t4   # $t3 = address of pixel 1 within field
    sw $t5, 0($t3)      # store pixel 1 in field

    # save pixel 2 to field
    la $t3, field       # $t3 = base address for field
    lw $t4, 8($t2)      # $t4 = pill[2] = position of pixel 2
    lw $t5, 12($t2)     # $t5 = pill[3] = colour of pixel 2
    add $t3, $t3, $t4   # $t3 = address of pixel 2 within field
    sw $t5, 0($t3)      # store pixel 2 in field

    jal eliminate_field   # eliminate any lines of 4+ pixels of the same colour from field
    jal create_pill       # create a new random pill at the starting location
    j check_landed_end

  check_landed_end:
  
  # 3. Draw the screen
  jal reset_display     # reset the entire display
  jal draw_field        # draw the playing field on the display
  jal draw_pill         # draw the current pill on the display
  
  # 4. Sleep
  li $v0, 32   # set syscall operation to sleep
  li $a0, 17   # sleep duration is 17 ms (~60 FPS)
  syscall

  # 5. Go back to Step 1
  j game_loop

# Function that eliminates any lines of 4+ pixels of the same colour from field.
# If at least one line was eliminated, then also asynchronously drops any floating pills,
# and jumps back to eliminate_field to check whether any new lines have been formed.
eliminate_field:
  # store $ra
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack
  
  # eliminate every vertical line
  li $t1, 652   # initialize current line $t1 to (3, 5) = position of top-left pixel in intr field
  li $t2, 0     # initialize loop variable $t2 (tracks x coordinate)
  li $t3, 17    # set stop variable $t3 (17 pixels = width of intr field)
  li $t4, 0     # $t4 = boolean for whether at least one line was eliminated
  
  eliminate_field_vertical_start:
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t1, 0($sp)      # push $t1 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t2, 0($sp)      # push $t2 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t3, 0($sp)      # push $t3 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t4, 0($sp)      # push $t4 to stack

    add $a0, $t1, $zero      # $a0 = $t1
    jal eliminate_vertical   # eliminate current vertical line
    
    lw $t4, 0($sp)      # pop $t4 to stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t3, 0($sp)      # pop $t3 to stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t2, 0($sp)      # pop $t2 to stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t1, 0($sp)      # pop $t1 to stack
    addi $sp, $sp, 4    # free 1 word from stack

    beq $v0, 1, eliminate_field_vertical_if_elimed   # if return value was 1
    j eliminate_field_vertical_increment   # otherwise, increment and continue
    eliminate_field_vertical_if_elimed:
      li $t4, 1   # set boolean to 1 to indicate that a line was eliminated
      j eliminate_field_vertical_increment   # increment and continue
    
    eliminate_field_vertical_increment:
    addi $t1, $t1, 4   # move current line to the right by one
    addi $t2, $t2, 1   # increment loop variable (x++)
    beq $t2, $t3, eliminate_field_vertical_end   # check loop stop condition
    j eliminate_field_vertical_start   # if not met, repeat loop
  eliminate_field_vertical_end:
    
  # eliminate every horizontal line
  li $t1, 652   # initialize current line $t1 to (3, 5) = position of top-left pixel in intr field
  li $t2, 0     # initialize loop variable $t2 (tracks y coordinate)
  li $t3, 24    # set stop variable $t3 (24 pixels = height of intr field)
  
  eliminate_field_horizontal_start:
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t1, 0($sp)      # push $t1 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t2, 0($sp)      # push $t2 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t3, 0($sp)      # push $t3 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t4, 0($sp)      # push $t4 to stack

    add $a0, $t1, $zero        # $a0 = $t1
    jal eliminate_horizontal   # eliminate current horizontal line
    
    lw $t4, 0($sp)      # pop $t4 to stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t3, 0($sp)      # pop $t3 to stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t2, 0($sp)      # pop $t2 to stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t1, 0($sp)      # pop $t1 to stack
    addi $sp, $sp, 4    # free 1 word from stack

    beq $v0, 1, eliminate_field_horizontal_if_elimed   # if return value was 1
    j eliminate_field_horizontal_increment   # otherwise, increment and continue
    eliminate_field_horizontal_if_elimed:
      li $t4, 1   # set boolean to 1 to indicate that a line was eliminated
      j eliminate_field_horizontal_increment   # increment and continue
    
    eliminate_field_horizontal_increment:
    addi $t1, $t1, 128   # move current line down by one
    addi $t2, $t2, 1     # increment loop variable (y++)
    beq $t2, $t3, eliminate_field_horizontal_end   # check loop stop condition
    j eliminate_field_horizontal_start   # if not met, repeat loop
  eliminate_field_horizontal_end:

  # restore $ra
  lw $ra, 0($sp)     # pop $t1 to stack
  addi $sp, $sp, 4   # free 1 word from stack
  
  # if any call returned 1 (so a line was eliminated), then drop field
  beq $t4, 1, drop_field
  jr $ra   # otherwise, return

  # run an async game loop that allows static pills in the playing field to drop
  # jump back to eliminate_field at the end to check for any new lines
  drop_field:
    la $t0, field         # $t0 = base address for field
    addi $t1, $t0, 3596   # $t1 = (3, 28) address of bottom-left pixel in intr field
    addi $t1, $t1, -128   # skip checking the last row
    
    li $t2, 0    # initialize outer loop variable $t2 (tracks y coordinate)
    li $t3, 23   # set outer stop variable $t3 (23 pixels = one less than height of intr field)
    li $t4, 0    # initialize inner loop variable $t4 (tracks x coordinate)
    li $t5, 17   # set inner stop variable $t5 (17 pixels = width of intr field)
    li $t8, 0    # $t8 = boolean for whether at least one pixel was dropped
    
    lw $t9, COLR_BLACK   # $t9 = black
  
    drop_field_start:
      drop_field_row_start:
        lw $t6, 0($t1)   # $t6 = current pixel in field
        # if current pixel != black:
        bne $t6, $t9, drop_field_curr_not_black
        j drop_field_row_increment   # otherwise, increment and continue
        drop_field_curr_not_black:
          # if pixel below current pixel == black:
          lw $t7, 128($t1)   # $t7 = pixel below current pixel
          beq $t7, $t9, drop_field_below_is_black
          j drop_field_row_increment   # otherwise, increment and continue
          drop_field_below_is_black:
            # move current pixel down by one
            sw $t9, 0($t1)     # blacken current pixel
            sw $t6, 128($t1)   # replace the pixel below current by the current pixel
            li $t8, 1          # set boolean to 1 to indicate that a pixel was dropped
            j drop_field_row_increment   # increment and continue
        drop_field_row_increment:
        addi $t4, $t4, 1   # increment inner loop variable (x++)
        addi $t1, $t1, 4   # move current field address to next pixel in row
        beq $t4, $t5, drop_field_row_end   # check if end of row has been reached (x == 17)
        j drop_field_row_start             # otherwise, repeat inner loop
      drop_field_row_end:
      li $t4, 0              # reset inner loop variable (x = 0)
      addi $t2, $t2, 1       # increment outer loop variable (y++)
      addi $t1, $t1, -196    # move current field address by (-17, -1) (start of next higher row of intr field)
      beq $t2, $t3, drop_field_end   # check if end of field has been reached (y == 23)
      j drop_field_start             # otherwise, repeat outer loop
    drop_field_end:

    # if at least one pixel was dropped, draw to display and repeat drop_field
    beq $t8, 1, drop_field_to_repeat
    
    # otherwise, jump to eliminate_field to check for any new lines
    j eliminate_field
    
    drop_field_to_repeat:
      # store $ra
      addi $sp, $sp, -4   # allocate 1 word in stack
      sw $ra, 0($sp)      # push $ra to stack
  
      # draw the screen
      jal reset_display   # reset the entire display
      jal draw_field      # draw the playing field on the display
  
      # sleep
      li $v0, 32    # set syscall operation to sleep
      li $a0, 150   # sleep duration is 17 ms (~60 FPS)
      syscall
  
      # restore $a
      lw $ra, 0($sp)     # pop $t1 to stack
      addi $sp, $sp, 4   # free 1 word from stack

      # repeat drop_field to check if any more pixels need to be dropped
      j drop_field

# Helper function for eliminate_field that performs elimination on the vertical line
# starting from bitmap position $a0 and going down until the first grey pixel that is hit.
# Returns $v0 = 1 if at least one line was elimninated, and $v0 = 0 otherwise.
eliminate_vertical:
  la $t0, field        # $t0 = base address for field
  add $t1, $a0, $t0    # $t1 = address of starting pixel within field
  li $t2, 0            # $t2 = boolean for whether at least one line was eliminated
  lw $t3, COLR_BLACK   # $t3 = (colour of) previous pixel (initially black)
  li $t4, 1            # $t4 = count (initially 1)
  lw $t9, COLR_GREY
  lw $t8, COLR_BLACK
  eliminate_vertical_start:
    lw $t5, 0($t1)   # $t5 = (colour of) current pixel
    # if current colour != black or previous colour != black:
    bne $t5, $t8, eliminate_vertical_not_black   # check current colour
    bne $t3, $t8, eliminate_vertical_not_black   # check previous colour
    j eliminate_vertical_increment   # otherwise, increment and continue
    eliminate_vertical_not_black:
      # if current colour == previous colour, add 1 to count
      beq $t5, $t3, eliminate_vertical_match   # if colours match
      j eliminate_vertical_mismatch            # otherwise, colours mismatch
      eliminate_vertical_match:
        addi $t4, $t4, 1   # add 1 to count
        j eliminate_vertical_increment   # increment and continue
      # if current colour != previous colour:
      eliminate_vertical_mismatch:
        # set previous colour to current colour
        add $t3, $t5, $zero   # previous pixel $t3 = current pixel $t5
        # if count >= 4:
        bge $t4, 4, eliminate_vertical_ge4
        li $t4, 1   # otherwise: reset count to 1,
        j eliminate_vertical_increment   # and increment/continue
        eliminate_vertical_ge4:
          # remove 'count' pixels from above current
          li $t6, -128        # $t6 = -128
          mult $t6, $t4       # $(hi, lo) = -128 * coun
          mflo $t6            # $t6 = hi = -128 * count (we assume -128 * count does not overflow)
          add $t6, $t1, $t6   # $t6 = address of pixel above current by count pixels
          eliminate_vertical_ge4_start:
            sw $t8, 0($t6)       # set the pixel at $t6 to black
            addi $t6, $t6, 128   # move $t6 down by one row
            addi $t4, $t4, -1    # decrement count by 1
            beq $t4, 0, eliminate_vertical_ge4_end   # if count == 0, break out of loop
            j eliminate_vertical_ge4_start           # otherwise, repeat loop
          eliminate_vertical_ge4_end:
          li $t4, 1   # reset count to 1
          li $t2, 1   # set boolean to 1 to indicate that a line was eliminated
          j eliminate_vertical_increment   # increment and continue
    # move to next row and check loop condition
    eliminate_vertical_increment:
    addi $t1, $t1, 128   # move to next row
    beq $t5, $t9, eliminate_vertical_end   # if current colour == grey, break out of loop
    j eliminate_vertical_start             # otherwise, repeat loop
  eliminate_vertical_end:

  add $v0, $t2, $zero   # set return value 
  jr $ra                # return

# Helper function for eliminate_field that performs elimination on the horizontal line
# starting from bitmap position $a0 and going right until the first grey pixel that is hit.
# Returns $v0 = 1 if at least one line was elimninated, and $v0 = 0 otherwise.
eliminate_horizontal:
  la $t0, field        # $t0 = base address for field
  add $t1, $a0, $t0    # $t1 = address of starting pixel within field
  li $t2, 0            # $t2 = boolean for whether at least one line was eliminated
  lw $t3, COLR_BLACK   # $t3 = (colour of) previous pixel (initially black)
  li $t4, 1            # $t4 = count (initially 1)
  lw $t9, COLR_GREY
  lw $t8, COLR_BLACK
  eliminate_horizontal_start:
    lw $t5, 0($t1)   # $t5 = (colour of) current pixel
    # if current colour != black or previous colour != black:
    bne $t5, $t8, eliminate_horizontal_not_black   # check current colour
    bne $t3, $t8, eliminate_horizontal_not_black   # check previous colour
    j eliminate_horizontal_increment   # otherwise, increment and continue
    eliminate_horizontal_not_black:
      # if current colour == previous colour, add 1 to count
      beq $t5, $t3, eliminate_horizontal_match   # if colours match
      j eliminate_horizontal_mismatch            # otherwise, colours mismatch
      eliminate_horizontal_match:
        addi $t4, $t4, 1   # add 1 to count
        j eliminate_horizontal_increment   # increment and continue
      # if current colour != previous colour:
      eliminate_horizontal_mismatch:
        # set previous colour to current colour
        add $t3, $t5, $zero   # previous pixel $t3 = current pixel $t5
        # if count >= 4:
        bge $t4, 4, eliminate_horizontal_ge4
        li $t4, 1   # otherwise: reset count to 1,
        j eliminate_horizontal_increment   # and increment/continue
        eliminate_horizontal_ge4:
          # remove 'count' pixels from left of current
          li $t6, -4          # $t6 = -4
          mult $t6, $t4       # $(hi, lo) = -4 * coun
          mflo $t6            # $t6 = hi = -4 * count (we assume -4 * count does not overflow)
          add $t6, $t1, $t6   # $t6 = address of pixel left of current by count pixels
          eliminate_horizontal_ge4_start:
            sw $t8, 0($t6)      # set the pixel at $t6 to black
            addi $t6, $t6, 4    # move $t6 right by one column
            addi $t4, $t4, -1   # decrement count by 1
            beq $t4, 0, eliminate_horizontal_ge4_end   # if count == 0, break out of loop
            j eliminate_horizontal_ge4_start           # otherwise, repeat loop
          eliminate_horizontal_ge4_end:
          li $t4, 1   # reset count to 1
          li $t2, 1   # set boolean to 1 to indicate that a line was eliminated
          j eliminate_horizontal_increment   # increment and continue
    # move to next column and check loop condition
    eliminate_horizontal_increment:
    addi $t1, $t1, 4   # move to next column
    beq $t5, $t9, eliminate_horizontal_end   # if current colour == grey, break out of loop
    j eliminate_horizontal_start             # otherwise, repeat loop
  eliminate_horizontal_end:

  add $v0, $t2, $zero   # set return value 
  jr $ra                # return

# Function that checks if the pixel at the given bitmap position $a0 is coloured black
# Returns $v0 = 1 for black, and $v0 = 0 otherwise
is_black:
  lw $t0, ADDR_DSPL    # $t0 = base address for display
  add $t0, $t0, $a0    # $t0 = display address of the given pixel
  lw $t0, 0($t0)       # $t7 = (colour of) the given pixel
  lw $t1, COLR_BLACK   # $t1 = black
  
  beq $t0, $t1, is_black_true   # check if the given pixel is black
  li $v0, 0                     # otherwise, set return value to 0
  jr $ra                        # return

  is_black_true:
    li $v0, 1   # set return value to 1
    jr $ra      # return

# Function that checks if the current pill is oriented vertically or horizontally
# Returns $v0 = 0 for vertical, $v0 = 1 for horizontal
pill_orien:
  # save return address since we will be calling a nested function
  addi $sp, $sp, -4     # allocate 1 word in stack
  sw $ra, 0($sp)        # push return address to stack
  
  # pixel 1 cartesian coordinates
  lw $a0, pill          # $a0 = pill[0] = position of pixel 1
  jal bitm_to_cart      # sets ($v0 = x1, $v1 = y1) to the coordinates of pixel 1
  add $t2, $v0, $zero   # $t2 = x1
  add $t3, $v1, $zero   # $t2 = y1

  # pixel 2 cartesian coordinates
  la $a0, pill          # $a0 = address of pill
  lw $a0, 8($a0)        # $a0 = pill[2] = position of pixel 2
  jal bitm_to_cart      # sets ($v0 = x1, $v1 = y1) to the coordinates of pixel 2
  add $t4, $v0, $zero   # $t4 = x2
  add $t5, $v1, $zero   # $t5 = y2

  lw $ra, 0($sp)     # pop return address from stack to $ra
  addi $sp, $sp, 4   # free 1 word from stack
  beq $t2, $t4, pill_orien_vertical     # if x1 = x2 (pill is vertical)
  beq $t3, $t5, pill_orien_horizontal   # if y1 = y2 (pill is horizontal)
  
  pill_orien_vertical:
    li $v0, 0   # return value is 0 = vertical
    jr $ra      # return
  
  pill_orien_horizontal:
    li $v0, 1   # return value is 1 = horizontal
    jr $ra      # return

# Function that converts the bitmap position $a0 to the corresponding
# cartesian coordinates (x = $v0, y = $v1)
bitm_to_cart:
  li $t0, 128
  div $a0, $t0      # lo = pos // 128, hi = pos % 128
  mfhi $v0          # $v0 = pos % 128
  mflo $v1          # $v1 = pos // 128
  sra $v0, $v0, 2   # $v1 = $v1 / 4
  
  jr $ra   # return

# Function that converts the cartesian coordinates (x = $a0, y = $a1)
# to the corresponding bitmap position $v0
cart_to_bitm:
  sll $a0, $a0, 2   # $a0 = x * 2 = x * 2^2
  sll $a1, $a1, 7   # $a1 = y * 128 = y * 2^7
  add $v0, $a0, $zero   # $v0 = $a0
  add $v0, $v0, $a1     # $v0 += $a1
  
  jr $ra   # return

# Function that resets the entire display bitmap
reset_display:
  lw $t0, ADDR_DSPL
  lw $t1, COLR_BLACK

  li $t2, 0          # initialize loop variable $t2
  li $t3, 4096       # set stop variable $t3 (size of whole bitmap = 4096)
  addi $t4, $t0, 0   # initialize current bitmap position $t4

  reset_screen_start:
      sw $t1, 0($t4)     # paint current pixel black
      addi $t2, $t2, 1   # increment loop variable
      addi $t4, $t4, 4   # move to next pixel in row
      beq $t2, $t3, reset_screen_end   # check stopping condition
      j reset_screen_start             # repeat loop
  reset_screen_end:

  jr $ra   # return

# Function that draws the medicine bottle and static pills in the playing field,
# based on the 'field' variable
draw_field:
  lw $t0, ADDR_DSPL    # $t0 = base address for display
  addi $t0, $t0, 264   # $t0 = address of top-left pixel of field within display
  la $t1, field        # $t1 = base address of for field
  addi $t1, $t1, 264   # $t1 = address of top-left pixel of field within field
  
  li $t2, 0    # initialize outer loop variable $t2 (tracks y coordinate)
  li $t3, 28   # set outer stop variable $t3 (28 pixels = height of field)
  li $t4, 0    # initialize inner loop variable $t4 (tracks x coordinate)
  li $t5, 19   # set inner stop variable $t5 (19 pixels = width of field)

  draw_field_start:
    draw_field_row_start:
      lw $t6, 0($t1)     # $t6 = current pixel in field
      sw $t6, 0($t0)     # draw current pixel in field to display
      addi $t4, $t4, 1   # increment inner loop variable (x++)
      addi $t0, $t0, 4   # move current display address to next pixel
      addi $t1, $t1, 4   # move current field address to next pixel
      beq $t4, $t5, draw_field_row_end   # check if end of row has been reached (x == 19)
      j draw_field_row_start             # otherwise, repeat inner loop
    draw_field_row_end:
    li $t4, 0            # reset inner loop variable (x = 0)
    addi $t2, $t2, 1     # increment outer loop variable (y++)
    addi $t0, $t0, 52    # move current display address by (-19, 1) (start of next row of field)
    addi $t1, $t1, 52    # move current field address by (-19, 1) (start of next row of field)
    beq $t2, $t3, draw_field_end   # check if end of field has been reached (y == 28)
    j draw_field_start             # otherwise, repeat outer loop
  draw_field_end:
  
  jr $ra   # return

# Function that draws the current pill, based on the 'pill' variable.
draw_pill:
  lw $t0, ADDR_DSPL   # $t0 = base address for display
  la $t1, pill        # $t1 = address of pill
  
  lw $t2, 0($t1)      # $t2 = pill[0] = position of pixel 1
  add $t2, $t2, $t0   # add base address of display to $t2
  lw $t3, 4($t1)      # $t3 = pill[1] = colour of pixel 1
  sw $t3, 0($t2)      # draw pixel 1

  lw $t2, 8($t1)      # $t2 = pill[2] = position of pixel 2
  add $t2, $t2, $t0   # add base address of display to $t2
  lw $t3, 12($t1)     # $t3 = pill[3] = colour of pixel 2
  sw $t3, 0($t2)      # draw pixel 2

  jr $ra   # return
