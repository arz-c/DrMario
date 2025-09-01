# 2a. Update locations (capsules)
# respond_to_s:
#   # move current pill to the next row
#   la $t2, pill   # $t2 = address of pill

#   # update pixel 1 (there is always space below)
#   lw $t3, 0($t2)       # $t3 = pill[0] = position of pixel 1
#   addi $t3, $t3, 128   # add one row to $t3
#   sw $t3, 0($t2)       # pill[0] = $t3

#   # update pixel 2 (there is always space below)
#   lw $t4, 8($t2)       # $t4 = pill[2] = position of pixel 2
#   addi $t4, $t4, 128   # add one row to $t4
#   sw $t4, 8($t2)       # pill[2] = $t4

#   j update_locations_end

# respond_to_a:
#   # move current pill to the next pixel in the row
#   la $t2, pill   # $t2 = address of pill

#   # compute new position of pixel 1
#   lw $t3, 0($t2)     # $t3 = pill[0] = position of pixel 1
#   add $t3, $t3, -4   # subtract one column to $t3

#   # check if new pixel 1 collided with something
#   add $a0, $t3, $zero   # $a0 = position of new pixel 1
#   jal is_black          # call function
#   beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 1 was black, so stop

#   # compute new position of pixel 2
#   lw $t4, 8($t2)     # $t4 = pill[2] = position of pixel 2
#   add $t4, $t4, -4   # subtract one column from $t3

#   # if the pill is vertical, check if pixel 2 collided
#   addi $sp, $sp, -4   # allocate 1 word in stack
#   sw $t2, 0($sp)      # push $t2 to stack
#   addi $sp, $sp, -4   # allocate 1 word in stack
#   sw $t3, 0($sp)      # push $t3 to stack
#   addi $sp, $sp, -4   # allocate 1 word in stack
#   sw $t4, 0($sp)      # push $t4 to stack
  
#   jal pill_orien      # call function

#   lw $t4, 0($sp)     # pop $t4 to stack
#   addi $sp, $sp, 4   # free 1 word from stack
#   lw $t3, 0($sp)     # pop $t3 from stack
#   addi $sp, $sp, 4   # free 1 word from stack
#   lw $t2, 0($sp)     # pop $t2 from stack
#   addi $sp, $sp, 4   # free 1 word from stack

#   beq $v0, 0, respond_to_a_vertical   # if 0 was returned, pill is vertical
#   sw $t3, 0($t2)           # otherwise: update pixel 1,
#   sw $t4, 8($t2)           # and pixel 2,
#   j update_locations_end   # and finish input handling

#   respond_to_a_vertical:
#     # check if new pixel 2 collided with something
#     add $a0, $t4, $zero   # $a0 = position of new pixel 2

#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t2, 0($sp)      # push $t2 to stack
#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t3, 0($sp)      # push $t3 to stack
#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t4, 0($sp)      # push $t4 to stack
    
#     jal is_black   # call function

#     lw $t4, 0($sp)     # pop $t4 to stack
#     addi $sp, $sp, 4   # free 1 word from stack
#     lw $t3, 0($sp)     # pop $t3 from stack
#     addi $sp, $sp, 4   # free 1 word from stack
#     lw $t2, 0($sp)     # pop $t2 from stack
#     addi $sp, $sp, 4   # free 1 word from stack
    
#     beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 2 was not black, so stop
#     sw $t3, 0($t2)           # otherwise: update pixel 1,
#     sw $t4, 8($t2)           # and pixel 2,
#     j update_locations_end   # and finish input handling

# respond_to_d:
#   # move current pill to the next pixel in the row
#   la $t2, pill   # $t2 = address of pill

#   # compute new position of pixel 2
#   lw $t3, 8($t2)    # $t3 = pill[2] = position of pixel 2
#   add $t3, $t3, 4   # add one column to $t3

#   # check if new pixel 2 collided with something
#   add $a0, $t3, $zero   # $a0 = position of new pixel 1
#   jal is_black          # call function
#   beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 1 was black, so stop

