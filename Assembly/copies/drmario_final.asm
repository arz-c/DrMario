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
# The three pill colours
COLR_RED:
  .word 0xff3333
COLR_BLUE:
  .word 0x3399ff
COLR_YELL:
  .word 0xffff33
# The three virus colours (obtained by subtracting 0x333333 from the pill colours)
COLR_RED_V:
  .word 0xcc0000
COLR_BLUE_V:
  .word 0x0066cc
COLR_YELL_V:
  .word 0xcccc00
# The two background colours
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
# - top-left pixel of the playing field is located at (2, 2) = ADDR_DSPL + 264
# - the interior of the field (i.e. excluding the medicine bottle) is 17x24 pixels
# - top-left pixel of intr field is located at (3, 5) = ADDR_DSPL + 652
field:
  .space 4096
# The number of viruses remaining on the field
viruses:
  .word 0
# The number of viruses initially on the field (initially 4)
max_viruses:
  .word 4
# Frames passed this time interval
frames_delta:
  .word 0
# Max frames before frames_delta is reset to 0
# 0 initially 25, corresponding roughly to 2 cycles per second (in 60 FPS)
max_frames:
  .word 0
# The next 4 pills in a queue, represented by a size 8 array of 1 word elements
# - each pill corresponds to 2 consecutive elements, holding the colours of
#   pixels 1 and 2
pill_queue:
  .space 32
# The saved pill, represented just like one pill in pill_queue
# - initially both pixels are black, representing an empty slot
saved_pill:
  .space 8

##############################################################################
# Code
##############################################################################
  .text
  .globl main

  # Run the game.
main:
  # Initialize the game
  # initialize the playing field
  jal initialize_field        # initialize field to an empty array
  jal initialize_background   # draw medicine bottle to field
  jal draw_field              # draw the playing field to the display

  # enqueue 4 random pills
  jal enqueue_pill
  jal enqueue_pill
  jal enqueue_pill
  jal enqueue_pill

  # dequeue 1 pill, set it to the current pill, and enqueue 1 more pill
  jal create_pill

  # initialize saved pill to black
  la $t0, saved_pill   # $t0 = address of saved_pill
  lw $t1, COLR_BLACK   # $t1 = black
  sw $t1, 0($t0)       # saved_pill[0] = black
  sw $t1, 4($t0)       # saved_pill[1] = black

  # initialize max_frames
  li $t0, 25
  sw $t0, max_frames   # initialize max_frames = 25

  # initialize viurses with random positions/colours
  lw $t0, max_viruses
  add $a0, $t0, $zero   # $a0 (number of viruses) = max_viruses
  jal create_viruses    # generate the viruses

  # sound effect
  li $a0, 64   # pitch = 64
  jal sound    # generate sound effect

  j game_loop   # jump to the game loop

game_loop:
  # 0. If no viruses remain on the field, game is won
  lw $t0, viruses        # $t0 = viruses
  beq $t0, 0, game_won   # if viruses == 0, game is won
  j game_won_end
  game_won:
    # increase max_viruses by 2
    lw $t0, max_viruses   # $t0 = max_viruses
    addi $t0, $t0, 2      # $t0 += 2
    sw $t0, max_viruses   # max_viruses = $t0
    # jump to main to re-initialize game
    j main
  game_won_end:
  
  # 1a. Check if key has been pressed
  lw $t0, ADDR_KBRD         # t0 = base address for keyboard
  lw $t1, 0($t0)            # $t1 = keyboard[0]
  beq $t1, 1, key_pressed   # if first word is 1, a key was pressed
  j handle_input_end        # else, skip input handling
  
  # 1b. Check which key has been pressed
  key_pressed:
    lw $t1, 4($t0)                # $t1 = keyboard[1]
    beq $t1, 0x73, respond_to_s   # check if 's' was pressed
    beq $t1, 0x61, respond_to_a   # check if 'a' was pressed
    beq $t1, 0x64, respond_to_d   # check if 'd' was pressed
    beq $t1, 0x77, respond_to_w   # check if 'w' was pressed
    beq $t1, 0x70, respond_to_p   # check if 'p' was pressed
    beq $t1, 0x71, respond_to_q   # check if 'q' was pressed
    beq $t1, 0x65, respond_to_e   # check if 'e' was pressed
    j handle_input_end            # otherwise, if an unmapped key was pressed, skip input handling
  
  # 2a. Update location of the current pill by input
  respond_to_s:
    jal move_pill_down
    j handle_input_end
  respond_to_a:
    jal move_pill_left
    j handle_input_end
  respond_to_d:
    jal move_pill_right
    j handle_input_end
  respond_to_w:
    jal rotate_pill
    j handle_input_end
  respond_to_p:
    jal pause
    j handle_input_end
  respond_to_q:
    jal quit
    j handle_input_end
  respond_to_e:
    jal save_pill
    j handle_input_end
  handle_input_end:

  # 2b. Check if current pill landed (i.e. the pixel below the pill is not black)
  jal check_pill_landed
  
  # 3. Draw the screen
  jal reset_display     # reset the entire display
  jal draw_field        # draw the playing field to the display
  jal draw_pill         # draw the current pill to the display
  jal draw_pill_queue   # draw the pill queue to the display
  jal draw_saved_pill   # draw the saved pill to the display
  
  # 4. Sleep and impose gravity every second
  # increment frames_delta by 1 (mod max_frames)
  lw $t0, frames_delta   # $t0 = frames_delta
  addi $t0, $t0, 1       # $t0++
  lw $t1, max_frames     # $t1 = max_frames
  beq $t0, $t1, frames_delta_maxed   # if $t0 == max_frames
  j frames_delta_maxed_end
  frames_delta_maxed:
    # impose gravity
    jal move_pill_down      # move pill down once
    jal check_pill_landed   # check if gravity caused pill to land
    # reset frames_delta
    li $t0, 0    # $t0 = 0
  frames_delta_maxed_end:
  sw $t0, frames_delta   # frames_delta = $t0

  # syscall sleep
  li $v0, 32   # set syscall operation to sleep
  li $a0, 17   # sleep duration is 17 ms (~60 FPS)
  syscall

  # 5. Go back to Step 1
  j game_loop

### Game initialization functions

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

# Function that shifts the contents of pill_queue up by 2 positions, overriding
# pill[6] and [7] in the proccess, and stores a newly randomized pill into pill[0] and [1]
enqueue_pill:
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push return address to stack

  # shift elements up by 2 positions in reverse order
  la $t0, pill_queue   # $t0 = address of pill_queue
  addi $t0, $t0, 20    # $t0 = address of pill_queue[5]
  li $t1, 5    # loop variable $t1 = 0
  li $t2, -1   # stop condition $t2 = -1
  enqueue_pill_shift_start:
    lw $t3, 0($t0)      # $t3 = current element of pill_queue
    sw $t3, 8($t0)      # store $t3 into the address two positions ahead of the current address
    addi $t0, $t0, -4   # move current address back 1 position
    addi $t1, $t1, -1   # decrement loop variable by 1
    beq $t1, $t2, enqueue_pill_shift_end   # if loop variable == stop condition, break from loop
    j enqueue_pill_shift_start             # otherwise, repeat the loop
  enqueue_pill_shift_end:
  
  la $s0, pill_queue   # $s0 = address of pill_queue
  
  jal random_colour   # call helper function
  sw $v0, 0($s0)      # pill_queue[0] = returned colour

  jal random_colour   # call helper function
  sw $v0, 4($s0)      # pill_queue[1] = returned colour

  # restore $ra from stack
  lw $ra, 0($sp)     # pop return address from stack to $ra
  addi $sp, $sp, 4   # free 1 word from stack
  
  # return
  jr $ra

# Function that sets the location of 'pill' to the starting location, and the colour
# is determined by dequeueing from 'pill_queue'; enqueues afterwards to fill the gap
create_pill:
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push return address to stack

  # initialize 'pill'
  la $t0, pill         # $t0 = address of current pill
  la $t1, pill_queue   # $t1 = address of pill_queue
  
  li $t2, 300
  sw $t2, 0($t0)    # pill[0] = 300 = (11, 2)

  lw $t2, 24($t1)
  sw $t2, 4($t0)    # pill[1] = pill_queue[6]

  li $t2, 428
  sw $t2, 8($t0)    # pill[2] = 428 = (11, 3)

  lw $t2, 28($t1)
  sw $t2, 12($t0)   # pill[3] = pill_queue[7]

  # enqueue to 'pill_queue'
  jal enqueue_pill

  # restore $ra from stack
  lw $ra, 0($sp)     # pop return address from stack to $ra
  addi $sp, $sp, 4   # free 1 word from stack
  
  # return
  jr $ra

# Helper function that returns a random main colour to $v0
random_colour:
  # generate a random integer between 0 and 2, inclusive
  li $v0, 42   # syscall config
  li $a0, 0    # RNG id
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

# Function that populates the field with $a0-many randomly coloured and positioned viruses
create_viruses:
  # set number of viruses currently on the field to $a0
  sw $a0, viruses
  
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack
  
  la $s7, field         # $s7 = base address for field
  li $s6, 0             # initialize loop variable $s6 to 0
  add $s5, $a0, $zero   # initialize stop condition $s5 to $a0

  create_viruses_start:
    # generate random position
    # generate a random integer (x coordinate) between 3 and 19, inclusive
    li $v0, 42   # syscall config
    li $a0, 0    # RNG id
    li $a1, 17   # maximum (exclusive)
    syscall      # return value is $a0
    addi $a0, $a0, 3      # shift return value by desired minimum
    add $s0, $a0, $zero   # $s0 = random x coordinate

    # generate a random integer (y coordinate) between 12 and 28, inclusive
    li $v0, 42   # syscall config
    li $a0, 0    # RNG id
    li $a1, 17   # maximum (exclusive)
    syscall      # return value is $a0
    addi $a0, $a0, 12     # shift return value by desired minimum
    add $s1, $a0, $zero   # $s1 = random y coordinate

    add $a0, $s0, $zero   # $a0 = x coordiante $s0
    add $a1, $s1, $zero   # $a1 = y coordinate $s1
    jal cart_to_bitm      # convert ($s0, $s1) to bitmap position $v0
    add $s1, $v0, $zero   # $s1 = return value $v0

    # generate random colour
    # generate a random integer between 0 and 2, inclusive
    li $v0, 42   # syscall config
    li $a0, 0    # RNG id
    li $a1, 3    # maximum (exclusive)
    syscall      # return value is $a0
  
    # branch off by the random number
    beq $a0, 0, random_colour_red_v
    beq $a0, 1, random_colour_blue_v
    beq $a0, 2, random_colour_yellow_v
  
    # set $s2 to the colour determined by the random number
    random_colour_red_v:
      lw $s2, COLR_RED_V
      j random_colour_end_v
    random_colour_blue_v:
      lw $s2, COLR_BLUE_V
      j random_colour_end_v
    random_colour_yellow_v:
      lw $s2, COLR_YELL_V
      j random_colour_end_v
    random_colour_end_v:

    # draw the virus to field
    add $s1, $s7, $s1    # $s1 = address of the random point within field
    # if the pixel currently at $s1 is not black, then pick a new random point
    # (this can technically fall into "infinite" loops, but we will ignore the highly unlikely possibility)
    lw $t0, 0($s1)       # $t0 = colour of pixel currently at $s1
    lw $t1, COLR_BLACK   # $t1 = black
    bne $t0, $t1, create_viruses_start   # check if the pixel at $s1 was not black
    sw $s2, 0($s1)       # otherwise, paint color $s2 at address $s1

    # increment
    addi $s6, $s6, 1   # increment loop variable $t1 by 1
    beq $s6, $s5, create_viruses_end   # if loop variable hits stop condition, break out of loop
    j create_viruses_start             # otherwise, repeat loop
  create_viruses_end:

  # restore $ra from stack
  lw $ra, 0($sp)     # pop $ra from stack
  addi $sp, $sp, 4   # free 1 word from stack

  # return
  jr $ra

### Game loop functions

# Function that saves the current pill, replacing it with a previously saved pill if one exists,
# or the next pill in queue otherwise.
save_pill:
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack

  # set up return label
  j save_pill_return_end
  save_pill_return:
    # restore $ra from stack
    lw $ra, 0($sp)     # pop $ra from stack
    addi $sp, $sp, 4   # free 1 word from stack
    # return
    jr $ra
  save_pill_return_end:

  la $t0, saved_pill   # $t0 = address of saved_pill
  la $t1, pill         # $t1 = address of current pill
  lw $t2, 0($t0)       # $t2 = saved_pill[0]
  lw $t4, 4($t1)       # $t4 = current_pill[1] = colour of pixel 1 of current pill
  lw $t5, 12($t1)      # $t5 = current_pill[3] = colour of pixel 2 of current pill
  lw $t9, COLR_BLACK   # $t9 = black
    
  beq $t2, $t9, save_pill_empty   # check if saved_pill is currently empty
  j save_pill_replace   # otherwise, current pill needs to be replaced

  save_pill_empty:
    # store current pill into saved_pill
    sw $t4, 0($t0)   # saved_pill[0] = colour of pixel 1 of current pill
    sw $t5, 4($t0)   # saved_pill[1] = colour of pixel 2 of current pill

    # replace colours of current pill with colours of the next pill in queue
    la $t3, pill_queue   # $t3 = address of pill_queue
    
    lw $t6, 24($t3)
    sw $t6, 4($t1)    # pill[1] = pill_queue[6]

    lw $t6, 28($t3)
    sw $t6, 12($t1)   # pill[3] = pill_queue[7]

    # enqueue to fill the gap
    jal enqueue_pill

    # return
    j save_pill_return

  save_pill_replace:
    lw $t3, 4($t0)   # $t3 = saved_pill[1]
    
    # store current pill into saved_pill
    sw $t4, 0($t0)   # saved_pill[0] = colour of pixel 1 of current pill
    sw $t5, 4($t0)   # saved_pill[1] = colour of pixel 2 of current pill

    # replace colours of current pill with colours of the previously saved pill
    sw $t2, 4($t1)    # pill[1] = $t2 = old saved_pill[0]
    sw $t3, 12($t1)   # pill[3] = $t3 = old saved_pill[1]

    # return
    j save_pill_return
  
