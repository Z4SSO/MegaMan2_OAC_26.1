.text
###########################    RENDER WORD    ###########################
#   Renders image when address is given. It renders word by word        #
#     -----------           argument registers           -----------    #
#       a0 = Image Address                                              #
#       a1 = X coordinate where rendering will start (top left)         #
#       a2 = Y coordinate where rendering will start (top left)         #
#       a3 = width of rendering area (usually the size of the sprite)   #
#       a4 = height of rendering area (usually the size of the sprite)  #
#       a5 = frame (0 or 1)                                             #
#       a6 = status of sprite (usually 0 for sprites that are alone)    #
#       a7 = operation (0 if normal printing, 1 cropped print)          #
# -- saved registers (recieved as arguments - only when on crop mode)-- #
#       s1 = X coordinate relative to sprite (top left)                 #
#       s2 = Y coordinate relative to sprite (top left)                 #
#       s3 = sprite width                                               #
#       s4 = sprite height                                              #
#     -----------          temporary registers           -----------    #
#       t0 = bitmap display printing address                            #
#       t1 = image address                                              #
#       t2 = line counter                                               #
#       t3 = column counter                                             #
#       t4 = temporary operations                                       #
#########################################################################
RENDER_WORD:
beqz a7,NORMAL_WORD
	CROP_MODE_WORD:	# When rendering cropped sprite	
		add a0,a0,s1	# Image address + X on sprite 
		mul t3,s3,s2	# t3 = sprite width * Y on sprite
		add a0,a0,t3	# a0 = Image address + X on sprite + sprite widht * Y on sprite
		mul t4,a6,s4	# t4 = sprite status x height of rendering area (for files that have more than one sprite)
		mul t4,t4,s3	# t4 = sprite status x height of rendering area x sprite's width
		j START_RENDER_WORD
	NORMAL_WORD:		# Executed even if on crop mode
		mul t4,a6,a4	# t4 = sprite status x height of rendering area (for files that have more than one sprite)
		mul t4,t4,a3	# t4 = sprite status x height of rendering area x width of rendering area (on NORMAL_RENDER: a3 = sprite's width)

	START_RENDER_WORD:
		add a0,a0,t4	# Adds the dislocation calculated on t4 to the sprite's address
	#Propper rendering
	li t0,0x0FF0	#t0 = 0x0FF0
	add t0,t0,a5	# Rendering Address corresponds to 0x0FF0 + frame
	slli t0,t0,20	# Shifts 20 bits, making printing adress correct (0xFF00 0000 or 0xFF10 0000)
	add t0,t0,a1	# t0 = 0xFF00 0000 + X or 0xFF10 0000 + X
	li t1,320	# t1 = 320
	mul t1,t1,a2	# t1 = 320 * Y 
	add t0,t0,t1	# t0 = 0xFF00 0000 + X + (Y * 320) or 0xFF10 0000 + X + (Y * 320)
	
	mv t2,zero	# t2 = 0 (Resets line counter)
	mv t3,zero	# t3 = 0 (Resets column counter)
	
	
	PRINT_LINE_WORD:	
		lbu t4,0(a0)	# loads word(4 pixels) on t4
		sb t4,0(t0)	# prints 4 pixels from t4
		
		addi t0,t0,1	# increments bitmap address
		addi a0,a0,1	# increments image address
		
		addi t3,t3,1		# increments column counter
		blt t3,a3,PRINT_LINE_WORD	# if column counter < width, repeat
		
		addi t0,t0,320	# goes to next line on bitmap display
		sub t0,t0,a3	# goes to right X on bitmap display (current address - width)
		
		beqz a7, NORMAL_RENDER_WORD	# If not on crop mode
		CROP_RENDER_WORD:
			add a0,a0,s3	# a0 += sprite width	
			sub a0,a0,a3	# a0 -= rendering width

		NORMAL_RENDER_WORD: 
			mv t3,zero		# t3 = 0 (Resets column counter)
			addi t2,t2,1		# increments line counter
			bgt a4,t2,PRINT_LINE_WORD	# if height > line counter, repeat
			j EndRender
############################## RENDER COLOR #############################
#                Renders a given color on a given space                 #
#     -----------           argument registers           -----------    #
#       a0 = color                                                      #
#       a1 = X coordinate where rendering will start (top left)         #	
#       a2 = Y coordinate where rendering will start (top left)         #
#       a3 = width of printing area (usually the size of the sprite)    #
#       a4 = height of printing area (usually the size of the sprite)   #
#       a5 = frame (0 or 1)                                             #
#       a6 = operation (0 - rendering 4 pixels at once;                 #
#                       1 -  rendering 2 pixels at once)                #	
#     -----------          temporary registers           -----------    #
#       t0 = bitmap display printing address                            #
#       t1 = temporary operations                                       #
#       t2 = line counter                                               #
#       t3 = column counter                                             # 
#########################################################################

