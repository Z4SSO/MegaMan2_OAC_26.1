# ==================================================================== #
#  enemies.s  --  IA dos inimigos (ENEMY_UPDATE)   [Requisito 8]       #
#                                                                      #
#  Percorre o ENEMY_POOL e, para cada inimigo vivo, roda a FSM do seu  #
#  tipo. Duas IAs distintas (o chefe, 3o tipo, vem depois):            #
#                                                                      #
#  VOADOR (ENT_FLYER) -- caveira:                                      #
#    IDLE    : parado (vx=vy=0).                                       #
#    SPOTTED : persegue o player em X E Y -- seta vx/vy na direcao do  #
#              player (voo livre, sem gravidade).                      #
#    Transicao IDLE->SPOTTED: player dentro do raio EN_SIGHT_RADIUS E  #
#    o inimigo estar visivel na tela.                                  #
#                                                                      #
#  CORREDOR (ENT_RUNNER) -- camera com pernas:                         #
#    IDLE    : parado.                                                 #
#    SPOTTED : corre so em X na direcao do player (preso ao chao pela  #
#              gravidade do PHYSICS_STEP). Nao mira Y.                  #
#                                                                      #
#  "Avistar" = distancia ao player < EN_SIGHT_RADIUS (usando a maior   #
#  das distancias |dx|,|dy| como aproximacao barata de raio) E o       #
#  inimigo estar dentro dos limites SCREEN_* (visivel).                #
#                                                                      #
#  Integracao de movimento:                                           #
#    - CORREDOR: escreve PH_ax e chama PHYSICS_STEP (gravidade + clamp)#
#    - VOADOR  : escreve PH_vx/PH_vy e chama PHYSICS_STEP (integra pos;#
#                PH_ax/ay ficam 0, entao so a posicao anda pela vel).  #
# -------------------------------------------------------------------- #
#  Convencao: chama PHYSICS_STEP -> salva ra. Pool percorrido em s0    #
#  (ponteiro do slot) e s1 (contador). Player em s2.                   #
# ==================================================================== #

.text

# ==================================================================== #
#  ENEMY_SPAWN_INIT  --  semeia inimigos de teste no boot.             #
#  Chamado UMA vez pelo main (antes de SETUP). Cria 1 voador e 1       #
#  corredor em posicoes fixas. Depois isso pode virar spawn por mapa   #
#  (ler posicoes de uma tabela em data.s, estilo Metroid).             #
#  Helper interno EN_INIT_SLOT preenche um slot com defaults sensatos. #
# ==================================================================== #
ENEMY_SPAWN_INIT:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, ENEMY_POOL

    # ---- Slot 0: VOADOR em (200, 40) ------------------------------ #
    li   t1, ENT_FLYER
    li   t2, 200               # x
    li   t3, 40                # y
    li   t4, EN_FLYER_HP
    li   t5, EN_FLYER_VMAX     # vx_max
    li   t6, EN_VYMAX_FLY      # vy_max (voo suave em Y)
    jal  EN_INIT_SLOT

    # ---- Slot 1: CORREDOR em (260, 144) --------------------------- #
    addi t0, t0, EN_STRIDE     # avanca p/ slot 1
    li   t1, ENT_RUNNER
    li   t2, 260               # x
    li   t3, 144               # y (perto do chao)
    li   t4, EN_RUNNER_HP
    li   t5, EN_RUNNER_VMAX    # vx_max
    li   t6, EN_VYMAX_FALL     # vy_max alto (cobre a queda)
    jal  EN_INIT_SLOT

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# --- helper: preenche o slot em t0 -------------------------------- #
#     Entrada: t1=tipo, t2=x, t3=y, t4=hp, t5=vx_max, t6=vy_max.      #
#     Zera fisica, marca ativo/idle. Usa ft0/a3 como scratch.        #
EN_INIT_SLOT:
    sw   t1, EN_type(t0)
    li   a3, 1
    sw   a3, EN_active(t0)
    li   a3, ENF_IDLE
    sw   a3, EN_fsm(t0)
    sw   t4, EN_hp(t0)
    li   a3, DIR_LEFT
    sw   a3, EN_dir(t0)
    sw   zero, EN_anim(t0)

    # posicao (int -> float)
    fcvt.s.w ft0, t2
    fsw  ft0, PH_x(t0)
    fcvt.s.w ft0, t3
    fsw  ft0, PH_y(t0)

    # zera vx/vy/ax/ay
    la   a3, PHYS_ZERO
    flw  ft0, 0(a3)
    fsw  ft0, PH_vx(t0)
    fsw  ft0, PH_vy(t0)
    fsw  ft0, PH_ax(t0)
    fsw  ft0, PH_ay(t0)

    # limites de velocidade (px/frame), vindos do chamador
    fcvt.s.w ft0, t5
    fsw  ft0, PH_vx_max(t0)
    fcvt.s.w ft0, t6
    fsw  ft0, PH_vy_max(t0)
    ret

# ==================================================================== #

ENEMY_UPDATE:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s0, 8(sp)
    sw   s1, 4(sp)
    sw   s2, 0(sp)

    la   s0, ENEMY_POOL
    li   s1, EN_MAX
    la   s2, PLAYER            # s2 = base do player (posicao alvo)

EU_LOOP:
    lw   t0, EN_active(s0)
    beqz t0, EU_NEXT           # slot livre: pula

    # ---- Distancia ao player (dx, dy em float) -------------------- #
    flw  ft0, PH_x(s0)         # enemy.x
    flw  ft1, PH_x(s2)         # player.x
    fsub.s ft2, ft1, ft0       # dx = player.x - enemy.x  (>0 => player a direita)

    flw  ft3, PH_y(s0)         # enemy.y
    flw  ft4, PH_y(s2)         # player.y
    fsub.s ft5, ft4, ft3       # dy = player.y - enemy.y

    # |dx| e |dy|
    fabs.s ft6, ft2            # |dx|
    fabs.s ft7, ft5            # |dy|

    # ---- Visibilidade: o CENTRO do inimigo esta na tela? ---------- #
    # Testar o centro (x + EN_W/2, y + EN_H/2) em vez do canto faz o
    # inimigo so congelar quando a MAIORIA do corpo saiu -- um pixel na
    # borda nao para mais o spotted. (hoje tp=0 => mundo == tela.)
    fcvt.w.s t2, ft0           # enemy.x (canto, int)
    li   t4, EN_W
    srli t4, t4, 1             # EN_W/2
    add  t2, t2, t4            # centro X
    li   t3, SCREEN_LEFT
    blt  t2, t3, EU_SET_IDLE   # centro fora pela esquerda
    li   t3, SCREEN_RIGHT
    bge  t2, t3, EU_SET_IDLE   # centro fora pela direita
    fcvt.w.s t2, ft3           # enemy.y (canto, int)
    li   t4, EN_H
    srli t4, t4, 1             # EN_H/2
    add  t2, t2, t4            # centro Y
    li   t3, SCREEN_TOP
    blt  t2, t3, EU_SET_IDLE
    li   t3, SCREEN_BOT
    bge  t2, t3, EU_SET_IDLE

    # ---- Dentro do raio de visao? (usa max(|dx|,|dy|) < R) -------- #
    fmax.s ft8, ft6, ft7       # ft8 = max(|dx|,|dy|)  (aprox. de raio)
    li   t2, EN_SIGHT_RADIUS
    fcvt.s.w ft9, t2           # ft9 = raio em float
    flt.s t2, ft8, ft9         # t2 = 1 se max < raio (avistou)
    beqz t2, EU_SET_IDLE       # fora do raio -> idle

    # ---- Avistou: SPOTTED ----------------------------------------- #
    li   t2, ENF_SPOTTED
    sw   t2, EN_fsm(s0)
    j    EU_MOVE                # segue p/ o movimento por aceleracao

    # ================= IDLE: sem alvo ============================== #
    # NAO zera velocidade bruscamente: apenas marca IDLE. O bloco de
    # movimento (EU_MOVE) aplica FREIO (desacelera ate parar) e, para
    # corredores, a gravidade continua agindo. Assim um inimigo visivel
    # sempre cai, e a parada e suave (inercia).
EU_SET_IDLE:
    li   t2, ENF_IDLE
    sw   t2, EN_fsm(s0)
    # cai em EU_MOVE

    # ================= MOVIMENTO POR ACELERACAO ==================== #
    # Escreve PH_ax/PH_ay (aceleracao) e deixa a PHYSICS_STEP integrar
    # vx/vy com clamp em vx_max/vy_max. Isso da inercia: a reversao de
    # direcao leva alguns frames (da p/ pular por cima e desviar).
    #
    # ft2 = dx (player.x - enemy.x), ft5 = dy. ft10 = 0.0 (PHYS_ZERO).
EU_MOVE:
    la   t2, PHYS_ZERO
    flw  ft10, 0(t2)           # ft10 = 0.0 (referencia de sinal)
    lw   t4, EN_fsm(s0)        # t4 = estado (SPOTTED/IDLE)
    lw   t6, EN_type(s0)       # t6 = tipo (FLYER/RUNNER)

    # ---------- Eixo X (comum aos dois tipos) ---------------------- #
    # SPOTTED: ax = +/-EN_ACCEL na direcao do player (sinal de dx).
    # IDLE   : ax = freio contrario ao vx atual (desacelera ate parar).
    li   t3, ENF_SPOTTED
    bne  t4, t3, EU_MOVE_X_IDLE

    # -- SPOTTED: acelera na direcao de dx --
    la   t2, EN_ACCEL
    flw  ft0, 0(t2)            # ft0 = +accel
    flt.s t2, ft2, ft10        # dx < 0 ? player a esquerda
    beqz t2, EU_MOVE_X_RIGHT
    fneg.s ft0, ft0           # acelera p/ esquerda
    li   t2, DIR_LEFT
    sw   t2, EN_dir(s0)
    j    EU_MOVE_X_STORE
EU_MOVE_X_RIGHT:
    li   t2, DIR_RIGHT
    sw   t2, EN_dir(s0)
    j    EU_MOVE_X_STORE

EU_MOVE_X_IDLE:
    # -- IDLE: freio. ax = -sign(vx)*EN_BRAKE (empurra vx p/ zero). --
    flw  ft1, PH_vx(s0)        # vx atual
    la   t2, EN_BRAKE
    flw  ft0, 0(t2)            # ft0 = +brake
    flt.s t2, ft10, ft1        # 0 < vx ? (vx positivo)
    beqz t2, EU_MOVE_X_IDLE_NEG
    fneg.s ft0, ft0           # vx>0 -> freio negativo
    j    EU_MOVE_X_STORE
EU_MOVE_X_IDLE_NEG:
    # vx <= 0: freio positivo (ft0 ja e +brake). Se vx==0 o clamp da
    # engine e o proprio movimento seguram perto de zero (aceitavel).

EU_MOVE_X_STORE:
    fsw  ft0, PH_ax(s0)

    # ---------- Eixo Y (depende do tipo) --------------------------- #
    li   t3, ENT_RUNNER
    beq  t6, t3, EU_MOVE_Y_RUNNER

    # -- VOADOR: ay perseguindo dy quando SPOTTED, freio quando IDLE -
    li   t3, ENF_SPOTTED
    bne  t4, t3, EU_MOVE_Y_FLY_IDLE
    la   t2, EN_ACCEL
    flw  ft0, 0(t2)
    flt.s t2, ft5, ft10        # dy < 0 ? player acima
    beqz t2, EU_MOVE_Y_STORE
    fneg.s ft0, ft0
    j    EU_MOVE_Y_STORE
EU_MOVE_Y_FLY_IDLE:
    flw  ft1, PH_vy(s0)
    la   t2, EN_BRAKE
    flw  ft0, 0(t2)
    flt.s t2, ft10, ft1        # vy > 0 ?
    beqz t2, EU_MOVE_Y_STORE
    fneg.s ft0, ft0
    j    EU_MOVE_Y_STORE

EU_MOVE_Y_RUNNER:
    # -- CORREDOR: gravidade SEMPRE (visivel => cai), independente da
    #    FSM. E o que faz qualquer corredor na tela sofrer gravidade. --
    la   t2, PHYS_GRAVITY
    flw  ft0, 0(t2)

EU_MOVE_Y_STORE:
    fsw  ft0, PH_ay(s0)
EU_INTEGRATE:
    mv   a0, s0
    call PHYSICS_STEP          # integra vx/vy/x/y do inimigo (s0 sobrevive)

    # ---- Chao PROVISORIO so p/ o CORREDOR (remover c/ COLLISION) --- #
    # Mesmo chao fixo (PHYS_GROUND_Y) que o player usa: sem colisao real
    # ainda, o corredor cairia p/ fora da tela. O voador NAO e afetado
    # (voa livre). Substituir por colisao player<->tile no Bloco 4.
    lw   t2, EN_type(s0)
    li   t3, ENT_RUNNER
    bne  t2, t3, EU_ANIM       # nao e corredor: pula o clamp
        flw  ft0, PH_y(s0)
        la   t2, PHYS_GROUND_Y
        flw  ft1, 0(t2)        # ft1 = chao
        flt.s t2, ft0, ft1     # (y < chao)?
        bnez t2, EU_ANIM       # ainda acima do chao: deixa cair
            fsw  ft1, PH_y(s0) # assenta no chao
            la   t2, PHYS_ZERO
            flw  ft2, 0(t2)
            fsw  ft2, PH_vy(s0) # zera vy

    # anima (contador simples)
EU_ANIM:
    lw   t2, EN_anim(s0)
    addi t2, t2, 1
    sw   t2, EN_anim(s0)

EU_NEXT:
    addi s0, s0, EN_STRIDE
    addi s1, s1, -1
    bnez s1, EU_LOOP

EU_END:
    lw   ra, 12(sp)
    lw   s0, 8(sp)
    lw   s1, 4(sp)
    lw   s2, 0(sp)
    addi sp, sp, 16
    ret
