# Caleb Huning CLH190006
# Bitmap project
# This is a painting program that lets you place 3x3 pixels on a 512 x 256 canvas
# You can choose between eight different colors to use using numbers 0 - 7
# Place a pixel of your current color on the cursor with SPACE
# Move the cursor with WASD
# Fill the screen with your current color using the F key
# You can switch to a rainbow color with '8' or a random color with '9' and fill the screen with these options
# Change to 'etch a sketch' mode with R, which places pixels automatically
# Invert the colors on the entire screen by pressing T
# Exit the program by pressing X

	.data

buffer:	.space	0x80000	# 512 x 256
s_color:.space	8	# reserved for the color underneath the cursor

red:	.word	0x00FF0000
blue:	.word	0x000000FF
green:	.word	0x0000FF00
purple:	.word	0x007F00FF
yellow:	.word	0x00FFFF00
orange:	.word	0x00FF7F00
black:	.word	0x00000000
white:	.word	0x00FFFFFF
cursor:	.word	0x007F7FFF
center:	.word	65792		# Center of screen = 512 x 128 + 256

	.text
	
	# Fill the screen with white background by default
	lw	$a0,white
	jal	fill
	
	# Set cursor to center of screen by default
	lw	$s0,center	# Cursor position in $s0, initially center of screen
	jal	drawcursor
	
	# Set default color
	lw	$a0,blue	# Default color: blue
	
	# Main program loop
	get_input:		# Gets user input
	li	$v0,12		# Get character syscall
	syscall
	
	# Cursor movement keys = WASD
	li	$t0,97
	beq	$v0,$t0,c_left	# User pressed 'A' key
	li	$t0,100
	beq	$v0,$t0,c_right	# User pressed 'D' key
	li	$t0,115
	beq	$v0,$t0,c_down	# User pressed 'S' key
	li	$t0,119
	beq	$v0,$t0,c_up	# User pressed 'W' key
	
	# Draw pixel key = space
	li	$t0,32
	beq	$v0,$t0,c_place	# User pressed 'space' key
	
	# Change color keys; 0 = white, 1 = black, 2 = red, 3 = blue, 4 = green, 5 = purple, 6 = yellow, 7 = orange, 8 = rainbow, 9 = random
	li	$t0,48
	beq	$v0,$t0,cc_white	# User pressed '0' key
	li	$t0,49
	beq	$v0,$t0,cc_black	# User pressed '1' key
	li	$t0,50
	beq	$v0,$t0,cc_red  	# User pressed '2' key
	li	$t0,51
	beq	$v0,$t0,cc_blue 	# User pressed '3' key
	li	$t0,52
	beq	$v0,$t0,cc_green	# User pressed '4' key
	li	$t0,53
	beq	$v0,$t0,cc_purple	# User pressed '5' key
	li	$t0,54
	beq	$v0,$t0,cc_yellow	# User pressed '6' key
	li	$t0,55
	beq	$v0,$t0,cc_orange	# User pressed '7' key
	li	$t0,56
	beq	$v0,$t0,cc_rainbow	# User pressed '8' key
	li	$t0,57
	beq	$v0,$t0,cc_random	# User pressed '9' key
	
	# Fill screen key = F
	li	$t0,102
	beq	$v0,$t0,fill_screen	# User pressed 'F' key
	
	# Toggle placement mode = R
	li	$t0,114
	beq	$v0,$t0,toggle_placement	# User pressed 'R' key
	
	# Invert screen = T
	li	$t0,116
	beq	$v0,$t0,fill_invert	# User pressed 'T' key
	
	# Exit program = X
	li	$t0,120
	beq	$v0,$t0,exit		# User pressed 'X' key
	
	j	get_input	# If valid input not pressed, loop back
	
	exit:
	li	$v0,10
	syscall
	
# Move cursor left
c_left:
	jal	restorecursor		# Restore pixels under cursor
	# Check if cursor is already on the left side
	li	$t0,512
	div	$s0,$t0			# Divide cursor position by 512
	mfhi	$t0			# Get remainder
	li	$t1,1			# If remainder is 1, it is on the left edge
	beq	$t0,$t1,c_left_cancel

	addi	$s0,$s0,-3		# Move cursor left three pixels
	jal	drawcursor		# Draw cursor on new position
	bne	$s2,$zero,c_place	# If placement is auto, draw pixel
	j	get_input		# Return to input
