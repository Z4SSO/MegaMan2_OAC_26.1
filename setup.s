.text

# ----> Summary: setup.s has setup related procedures
# 1 - SETUP (Sets up game by rendering maps and attributing default values)
# 2 - UPDATE DOORS (Updates status of doors when necessary)


#####################          SETUP          ######################
#   Sets up game by rendering maps and attributing default values  #
#                                                                  #		
#  ----------------        registers used        ----------------  #
#    t1 -- t5,tp = Temporary Registers                             #
#    a0 -- a7 => used as arguments                                 #
#                                                                  #
####################################################################

SETUP:

    SETUP_GAME:

    # Setting Render Next Map Door to zero
    la t0, NEXT_MAP   # Loads NEXT_MAP address
    sb zero,10(t0)    # Stores 0 on Render Next Map Door (in order to render current map's doors properly)

    # Getting informations about Current Map
    la t0, MAP_INFO # Loads Map Info address
    lbu t1, 0 (t0)  # Loads byte related to map number
    lbu t2, 1 (t0)  # Loads rendering byte (0 - don't render, 1 - render once, 2 - render twice, 
                    # 3 - switch map (through door), 4 - switch map (through cheat input)) 
                   

    li t0, 1 

    j MAP1_SETUP



    MAP1_SETUP:
        la a0, Map1 	# Map Address     
        la t0, CURRENT_MAP # Loads CURRENT_MAP address
        sw a0, 0(t0)    # Stores Map1 address on CURRENT_MAP
        
        lbu a1, 6(t0)   # Loads current X on Map (starting X on Matrix (top left))
        lbu a2, 7(t0)   # Loads current Y on Map (starting Y on Matrix (top left))	
        lbu a3, 8(t0)   # Loads current X offset on Map
        lbu a4, 9(t0)   # Loads current Y offset on Map	

        li t1, 4
        bne t2, t1 CONTINUE_MAP1_SETUP

        CONTINUE_MAP1_SETUP:
        li a5, 0		# Frame = 0
        li a6, m_screen_width	# Screen Width = 20
        li a7, m_screen_height	# Screen Height = 15
        li t3, 0		# Starting X for rendering (top left, related to Matrix)
        li t2, 0		# Starting Y for rendering (top left, related to Matrix)
        li tp, 0        # Map won't be dislocated
        
        call RENDER_MAP
  


        END_SETUP:
    la t0, CURRENT_MAP   # Loads CURRENT_MAP address
    lbu t1,5(t0)         # Loads rendering byte     
    li t2, 3             # Loads 3 (switch map through door) to be compared with





    j GAME_LOOP