RENDER_COLOR:
	li t0,0xFF0	# t0 = 0xFF0
	add t0,t0,a5	# Rendering Address corresponds to 0x0FF0 + frame
	slli t0,t0,20	# Shifts 20 bits, making printing adress correct (0xFF00 0000 or 0xFF10 0000)
	
	add t0,t0,a1	# t0 = 0xFF00 0000 + X or 0xFF10 0000 + X
	
	li t1,320	# t1 = 320
	mul t1,t1,a2	# t1 = 320 * Y 
	add t0,t0,t1	# t0 = 0xFF00 0000 + X + (Y * 320) or 0xFF10 0000 + X + (Y * 320)
	
	mv t2,zero	# t2 = 0 (Resets line counter)
	mv t3,zero	# t3 = 0 (Resets column counter)
	
	slli t1,a0,8	# Shifts 8 bits on a0
	add a0,a0,t1	# a0 now stores two bytes of the same color (e.g.: 0x000000FF -> 0x0000FFFF)
	
	bnez a6, PRINT_LINE_COLOR_HALF # If not printing 4 pixels at once
		slli t1,a0,16	       # Shifts 16 bits on a0
		add a0,a0,t1	       # a0 now stores four bytes of the same color (e.g.: 0x0000FFFF -> 0xFFFFFFFF)
		j PRINT_LINE_COLOR_WORD
		
	PRINT_LINE_COLOR_HALF:	
		sh a0,0(t0)	# Renders two color pixels at once
		addi t0,t0,2	# increments bitmap address by 2 bytes
		
		addi t3,t3,2			# increments column counter
		blt t3,a3,PRINT_LINE_COLOR_HALF	# if column counter < width, repeat
		
		addi t0,t0,320	# goes to next line on bitmap display
		sub t0,t0,a3	# goes to right X on bitmap display (current address - width)
		
		mv t3,zero			# t3 = 0 (resets column counter)
		addi t2,t2,1			# increments line counter
		bgt a4,t2,PRINT_LINE_COLOR_HALF	# if height > line counter, repeat
		j EndRender			
		
	PRINT_LINE_COLOR_WORD:
		sw a0,0(t0)	# Renders four color pixels at once
		addi t0,t0,4	# increments bitmap address by 4 bytes
		
		addi t3,t3,4			# increments column counter
		blt t3,a3,PRINT_LINE_COLOR_WORD	# if column counter < width, repeat
		addi t0,t0,320	# goes to next line on bitmap display
		sub t0,t0,a3	# goes to right X on bitmap display (current address - width)
		
		mv t3,zero			# t3 = 0 (resets column counter)
		addi t2,t2,1			# increments line counter
		bgt a4,t2,PRINT_LINE_COLOR_WORD	# if height > line counter, repeat
		j EndRender


RENDER_MAP:
# Storing Registers on Stack
	addi sp,sp,-20
	sw ra,16(sp)
	sw s3,12(sp)
	sw s2,8(sp)
	sw s1,4(sp)
	sw s0,0(sp)
# End of Stack Operations
	addi t0,a0,3 	# skips first 3 bytes of information (goes to the actual matrix)
	add s0, t0, a1 	# s0 = Matrix Address + Starting X on Matrix
	lbu s1,1(a0)	# s1 = matrix width
	mul t0,s1,a2    # t0 = Matrix Width x Starting Y on Matrix
	add s0, s0, t0	# s0 = Address to current X and Y on Matrix
	
	RENDER_MAP_GetCurrentX:
	add s3,t3,a6 	# s3 will be compared with t3 (column counter) to go to next line
	beqz t3,RENDER_MAP_NoTrailX
	
	sub t3,t3,a1	# t3 now is the column counter related to the screen matrix
	add s3,t3,a6
	add s0, s0, t3 	# s0 = Matrix Address + Current X on Matrix
	j RENDER_MAP_GetCurrentY
	
	RENDER_MAP_NoTrailX:
	beqz a3, RENDER_MAP_GetCurrentY # If there's no X offset
	li t0, m_screen_width
	blt a6,t0, RENDER_MAP_GetCurrentY   # If width of rendering area is smaller than the screen's width, ignore
	blt zero,tp, RENDER_MAP_GetCurrentY # If map is dislocated, ignore the next step
	add t1,a1,a6    # t1 = Starting X + Width in tiles
	beq t1,s1, RENDER_MAP_GetCurrentY   # If map is on furthest X to the right, don't increase width
	addi s3,t0,1	# if rendering a full screen (20 wide) with offset, will need to render 21 tiles
		
	RENDER_MAP_GetCurrentY:
	add s2,t2,a7 	# s2 will be compared with t2 (column counter) to go to next line
	beqz t2,RENDER_MAP_NoTrailY
	
	sub t2,t2,a2	# t2 now is the column counter related to the screen matrix
	add s2,t2,a7
	mul t0,s1,t2    # t0 = Matrix Width x Current Y on Matrix
	add s0, s0, t0	# s0 = Address to current X and Y on Matrix
	j RENDER_MAP_LOOP

    RENDER_MAP_NoTrailY:
	beqz a4, RENDER_MAP_LOOP # If there's an X offset
	li t0, m_screen_height
	blt a7,t0 RENDER_MAP_LOOP # If height of rendering area is smaller than the screen's height, ignore
	addi s2,t0,1	# if rendering a full screen (15 wide) with offset, will need to render 16 tiles
	