# Cancel move if cursor is already on left side of screen
c_left_cancel:
	jal	drawcursor	# Redraw cursor
	j	get_input	# Return
	
# Move cursor right
c_right:
	jal	restorecursor		# Restore pixels under cursor
	addi	$s0,$s0,3		# Move cursor right three pixels
	# Check if cursor is already on the right side
	li	$t0,512			
	div	$s0,$t0			# Divide cursor position by 512
	mfhi	$t0			# Get remainder
	li	$t1,511			# If remainder is 511, it is on the right edge
	beq	$t0,$t1,c_right_cancel

	jal	drawcursor		# Draw cursor on new position
	bne	$s2,$zero,c_place	# If placement is auto, draw pixel
	j	get_input		# Return to input
# Cancel move if cursor is already on right side of screen
c_right_cancel:
	addi	$s0,$s0,-3	# If cursor is off screen
	jal	drawcursor	# Redraw cursor
	j	get_input	# Return

# Move cursor up
c_up:
	jal	restorecursor		# Restore pixels under cursor
	addi	$s0,$s0,-1536		# Move cursor up three pixels
	blt	$s0,$zero,c_up_cancel	# If cursor position less than zero, it is off the top edge
	jal	drawcursor		# Draw cursor on new position
	bne	$s2,$zero,c_place	# If placement is auto, draw pixel
	j	get_input		# Return to input
# Cancel move if cursor is already on top edge of screen
c_up_cancel:
	addi	$s0,$s0,1536	# If cursor is off screen
	jal	drawcursor	# Redraw cursor
	j	get_input	# Return
	
# Move cursor down
c_down:
	jal	restorecursor		# Restore pixels under cursor
	addi	$s0,$s0,1536		# Move cursor down three pixels
	li	$t0,131072
	bgt	$s0,$t0,c_down_cancel	# If cursor position greater than 512x256, it is off the bottom edge
	jal	drawcursor		# Draw cursor on new position
	bne	$s2,$zero,c_place	# If placement is auto, draw pixel
	j	get_input		# Return to input
# Cancel move if cursor is already on bottom edge of screen
c_down_cancel:
	addi	$s0,$s0,-1536	# If cursor is off screen
	jal	drawcursor	# Redraw cursor
	j	get_input	# Return
	
# Place a pixel of the current color under the cursor
c_place:
	li	$t0,1
	beq	$s1,$t0,cycle_rainbow	# If rainbow mode is on, cycle to the next color
	done_rainbow:	
	
	li	$t0,2
	beq	$s1,$t0,cycle_random	# If random mode is on, get new random color
	done_random:
	
	jal	drawpixel	# Set color under the cursor to the current color
	j	get_input	# Return
# Change color to white
cc_white:
	li	$s1,0		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,white	# Set color to white
	j	get_input	# Return
# Change color to black
cc_black:
	li	$s1,0		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,black	# Set color to black
	j	get_input	# Return
# Change color to red
cc_red:
	li	$s1,0		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,red		# Set color to red
	j	get_input	# Return
# Change color to blue
cc_blue:
	li	$s1,0		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,blue	# Set color to blue
	j	get_input	# Return
# Change color to green
cc_green:
	li	$s1,0		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,green	# Set color to green
	j	get_input	# Return
# Change color to purple
cc_purple:
	li	$s1,0		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,purple	# Set color to purple
	j	get_input	# Return
# Change color to yellow
cc_yellow:
	li	$s1,0		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,yellow	# Set color to yellow
	j	get_input	# Return
# Change color to orange
cc_orange:
	li	$s1,0		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,orange	# Set color to orange
	j	get_input	# Return
# Change color to rainbow
cc_rainbow:
	li	$s1,1		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,purple	# Rainbow starting color is red (purple will cycle to it)
	j	get_input	# Return
# Change color to random
cc_random:
	li	$s1,2		# s1 modes: 0 = normal, 1 = rainbow, 2 = random
	lw	$a0,black	# Random starting color does not matter
	j	get_input	# Return
