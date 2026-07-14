# ==================================================================== #
#  render_map_frame.s  --  Redesenho do mapa por frame                 #
#                          (subsistema RENDER_MAP_FRAME)               #
#                                                                      #
#  Chamado uma vez por frame pelo GAME_LOOP, ANTES de desenhar player  #
#  e entidades. Redesenha o mapa inteiro no frame corrente, o que      #
#  apaga o rastro deixado pelas sprites moveis no frame anterior.      #
#                                                                      #
#  RENDER_MAP (render.s) e de baixo nivel e exige os argumentos ja     #
#  montados. Esta rotina monta esses argumentos a partir do estado do  #
#  mapa atual (CURRENT_MAP), replicando o bloco MAP1_SETUP de setup.s. #
#                                                                      #
#  NOTA DE REFACTOR: este bloco e quase identico ao MAP1_SETUP em      #
#  setup.s. Um proximo passo de limpeza seria o SETUP tambem chamar    #
#  esta rotina, eliminando a duplicacao. Mantido separado por ora para #
#  nao arriscar regressao no setup que ja funciona.                    #
# -------------------------------------------------------------------- #
#  Convencao: chama RENDER_MAP -> precisa salvar ra. Usa a0..a7 como   #
#  argumentos e t2/t3/tp como o RENDER_MAP espera.                     #
# ==================================================================== #

.text

RENDER_MAP_FRAME:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, CURRENT_MAP     # base do mapa atual
    lw   a0, 0(t0)           # a0 = endereco do mapa (setado pelo SETUP)

    # ---- Scroll: converte GS_cam_x (pixels) em coluna + offset ------ #
    # coluna inicial na matriz = cam_x / 16 ; offset sub-tile = cam_x%16
    la   t1, GAME_STATE
    lw   t0, GS_cam_x(t1)    # t0 = cam_x (pixels de mundo)
    srli a1, t0, 4           # a1 = coluna inicial na matriz (cam_x / 16)
    andi a3, t0, 15          # a3 = offset X sub-tile (cam_x % 16) -> scroll fino
    li   a2, 0               # Y inicial na matriz (sem scroll vertical)
    li   a4, 0               # offset Y sub-tile (0)

    # Frame de destino: le GS_frame (0 enquanto double buffering off).
    lw   a5, GS_frame(t1)    # a5 = frame onde desenhar

    li   a6, m_screen_width  # largura da tela em tiles (20)
    li   a7, m_screen_height # altura da tela em tiles (15)
    li   t3, 0               # X inicial de render (tela, matriz)
    li   t2, 0               # Y inicial de render (tela, matriz)
    li   tp, 0               # tp fica 0: o deslocamento fino vai em a3

    call RENDER_MAP

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
