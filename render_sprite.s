# ==================================================================== #
#  render_sprite.s  --  Desenho de UMA sprite individual               #
#                                                                      #
#  Portado do RENDER_WORD standalone do projeto Metroid (helpers/      #
#  render.s). O RENDER_WORD do NOSSO render.s foi fundido com o loop    #
#  do RENDER_MAP e so funciona chamado de dentro dele -- nao serve     #
#  para desenhar player/inimigos/itens isolados. Esta rotina (RENAMED  #
#  para RENDER_SPRITE, evitando colisao de labels) e uma sub-rotina    #
#  independente, com loop e 'ret' proprios, chamavel via 'call'.       #
#                                                                      #
#  Argumentos (iguais aos do RENDER_WORD documentado):                 #
#    a0 = endereco da sprite                                           #
#    a1 = X (tela, top-left)     a2 = Y (tela, top-left)               #
#    a3 = largura   a4 = altura   a5 = frame (0/1)                     #
#    a6 = status (indice de animacao; desloca o endereco da sprite)    #
#    a7 = 0 (print normal) | 1 (crop; exige s1..s4 -- nao usado aqui)  #
#         | 2 (ESPELHADO na horizontal -- ver RENDER_SPRITE_MIRROR)    #
#  Nao abre pilha: usa so t0..t6 e nao chama ninguem. Retorna com ret. #
#                                                                      #
#  ------------------- MODO 2: ESPELHADO (a7=2) --------------------   #
#  Adicionado para o req 3 (animacao simetrica): os .data do artista   #
#  so tem o personagem virado para UM lado. Espelhar em tempo de       #
#  execucao evita duplicar ~42KB de sprites no .data (que virariam     #
#  ~178KB de texto fonte) e faz o flip valer de graca para qualquer    #
#  sprite futuro (inclusive o chefao).                                 #
#                                                                      #
#  Como funciona: identico ao modo normal, mas a leitura da LINHA da   #
#  sprite anda de TRAS PRA FRENTE (a0 comeca no ultimo pixel da linha  #
#  e decrementa), enquanto a escrita no framebuffer segue normal (da   #
#  esquerda pra direita). Resultado: a linha sai invertida.            #
#  A transparencia (cor 199) continua funcionando porque quem a trata  #
#  e o simulador, na escrita -- nao muda nada aqui.                    #
# ==================================================================== #

.text

RENDER_SPRITE:
li t0,2
beq a7,t0,RENDER_SPRITE_MIRROR   # a7 = 2 -> desenho espelhado (ver abaixo)
beqz a7,NORMAL_SPR
	CROP_MODE_SPR:	# When rendering cropped sprite	
		add a0,a0,s1	# Image address + X on sprite 
		mul t3,s3,s2	# t3 = sprite width * Y on sprite
		add a0,a0,t3	# a0 = Image address + X on sprite + sprite widht * Y on sprite
		mul t4,a6,s4	# t4 = sprite status x height of rendering area (for files that have more than one sprite)
		mul t4,t4,s3	# t4 = sprite status x height of rendering area x sprite's width
		j START_RENDER_SPRITE
	NORMAL_SPR:		# Executed even if on crop mode
		mul t4,a6,a4	# t4 = sprite status x height of rendering area (for files that have more than one sprite)
		mul t4,t4,a3	# t4 = sprite status x height of rendering area x width of rendering area (on NORMAL_RENDER: a3 = sprite's width)

	START_RENDER_SPRITE:
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
	
	
	PRINT_LINE_SPR:	
		lb t4,0(a0)	# loads word(4 pixels) on t4
		sb t4,0(t0)	# prints 4 pixels from t4
		
		addi t0,t0,1	# increments bitmap address
		addi a0,a0,1	# increments image address
		
		addi t3,t3,1		# increments column counter
		blt t3,a3,PRINT_LINE_SPR	# if column counter < width, repeat
		
		addi t0,t0,320	# goes to next line on bitmap display
		sub t0,t0,a3	# goes to right X on bitmap display (current address - width)
		
		beqz a7, NORMAL_RENDER_SPRITE	# If not on crop mode
		CROP_RENDER_SPRITE:
			add a0,a0,s3	# a0 += sprite width	
			sub a0,a0,a3	# a0 -= rendering width

		NORMAL_RENDER_SPRITE: 
			mv t3,zero		# t3 = 0 (Resets column counter)
			addi t2,t2,1		# increments line counter
			bgt a4,t2,PRINT_LINE_SPR	# if height > line counter, repeat
			ret


# ==================================================================== #
#  RENDER_SPRITE_MIRROR  --  desenho espelhado na horizontal (a7=2)    #
#                                                                      #
#  Mesmos argumentos do modo normal (a0..a6); a7 ja vale 2. NAO        #
#  suporta crop (o modo 1 continua sendo o crop, intocado) -- os       #
#  chamadores fazem cull total, entao crop+flip nunca coexistem.       #
#                                                                      #
#  Aritmetica: para cada linha, a leitura comeca no ULTIMO pixel       #
#  (a0 + largura - 1) e anda para tras; a escrita anda para frente.    #
#  Ao fim da linha, a0 ja recuou 'largura' bytes e esta 1 byte ANTES   #
#  do inicio da linha atual -> somar 2*largura o poe no ultimo pixel   #
#  da PROXIMA linha. (a0 += 2*W)                                       #
#                                                                      #
#  Usa t0..t6. Nao abre pilha, nao chama ninguem.                      #
# ==================================================================== #
RENDER_SPRITE_MIRROR:
	mul t4,a6,a4	# t4 = status * altura
	mul t4,t4,a3	# t4 = status * altura * largura (mesmo deslocamento do modo normal)
	add a0,a0,t4	# a0 = base do frame

	addi t5,a3,-1	# t5 = largura - 1
	add a0,a0,t5	# a0 = ULTIMO pixel da 1a linha (leitura vai para tras)

	slli t6,a3,1	# t6 = 2 * largura (avanco de linha da leitura espelhada)

	li t0,0x0FF0
	add t0,t0,a5	# endereco base + frame (double buffering)
	slli t0,t0,20
	add t0,t0,a1	# + X
	li t1,320
	mul t1,t1,a2
	add t0,t0,t1	# + Y*320  -> t0 = destino no framebuffer

	mv t2,zero	# contador de linhas
	mv t3,zero	# contador de colunas

	PRINT_LINE_MIR:
		lb t4,0(a0)	# le o pixel espelhado (da direita para a esquerda)
		sb t4,0(t0)	# escreve normal (da esquerda para a direita)

		addi t0,t0,1	# framebuffer: avanca
		addi a0,a0,-1	# sprite: RECUA (e o espelhamento)

		addi t3,t3,1
		blt t3,a3,PRINT_LINE_MIR	# repete ate acabar a linha

		addi t0,t0,320	# framebuffer: proxima linha...
		sub t0,t0,a3	# ...na mesma coluna X inicial

		add a0,a0,t6	# sprite: a0 recuou W; +2W = ultimo pixel da proxima linha

		mv t3,zero
		addi t2,t2,1
		bgt a4,t2,PRINT_LINE_MIR	# repete ate acabar a altura
		ret
