# ==================================================================== #
#  camera.s  --  Camera / scroll horizontal (CAMERA_UPDATE)            #
#                                                                      #
#  Calcula GS_cam_x (posicao X da camera em pixels de mundo) de modo   #
#  que o player fique CENTRALIZADO na tela, TRAVANDO nas bordas do     #
#  mapa para nunca mostrar area fora dos limites (out of bounds).      #
#                                                                      #
#  Formula:                                                            #
#    cam_x = player_x - CAM_MARGIN                                     #
#      (CAM_MARGIN = SCREEN_W/2 - PLAYER_W/2 -> player no centro)      #
#    depois clamp: 0 <= cam_x <= CAM_MAX_X                             #
#      (CAM_MAX_X = largura_mapa_px - largura_tela = 2080)             #
#                                                                      #
#  Quem usa GS_cam_x:                                                  #
#    - RENDER_MAP_FRAME: converte em coluna inicial (cam_x/16) +       #
#      offset sub-tile (cam_x%16) e passa ao RENDER_MAP.               #
#    - RENDER_PLAYER / RENDER_ENTITIES: desenham em (mundo_x - cam_x). #
#                                                                      #
#  Chamado 1x por frame pelo GAME_LOOP, ANTES dos renders.            #
#  So mexe em X (scroll horizontal, requisito 9). Y fica fixo.         #
# -------------------------------------------------------------------- #
#  Nao chama ninguem -> nao precisa de pilha. Usa t0..t3, ft0.        #
# ==================================================================== #

.text

CAMERA_UPDATE:
    la   t0, PLAYER
    flw  ft0, PH_x(t0)
    fcvt.w.s t1, ft0           # t1 = player_x (int, pixels de mundo)

    # cam_x = player_x - CAM_MARGIN  (centraliza o player)
    li   t2, CAM_MARGIN
    sub  t1, t1, t2            # t1 = cam_x bruto

    # ---- Clamp inferior: cam_x >= 0 (nao mostra antes da borda esq) - #
    bgez t1, CAM_CHK_MAX
    li   t1, 0                 # travou na borda esquerda
    j    CAM_STORE
CAM_CHK_MAX:
    # ---- Clamp superior: cam_x <= cam_max (borda direita) ----------- #
    # cam_max = largura_do_MAPA_ATUAL_em_px - largura_da_tela. Calculado
    # na hora (em vez do antigo CAM_MAX_X fixo, valido so p/ Map_W1)
    # porque agora trocamos de mapa em tempo real (level.s): Map_W2 e
    # Map_BOSS tem larguras diferentes. Map_BOSS (20 tiles = tela
    # inteira) da cam_max <= 0 -> clamp em 0 (camera fixa, de proposito:
    # decisao 13 do handoff, arena do boss sem scroll).
    la   t2, CURRENT_MAP
    lw   t2, 0(t2)
    lbu  t2, 1(t2)             # largura do mapa atual (tiles)
    slli t2, t2, 4             # largura em pixels (tiles * 16)
    li   t4, SCREEN_W_PX
    sub  t2, t2, t4            # t2 = cam_max bruto
    bgtz t2, CAM_HAVE_MAX
    li   t2, 0                 # mapa mais estreito que a tela: camera fixa em 0
CAM_HAVE_MAX:
    ble  t1, t2, CAM_STORE
    mv   t1, t2                # travou na borda direita

CAM_STORE:
    # Quantiza p/ PAR: crop com largura impar quebra o RENDER_COLOR em
    # modo half (sh = 2px/vez estoura 1px/linha e deriva na diagonal --
    # o "lixo em escadinha" nas bordas). Com cam_x par, todo offset de
    # crop (cam_x % 16) e par e as larguras fecham certinho.
    andi t1, t1, -2            # limpa o bit 0 (arredonda p/ baixo, par)
    la   t0, GAME_STATE
    sw   t1, GS_cam_x(t0)      # publica a posicao da camera
    ret