#   # compute new position of pixel 1
#   lw $t4, 0($t2)    # $t4 = pill[0] = position of pixel 1
#   add $t4, $t4, 4   # add one column to $t3

#   # if the pill is vertical, check if pixel 1 collided
#   addi $sp, $sp, -4   # allocate 1 word in stack
#   sw $t2, 0($sp)      # push $t2 to stack
#   addi $sp, $sp, -4   # allocate 1 word in stack
#   sw $t3, 0($sp)      # push $t3 to stack
#   addi $sp, $sp, -4   # allocate 1 word in stack
#   sw $t4, 0($sp)      # push $t4 to stack
  
#   jal pill_orien      # call function

#   lw $t4, 0($sp)     # pop $t4 to stack
#   addi $sp, $sp, 4   # free 1 word from stack
#   lw $t3, 0($sp)     # pop $t3 from stack
#   addi $sp, $sp, 4   # free 1 word from stack
#   lw $t2, 0($sp)     # pop $t2 from stack
#   addi $sp, $sp, 4   # free 1 word from stack

#   beq $v0, 0, respond_to_d_vertical   # if 0 was returned, pill is vertical
#   sw $t3, 8($t2)           # otherwise: update pixel 2,
#   sw $t4, 0($t2)           # and pixel 1,
#   j update_locations_end   # and finish input handling

#   respond_to_d_vertical:
#     # check if new pixel 1 collided with something
#     add $a0, $t4, $zero   # $a0 = position of new pixel 2

#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t2, 0($sp)      # push $t2 to stack
#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t3, 0($sp)      # push $t3 to stack
#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t4, 0($sp)      # push $t4 to stack
    
#     jal is_black   # call function

#     lw $t4, 0($sp)     # pop $t4 to stack
#     addi $sp, $sp, 4   # free 1 word from stack
#     lw $t3, 0($sp)     # pop $t3 from stack
#     addi $sp, $sp, 4   # free 1 word from stack
#     lw $t2, 0($sp)     # pop $t2 from stack
#     addi $sp, $sp, 4   # free 1 word from stack
    
#     beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 2 was not black, so stop
#     sw $t3, 8($t2)           # otherwise: update pixel 2,
#     sw $t4, 0($t2)           # and pixel 1,
#     j update_locations_end   # and finish input handling

# respond_to_w:
#   # check if pill is currently oriented vertically or horizontally
#   jal pill_orien
#   beq $v0, 0, rotate_vertical     # if 0 was returned, pill is vertical
#   beq $v0, 1, rotate_horizontal   # if 1 was returned, pill is horizontal
#   j update_locations_end   # this should never be hit (pill is always either vertical or horizontal)

#   rotate_vertical:
#     la $t2, pill   # $t2 = address of pill

#     # compute x1++ and y1++
#     lw $t3, 0($t2)       # $t3 = pill[0] = position of pixel 1
#     addi $t3, $t3, 132   # $t3 = $t3 + (1, 1)

#     # check if new pixel 1 collides with something
#     # (it suffices to just check pixel 1 = originally top pixel)
#     add $a0, $t3, $zero   # $a0 = position of new pixel 1

#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t2, 0($sp)      # push $t2 to stack
#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t3, 0($sp)      # push $t3 to stack
    
#     jal is_black   # call function

#     lw $t3, 0($sp)     # pop $t3 from stack
#     addi $sp, $sp, 4   # free 1 word from stack
#     lw $t2, 0($sp)     # pop $t2 from stack
#     addi $sp, $sp, 4   # free 1 word from stack
    
#     beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 1 was not black, so stop
#     sw $t3, 0($t2)   # otherwise: update pixel 1

#     # swap the roles of pixel 1 and pixel 2
#     # $t3 already has position of pixel 1
#     lw $t4, 4($t2)    # $t4 = pill[1] = colour of pixel 1
#     lw $t5, 8($t2)    # $t5 = pill[2] = position of pixel 2
#     lw $t6, 12($t2)   # $t6 = pill[3] = colour of pixel 2
#     sw $t5, 0($t2)    # pill[0] = $t5
#     sw $t6, 4($t2)    # pill[1] = $t6
#     sw $t3, 8($t2)    # pill[2] = $t3
#     sw $t4, 12($t2)   # pill[3] = $t4
    
