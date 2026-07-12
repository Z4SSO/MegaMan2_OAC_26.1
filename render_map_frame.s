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

    lbu  a1, 6(t0)           # X inicial na matriz (top-left)
    lbu  a2, 7(t0)           # Y inicial na matriz (top-left)
    lbu  a3, 8(t0)           # offset X no mapa
    lbu  a4, 9(t0)           # offset Y no mapa

    # Frame de destino: le GS_frame (0 enquanto double buffering off).
    la   t1, GAME_STATE
    lw   a5, GS_frame(t1)    # a5 = frame onde desenhar

    li   a6, m_screen_width  # largura da tela em tiles (20)
    li   a7, m_screen_height # altura da tela em tiles (15)
    li   t3, 0               # X inicial de render (matriz)
    li   t2, 0               # Y inicial de render (matriz)
    li   tp, 0               # mapa nao deslocado (scroll = 0 por ora)

    call RENDER_MAP

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
