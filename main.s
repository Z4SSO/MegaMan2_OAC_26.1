.include "data.s"


.text
main:
	li s0, 0  # Initial frame
	li s1, 0  # Reseting time
	li s2, 1  # Game loop state 
	li s3, 0  # Select state

j SETUP

GAME_LOOP:

j GAME_LOOP


.include "setup.s"
.include "render.s"	

