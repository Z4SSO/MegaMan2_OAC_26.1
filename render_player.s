# ==================================================================== #
#  render_player.s  --  Desenho do jogador (subsistema RENDER_PLAYER)  #
#  [Requisito 3: movimentacao E ANIMACAO do personagem]                #
#                                                                      #
#  Chamado uma vez por frame, DEPOIS de RENDER_MAP_FRAME e das         #
#  entidades, para o player ficar por cima.                            #
#                                                                      #
#  ---------------- SELECAO DO FRAME (prioridade) -------------------  #
#    1. PLAYER_shoot_timer > 0  -> PLAYER_SHOOT (48x48) pose de tiro   #
#    2. !on_ground              -> PLAYER_JUMP  (48x48) no ar          #
#    3. |vx| >= PANIM_VX_MIN    -> PLAYER_RUN1..6 (64x48) ciclando     #
#    4. senao                   -> PLAYER_IDLE  (32x48) parado         #
#  O ciclo de corrida avanca com GS_tick>>1 (troca a cada 2 frames =   #
#  100ms a 20fps) e usa a PLAYER_RUN_TABLE (state.s). O indice do      #
#  frame escolhido e publicado em PLAYER_status (o campo de animacao   #
#  que existia sem consumidor): 0=idle, 1..6=run, 7=jump, 8=shoot.     #
#                                                                      #
#  ---------------- ALINHAMENTO SPRITE x HITBOX ---------------------  #
#  A caixa de colisao e SEMPRE 32x48 (PLAYER_W/H) -- ela nao muda com  #
#  a animacao. Os canvases dos frames variam (32/48/64 de largura,     #
#  todos 48 de altura, personagem centralizado, pes na base -- medido  #
#  pixel a pixel nos .data). Entao:                                    #
#     draw_x = x_tela - (spriteW - 32)/2    (ANIM_OFF_48/64, state.s)  #
#     draw_y = y_tela                        (alturas iguais)          #
#                                                                      #
#  ---------------- CULL COM FALLBACK -------------------------------  #
#  RENDER_SPRITE nao tem crop de borda: sprite parcialmente fora faz   #
#  wrap de linha (lixo) ou endereco invalido (crash). Sprite que nao   #
#  cabe INTEIRO nao e desenhado -- MAS, como os frames largos (48/64)  #
#  estouram a janela antes do idle (32), um frame largo culled cai de  #
#  volta pro PLAYER_IDLE antes de desistir. Sem isso o player sumiria  #
#  a 16px das bordas do mapa enquanto corre.                           #
# -------------------------------------------------------------------- #
#  Convencao: chama RENDER_SPRITE -> salva ra. Usa t0..t6, a0..a7.     #
# ==================================================================== #

.text

RENDER_PLAYER:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, PLAYER

    # =============== 1. Escolhe o frame de animacao ================= #
    # Saida desta secao: a0=sprite, a3=largura, t4=offset X, t5=id p/
    # PLAYER_status. Altura e sempre PLAYER_H (48).

    # -- prioridade 1: pose de tiro ---------------------------------- #
    lw   t1, PLAYER_shoot_timer(t0)
    beqz t1, RP_CHK_AIR
    la   a0, PLAYER_SHOOT
    li   a3, 48
    li   t4, ANIM_OFF_48
    li   t5, 8
    j    RP_HAVE_FRAME

RP_CHK_AIR:
    # -- prioridade 2: no ar ----------------------------------------- #
    lw   t1, PLAYER_on_ground(t0)
    bnez t1, RP_CHK_RUN
    la   a0, PLAYER_JUMP
    li   a3, 48
    li   t4, ANIM_OFF_48
    li   t5, 7
    j    RP_HAVE_FRAME

RP_CHK_RUN:
    # -- prioridade 3: correndo? (|vx| >= PANIM_VX_MIN) --------------- #
    flw   ft0, PH_vx(t0)
    fabs.s ft0, ft0              # |vx|
    la    t1, PANIM_VX_MIN
    flw   ft1, 0(t1)
    flt.s t1, ft0, ft1           # |vx| < limiar ?
    bnez  t1, RP_IDLE

    # ciclo de corrida: frame = (GS_tick >> 1) % 6, via PLAYER_RUN_TABLE
    la   t1, GAME_STATE
    lw   t2, GS_tick(t1)
    srli t2, t2, 1               # troca de frame a cada 2 ticks (100ms)
    li   t3, 6
    remu t2, t2, t3              # t2 = indice 0..5
    la   t1, PLAYER_RUN_TABLE
    slli t3, t2, 2
    add  t1, t1, t3
    lw   a0, 0(t1)               # a0 = PLAYER_RUN<n>
    li   a3, 64
    li   t4, ANIM_OFF_64
    addi t5, t2, 1               # status 1..6
    j    RP_HAVE_FRAME

RP_IDLE:
    la   a0, PLAYER_IDLE
    li   a3, PLAYER_W            # 32
    li   t4, 0                   # sem offset: canvas == hitbox
    li   t5, 0

RP_HAVE_FRAME:
    sw   t5, PLAYER_status(t0)   # publica o frame atual (campo de animacao)

    # =============== 2. Posicao de tela + cull (c/ fallback) ======== #
    # Posicao de render: projetada da posicao float (fonte de verdade)
    # por fcvt.w.s, recalculada a cada frame -> nunca realimenta erro.
    flw   ft0, PH_x(t0)
    fcvt.w.s a1, ft0             # a1 = (int) x de MUNDO (da HITBOX)
    la    t2, GAME_STATE
    lw    t3, GS_cam_x(t2)
    sub   a1, a1, t3            # a1 = X da hitbox na tela
    mv    t6, a1                 # t6 = copia (p/ o fallback recalcular)
    sub   a1, a1, t4             # a1 = X de DESENHO (centraliza canvas largo)

    # cull X do frame escolhido: [0, 320-W]
    bltz  a1, RP_FALLBACK        # estourou a esquerda
    li    t3, 320
    sub   t3, t3, a3             # 320 - largura do sprite
    bgt   a1, t3, RP_FALLBACK    # estourou a direita
    j     RP_CULL_Y

RP_FALLBACK:
    # Frame largo nao coube: tenta o IDLE (32, sem offset) na mesma
    # posicao da hitbox. Se ja ERA o idle (t4==0), nao ha o que tentar.
    beqz  t4, RP_SKIP
    la    a0, PLAYER_IDLE
    li    a3, PLAYER_W
    sw    zero, PLAYER_status(t0)
    mv    a1, t6                 # X da hitbox (offset 0)
    bltz  a1, RP_SKIP
    li    t3, 288                # 320 - 32
    bgt   a1, t3, RP_SKIP

RP_CULL_Y:
    flw   ft1, PH_y(t0)
    fcvt.w.s a2, ft1            # a2 = (int) y (todas as alturas sao 48)
    bltz  a2, RP_SKIP           # saiu por cima (evita crash)
    li    t3, 192               # 240 - 48
    bgt   a2, t3, RP_SKIP       # saiu por baixo

    # =============== 3. Desenha ===================================== #
    li   a4, PLAYER_H            # altura: 48 em todos os frames atuais

    la   t1, GAME_STATE
    lw   a5, GS_frame(t1)        # frame de destino (double buffering)

    li   a6, 0                   # status SEMPRE 0 aqui: os frames sao
                                 # labels separados (a tabela escolhe o
                                 # endereco); a6!=0 deslocaria o endereco
                                 # por status*W*H e leria lixo.
    li   a7, 0                   # print normal (nao cropped)

    call RENDER_SPRITE           # rotina standalone (render_sprite.s)

RP_SKIP:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