# Fill the screen with the currently selected color. Works with rainbow and random colors
fill_screen:
	jal	fill		# Fill the screen
	jal	drawpixel	# Make sure the color under the cursor is also filled
	jal	drawcursor	# Redraw the cursor
	j	get_input	# Return
# Invert all colors on the screen. Leaves an inverted cursor under the cursor
fill_invert:
	jal	fill_i		# Invert screen
	li	$t0,0x00808000
	sw	$t0,s_color	# Invert cursor
	jal	drawcursor	# Redraw cursor
	j	get_input	# Return
# Toggle placement mode between normal and auto
toggle_placement:
	beq	$s2,$zero,tp_true	# s2 = placement mode: 0 = normal, 1 = place on move cursor
	li	$s2,0		# Set placement to normal
	j	get_input
	tp_true:
	li	$s2,1		# Set placement to auto
	j	get_input
	
# If rainbow mode is on, cycle the color
cycle_rainbow:
	jal	rainbow_color	# Change the color to the next rainbow color
	j	done_rainbow	# Return
# If random mode is on, get a new random color
cycle_random:
	sw	$v0,-4($sp)	# Store v0 on the stack as it will be modified by random_color
	jal	random_color	# Get new random color in a0
	lw	$v0,-4($sp)	# Restore v0
	j	done_random	# Return
	
	
	
# Fills the screen with a solid color
# Parameters: Color hex in $a0
fill:
	li	$t3,1
	beq	$s1,$t3,fill_rainbow	# Check if rainbow is on
	li	$t3,2
	beq	$s1,$t3,fill_random	# Check if random is on
	
	la	$t0,buffer	# Buffer address in t0
	li	$t1,0x20000	# Number of pixels in t1
	move	$t2,$a0		# Color in t2
	
	fill_loop:
		sw	$t2,0($t0)		# Set current pixel to color
		addi	$t0,$t0,4 		# Move to next pixel
		addi	$t1,$t1,-1		# Decrement number of pixels
		
		bne	$t1,$zero,fill_loop	# Loop while num pixels not zero
		jr	$ra			# Return when done
	
# Inverts every color on the screen	
fill_i:
	la	$t0,buffer	# Buffer address in t0
	li	$t1,0x20000	# Number of pixels in t1
	
	fill_i_loop:
		lw	$t3,0($t0)	# Get current pixel color
		lw	$t4,black
		beq	$t3,$t4,fill_i_black	# Invert black color
		lw	$t4,white
		beq	$t3,$t4,fill_i_white	# Invert white color
		lw	$t4,red
		beq	$t3,$t4,fill_i_red	# Invert red color
		lw	$t4,blue
		beq	$t3,$t4,fill_i_blue	# Invert blue color
		lw	$t4,green
		beq	$t3,$t4,fill_i_green	# Invert green color
		lw	$t4,yellow
		beq	$t3,$t4,fill_i_yellow	# Invert yellow color
		lw	$t4,purple
		beq	$t3,$t4,fill_i_purple	# Invert purple color
		lw	$t4,orange
		beq	$t3,$t4,fill_i_orange	# Invert orange color
		li	$t4,0x0000FFFF
		beq	$t3,$t4,fill_i_aqua	# Invert aqua color
		li	$t4,0x00FF00FF
		beq	$t3,$t4,fill_i_pink	# Invert pink color
		li	$t4,0x0080FF00
		beq	$t3,$t4,fill_i_lime	# Invert lime color
		li	$t4,0x000080FF
		beq	$t3,$t4,fill_i_navy	# Invert navy color
		fill_i_loop2:
		addi	$t0,$t0,4 		# Move to next pixel
		addi	$t1,$t1,-1		# Decrement number of pixels
		
		bne	$t1,$zero,fill_i_loop	# Loop while num pixels not zero
		jr	$ra			# Return when done
		
		fill_i_black:
		li	$t2,0x00FFFFFF	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_white:
		li	$t2,0x00000000	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_red:
		li	$t2,0x0000FFFF	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_blue:
		li	$t2,0x00FFFF00	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_green:
		li	$t2,0x00FF00FF	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_yellow:
		li	$t2,0x000000FF	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_purple:
		li	$t2,0x0080FF00	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_orange:
		li	$t2,0x000080FF	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_aqua:
		lw	$t2,red		# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_pink:
		lw	$t2,green	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_lime:
		lw	$t2,purple	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		fill_i_navy:
		lw	$t2,orange	# Invert color
		sw	$t2,0($t0)	# Set current pixel
		j	fill_i_loop2	# Return
		