# Function that generates a sound effect with consistent duration, instrument, and volume.
# The pitch is determined by $a0 (0-127).
sound:
  li $v0, 31    # syscall config
  li $a1, 100   # duration (in ms)
  li $a2, 4     # instrument (0-127)
  li $a3, 64    # volume (0-127)
  syscall       # midi out
  jr $ra        # return

# Function that checks if the current pill landed (i.e. the pixel below the pill is not black).
# If the pill landed at the mouth, restarts the game.
# If the pill landed elsewhere, eliminates lines, drops static pills, and generates a new pill.
check_pill_landed:
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack

  # set up return label
  j check_pill_landed_return_end
  check_pill_landed_return:
    # restore $ra from stack
    lw $ra, 0($sp)     # pop $ra from stack
    addi $sp, $sp, 4   # free 1 word from stack
    # return
    jr $ra
  check_pill_landed_return_end:

  # check if pixel 2 landed
  la $t2, pill              # $t2 = address of pill
  lw $a0, 8($t2)            # $a0 = pill[2] = position of pixel 2
  addi $a0, $a0, 128        # $a0 = position of the pixel below pixel 2
  jal is_black              # call function
  beq $v0, 0, pill_landed   # if 0 was returned, pixel below pixel 2 is not black
  
  # if the pill is horizontal, also check if new pixel 1 landed
  jal pill_orien   # call function
  beq $v0, 1, check_pill_landed_horizontal   # if 1 was returned, pill is horizontal
  j check_pill_landed_return                 # otherwise, the pill didn't land

  check_pill_landed_horizontal:
    # check if pixel 1 landed
    la $t2, pill         # $t2 = address of pill
    lw $a0, 0($t2)       # $a0 = pill[0] = position of pixel 1
    addi $a0, $a0, 128   # $a0 = position of the pixel below pixel 1
    jal is_black
    beq $v0, 0, pill_landed      # if 0 was returned, pixel below new pixel 1 is not black
    j check_pill_landed_return   # otherwise, the pill didn't land

  pill_landed:
    la $t2, pill   # $t2 = address of pill

    # save pixel 1 to field
    la $t3, field    # $t3 = base address for field
    lw $t4, 0($t2)   # $t4 = pill[0] = position of pixel 1

    ble $t4, 560, game_over   # if position of pixel 1 <= (12, 4), then game is over
    j game_over_end
    game_over:
      # reset max_viruses to 4
      li $t0, 4
      sw $t0, max_viruses
      # jump to main to re-initialize game
      j main
    game_over_end:
    
    lw $t5, 4($t2)      # $t5 = pill[1] = colour of pixel 1
    add $t3, $t3, $t4   # $t3 = address of pixel 1 within field
    sw $t5, 0($t3)      # store pixel 1 in field

    # save pixel 2 to field
    la $t3, field       # $t3 = base address for field
    lw $t4, 8($t2)      # $t4 = pill[2] = position of pixel 2
    lw $t5, 12($t2)     # $t5 = pill[3] = colour of pixel 2
    add $t3, $t3, $t4   # $t3 = address of pixel 2 within field
    sw $t5, 0($t3)      # store pixel 2 in field

    # sound effect
    li $a0, 50   # pitch = 50
    jal sound    # generate sound effect

    jal eliminate_field          # eliminate lines and drop static pills
    jal create_pill              # create a new random pill at the starting location
    j check_pill_landed_return   # return

# Function that pauses the game until 'p' is pressed
pause:
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack

  # sound effect (on pause)
  li $a0, 80   # pitch = 80
  jal sound    # generate sound effect
  
  # draw pause symbol
  lw $t0, ADDR_DSPL     # $t0 = base address for display
  li $t1, 0             # loop variable $t1 = 0
  li $t2, 5             # stop condition $t2 = 5
  addi $t3, $t0, 3304   # current pixel = address of (26, 25)
  lw $t4, COLR_GREY     # $t4 = grey
  pause_draw_start:
    sw $t4, 0($t3)       # paint $t4 at $t3
    sw $t4, 12($t3)      # paint $t4 12 pixels to the right of $t3
    addi $t1, $t1, 1     # increment loop variable by 1
    addi $t3, $t3, 128   # move current pixel down by 1
    beq $t1, $t2, pause_loop   # if loop variable = stop condition, break out of draw loop
    j pause_draw_start         # otherwise, repeat draw loop
  
  pause_loop:
    lw $t0, ADDR_KBRD               # t0 = base address for keyboard
    lw $t1, 0($t0)                  # $t1 = keyboard[0]
    beq $t1, 1, pause_key_pressed   # if first word is 1, a key was pressed
    j pause_loop                    # else, repeat pause loop
    
    pause_key_pressed:
      lw $t1, 4($t0)                      # $t1 = keyboard[1]
      beq $t1, 0x70, pause_respond_to_p   # check if 'p' was pressed
      j pause_loop                        # otherwise, repeat pause loop
  
    pause_respond_to_p:
      # sound effect (on resume)
      li $a0, 80   # pitch = 80
      jal sound    # generate sound effect
      
      # restore $ra from stack
      lw $ra, 0($sp)     # pop $ra from stack
      addi $sp, $sp, 4   # free 1 word from stack
      
      # return
      jr $ra

