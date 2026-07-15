# ==================================================================== #
#  render_entities.s -- Desenho de entidades (RENDER_ENTITIES)         #
#                                                                      #
#  Chamado uma vez por frame, DEPOIS de RENDER_MAP_FRAME e ANTES de    #
#  RENDER_PLAYER (o player fica por cima). Por ora desenha apenas os   #
#  PROJETEIS ativos; inimigos e itens entram aqui no Bloco 3/4         #
#  (mesma estrutura: iterar o pool, chamar RENDER_SPRITE por sprite).  #
#                                                                      #
#  Usa RENDER_SPRITE (render_sprite.s), a rotina STANDALONE com 'ret'  #
#  proprio -- NAO o RENDER_WORD interno do RENDER_MAP.                 #
#                                                                      #
#  RENDER_SPRITE espera:                                               #
#    a0 = endereco da sprite   a1 = X (tela)   a2 = Y (tela)           #
#    a3 = largura   a4 = altura   a5 = frame                           #
#    a6 = status (0)   a7 = 0 (print normal)                           #
# -------------------------------------------------------------------- #
#  Convencao: chama RENDER_SPRITE -> salva ra. s0/s1 preservados       #
#  (callee-saved) p/ manter o ponteiro do pool atravessando o call.    #
# ==================================================================== #

.text

RENDER_ENTITIES:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s0, 4(sp)                 # s0 = ponteiro do slot atual (sobrevive ao call)
    sw   s1, 0(sp)                 # s1 = contador de slots restantes

    la   s0, PROJ_POOL
    li   s1, PROJ_MAX

RE_LOOP:
    lw   t0, PR_active(s0)
    beqz t0, RE_NEXT              # slot livre: nao desenha

    # Monta argumentos do RENDER_SPRITE p/ este tiro
    la   a0, BUSTER_SPRITE        # sprite do projetil
    lw   a1, PR_x(s0)             # X de MUNDO
    la   t0, GAME_STATE
    lw   t1, GS_cam_x(t0)
    sub  a1, a1, t1              # X de tela = mundo - cam_x
    # CULL: RENDER_SPRITE nao faz crop de borda -- desenhar parcialmente
    # fora (X<0 ou X+W>320) "da a volta" na linha do framebuffer e vira
    # colunas de lixo. Sprite que nao cabe INTEIRO na tela nao desenha.
    bltz a1, RE_NEXT             # saiu pela esquerda
    li   t2, 312                 # 320 - PROJ_W(8)
    bgt  a1, t2, RE_NEXT         # saiu pela direita
    lw   a2, PR_y(s0)             # Y na tela (sem scroll vertical)
    bltz a2, RE_NEXT              # CULL Y: fora por cima (evita crash)
    li   t2, 232                  # 240 - PROJ_H(8)
    bgt  a2, t2, RE_NEXT          # fora por baixo
    li   a3, PROJ_W               # largura (8)
    li   a4, PROJ_H               # altura (8)

    lw   a5, GS_frame(t0)         # frame de destino (double buffering)
    li   a6, 0                    # status 0 (1 frame de animacao)
    li   a7, 0                    # print normal (nao cropped)

    call RENDER_SPRITE

RE_NEXT:
    addi s0, s0, PROJ_STRIDE
    addi s1, s1, -1
    bnez s1, RE_LOOP

    # ================= 2a passada: INIMIGOS ======================== #
    # [Req 3/8: animacao] Sprite escolhido por TIPO + estado da FSM,
    # ciclando pelo EN_anim (contador por entidade que enemies.s ja
    # incrementava sem consumidor -- agora ele e a animacao):
    #   VOADOR  : IDLE -> EN2_IDLE parado; SPOTTED -> EN2_A1..6 (asas)
    #   CORREDOR: IDLE -> EN1_IDLE parado; SPOTTED -> EN1_RUN1..3
    # A troca parado/animando tambem e feedback de aggro pro jogador.
    #
    # ALINHAMENTO: a caixa de colisao NAO muda (voador 32x32, corredor
    # 32x48). Frames RUN do corredor tem canvas 64 de largura com o
    # corpo centralizado -> draw_x = x_hitbox - ANIM_OFF_64. Se o frame
    # largo nao couber na tela (cull total, sem crop), cai de volta pro
    # EN1_IDLE (32) antes de desistir -- senao o corredor sumiria perto
    # das bordas. Alturas sempre iguais as da hitbox -> draw_y = y.
    la   s0, ENEMY_POOL
    li   s1, EN_MAX