# Fills with rainbow mode
fill_rainbow:
	sw	$s0,-8($sp)	# Store cursor position
	li	$s0,1025	# Move to top left corner
	li	$t6,1		# Current row
	li	$t7,0		# Current column
	sw	$ra,-4($sp)	# Store return address on stack
	fr_loop:
		jal	drawpixel	# Set the current 3x3 to the current rainbow color
		jal	restorecursor	# Draw the current 3x3
		jal	rainbow_color	# Cycle color
		addi	$s0,$s0,3	# Move cursor spot
		
		addi	$t7,$t7,1	# Increment column
		li	$t0,170
		bge	$t7,$t0,fr_incrow	# Move to next row after 170 columns
		
		j	fr_loop		# Loop
	fr_incrow:
		addi	$t6,$t6,1	# Increment row
		li	$t0,86
		bge	$t6,$t0,fr_done	# After 86 rows, then done
		li	$t0,1536
		mul	$s0,$t6,$t0	# Reset cursor position to beginning of row
		addi	$s0,$s0,-511
		li	$t7,0		# Reset column to 0
		j	fr_loop
		
	fr_done:
	lw	$ra,-4($sp)	# Restore return address from stack
	lw	$s0,-8($sp)	# Restore cursor position
	jr	$ra
	
# Fills with random mode
fill_random:
	sw	$s0,-8($sp)	# Store cursor position
	li	$s0,1025	# Move to top left corner
	li	$t6,1		# Current row
	li	$t7,0		# Current column
	sw	$ra,-4($sp)	# Store return address on stack
	fra_loop:
		jal	drawpixel	# Set the current 3x3 to the current rainbow color
		jal	restorecursor	# Draw the current 3x3
		jal	random_color	# Change color
		addi	$s0,$s0,3	# Move cursor spot
		
		addi	$t7,$t7,1	# Increment column
		li	$t0,170
		bge	$t7,$t0,fra_incrow	# Move to next row after 170 columns
		
		j	fra_loop		# Loop
	fra_incrow:
		addi	$t6,$t6,1	# Increment row
		li	$t0,86
		bge	$t6,$t0,fra_done	# After 86 rows, then done
		li	$t0,1536
		mul	$s0,$t6,$t0	# Reset cursor position to beginning of row
		addi	$s0,$s0,-511
		li	$t7,0		# Reset column to 0
		j	fra_loop
		
	fra_done:
	lw	$ra,-4($sp)	# Restore return address from stack
	lw	$s0,-8($sp)	# Restore cursor position
	jr	$ra
		
	
# Draws the cursor on the screen in lavender color in 3x3 pixels
# No parameters, expects cursor position in $s0	
drawcursor:
	la	$t0,buffer	# Buffer address in t0
	li	$t4,4		# $t4 = 4
	
	# Top three pixels
	addi	$t1,$s0,-512	# Get position of row above
			
	mul	$t1,$t4,$t1	# Get position times 4
	add	$t0,$t0,$t1	# Get address of cursor position
	
	lw	$t3,cursor	# Get cursor color in $t3
	
	sw	$t3,-4($t0)	# Store cursor color in three pixels
	sw	$t3,0($t0)
	sw	$t3,4($t0)
	
	# Middle three pixels
	addi	$t0,$t0,2048	# Get address of current position
	
	lw	$t5,0($t0)	# Store pixel color underneath the cursor in s_color
	sw	$t5,s_color

	sw	$t3,-4($t0)	# Store cursor color in three pixels
	sw	$t3,0($t0)
	sw	$t3,4($t0)
	
	# Bottom three pixels
	addi	$t0,$t0,2048	# Get address of row below

	sw	$t3,-4($t0)	# Store cursor color in three pixels
	sw	$t3,0($t0)
	sw	$t3,4($t0)
	
	jr	$ra		# Return
	