# Function that quits the program gracefully
quit:
  li $v0, 10   # syscall config
  syscall      # quit gracefully

# Function that moves the current pill down one pixel, if there is space
move_pill_down:
  la $t2, pill   # $t2 = address of pill

  # update pixel 1 (there is always space below)
  lw $t3, 0($t2)       # $t3 = pill[0] = position of pixel 1
  addi $t3, $t3, 128   # add one row to $t3
  sw $t3, 0($t2)       # pill[0] = $t3

  # update pixel 2 (there is always space below)
  lw $t4, 8($t2)       # $t4 = pill[2] = position of pixel 2
  addi $t4, $t4, 128   # add one row to $t4
  sw $t4, 8($t2)       # pill[2] = $t4

  jr $ra   # return

# Function that moves the current pill left by one pixel, if there is space
move_pill_left:
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack

  # set up return label
  j move_pill_left_return_end
  move_pill_left_return:
    # restore $ra from stack
    lw $ra, 0($sp)     # pop $ra from stack
    addi $sp, $sp, 4   # free 1 word from stack
    # return
    jr $ra
  move_pill_left_return_end:
  
  la $t2, pill   # $t2 = address of pill

  # compute new position of pixel 1
  lw $t3, 0($t2)     # $t3 = pill[0] = position of pixel 1
  add $t3, $t3, -4   # subtract one column from $t3

  # check if new pixel 1 collided with something
  add $a0, $t3, $zero   # $a0 = position of new pixel 1
  jal is_black          # call function

  # if 0 was returned, new pixel 1 was not black, so return immediately
  beq $v0, 0, move_pill_left_return

  # compute new position of pixel 2
  lw $t4, 8($t2)     # $t4 = pill[2] = position of pixel 2
  add $t4, $t4, -4   # subtract one column from $t4

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

  # if 0 was returned, pill is vertical, so check pixel 2 for collision
  beq $v0, 0, move_pill_left_vertical

  # otherwise:
  sw $t3, 0($t2)            # update pixel 1
  sw $t4, 8($t2)            # update pixel 2
  j move_pill_left_return   # return

  move_pill_left_vertical:
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

    # if 0 was returned, new pixel 2 was not black, so return immediately
    beq $v0, 0, move_pill_left_return

    # otherwise:
    sw $t3, 0($t2)            # update pixel 1
    sw $t4, 8($t2)            # update pixel 2
    j move_pill_left_return   # return

# Function that moves the current pill right by one pixel, if there is space
move_pill_right:
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack

  # set up return label
  j move_pill_right_return_end
  move_pill_right_return:
    # restore $ra from stack
    lw $ra, 0($sp)     # pop $ra from stack
    addi $sp, $sp, 4   # free 1 word from stack
    # return
    jr $ra
  move_pill_right_return_end:
  
  la $t2, pill   # $t2 = address of pill

  # compute new position of pixel 2
  lw $t3, 8($t2)    # $t3 = pill[2] = position of pixel 2
  add $t3, $t3, 4   # add one column to $t3

  # check if new pixel 2 collided with something
  add $a0, $t3, $zero   # $a0 = position of new pixel 2
  jal is_black          # call function

  # if 0 was returned, new pixel 2 was not black, so return immediately
  beq $v0, 0, move_pill_right_return

  # compute new position of pixel 1
  lw $t4, 0($t2)    # $t4 = pill[0] = position of pixel 1
  add $t4, $t4, 4   # add one column to $t4

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

  # if 0 was returned, pill is vertical, so check pixel 1 for collision
  beq $v0, 0, move_pill_right_vertical

  # otherwise:
  sw $t3, 8($t2)             # update pixel 2
  sw $t4, 0($t2)             # update pixel 1
  j move_pill_right_return   # return

  move_pill_right_vertical:
    # check if new pixel 1 collided with something
    add $a0, $t4, $zero   # $a0 = position of new pixel 1
  
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

    # if 0 was returned, new pixel 1 was not black, so return immediately
    beq $v0, 0, move_pill_right_return

    # otherwise:
    sw $t3, 8($t2)            # update pixel 2
    sw $t4, 0($t2)            # update pixel 1
    j move_pill_right_return   # return

