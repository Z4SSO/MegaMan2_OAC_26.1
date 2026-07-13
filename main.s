# ==================================================================== #
#  main.s  --  Ponto de entrada do MegaMan 2 (OAC 2026/1)              #
#                                                                      #
#  Responsabilidade unica: montar o programa (includes) e inicializar  #
#  o minimo antes de entregar o controle ao SETUP -> GAME_LOOP.        #
#  NAO coloque logica de jogo aqui: ela vive nos subsistemas.          #
#                                                                      #
#  ORDEM DE INCLUDE (critica!):                                        #
#   1. MACROSv24.s PRIMEIRO de tudo. Ele coloca no .text um codigo de   #
#      setup (configura utvec/ExceptionHandling e liga interrupcoes)   #
#      que DEVE ser a primeira instrucao executada e cair direto no    #
#      'main'. Incluir qualquer coisa com .text antes dele desalinha   #
#      o boot (foi a causa da 'tela azul' no inicio do projeto).       #
#   2. Dados (.data) e o label main logo apos -> o setup cai no main.  #
#   3. SYSTEMv24.s entra junto dos modulos de codigo, DEPOIS do main    #
#      (nunca antes), como o projeto Metroid faz.                      #
#  Nada nos arquivos MACROS/SYSTEM esta errado; o problema anterior era #
#  so ordem de include.                                                #
# ==================================================================== #

# ---- 1. Macros PRIMEIRO (setup de excecao vira a 1a instrucao) ----- #
.include "MACROSv24.s"  # bitmap, KDMMIO, VGAFRAMESELECT, setup utvec

# ---- 2. Dados (.data) ---------------------------------------------- #
.include "data.s"       # tiles, mapas, MAP_INFO/NEXT_MAP (motor base)
.include "state.s"      # GAME_STATE e PLAYER (structs de estado)

# ---- Codigo (.text): o setup do MACROS cai aqui, no main ----------- #
.text
main:
    # Inicializacao minima. O estado ja nasce com valores default em
    # state.s; aqui so garantimos a cena inicial e partimos pro setup.
    la   t0, GAME_STATE
    li   t1, SCENE_GAME
    sw   t1, GS_scene(t0)        # comeca direto no jogo (menu vem depois)

    j SETUP                      # SETUP renderiza o mapa e cai no GAME_LOOP

# ---- Modulos de codigo --------------------------------------------- #
.include "gameloop.s"          # GAME_LOOP (orquestrador) + stubs restantes
# ---- Teclado: escolha UM dos dois (nunca os dois juntos) ----------- #
#   input.s          -> KDMMIO (ASCII). Funciona no RARS, FPGRARS (PC)
#                       e DE2. PADRAO para desenvolver e apresentar.
#   input_scancode.s -> Buffer0Teclado (scancode PS/2). Estado real por
#                       tecla (sem o bug do 'd' apos pulo), MAS so
#                       funciona na DE2 FISICA. Trava no PC.
#   Para rodar na DE2 com o teclado melhor, comente a linha de input.s
#   e descomente a de input_scancode.s.
.include "input.s"             # INPUT_READ (KDMMIO, padrao)
# .include "input_scancode.s"  # INPUT_READ (scancode PS/2, so DE2)
.include "physics.s"           # PHYSICS_STEP (engine de fisica float)
.include "player.s"            # PLAYER_UPDATE (intencao + chama engine)
.include "render_map_frame.s"  # RENDER_MAP_FRAME (redesenho do mapa por frame)
.include "render_player.s"     # RENDER_PLAYER (desenha o personagem)
.include "render_sprite.s"     # RENDER_SPRITE (desenho de sprite individual)
.include "musicFunct.s"        # MUSIC_LOOP / PLAY_MUSIC (musica multi-canal)
.include "setup.s"             # SETUP (render inicial do mapa)
.include "render.s"            # RENDER_WORD / RENDER_COLOR / RENDER_MAP

# ---- SYSTEMv24 por ultimo (ecalls custom, tabelas, teclado PS/2) --- #
# Depois do main, nunca antes. Traz ExceptionHandling, scancode->ascii,
# Buffer0Teclado, print de fonte no bitmap, etc.
.include "SYSTEMv24.s"
