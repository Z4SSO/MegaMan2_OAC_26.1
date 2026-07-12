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

    la   a0, PLAYER_SPRITE       # endereco da sprite (placeholder)
    lw   a1, PLAYER_scr_x(t0)    # X na tela
    lw   a2, PLAYER_scr_y(t0)    # Y na tela
    li   a3, PLAYER_W            # largura (16)
    li   a4, PLAYER_H            # altura (16)

    la   t1, GAME_STATE
    lw   a5, GS_frame(t1)        # frame de destino (0 enquanto DB off)

    lw   a6, PLAYER_status(t0)   # status/frame de animacao
    li   a7, 0                   # print normal (nao cropped)

    call RENDER_SPRITE           # rotina standalone (render_sprite.s)

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