RENDER_MAP_LOOP:

	# Getting tile information from the map matrix
	lbu t1,0(s0)		# t1 = tile ID (21 means empty/background - dummy tile)
	mv t0,zero		# default address for color render
	mv t4,zero		# default sprite status
	li t5,21		# t5 = ID treated as empty/background (dummy tile)
	beq t1,t5,RENDER_MAP_SaveRegisters
	slli t0,t1,8		# each tile sprite has 16 x 16 = 256 bytes
	la t4,Tileset
	add t0,t4,t0		# t0 = address of tile sprite
	mv t4,zero		# tiles use sprite status 0

	RENDER_MAP_SaveRegisters:

	# Storing Registers on Stack
	addi sp,sp,-56
	sw s4,52(sp)
	sw s3,48(sp)
	sw s2,44(sp)
	sw s1,40(sp)
	sw a7,36(sp)
	sw a6,32(sp)
	sw a4,28(sp)
	sw a3,24(sp)
	sw a2,20(sp)
	sw a1,16(sp)
	sw a0,12(sp)
	sw t2,8(sp)
	sw t3,4(sp)
	sw tp,0(sp)
	# End of Stack Operations

	mv a0, t0 # Moves t0 (storing tile address) to a0
	mv a6,t4  # Moves tmv t4 (tile's sprite status) to a6
	          # +--> a6 will be always set to zero when in color mode afterwards 
	# Defining rendering coordinates
	li t0, tile_size 	# Tile size = 16
	add t6,tp,t3        # t6 gets t3 (current X) + tp (X dislocation)
	mul t4,t6,t0		# t4 gets the X value relative to the screen ((t3 + tp) * tile size)
	mul t5,t2,t0		# t5 gets the Y value relative to the screen (t2 (current Y) * tile size)
	# Obs.: don't use t4 and t5 until stack is saved, unless it's related to rendering coordinates
	li t6,0
	bnez a3, X_Offset 	# If there's a X offset
	j Check_Y_Offset
	X_Offset:
		add t0,t3,tp
		bnez t0, TryRightOffset  # If t3 (current colum, i.e., current X) = 0, it's on the left border
		li t6,1			         # t6 = 1: Cropping leftmost tile
		j START_RENDER_MAP  	 # start rendering process
		TryRightOffset:
		li t0, m_screen_width    # screen width related to matrix = 20
		sub t0,t0,t3             # t0 = screen width - t3 (current X) 
		sub t0,t0,tp             # t0 = screen width - t3 (current X) - tp (X dislocation) 
		bne zero, t0, NoX_Offset # If t0 <= 0 (t3 + tp >= 20), it's on the right border
		li t6,2			 # t6 = 2: Cropping rightmost tile
		NoX_Offset:
		j START_RENDER_MAP	 # start rendering process
	
	Check_Y_Offset:
	bnez a4, Y_Offset		 # Or a Y offset, go to offset operations
	j START_RENDER_MAP
	
	Y_Offset:
		bnez t2, TryBottomOffset # If t3 (current colum, i.e., current X) = 0, it's on the top border
		li t6,1			 # t6 = 1: Cropping uppermost tile
		j START_RENDER_MAP	 # start rendering process
		TryBottomOffset:
		li t0, m_screen_height   # screen height related to matrix = 15
		bne t2, t0, NoY_Offset   # If t2 = 15, it's on the lower border
		li t6,2			 # t6 = 2: Cropping lowermost tile
		NoY_Offset:
		j START_RENDER_MAP	 # start rendering process
	
	START_RENDER_MAP:
	li t0,21
	beq t1,t0,ColorRenderBlock
	j NormalRender
	ColorRenderBlock:
	# Color Render
		li a0, 0x00 		# Black
		mv a1, t4		# Top Left X
		mv a2, t5		# Top Left Y	
		mv a6, zero
		# a5 doesn't change
		bnez t6, CropColor 
		j NoCropColor
		CropColor:
		li a6, 1
		addi t6,t6,-1
		bnez t6, RightBottomColorCrop
			LeftTopColorCrop:
				li t0, tile_size	
				sub a3,t0, a3		# a3 will hold rendering widht that is equal to the tile size (16) - X offset
				sub a4,t0, a4		# a4 will hold rendering height that is equal to the tile size (16) - Y offset
				j StartColorRender
			RightBottomColorCrop:	
				sub a1,a1,a3		# a1 will shift left the ammount of a3 (currently X offset) 
				sub a2,a2,a4		# a2 will shift up the ammount of a4 (currently Y offset)
				CheckXColor:
				bnez a3, CheckYColor # If X offset (a3) isn't zero, the widht for rendering the cropped tile will be the X offset
				li a3, tile_size	    # otherwise, it'll be the tile size
				CheckYColor:
				bnez a4, EndRightBottomCropColor # If Y offset (a4) isn't zero, the widht for rendering the cropped tile will be the Y offset
				li a4, tile_size	    # otherwise, it'll be the tile size
				EndRightBottomCropColor:
				j StartColorRender
		NoCropColor:
			sub a1,a1,a3		# a1 will shift left the ammount of a3 (currently X offset) 
			sub a2,a2,a4		# a2 will shift up the ammount of a4 (currently Y offset)	
			li a3, tile_size	# Tile Width (Screen)
			li a4, tile_size	# Tile Height (Screen)	
		
		StartColorRender:
		j RENDER_COLOR
		j EndRender
	
	NormalRender:
		# a0 has the tile address
		mv a1, t4		# Top Left X where tile will start rendering
		mv a2, t5		# Top Left Y where tile will start rendering			
		# a6 was already set (Tiles usually have one image, thus their status is allways 0  -- there are exceptions)
		# If no offset is taken into account, will skip unecessary parameters  
		bnez t6, Continue_Crop 
		j Skip_Offset
		Continue_Crop: 
		li a7,1			# Cropped Render operations
		addi t6,t6,-1		# After this, t6 = 0 or t6 = 1
		bnez t6, RightBottomCrop
		LeftTopCrop:	 # Will crop tile from the left or from the top
			mv s1, a3		# s1 will store the X offset (where rendering will start from)
			mv s2, a4		# s2 will store the Y offset (where rendering will start from)
			li s3, tile_size	# s3 = 16
			li s4, tile_size	# s4 = 16
			sub a3,s3, s1		# a3 will hold rendering widht that is equal to the tile size (16) - X offset
			sub a4,s3, s2		# a4 will hold rendering height that is equal to the tile size (16) - Y offset
			j Start_NormalRender
		RightBottomCrop: # Will crop tile from the right or bottom
			mv s1,zero		# s1 = 0 (rendering will start from the left)
			mv s2,zero		# s2 = 0 (rendering will start from the top)
			li s3, tile_size	# s3 = 16
			li s4, tile_size	# s4 = 16
			sub a1,a1,a3		# a1 will shift left the ammount of a3 (currently X offset) 
			sub a2,a2,a4		# a2 will shift up the ammount of a4 (currently Y offset)
			CheckX:
			bnez a3, CheckY # If X offset (a3) isn't zero, the widht for rendering the cropped tile will be the X offset
			li a3, tile_size	    # otherwise, it'll be the tile size
			CheckY:
			bnez a4, EndRightBottomCrop # If Y offset (a4) isn't zero, the widht for rendering the cropped tile will be the Y offset
			li a4, tile_size	    # otherwise, it'll be the tile size
			EndRightBottomCrop:
			j Start_NormalRender
		# If no offset is taken into account, a3 and a4 will be overriten with the deffault tile size (16)  
		Skip_Offset:
		sub a1,a1,a3		# a1 will shift left the ammount of a3 (currently X offset) 
		sub a2,a2,a4		# a2 will shift up the ammount of a4 (currently Y offset) 
		li a3, tile_size	# Tile Width (Relative to Screen)
		li a4, tile_size	# Tile Height (Relative to Screen)
		mv a7,zero		# Normal Render operations
		Start_NormalRender:
		j RENDER_WORD
	
	EndRender:
# Procedure finished: Loading Registers from Stack
	lw s4,52(sp)
	lw s3,48(sp)
	lw s2,44(sp)
	lw s1,40(sp)
	lw a7,36(sp)
	lw a6,32(sp)
	lw a4,28(sp)
	lw a3,24(sp)
	lw a2,20(sp)
	lw a1,16(sp)
	lw a0,12(sp)
	lw t2,8(sp)
	lw t3,4(sp)
	lw tp,0(sp)
	addi sp,sp,56
# End of Stack Operations
			
	addi t3,t3,1	# Increments column counter (current X on Matrix)
	addi s0,s0,1	# Goes to next byte
	bge t3,s3,CONTINUE_LINE	# if column counter >= width, repeat
	j RENDER_MAP_LOOP	# if column counter < width, repeat
	
	CONTINUE_LINE:
		add s0,s0,s1	# s0 = Current Address on Matrix + Matrix Width
		li t0, m_screen_width
		bge a6,t0, MINUS_WIDTH # If width = 20, probably not on remove trail mode
		sub s0,s0,a6	# s0 = New Current Address on Matrix 
		sub t3,t3,a6	# t3 = 0 (resets column counter)
		j CONTINUE_LINE2
		MINUS_WIDTH:
		sub s0,s0,s3
		mv t3,zero	# t3 = 0 (resets column counter)
		
		CONTINUE_LINE2:
		addi t2,t2,1	# Increments line counter (current Y on Matrix)
		bge t2,s2,CONTINUE_COLUMN # If height > line counter, repeat
		j RENDER_MAP_LOOP	  # Return to beggining of loop
		CONTINUE_COLUMN:
	# Procedure finished: Loading Registers from Stack
		lw ra,16(sp)	
		lw s3,12(sp)
		lw s2,8(sp)
		lw s1,4(sp)
		lw s0,0(sp)
		addi sp,sp,20
	# End of Stack Operations: Return to caller		
		ret
		
