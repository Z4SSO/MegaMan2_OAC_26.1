# ==================================================================== #
#  attack.s  --  Ataque base do Mega Man (subsistema ATTACK_UPDATE)    #
#                                                                      #
#  Requisito 2 (0,5) -- ataque base; e base do req 4 (tipo de tiro     #
#  passa a variar com PLAYER_ability quando as armas chegarem).        #
#                                                                      #
#  Duas responsabilidades por frame:                                   #
#    1. SPAWN: na BORDA DE SUBIDA de INPUT_SHOOT (tecla passou de solta #
#       p/ pressionada neste frame), ocupa um slot livre do PROJ_POOL  #
#       e cria um tiro na frente do player, na direcao de PLAYER_dir.  #
#    2. ADVANCE: anda cada tiro ativo por PR_vx; quem sai da tela      #
#       (X < 0 ou X >= 320) volta a ficar livre (PR_active = 0).       #
#                                                                      #
#  Borda de subida: o GAME_LOOP salva GS_input_prev ANTES do           #
#  INPUT_READ, entao aqui prev = frame anterior e bits = frame atual.  #
#  Edge = (bits & SHOOT) AND NOT (prev & SHOOT).                       #
#                                                                      #
#  Coordenadas do tiro em pixel inteiro (sem fisica float): tiro anda  #
#  a velocidade constante. Posicao do player vem do bloco float PH_*,  #
#  convertida uma vez no spawn via fcvt.w.s.                           #
# -------------------------------------------------------------------- #
#  Convencao: nao chama ninguem -> nao precisa salvar ra, mas mantem   #
#  o padrao de pilha por consistencia. Usa t0..t6, ft0.                #
# ==================================================================== #

.text

ATTACK_UPDATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, GAME_STATE
    lw   t1, GS_input_bits(t0)      # t1 = teclas deste frame
    lw   t2, GS_input_prev(t0)      # t2 = teclas do frame anterior

    # ---- 1. Deteccao de borda de subida do tiro -------------------- #
    andi t3, t1, INPUT_SHOOT        # bit de tiro neste frame
    beqz t3, AU_ADVANCE             # nao esta pressionando: sem spawn
    andi t4, t2, INPUT_SHOOT        # bit de tiro no frame anterior
    bnez t4, AU_ADVANCE             # ja estava pressionado: nao e borda

    # ---- 2. Procura um slot livre no pool -------------------------- #
    la   t0, PROJ_POOL              # t0 = base do pool (percorre slots)
    li   t1, PROJ_MAX               # t1 = contador de slots restantes
AU_FIND:
    lw   t3, PR_active(t0)          # slot ocupado?
    beqz t3, AU_SPAWN               # livre -> usa este
    addi t0, t0, PROJ_STRIDE        # avanca p/ proximo slot
    addi t1, t1, -1
    bnez t1, AU_FIND
    j    AU_ADVANCE                 # pool cheio: descarta o tiro deste frame

    # ---- 3. Spawn no slot livre (t0 aponta p/ ele) ----------------- #
AU_SPAWN:
    li   t3, 1
    sw   t3, PR_active(t0)          # marca ocupado
    sw   zero, PR_type(t0)          # tipo 0 = Buster

    la   t4, PLAYER
    # X e Y do player (float -> int)
    flw  ft0, PH_x(t4)
    fcvt.w.s t5, ft0               # t5 = X do player (int, top-left)
    flw  ft0, PH_y(t4)
    fcvt.w.s t6, ft0               # t6 = Y do player (int, top-left)

    # Y do tiro: meio do corpo do player (PLAYER_H/2 - PROJ_H/2)
    li   t3, PLAYER_H
    srli t3, t3, 1                 # PLAYER_H/2
    add  t6, t6, t3                # centro vertical do player
    li   t3, PROJ_H
    srli t3, t3, 1
    sub  t6, t6, t3                # ajusta p/ top-left do tiro
    sw   t6, PR_y(t0)

    # Direcao: PLAYER_dir decide vx e a borda de spawn em X
    lw   t3, PLAYER_dir(t4)
    bnez t3, AU_SPAWN_LEFT         # DIR_LEFT = 1

AU_SPAWN_RIGHT:
    # sai pela direita do player: X = playerX + PLAYER_W
    li   t3, PLAYER_W
    add  t5, t5, t3
    sw   t5, PR_x(t0)
    li   t3, PROJ_SPEED            # vx positivo
    sw   t3, PR_vx(t0)
    li   a0, SFX_SHOOT             # som do Buster (sfx.s); t0..t6 nao sao
    call SFX_PLAY                  # mais usados daqui pra frente
    j    AU_ADVANCE

AU_SPAWN_LEFT:
    # sai pela esquerda do player: X = playerX - PROJ_W
    li   t3, PROJ_W
    sub  t5, t5, t3
    sw   t5, PR_x(t0)
    li   t3, PROJ_SPEED
    neg  t3, t3                    # vx negativo
    sw   t3, PR_vx(t0)
    li   a0, SFX_SHOOT             # som do Buster (sfx.s)
    call SFX_PLAY
    j    AU_ADVANCE

    # ---- 4. Avanca todos os tiros ativos --------------------------- #
AU_ADVANCE:
    la   t0, PROJ_POOL
    li   t1, PROJ_MAX
AU_ADV_LOOP:
    lw   t3, PR_active(t0)
    beqz t3, AU_ADV_NEXT           # slot livre: pula

    lw   t4, PR_x(t0)              # X atual
    lw   t5, PR_vx(t0)             # velocidade
    add  t4, t4, t5               # X += vx
    sw   t4, PR_x(t0)

    # Cull: fora da JANELA DA CAMERA (com folga de 16px) -> libera slot.
    # (antes comparava com [0,320) de mundo -- errado com scroll)
    la   t5, GAME_STATE
    lw   t5, GS_cam_x(t5)
    sub  t4, t4, t5               # X na tela = mundo - cam_x
    li   t5, -16
    blt  t4, t5, AU_ADV_FREE      # bem fora pela esquerda
    li   t5, 336                  # 320 + folga
    bge  t4, t5, AU_ADV_FREE      # bem fora pela direita
    j    AU_ADV_NEXT

AU_ADV_FREE:
    sw   zero, PR_active(t0)       # devolve o slot ao pool

AU_ADV_NEXT:
    addi t0, t0, PROJ_STRIDE
    addi t1, t1, -1
    bnez t1, AU_ADV_LOOP

AU_END:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
