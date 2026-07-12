# ==================================================================== #
#  player.s  --  Atualizacao do jogador (subsistema PLAYER_UPDATE)     #
#                                                                      #
#  Aplica o input do frame ao estado do PLAYER: movimento horizontal,  #
#  inicio de pulo e integracao da gravidade. Le GS_input_bits (posto   #
#  por INPUT_READ) e le/escreve os campos do struct PLAYER.            #
#                                                                      #
#  Fisica inteira (px/frame), suficiente para plataforma. Se o pulo    #
#  precisar de mais suavidade depois, migrar vy para float (fs*) como  #
#  o Metroid fez -- mas so se o inteiro nao bastar.                    #
#                                                                      #
#  PROVISORIO: enquanto COLLISION_UPDATE (Bloco 4) nao existe, usamos  #
#  um "chao" fixo (TEMP_GROUND_Y) so para o player nao cair para fora  #
#  da tela e dar para ver o pulo. Isso NAO e colisao real com tiles;   #
#  quando collision.s existir, a checagem de chao migra para la e o    #
#  uso de TEMP_GROUND_Y deve ser removido daqui.                       #
# -------------------------------------------------------------------- #
#  Convencao de registradores: usa t0..t3 (caller-saved). Nao chama    #
#  outra rotina, entao nao salva ra. Nao toca s*.                      #
# ==================================================================== #

.text

PLAYER_UPDATE:
    la   t0, GAME_STATE
    lw   t1, GS_input_bits(t0)   # t1 = teclas ativas neste frame
    la   t0, PLAYER              # t0 = base do struct PLAYER

    # ---- Movimento horizontal -------------------------------------- #
    # LEFT e RIGHT ajustam scr_x e a direcao (para espelhar a sprite).
    andi t2, t1, INPUT_LEFT
    beqz t2, PU_CHECK_RIGHT
        lw   t3, PLAYER_scr_x(t0)
        li   t4, PLAYER_SPEED
        sub  t3, t3, t4
        sw   t3, PLAYER_scr_x(t0)
        li   t3, DIR_LEFT
        sw   t3, PLAYER_dir(t0)
        j    PU_VERTICAL          # uma direcao por frame basta

PU_CHECK_RIGHT:
    andi t2, t1, INPUT_RIGHT
    beqz t2, PU_VERTICAL
        lw   t3, PLAYER_scr_x(t0)
        addi t3, t3, PLAYER_SPEED
        sw   t3, PLAYER_scr_x(t0)
        li   t3, DIR_RIGHT
        sw   t3, PLAYER_dir(t0)

    # ---- Pulo e gravidade ------------------------------------------ #
PU_VERTICAL:
    lw   t2, PLAYER_on_ground(t0)

    # Se esta no chao E apertou JUMP -> aplica impulso inicial de pulo.
    beqz t2, PU_APPLY_GRAVITY     # no ar: nao pode iniciar pulo
        andi t3, t1, INPUT_JUMP
        beqz t3, PU_APPLY_GRAVITY
            li   t3, PLAYER_JUMP_VY
            sw   t3, PLAYER_vy(t0)
            sw   zero, PLAYER_on_ground(t0)  # saiu do chao

PU_APPLY_GRAVITY:
    # vy += GRAVITY, saturando em MAX_FALL_VY (velocidade terminal).
    lw   t2, PLAYER_vy(t0)
    addi t2, t2, GRAVITY
    li   t3, MAX_FALL_VY
    blt  t2, t3, PU_VY_OK
        mv   t2, t3               # limita a queda
PU_VY_OK:
    sw   t2, PLAYER_vy(t0)

    # scr_y += vy
    lw   t3, PLAYER_scr_y(t0)
    add  t3, t3, t2
    sw   t3, PLAYER_scr_y(t0)

    # ---- Chao PROVISORIO (substituir por colisao real) ------------- #
    # Se passou do chao de teste, gruda no chao e zera vy.
    li   t2, TEMP_GROUND_Y
    blt  t3, t2, PU_AIRBORNE      # ainda acima do chao -> continua no ar
        sw   t2, PLAYER_scr_y(t0) # assenta no chao
        sw   zero, PLAYER_vy(t0)  # para de cair
        li   t2, 1
        sw   t2, PLAYER_on_ground(t0)
        j    PU_END

PU_AIRBORNE:
    sw   zero, PLAYER_on_ground(t0)

PU_END:
    ret
