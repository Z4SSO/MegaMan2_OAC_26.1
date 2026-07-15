# ==================================================================== #
#  render_player.s  --  Desenho do jogador (subsistema RENDER_PLAYER)  #
#                                                                      #
#  Chamado uma vez por frame, DEPOIS de RENDER_MAP_FRAME e das         #
#  entidades, para o player ficar por cima. Desenha a sprite do        #
#  personagem em (PLAYER_scr_x, PLAYER_scr_y) chamando RENDER_WORD.    #
#                                                                      #
#  RENDER_SPRITE (render_sprite.s) espera:                             #
#    a0 = endereco da sprite   a1 = X (tela)   a2 = Y (tela)           #
#    a3 = largura   a4 = altura   a5 = frame                           #
#    a6 = status (indice de animacao)   a7 = 0 (print normal)          #
#                                                                      #
#  Animacao: PLAYER_status vai em a6. O RENDER_WORD desloca o endereco #
#  da sprite por (status * altura), entao empilhar frames de animacao  #
#  verticalmente no .data e variar PLAYER_status anima o personagem    #
#  (tecnica do projeto Metroid). Com o placeholder de 1 frame, status  #
#  fica 0.                                                             #
#                                                                      #
#  Espelhamento por direcao (PLAYER_dir): o RENDER_WORD atual nao tem  #
#  flag de flip horizontal. Quando o sprite real chegar, a forma       #
#  idiomatica aqui e ter frames "virado p/ esquerda" e "p/ direita" no #
#  .data e escolher o offset de status conforme PLAYER_dir. Por ora,   #
#  dir e lido mas nao altera o desenho (placeholder e simetrico).      #
# -------------------------------------------------------------------- #
#  Convencao: chama RENDER_WORD -> salva ra. Usa a0..a7.               #
# ==================================================================== #

.text

RENDER_PLAYER:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, PLAYER

    la   a0, PLAYER_IDLE         # sprite real do personagem (32x48, arte do grupo)

    # Posicao de render: projetada da posicao float (fonte de verdade)
    # por fcvt.w.s, recalculada a cada frame -> nunca realimenta erro.
    flw   ft0, PH_x(t0)
    fcvt.w.s a1, ft0             # a1 = (int) x de MUNDO
    # converte mundo->tela: X_tela = X_mundo - cam_x
    la    t2, GAME_STATE
    lw    t3, GS_cam_x(t2)
    sub   a1, a1, t3            # a1 = X na tela (player fica centralizado)
    # CULL de seguranca: se o player sair da janela (ex.: andar alem da
    # borda do mapa com a camera travada), nao desenha -- RENDER_SPRITE
    # sem crop faria wrap de linha (lixo). Clamp do X de mundo do player
    # e a solucao definitiva (pendente).
    bltz  a1, RP_SKIP
    li    t3, 288               # 320 - PLAYER_W(32)
    bgt   a1, t3, RP_SKIP
    flw   ft1, PH_y(t0)
    fcvt.w.s a2, ft1            # a2 = (int) y (sem scroll vertical)
    # CULL vertical: pulo perto do topo poe Y negativo -> endereco antes
    # do framebuffer -> CRASH. Mesma regra do X: fora inteiro, nao desenha.
    bltz  a2, RP_SKIP           # saiu por cima
    li    t3, 192               # 240 - PLAYER_H(48)
    bgt   a2, t3, RP_SKIP       # saiu por baixo

    li   a3, PLAYER_W            # largura real (32)
    li   a4, PLAYER_H            # altura real (48)

    la   t1, GAME_STATE
    lw   a5, GS_frame(t1)        # frame de destino

    lw   a6, PLAYER_status(t0)   # status/frame de animacao
    li   a7, 0                   # print normal (nao cropped)

    call RENDER_SPRITE           # rotina standalone (render_sprite.s)

RP_SKIP:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