# Function that rotates the pill clockwise, if there is space
rotate_pill:
  # store $ra in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack

  # set up return label
  j rotate_pill_return_end
  rotate_pill_return:
    # restore $ra from stack
    lw $ra, 0($sp)     # pop $ra from stack
    addi $sp, $sp, 4   # free 1 word from stack
    # return
    jr $ra
  rotate_pill_return_end:
  
  # check if pill is currently oriented vertically or horizontally
  jal pill_orien
  beq $v0, 0, rotate_vertical     # if 0 was returned, pill is vertical
  beq $v0, 1, rotate_horizontal   # if 1 was returned, pill is horizontal

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

    # if 0 was returned, new pixel 1 was not black, so return
    beq $v0, 0, rotate_pill_return

    # otherwise:
    sw $t3, 0($t2)   # update pixel 1

    # swap the roles of pixel 1 and pixel 2
    # ($t3 already has position of pixel 1)
    lw $t4, 4($t2)    # $t4 = pill[1] = colour of pixel 1
    lw $t5, 8($t2)    # $t5 = pill[2] = position of pixel 2
    lw $t6, 12($t2)   # $t6 = pill[3] = colour of pixel 2
    sw $t5, 0($t2)    # pill[0] = $t5
    sw $t6, 4($t2)    # pill[1] = $t6
    sw $t3, 8($t2)    # pill[2] = $t3
    sw $t4, 12($t2)   # pill[3] = $t4

    # sound effect
    li $a0, 40   # pitch = 40
    jal sound    # generate sound effect
    
    j rotate_pill_return   # return

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

    # if 0 was returned, new pixel 1 was not black, so stop
    beq $v0, 0, rotate_pill_return

    # otherwise:
    sw $t3, 0($t2)   # update pixel 1
    sw $t4, 8($t2)   # update pixel 2

    # sound effect
    li $a0, 40   # pitch = 40
    jal sound    # generate sound effect
    
    j rotate_pill_return   # return

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
  li $a1, 128   # set $a1 (argument for eliminate_line determining the bitmap increment) to 128 (to increment by rows)
  
  eliminate_field_vertical_start:
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t1, 0($sp)      # push $t1 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t2, 0($sp)      # push $t2 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t3, 0($sp)      # push $t3 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t4, 0($sp)      # push $t4 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $a1, 0($sp)      # push $a1 to stack

    add $a0, $t1, $zero   # $a0 = $t1
    jal eliminate_line    # eliminate current vertical line

    lw $a1, 0($sp)      # pop $a1 from stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t4, 0($sp)      # pop $t4 from stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t3, 0($sp)      # pop $t3 from stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t2, 0($sp)      # pop $t2 from stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t1, 0($sp)      # pop $t1 from stack
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
  li $a1, 4     # set $a1 (argument for eliminate_line determining the bitmap increment) to 4 (to increment by columns)
  
  eliminate_field_horizontal_start:
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t1, 0($sp)      # push $t1 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t2, 0($sp)      # push $t2 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t3, 0($sp)      # push $t3 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $t4, 0($sp)      # push $t4 to stack
    addi $sp, $sp, -4   # allocate 1 word in stack
    sw $a1, 0($sp)      # push $a1 to stack

    add $a0, $t1, $zero   # $a0 = $t1
    jal eliminate_line    # eliminate current horizontal line
    
    lw $a1, 0($sp)      # pop $a1 from stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t4, 0($sp)      # pop $t4 from stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t3, 0($sp)      # pop $t3 from stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t2, 0($sp)      # pop $t2 from stack
    addi $sp, $sp, 4    # free 1 word from stack
    lw $t1, 0($sp)      # pop $t1 from stack
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
    lw $s0, COLR_RED_V
    lw $s1, COLR_BLUE_V
    lw $s2, COLR_YELL_V
  
    drop_field_start:
      drop_field_row_start:
        lw $t6, 0($t1)   # $t6 = current pixel in field
        # if current pixel == black, or a virus colour, then increment/continue
        beq $t6, $t9, drop_field_row_increment   # check if black
        beq $t6, $s0, drop_field_row_increment   # check if virus red
        beq $t6, $s1, drop_field_row_increment   # check if virus blue
        beq $t6, $s2, drop_field_row_increment   # check if virus yellow
        # else, if pixel below current pixel == black:
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
      jal reset_display     # reset the entire display
      jal draw_field        # draw the playing field to the display
      jal draw_pill_queue   # draw the pill queue to the display
  
      # sleep
      li $v0, 32    # set syscall operation to sleep
      li $a0, 100   # sleep duration is 150 ms (~10 FPS)
      syscall
  
      # restore $a
      lw $ra, 0($sp)     # pop $t1 to stack
      addi $sp, $sp, 4   # free 1 word from stack

      # repeat drop_field to check if any more pixels need to be dropped
      j drop_field

