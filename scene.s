# ==================================================================== #
#  scene.s  --  Tela inicial mock (SCENE_MENU) + tela preta reutilizavel#
#                                                                      #
#  MENU_UPDATE: le o evento cru do KDMMIO (igual ao input.s, mas SEM   #
#  passar pelo mapeamento de teclas -- qualquer tecla vale) e, ao      #
#  detectar uma, chama LEVEL_ENTER_W1 (level.s) pra comecar o jogo de  #
#  verdade. So roda durante SCENE_MENU (o GAME_LOOP so chama este      #
#  subsistema nesse estado).                                          #
#                                                                      #
#  RENDER_BLACKSCREEN: preenche o framebuffer do frame atual com preto #
#  (cor 0). Reutilizada pelas 3 telas sem jogo rodando (MENU,          #
#  SCENE_TRANSITION -- a "porta" do MegaMan -- e SCENE_WIN). Usa sw    #
#  (4 pixels por vez) em vez de sb byte a byte: e a tela inteira       #
#  (320x240 = 76800 bytes), sb custaria 4x mais ecalls/iteracoes.      #
# -------------------------------------------------------------------- #
#  Nenhuma das duas chama outra rotina -> nenhuma precisa de pilha.    #
# ==================================================================== #

.text

# ==================================================================== #
#  MENU_UPDATE                                                         #
# ==================================================================== #
MENU_UPDATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    li   t0, KDMMIO_Ctrl
    lw   t1, 0(t0)
    andi t1, t1, 1
    beqz t1, MU_END             # nenhum evento de tecla neste frame

    li   t0, KDMMIO_Data
    lw   t1, 0(t0)              # consome o dado (limpa o evento no KDMMIO);
                                 # o valor da tecla e ignorado de proposito --
                                 # QUALQUER tecla comeca o jogo (pedido do usuario).
    call LEVEL_ENTER_W1

MU_END:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# ==================================================================== #
#  RENDER_BLACKSCREEN                                                   #
#  Preenche 320x240 px (1 byte/pixel) com 0 no frame atual (GS_frame),  #
#  em passos de 4 bytes (sw) -> 19200 iteracoes em vez de 76800.        #
# ==================================================================== #
RENDER_BLACKSCREEN:
    la   t0, GAME_STATE
    lw   t1, GS_frame(t0)
    slli t1, t1, 20
    li   t0, VGAADDRESSINI0      # 0xFF000000 (MACROSv24.s)
    add  t0, t0, t1              # t0 = base do frame atual

    li   t1, 19200                # (320*240)/4 words
    mv   t2, zero
RBS_LOOP:
    sw   zero, 0(t0)
    addi t0, t0, 4
    addi t2, t2, 1
    blt  t2, t1, RBS_LOOP

    ret
