# ==================================================================== #
#  player.s  --  Atualizacao do jogador (subsistema PLAYER_UPDATE)     #
#                                                                      #
#  Decide a INTENCAO de movimento do player a partir do input e chama  #
#  a engine PHYSICS_STEP para integrar. NAO integra fisica ele mesmo:  #
#  so escreve ax/ay/vx/vy no bloco de fisica do player (offsets PH_*)  #
#  e delega a integracao. Toda a "jogabilidade" mora aqui; a fisica    #
#  pura mora na engine.                                                #
#                                                                      #
#  Movimento horizontal com INERCIA: LEFT/RIGHT aplicam aceleracao     #
#  (nao velocidade direta); sem input, aplica atrito. Assim um pulo    #
#  em movimento mantem vx e vira uma parabola (o "lancamento obliquo") #
#  mesmo com o KDMMIO entregando uma tecla por frame.                  #
#                                                                      #
#  ETAPA 2 (futuro, player-friendly): gravidade assimetrica, coyote    #
#  frames, altura de pulo variavel -- tudo se implementa AQUI,         #
#  escrevendo ay/vy diferentes conforme o estado. A engine nao muda.   #
#                                                                      #
#  PROVISORIO: chao fixo (PHYS_GROUND_Y) ate COLLISION_UPDATE existir. #
#  Marcado abaixo; remover quando a colisao com tiles chegar.          #
# -------------------------------------------------------------------- #
#  Convencao: chama PHYSICS_STEP -> salva ra. Usa t0..t2, ft0..ft2.    #
# ==================================================================== #

.text

PLAYER_UPDATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, GAME_STATE
    lw   t1, GS_input_bits(t0)   # t1 = teclas ativas neste frame
    la   t0, PLAYER              # t0 = base do player (= base do bloco PH_*)

    # =============== 1. Intencao horizontal (ax) =================== #
    la    t2, PHYS_ZERO
    flw   ft0, 0(t2)
    fsw   ft0, PH_ax(t0)         # zera ax; setado conforme input abaixo

    andi  t2, t1, INPUT_LEFT
    beqz  t2, PU_CHK_RIGHT
        la    t2, PHYS_ACCEL
        flw   ft0, 0(t2)
        fneg.s ft0, ft0          # acelera para a esquerda (ax negativo)
        fsw   ft0, PH_ax(t0)
        li    t2, DIR_LEFT
        sw    t2, PLAYER_dir(t0)
        j     PU_VERTICAL

PU_CHK_RIGHT:
    andi  t2, t1, INPUT_RIGHT
    beqz  t2, PU_FRICTION
        la    t2, PHYS_ACCEL
        flw   ft0, 0(t2)
        fsw   ft0, PH_ax(t0)     # acelera para a direita (ax positivo)
        li    t2, DIR_RIGHT
        sw    t2, PLAYER_dir(t0)
        j     PU_VERTICAL

PU_FRICTION:
    # Sem input horizontal: atrito puxa vx para zero.
    # vx>0 -> ax = -friction ; vx<0 -> ax = +friction ; vx==0 -> ax = 0.
    flw   ft0, PH_vx(t0)         # ft0 = vx
    la    t2, PHYS_ZERO
    flw   ft1, 0(t2)             # ft1 = 0.0
    la    t2, PHYS_FRICTION
    flw   ft2, 0(t2)             # ft2 = friction (>0)

    flt.s t2, ft1, ft0          # (0 < vx)?
    beqz  t2, PU_FRICTION_NEG
        fneg.s ft2, ft2          # vx>0 -> ax = -friction
        fsw   ft2, PH_ax(t0)
        j     PU_VERTICAL
PU_FRICTION_NEG:
    flt.s t2, ft0, ft1          # (vx < 0)?
    beqz  t2, PU_VERTICAL       # vx == 0: ax fica 0
        fsw   ft2, PH_ax(t0)     # vx<0 -> ax = +friction

    # =============== 2. Intencao vertical (pulo + gravidade) ======= #
PU_VERTICAL:
    la    t2, PHYS_GRAVITY
    flw   ft0, 0(t2)
    fsw   ft0, PH_ay(t0)        # gravidade sempre puxa pra baixo

    lw    t2, PLAYER_on_ground(t0)
    beqz  t2, PU_PHYSICS        # no ar: nao pode iniciar pulo
        andi t2, t1, INPUT_JUMP
        beqz t2, PU_PHYSICS
            la   t2, PHYS_JUMP_VY
            flw  ft0, 0(t2)
            fsw  ft0, PH_vy(t0) # vy = velocidade de pulo (pra cima)
            sw   zero, PLAYER_on_ground(t0)

    # =============== 3. Integra via engine ========================= #
PU_PHYSICS:
    mv    a0, t0                # a0 = ponteiro da entidade (player)
    call  PHYSICS_STEP
    la    t0, PLAYER           # recarrega base

    # =============== 4. Chao PROVISORIO (remover c/ colisao) ======= #
    flw   ft0, PH_y(t0)
    la    t2, PHYS_GROUND_Y
    flw   ft1, 0(t2)           # ft1 = chao
    flt.s t2, ft0, ft1         # (y < chao)?
    bnez  t2, PU_AIRBORNE      # acima do chao -> no ar
        fsw   ft1, PH_y(t0)     # assenta no chao
        la    t2, PHYS_ZERO
        flw   ft2, 0(t2)
        fsw   ft2, PH_vy(t0)    # zera vy
        li    t2, 1
        sw    t2, PLAYER_on_ground(t0)
        j     PU_END

PU_AIRBORNE:
    sw    zero, PLAYER_on_ground(t0)

PU_END:
    lw    ra, 0(sp)
    addi  sp, sp, 4
    ret
