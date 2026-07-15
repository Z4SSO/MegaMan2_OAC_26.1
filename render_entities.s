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
    la   s0, ENEMY_POOL
    li   s1, EN_MAX
RE_EN_LOOP:
    lw   t0, EN_active(s0)
    beqz t0, RE_EN_NEXT

    # escolhe o sprite E as dimensoes pelo tipo (voador e corredor tem
    # tamanhos diferentes: EN2=32x32, EN1=32x48).
    lw   t0, EN_type(s0)
    li   t1, ENT_FLYER
    bne  t0, t1, RE_EN_RUNNER
    la   a0, EN2_IDLE          # voador (caveira) 32x32
    li   a3, EN_FLYER_W
    li   a4, EN_FLYER_H
    j    RE_EN_DRAW
RE_EN_RUNNER:
    la   a0, EN1_IDLE          # corredor (camera) 32x48
    li   a3, EN_RUNNER_W
    li   a4, EN_RUNNER_H
RE_EN_DRAW:
    flw  ft0, PH_x(s0)
    fcvt.w.s a1, ft0            # X de MUNDO (float -> int)
    la   t0, GAME_STATE
    lw   t1, GS_cam_x(t0)
    sub  a1, a1, t1            # X de tela = mundo - cam_x
    # CULL: sem crop de borda no RENDER_SPRITE, sprite parcialmente fora
    # (X<0 ou X+W>320) faz wrap de linha = lixo nas bordas. Nao desenha.
    bltz a1, RE_EN_NEXT        # saiu pela esquerda
    li   t2, 320
    sub  t2, t2, a3            # t2 = 320 - largura do sprite
    bgt  a1, t2, RE_EN_NEXT    # saiu pela direita
    flw  ft0, PH_y(s0)
    fcvt.w.s a2, ft0            # Y (sem scroll vertical)
    bltz a2, RE_EN_NEXT         # CULL Y: fora por cima (evita crash)
    li   t2, 240
    sub  t2, t2, a4             # 240 - altura do sprite
    bgt  a2, t2, RE_EN_NEXT     # fora por baixo
    lw   a5, GS_frame(t0)       # frame destino (double buffering)
    li   a6, 0
    li   a7, 0
    call RENDER_SPRITE

RE_EN_NEXT:
    addi s0, s0, EN_STRIDE
    addi s1, s1, -1
    bnez s1, RE_EN_LOOP

RE_END:
    lw   ra, 8(sp)
    lw   s0, 4(sp)
    lw   s1, 0(sp)
    addi sp, sp, 12
    ret