#RENDER_CUSTOM:
#
#	sw s4,52(sp)
#	sw s3,48(sp)
#	sw s2,44(sp)
#	sw s1,40(sp)
#	sw a7,36(sp)
#	sw a6,32(sp)
#	sw a4,28(sp)
#	sw a3,24(sp)
#	sw a2,20(sp)
#	sw a1,16(sp)
#	sw a0,12(sp)
#	sw t2,8(sp)
#	sw t3,4(sp)
#	sw tp,0(sp)
	
#	mv t0, a0
#	lw t1, 0(t0)
#	lw t2, 4(t0)
#	addi t0, t0, 8
	
#	li t3,0xFF0	# t0 = 0xFF0
#	add t3,t3,a5	# Rendering Address corresponds to 0x0FF0 + frame
#	slli t3,t3,20	# Shifts 20 bits, making printing adress correct (0xFF00 0000 or 0xFF10 0000) 
	
#	add t3,t3,t1	# t0 = 0xFF00 0000 + X or 0xFF10 0000 + X
	
#	li t4,320	# t1 = 320
#	mul t4,t4,t2	# t1 = 320 * Y 
#	add t3,t3,t4	# t0 = 0xFF00 0000 + X + (Y * 320) or 0xFF10 0000 + X + (Y * 320)
	
#	mv s2,zero	# t2 = 0 (Resets line counter)
#	mv s3,zero	# t3 = 0 (Resets column counter)
	
	
#	RENDER_CUSTOM_LOOP:
	
#	addi s4, s2, 1
#	beq s4, t2, FIM_RENDER_CUSTOM
	
#	lw s1,0(t0)
#	sw s1, 0(t3)
	
#	addi s3, s3, 4
#	li t6, 128
#	bne s3, t6, CALCULA_ENDERECO_CUSTOM
#	mv s3, zero
#	addi s2, s2, 1
	
#	CALCULA_ENDERECO_CUSTOM:
	
#	li t6, 96
#	add t6, t6, s3
#	li t4,320	# t1 = 320
#	mul t4,t4,s2	# t1 = 320 * Y 
#	add t6, t6, t4
#	mv t3, t6
#	addi t0, t0, 4
	
#	j RENDER_CUSTOM_LOOP 
	
#	FIM_RENDER_CUSTOM:
	
#	lw s4,52(sp)
#	lw s3,48(sp)
#	lw s2,44(sp)
#	lw s1,40(sp)
#	lw a7,36(sp)
#	lw a6,32(sp)
#	lw a4,28(sp)
#	lw a3,24(sp)
#	lw a2,20(sp)
#	lw a1,16(sp)
#	lw a0,12(sp)
#	lw t2,8(sp)
#	lw t3,4(sp)
#	lw tp,0(sp)
#	addi sp,sp,56
	
#	ret

	
