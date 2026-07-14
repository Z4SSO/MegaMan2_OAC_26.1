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
    # ---- Clamp superior: cam_x <= CAM_MAX_X (borda direita) --------- #
    li   t2, CAM_MAX_X
    ble  t1, t2, CAM_STORE
    mv   t1, t2                # travou na borda direita

CAM_STORE:
    la   t0, GAME_STATE
    sw   t1, GS_cam_x(t0)      # publica a posicao da camera
    ret