RE_EN_LOOP:
    lw   t0, EN_active(s0)
    beqz t0, RE_EN_NEXT

    lw   t0, EN_type(s0)
    li   t1, ENT_FLYER
    bne  t0, t1, RE_EN_RUNNER

    # ---- VOADOR (32x32, canvas == hitbox, offset 0 sempre) --------- #
    li   a3, EN_FLYER_W
    li   a4, EN_FLYER_H
    li   t4, 0                  # offset X: nenhum
    lw   t1, EN_fsm(s0)
    li   t2, ENF_SPOTTED
    beq  t1, t2, RE_EN2_FLYANIM
    la   a0, EN2_IDLE           # parado: caveira estatica
    j    RE_EN_DRAW
RE_EN2_FLYANIM:
    lw   t1, EN_anim(s0)        # frame = (EN_anim >> 1) % 6
    srli t1, t1, 1
    li   t2, 6
    remu t1, t1, t2
    la   t2, EN2_FLY_TABLE
    slli t1, t1, 2
    add  t2, t2, t1
    lw   a0, 0(t2)              # a0 = EN2_A<n>
    j    RE_EN_DRAW

RE_EN_RUNNER:
    # ---- CORREDOR (hitbox 32x48; RUN em canvas 64x48) --------------- #
    li   a3, EN_RUNNER_W        # 32 (caso idle; sobrescrito se correndo)
    li   a4, EN_RUNNER_H
    li   t4, 0
    lw   t1, EN_fsm(s0)
    li   t2, ENF_SPOTTED
    beq  t1, t2, RE_EN1_RUNANIM
    la   a0, EN1_IDLE           # parado: sprite estatico 32x48
    j    RE_EN_DRAW
RE_EN1_RUNANIM:
    lw   t1, EN_anim(s0)        # frame = (EN_anim >> 1) % 3
    srli t1, t1, 1
    li   t2, 3
    remu t1, t1, t2
    la   t2, EN1_RUN_TABLE
    slli t1, t1, 2
    add  t2, t2, t1
    lw   a0, 0(t2)              # a0 = EN1_RUN<n> (64x48)
    li   a3, 64
    li   t4, ANIM_OFF_64        # centraliza o canvas de 64 na hitbox de 32

RE_EN_DRAW:
    flw  ft0, PH_x(s0)
    fcvt.w.s a1, ft0            # X de MUNDO da HITBOX (float -> int)
    la   t0, GAME_STATE
    lw   t1, GS_cam_x(t0)
    sub  a1, a1, t1            # X da hitbox na tela
    mv   t6, a1                 # copia p/ o fallback
    sub  a1, a1, t4             # X de DESENHO (aplica o offset do canvas)
    # CULL: sem crop de borda no RENDER_SPRITE, sprite parcialmente fora
    # (X<0 ou X+W>320) faz wrap de linha = lixo nas bordas. Nao desenha.
    bltz a1, RE_EN_FALLBACK    # saiu pela esquerda
    li   t2, 320
    sub  t2, t2, a3            # t2 = 320 - largura do sprite
    bgt  a1, t2, RE_EN_FALLBACK # saiu pela direita
    j    RE_EN_CULL_Y

RE_EN_FALLBACK:
    # Frame largo nao coube: tenta o IDLE do tipo (canvas == hitbox).
    # Se o frame ja era sem offset (t4==0), nao ha fallback: pula.
    beqz t4, RE_EN_NEXT
    la   a0, EN1_IDLE           # so o corredor tem frames largos hoje
    li   a3, EN_RUNNER_W
    mv   a1, t6                 # X da hitbox (offset 0)
    bltz a1, RE_EN_NEXT
    li   t2, 288                # 320 - 32
    bgt  a1, t2, RE_EN_NEXT

RE_EN_CULL_Y:
    flw  ft0, PH_y(s0)
    fcvt.w.s a2, ft0            # Y (alturas do canvas == hitbox sempre)
    bltz a2, RE_EN_NEXT         # CULL Y: fora por cima (evita crash)
    li   t2, 240
    sub  t2, t2, a4             # 240 - altura do sprite
    bgt  a2, t2, RE_EN_NEXT     # fora por baixo
    la   t0, GAME_STATE
    lw   a5, GS_frame(t0)       # frame destino (double buffering)
    li   a6, 0                  # frames sao labels separados: a6 fica 0
    li   a7, 0
    call RENDER_SPRITE

RE_EN_NEXT:
    addi s0, s0, EN_STRIDE
    addi s1, s1, -1
    bnez s1, RE_EN_LOOP

    # ================= 3a passada: ITENS (cura/recarga) ============= #
    la   s0, ITEM_POOL
    li   s1, ITEM_MAX
RE_IT_LOOP:
    lw   t0, IT_active(s0)
    beqz t0, RE_IT_NEXT

    lw   t0, IT_type(s0)
    li   t1, ITEM_TYPE_HEAL
    beq  t0, t1, RE_IT_SPR
    la   a0, ITEM_CHARGE_SPRITE
    j    RE_IT_DRAW
RE_IT_SPR:
    la   a0, ITEM_HEAL_SPRITE
RE_IT_DRAW:
    lw   a1, IT_x(s0)             # X de MUNDO (item e estatico, sem PH_*)
    la   t0, GAME_STATE
    lw   t1, GS_cam_x(t0)
    sub  a1, a1, t1              # X de tela = mundo - cam_x
    bltz a1, RE_IT_NEXT          # CULL: saiu pela esquerda
    li   t2, 304                 # 320 - ITEM_W(16)
    bgt  a1, t2, RE_IT_NEXT      # saiu pela direita
    lw   a2, IT_y(s0)             # Y (sem scroll vertical)
    bltz a2, RE_IT_NEXT
    li   t2, 224                 # 240 - ITEM_H(16)
    bgt  a2, t2, RE_IT_NEXT
    li   a3, ITEM_W
    li   a4, ITEM_H
    lw   a5, GS_frame(t0)
    li   a6, 0
    li   a7, 0
    call RENDER_SPRITE

RE_IT_NEXT:
    addi s0, s0, ITEM_STRIDE
    addi s1, s1, -1
    bnez s1, RE_IT_LOOP

    # ================= 4a passada: PORTA / GATILHO DE VITORIA ======= #
    # Placeholder visual do req 7 (porta) e do req 8 (chefe ainda nao   #
    # implementado -- so um marcador do gatilho de vitoria na arena).   #
    # Estatico (sem pool): 1 por fase, conforme GS_level.               #
    la   t0, GAME_STATE
    lw   t0, GS_level(t0)

    li   t1, LEVEL_W1
    bne  t0, t1, RE_DOOR_CHK_W2
    la   a0, DOOR_SPRITE
    li   a1, DOOR_W1_X
    li   a2, DOOR_W1_Y
    li   a3, DOOR_W
    li   a4, DOOR_H
    j    RE_DOOR_DRAW
RE_DOOR_CHK_W2:
    li   t1, LEVEL_W2
    bne  t0, t1, RE_DOOR_CHK_BOSS
    la   a0, DOOR_SPRITE
    li   a1, DOOR_W2_X
    li   a2, DOOR_W2_Y
    li   a3, DOOR_W
    li   a4, DOOR_H
    j    RE_DOOR_DRAW
RE_DOOR_CHK_BOSS:
    li   t1, LEVEL_BOSS
    bne  t0, t1, RE_END          # fase desconhecida: nada a desenhar
    la   a0, WIN_MARKER_SPRITE
    li   a1, WIN_TRIGGER_X
    li   a2, WIN_TRIGGER_Y
    li   a3, 16                  # WIN_MARKER_SPRITE e 16x16 (so um marcador)
    li   a4, 16

RE_DOOR_DRAW:
    # a1/a2 chegam em coordenadas de MUNDO -> converte p/ tela e cull,
    # mesmo padrao das outras 3 passadas acima.
    la   t0, GAME_STATE
    lw   t1, GS_cam_x(t0)
    sub  a1, a1, t1              # X de tela = mundo - cam_x
    bltz a1, RE_END              # saiu pela esquerda
    li   t2, 320
    sub  t2, t2, a3
    bgt  a1, t2, RE_END          # saiu pela direita
    bltz a2, RE_END              # saiu por cima
    li   t2, 240
    sub  t2, t2, a4
    bgt  a2, t2, RE_END          # saiu por baixo
    lw   a5, GS_frame(t0)
    li   a6, 0
    li   a7, 0
    call RENDER_SPRITE

RE_END:
    lw   ra, 8(sp)
    lw   s0, 4(sp)
    lw   s1, 0(sp)
    addi sp, sp, 12
    ret
