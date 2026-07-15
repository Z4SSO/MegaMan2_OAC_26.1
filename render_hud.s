# ==================================================================== #
#  render_hud.s -- HUD de vida (RENDER_HUD)   [Requisito 5, parcial]   #
#                                                                      #
#  Barra de vida no canto superior esquerdo, desenhada DIRETO no       #
#  framebuffer (sb, 1 byte/pixel -- sem risco de alinhamento nem de    #
#  cor transparente 199). Escala: 4 px de largura por ponto de vida.   #
#    - trilho escuro   : PLAYER_max_hp * 4 px (o que falta)            #
#    - preenchimento   : PLAYER_health * 4 px (vermelho)               #
#  6 px de altura, origem em (8, 8) na tela.                           #
#                                                                      #
#  Desenhado por ultimo no frame (depois do player), entao fica por    #
#  cima de tudo. Enquanto o player toma dano, a barra encolhe -- e o   #
#  feedback visual dos i-frames/dano que faltava.                      #
# -------------------------------------------------------------------- #
#  Leaf (nao chama ninguem): sem pilha. Usa t0..t5, a3..a5.            #
# ==================================================================== #

.text

RENDER_HUD:
    # base do frame atual: 0xFF000000 + (GS_frame << 20)
    la   t0, GAME_STATE
    lw   t1, GS_frame(t0)
    slli t1, t1, 20
    li   t0, 0xFF000000
    add  t0, t0, t1
    li   t1, 2568              # offset de (8,8): 8 + 8*320
    add  t0, t0, t1            # t0 = endereco do 1o pixel da barra

    la   t2, PLAYER
    lw   t3, PLAYER_health(t2)
    bgez t3, HUD_CLAMP_OK
    li   t3, 0                 # clamp: vida negativa desenha barra vazia
HUD_CLAMP_OK:
    slli t3, t3, 2             # t3 = pixels preenchidos (vida * 4)
    lw   t4, PLAYER_max_hp(t2)
    slli t4, t4, 2             # t4 = largura total (max_hp * 4)

    li   t5, 6                 # t5 = linhas restantes (altura da barra)
HUD_ROW:
    mv   a3, zero              # a3 = coluna atual
HUD_COL:
    li   a4, 224               # cor cheia: vermelho (RRRGGGBB = 11100000)
    blt  a3, t3, HUD_PUT       # dentro da parte preenchida?
    li   a4, 32                # cor do trilho vazio (escuro)
HUD_PUT:
    add  a5, t0, a3
    sb   a4, 0(a5)
    addi a3, a3, 1
    blt  a3, t4, HUD_COL
    addi t0, t0, 320           # proxima linha do framebuffer
    addi t5, t5, -1
    bnez t5, HUD_ROW
    ret