# Helper function for eliminate_field that performs elimination on the line starting from bitmap position
# $a0 and going in the direction determined by the bitmap increment $a1 until the first grey pixel is hit.
# Returns $v0 = 1 if at least one line was elimninated, and $v0 = 0 otherwise.
eliminate_line:
  # store $ra and $s0 in stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $ra, 0($sp)      # push $ra to stack
  addi $sp, $sp, -4   # allocate 1 word in stack
  sw $s0, 0($sp)      # push $s0 to stack
  
  la $t0, field         # $t0 = base address for field
  add $t1, $a0, $t0     # $t1 = address of given starting pixel within field
  add $s0, $a1, $zero   # $s0 = given bitmap increment $a1
  li $t2, 0             # $t2 = boolean for whether at least one line was eliminated
  lw $t3, COLR_BLACK    # $t3 = (colour of) previous pixel (initially black)
  li $t4, 1             # $t4 = count of number of same colours seen consecutively (initially 1)
  li $t7, 0             # $t7 = count of number of viruses in the current same-colour line
  lw $t8, COLR_BLACK    # $t8 = black
  lw $t9, COLR_GREY     # $t9 = grey
  
  eliminate_line_start:
    # $t5 = colour of the current pixel
    lw $t5, 0($t1)
    
    # only proceed if either current colour != black or previous colour != black:
    bne $t5, $t8, eliminate_line_not_black   # check current colour
    bne $t3, $t8, eliminate_line_not_black   # check previous colour

    # otherwise, increment and continue
    j eliminate_line_increment
    
    eliminate_line_not_black:
      # check if current colour matches previous colour
      # i.e. either they are the same colour, or they form a matching virus-pill pair
      sub $t6, $t5, $t3                              # $t6 = current colour - previous colour
      beq $t6, 0, eliminate_line_match           # check if current colour == previous colour
      beq $t6, 0x333333, eliminate_line_match    # check if current is a pill matching previous which is a virus
      beq $t6, -0x333333, eliminate_line_match   # check if current is a virus matching previous which is a pill
      
      # otherwise, the colours mismatch
      j eliminate_line_mismatch
      
      eliminate_line_match:
        # set previous colour $t3 to current colour $t5
        # (this makes a difference only when one of the colours was a virus)
        add $t3, $t5, $zero
        
        # add 1 to same-colour count
        addi $t4, $t4, 1
        
        # increment and continue
        j eliminate_line_increment
      
      eliminate_line_mismatch:
        # set previous colour $t3 to current colour $t5
        add $t3, $t5, $zero
        
        # check if same-colour count >= 4
        bge $t4, 4, eliminate_line_ge4
        
        # otherwise:
        li $t4, 1   # reset same-colour count to 1
        li $t7, 0   # reset virus count to 0
        j eliminate_line_increment   # increment and continue
        
        eliminate_line_ge4:
          # sound effect
          li $a0, 74   # pitch = 74
          jal sound    # generate sound effect
          
          # remove 'count' pixels from above current (recall $s0 = given bitmap increment)
          sub $t6, $zero, $s0   # $t6 = -$s0
          mult $t6, $t4         # $(hi, lo) = -$s0 * count
          mflo $t6              # $t6 = hi = -$s0 * count (we assume -$s0 * count does not overflow)
          add $t6, $t1, $t6     # $t6 = address of the pixel count positions before the current pixel
          
          eliminate_line_ge4_start:
            sw $t8, 0($t6)       # set the pixel at $t6 to black
            add $t6, $t6, $s0    # move $t6 according to $s0
            addi $t4, $t4, -1    # decrement count by 1
            beq $t4, 0, eliminate_line_ge4_end   # if count == 0, break out of loop
            j eliminate_line_ge4_start           # otherwise, repeat loop
          eliminate_line_ge4_end:
          
          li $t4, 1   # reset count to 1
          li $t2, 1   # set boolean to 1 to indicate that a line was eliminated
          
          # check if the just-eliminated line contained a virus
          bne $t7, 0, eliminate_line_virus_elimed   # check if virus count $t7 is non-zero

          # otherwise, increment and continue
          j eliminate_line_increment
          
          eliminate_line_virus_elimed:
            # decrement 'viruses' by virus count $t7
            lw $t6, viruses     # $t6 = viruses
            sub $t6, $t6, $t7   # $t6 -= virus count
            sw $t6, viruses     # viruses = $t6

            # check if 'viruses' is low enough to enhance gravity
            lw $t7, max_viruses   # $t7 = max_viruses (temporarily using $t7 for a computation)
            sra $t7, $t7, 1       # $t7 /= 2
            
            # if viruses == max_viruses / 2
            beq $t6, $t7, eliminate_line_enhance_gravity
            
            # otherwise:
            li $t7, 0   # reset virus count $t7 to 0
            j eliminate_line_increment   # increment/continue
            
            eliminate_line_enhance_gravity:
              # enhance gravity by a factor of two
              lw $t6, max_frames     # $t6 = max_frames
              sra $t6, $t6, 1        # $t6 /= 2
              sw $t6, max_frames     # max_frames = $t6
              li $t6, 0              # $t6 = 0
              sw $t6, frames_delta   # frames_delta = $t6

              # sound effect
              li $a0, 86   # pitch = 86
              jal sound    # generate sound effect
              
              li $t7, 0   # reset virus count $t7 to 0
              j eliminate_line_increment   # increment and continue
    
    eliminate_line_increment:
    # check if the current colour was a virus colour
    lw $t6, COLR_RED_V
    beq $t5, $t6, eliminate_line_virus   # check if current colour is red_v
    lw $t6, COLR_BLUE_V
    beq $t5, $t6, eliminate_line_virus   # check if current colour is blue_v
    lw $t6, COLR_YELL_V
    beq $t5, $t6, eliminate_line_virus   # check if current colour is yellow_v
    j eliminate_line_virus_end
    
    eliminate_line_virus:
      # if so, add 1 to virus count $t7
      addi $t7, $t7, 1
    eliminate_line_virus_end:

    # increment and check stop condition
    add $t1, $t1, $s0   # move to next pixel in the direction determined by input $s0
    beq $t5, $t9, eliminate_line_end   # if current colour == grey, break from loop
    j eliminate_line_start             # otherwise, repeat the loop
  eliminate_line_end:

  # set return value to the boolean indicating if a line was eliminated
  add $v0, $t2, $zero

  # restore $ra and $s0 from stack
  lw $s0, 0($sp)     # pop $s0 from stack
  addi $sp, $sp, 4   # free 1 word from stack
  lw $ra, 0($sp)     # pop $t1 from stack
  addi $sp, $sp, 4   # free 1 word from stack

  # return
  jr $ra

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
  sll $a0, $a0, 2     # $a0 = x * 4 = x * 2^2
  sll $a1, $a1, 7     # $a1 = y * 128 = y * 2^7
  add $v0, $a0, $a1   # $v0 = $a0 + $a1
  
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