#     j update_locations_end

#   rotate_horizontal:
#     la $t2, pill   # $t2 = address of pill

#     # compute y1++
#     lw $t3, 0($t2)        # $t3 = pill[0] = position of pixel 1
#     addi $t3, $t3, -128   # $t3 = $t3 + (0, -1)

#     # compute x2--
#     lw $t4, 8($t2)      # $t4 = pill[2] = position of pixel 2
#     addi $t4, $t4, -4   # $t4 = $t4 + (-1, 0)

#     # check if new pixel 1 collides with something
#     # (it suffices to just check pixel 1 = originally right pixel)
#     add $a0, $t3, $zero   # $a0 = position of new pixel 1

#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t2, 0($sp)      # push $t2 to stack
#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t3, 0($sp)      # push $t3 to stack
#     addi $sp, $sp, -4   # allocate 1 word in stack
#     sw $t4, 0($sp)      # push $t4 to stack
    
#     jal is_black   # call function

#     lw $t4, 0($sp)     # pop $t4 from stack
#     addi $sp, $sp, 4   # allocate 1 word in stack
#     lw $t3, 0($sp)     # pop $t3 from stack
#     addi $sp, $sp, 4   # free 1 word from stack
#     lw $t2, 0($sp)     # pop $t2 from stack
#     addi $sp, $sp, 4   # free 1 word from stack
    
#     beq $v0, 0, update_locations_end   # if 0 was returned, new pixel 1 was not black, so stop
#     sw $t3, 0($t2)           # otherwise: update pixel 1,
#     sw $t4, 8($t2)           # and pixel 2,
#     j update_locations_end   # and finish input handling

# update_locations_end:





# 2b. Check if current pill landed (i.e. the pixel below the pill is not black)
# # check if pixel 2 landed
# la $t2, pill         # $t2 = address of pill
# lw $a0, 8($t2)       # $a0 = pill[2] = position of pixel 2
# addi $a0, $a0, 128   # $a0 = position of the pixel below pixel 2
# jal is_black         # call function
# beq $v0, 0, pill_landed   # if 0 was returned, pixel below pixel 2 is not black

# # if the pill is horizontal, also check if new pixel 1 landed
# jal pill_orien       # call function
# beq $v0, 1, check_landed_horizontal   # if 1 was returned, pill is horizontal
# j check_landed_end   # otherwise, the pill didn't land

# check_landed_horizontal:
#   # check if pixel 1 landed
#   la $t2, pill         # $t2 = address of pill
#   lw $a0, 0($t2)       # $a0 = pill[0] = position of pixel 1
#   addi $a0, $a0, 128   # $a0 = position of the pixel below pixel 1
#   jal is_black
#   beq $v0, 0, pill_landed   # if 0 was returned, pixel below new pixel 1 is not black
#   j check_landed_end   # otherwise, the pill didn't land

# pill_landed:
#   la $t2, pill   # $t2 = address of pill

#   # save pixel 1 to field
#   la $t3, field    # $t3 = base address for field
#   lw $t4, 0($t2)   # $t4 = pill[0] = position of pixel 1

#   ble $t4, 560, main   # if position of pixel 1 <= (12, 4), then game over
  
#   lw $t5, 4($t2)      # $t5 = pill[1] = colour of pixel 1
#   add $t3, $t3, $t4   # $t3 = address of pixel 1 within field
#   sw $t5, 0($t3)      # store pixel 1 in field

#   # save pixel 2 to field
#   la $t3, field       # $t3 = base address for field
#   lw $t4, 8($t2)      # $t4 = pill[2] = position of pixel 2
#   lw $t5, 12($t2)     # $t5 = pill[3] = colour of pixel 2
#   add $t3, $t3, $t4   # $t3 = address of pixel 2 within field
#   sw $t5, 0($t3)      # store pixel 2 in field

#   jal eliminate_field   # eliminate any lines of 4+ pixels of the same colour from field
#   jal create_pill       # create a new random pill at the starting location
#   j check_landed_end

# check_landed_end: