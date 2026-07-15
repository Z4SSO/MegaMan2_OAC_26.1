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

    # =============== 0. Dash em andamento? (habilidade DASH) ======== #
    # Enquanto PLAYER_dash_timer > 0 o dash e INTERROMPIVEL: ignora todo
    # o controle normal (esquerda/direita/pulo), trava ax=ay=0 e vy=0 pra
    # vx (ja setado no frame que iniciou o dash, junto com PH_vx_max
    # temporariamente elevado -- ver PU_TRY_DASH) ficar constante e o
    # player so andar reto na direcao que estava olhando.
    lw   t2, PLAYER_dash_timer(t0)
    beqz t2, PU_NORMAL_CONTROL
        la   t3, PHYS_ZERO
        flw  ft0, 0(t3)
        fsw  ft0, PH_ax(t0)
        fsw  ft0, PH_ay(t0)
        fsw  ft0, PH_vy(t0)      # dash nao cai nem ganha vy
        addi t2, t2, -1
        sw   t2, PLAYER_dash_timer(t0)
        bnez t2, PU_DASH_PHYSICS
            la   t3, PLAYER_VX_MAX_DEFAULT   # dash acabou: restaura o clamp normal
            flw  ft0, 0(t3)
            fsw  ft0, PH_vx_max(t0)
PU_DASH_PHYSICS:
        mv   a0, t0
        call PHYSICS_STEP
        j    PU_END

PU_NORMAL_CONTROL:
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
    beqz  t2, PU_AIRBORNE       # no ar: pulo normal nao, mas habilidade sim
        sw   zero, PLAYER_air_used(t0)  # pisou no chao: libera a habilidade aerea de novo
        andi t2, t1, INPUT_JUMP
        beqz t2, PU_PHYSICS
            la   t2, PHYS_JUMP_VY
            flw  ft0, 0(t2)
            fsw  ft0, PH_vy(t0) # vy = velocidade de pulo (pra cima)
            sw   zero, PLAYER_on_ground(t0)
        j    PU_PHYSICS

    # ---- No ar: pulo duplo ou dash (req 4), 1x por queda/pulo ------ #
    # So dispara na tecla de pulo (mesmo botao do pulo normal -- no ar
    # ele vira a habilidade equipada) e so se ainda nao usou a
    # habilidade aerea nesta queda e ha carga suficiente.
PU_AIRBORNE:
    lw   t2, PLAYER_air_used(t0)
    bnez t2, PU_PHYSICS         # ja usou a habilidade aerea nesta queda
    andi t2, t1, INPUT_JUMP
    beqz t2, PU_PHYSICS

    lw   t3, PLAYER_ability(t0)
    li   t4, ABILITY_DASH
    beq  t3, t4, PU_TRY_DASH

    # ---- Pulo duplo ------------------------------------------------ #
    lw   t2, PLAYER_ability_charge(t0)
    li   t4, ABILITY_COST_JUMP
    blt  t2, t4, PU_PHYSICS     # carga insuficiente: nada acontece
    sub  t2, t2, t4
    sw   t2, PLAYER_ability_charge(t0)
    la   t4, PHYS_JUMP_VY
    flw  ft0, 0(t4)
    fsw  ft0, PH_vy(t0)         # 2o pulo: mesma velocidade do pulo normal
    li   t4, 1
    sw   t4, PLAYER_air_used(t0)
    j    PU_PHYSICS

    # ---- Dash -------------------------------------------------------#
    # Rajada horizontal na direcao que o player esta olhando (PLAYER_dir):
    # trava vx em DASH_SPEED_F, eleva PH_vx_max pro clamp da engine nao
    # cortar a velocidade, zera vy/ay (nao cai durante o dash) e arma
    # PLAYER_dash_timer -- o desvio no topo desta rotina segura tudo por
    # DASH_DURATION frames.
PU_TRY_DASH:
    lw   t2, PLAYER_ability_charge(t0)
    li   t4, ABILITY_COST_DASH
    blt  t2, t4, PU_PHYSICS     # carga insuficiente: nada acontece
    sub  t2, t2, t4
    sw   t2, PLAYER_ability_charge(t0)

    la   t4, DASH_SPEED_F
    flw  ft0, 0(t4)             # ft0 = DASH_SPEED (positivo)
    fsw  ft0, PH_vx_max(t0)     # eleva o clamp temporariamente
    lw   t5, PLAYER_dir(t0)
    li   t6, DIR_LEFT
    bne  t5, t6, PU_DASH_SIGN_OK
        fneg.s ft0, ft0
PU_DASH_SIGN_OK:
    fsw  ft0, PH_vx(t0)
    la   t4, PHYS_ZERO
    flw  ft1, 0(t4)
    fsw  ft1, PH_vy(t0)         # sem vy durante o dash
    fsw  ft1, PH_ay(t0)         # sem gravidade durante o dash
    li   t4, DASH_DURATION
    sw   t4, PLAYER_dash_timer(t0)
    li   t4, 1
    sw   t4, PLAYER_air_used(t0)

    # =============== 3. Integra via engine ========================= #
PU_PHYSICS:
    mv    a0, t0                # a0 = ponteiro da entidade (player)
    call  PHYSICS_STEP
    la    t0, PLAYER           # recarrega base

    # =============== 4. Chao/paredes: COLLISION_UPDATE ============= #
    # O chao provisorio (PHYS_GROUND_Y) foi removido: a colisao real
    # com os tiles do mapa (collision.s) resolve pes/cabeca/paredes e
    # escreve PLAYER_on_ground todo frame, logo apos este update.

PU_END:
    lw    ra, 0(sp)
    addi  sp, sp, 4
    ret