# Function that draws a preview of the next 4 pills, based on the 'pill_queue' variable
draw_pill_queue:
  lw $t0, ADDR_DSPL    # $t0 = base address for display
  la $t1, pill_queue   # address of current pill $t1 = address of first pill in pill_queue
  addi $t1, $t1, 24    # address of current pill $t1 = address of last pill in pill_queue
  
  li $t2, 0            # loop variable $t2 = 0
  li $t3, 4            # stop condition $t3 = 4
  addi $t4, $t0, 348   # current pixel $t4 = address of (23, 2)
  
  draw_pill_queue_start:
    lw $t5, 0($t1)      # $t5 = pixel 1 of current pill in queue
    sw $t5, 0($t4)      # paint $t5 at current location
    lw $t5, 4($t1)      # $t5 = pixel 2 of current pill in queue
    sw $t5, 128($t4)    # paint $t5 one row below current pixel
    addi $t2, $t2, 1    # increment loop variable by 1
    addi $t1, $t1, -8   # move address of current pill in pill_queue back by 2 positions
    addi $t4, $t4, 8    # move current pixel to the right by 2
    beq $t2, $t3, draw_pill_queue_end   # if loop variable = stop condition, break from loop
    j draw_pill_queue_start             # otherwise, repeat the loop
  draw_pill_queue_end:
    
  jr $ra   # return

# Function that draws the saved pill, based on the 'saved_pill' variable
draw_saved_pill:
  lw $t0, ADDR_DSPL    # $t0 = base address for display
  addi $t0, $t0, 732   # current location $t0 = address of (23, 5)
  la $t1, saved_pill   # $t1 = address of saved_pill
  
  lw $t2, 0($t1)       # $t2 = pixel 1 of saved_pill
  sw $t2, 0($t0)       # paint $t2 at current location
  
  lw $t2, 4($t1)       # $t2 = pixel 2 of saved_pill
  sw $t2, 128($t0)     # paint $t2 one row below current location
  
  jr $ra   # return