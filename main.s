# ==================================================================== #
#  main.s  --  Ponto de entrada do MegaMan 2 (OAC 2026/1)              #
#                                                                      #
#  Responsabilidade unica: montar o programa (includes) e inicializar  #
#  o minimo antes de entregar o controle ao SETUP -> GAME_LOOP.        #
#  NAO coloque logica de jogo aqui: ela vive nos subsistemas.          #
# ==================================================================== #

# ---- Dados (.data) ------------------------------------------------- #
.include "data.s"       # tiles, mapas, MAP_INFO/NEXT_MAP (motor base)
.include "state.s"      # GAME_STATE e PLAYER (structs de estado)

# ---- Codigo (.text) ------------------------------------------------ #
.text
main:
    # Inicializacao minima. O estado ja nasce com valores default em
    # state.s; aqui so garantimos a cena inicial e partimos pro setup.
    la   t0, GAME_STATE
    li   t1, SCENE_GAME
    sw   t1, GS_scene(t0)        # comeca direto no jogo (menu vem depois)

    j SETUP                      # SETUP renderiza o mapa e cai no GAME_LOOP

# ---- Modulos ------------------------------------------------------- #
.include "gameloop.s"          # GAME_LOOP (orquestrador) + stubs restantes
.include "input.s"             # INPUT_READ (teclado -> bitmask)
.include "player.s"            # PLAYER_UPDATE (movimento, pulo, gravidade)
.include "render_map_frame.s"  # RENDER_MAP_FRAME (redesenho do mapa por frame)
.include "render_player.s"     # RENDER_PLAYER (desenha o personagem)
.include "render_sprite.s"     # RENDER_SPRITE (desenho de sprite individual)
.include "musicFunct.s"        # MUSIC_LOOP / PLAY_MUSIC (musica multi-canal)
.include "setup.s"             # SETUP (render inicial do mapa)
.include "render.s"            # RENDER_WORD / RENDER_COLOR / RENDER_MAP