# Restores the nine pixels that were below the cursor
# No parameters, expects cursor position in $s0
restorecursor:
	la	$t0,buffer	# Buffer address in t0
	li	$t4,4		# $t4 = 4
	lw	$t5,s_color	# Get color under the cursor
	
	# Bottom three pixels
	addi	$t1,$s0,512	# Get position of row below
	
	mul	$t1,$t4,$t1	# Get position times 4
	add	$t0,$t0,$t1	# Get address of cursor position
	
	sw	$t5,-4($t0)	# Restore bottom three pixels
	sw	$t5,0($t0)
	sw	$t5,4($t0)
	
	# Middle three pixels
	addi	$t0,$t0,-2048	# Get address of current position
	
	sw	$t5,-4($t0)	# Restore middle three pixels
	sw	$t5,0($t0)
	sw	$t5,4($t0)
	
	# Top three pixels
	addi	$t0,$t0,-2048	# Get address of top row
	
	sw	$t5,-4($t0)	# Restore top three pixels
	sw	$t5,0($t0)
	sw	$t5,4($t0)
	
	jr	$ra		# Return
	
# Draws a 3x3 block of the current color under the user's cursor
# Parameters: color hex in $a0
drawpixel:
	# Changes s_color to the specified color so that when the cursor is moved, that
	# color is underneath
	sw	$a0,s_color
	jr	$ra
	
# If rainbow mode is on, cycles the color in $a0 to the next color of the rainbow
rainbow_color:
	lw	$t0,red
	beq	$a0,$t0,rc_orange	# If red, change to orange
	lw	$t0,orange
	beq	$a0,$t0,rc_yellow	# If orange, change to yellow
	lw	$t0,yellow
	beq	$a0,$t0,rc_green	# If yellow, change to green
	lw	$t0,green
	beq	$a0,$t0,rc_blue		# If green, change to blue
	lw	$t0,blue
	beq	$a0,$t0,rc_purple	# If blue, change to purple
	lw	$t0,purple
	beq	$a0,$t0,rc_red		# If purple, change to red
	jr	$ra
	rc_orange:
	lw	$a0,orange
	jr	$ra
	rc_yellow:
	lw	$a0,yellow
	jr	$ra
	rc_green:
	lw	$a0,green
	jr	$ra
	rc_blue:
	lw	$a0,blue
	jr	$ra
	rc_purple:
	lw	$a0,purple
	jr	$ra
	rc_red:
	lw	$a0,red
	jr	$ra
	
# If random mode is on, changes the color in $a0 to a random color
random_color:
	li	$v0,41		# Get random number
	syscall
	
	li	$t0,8
	div	$a0,$t0		# Divide random number by 8 and get remainder
	mfhi	$t0
	# Check for all possible random outputs and change the color accordingly
	beq	$t0,$zero,rnc_white
	li	$t1,1
	beq	$t0,$t1,rnc_black
	li	$t1,2
	beq	$t0,$t1,rnc_red
	li	$t1,3
	beq	$t0,$t1,rnc_blue
	li	$t1,4
	beq	$t0,$t1,rnc_green
	li	$t1,5
	beq	$t0,$t1,rnc_purple
	li	$t1,6
	beq	$t0,$t1,rnc_yellow
	li	$t1,7
	beq	$t0,$t1,rnc_orange
	jr	$ra
	
	rnc_white:
	lw	$a0,white
	jr	$ra
	rnc_black:
	lw	$a0,black
	jr	$ra
	rnc_red:
	lw	$a0,red
	jr	$ra
	rnc_blue:
	lw	$a0,blue
	jr	$ra
	rnc_green:
	lw	$a0,green
	jr	$ra
	rnc_purple:
	lw	$a0,purple
	jr	$ra
	rnc_yellow:
	lw	$a0,yellow
	jr	$ra
	rnc_orange:
	lw	$a0,orange
	jr	$ra
	
	
	
	
	
	
	
	
	
	
	
	
	
