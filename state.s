# ==================================================================== #
#  state.s  --  Estado global do jogo (structs em memoria)             #
#  Incluido dentro da secao .data (via .include no main.s).            #
#                                                                      #
#  Filosofia: o estado do jogo vive AQUI, nao em registradores s*.     #
#  Cada subsistema le/escreve estes campos por offset nomeado (.eqv).  #
#  NUNCA use numeros magicos de offset no codigo -- use os .eqv.       #
# ==================================================================== #

.data

# -------------------- Enderecos de hardware ------------------------- #
# Os enderecos de MMIO (bitmap frame select, teclado) vem do MACROSv24.s
# (VGAFRAMESELECT, KDMMIO_Ctrl/Data, Buffer0Teclado). Nao redefinimos
# aqui para evitar duplicacao.

# Double buffering: o bitmap tem 2 frames (0 e 1). So compensa alternar
# entre eles quando TODO o conteudo e redesenhado a cada frame no frame
# invisivel antes da troca. Enquanto o redesenho completo por frame nao
# existir (RENDER_MAP_FRAME e renders de entidade ainda sao stubs), o
# loop mantem GS_frame fixo em 0 para evitar flicker. Ver comentario no
# passo 2 do GAME_LOOP para reativar.

# -------------------- Constantes de cena ---------------------------- #
.eqv SCENE_MENU      0
.eqv SCENE_GAME      1
.eqv SCENE_GAMEOVER  2
.eqv SCENE_WIN       3

# -------------------- Bits de input (KDMMIO) ------------------------ #
# Mascaras de bit em GAME_STATE.input_bits. Uma tecla por bit.
# Ajuste os codigos de tecla no INPUT_READ conforme o teclado do FPGA.
.eqv INPUT_LEFT   0x01
.eqv INPUT_RIGHT  0x02
.eqv INPUT_JUMP   0x04
.eqv INPUT_SHOOT  0x08
.eqv INPUT_SWAP   0x10   # troca de habilidade/arma
.eqv INPUT_DOWN   0x20
.eqv INPUT_UP     0x40

# -------------------- Direcao do player ----------------------------- #
.eqv DIR_RIGHT  0
.eqv DIR_LEFT   1

# -------------------- Constantes de fisica (float) ------------------ #
# Valores em pixels/frame. Carregados com flw pelo player.s.
# Ajuste fino depois de ver na tela; a etapa 2 (pulo player-friendly)
# so mexe nestes numeros e na logica do player.s -- a engine nao muda.
PHYS_ACCEL:    .float 0.5    # aceleracao horizontal ao andar (px/frame^2)
PHYS_GRAVITY:  .float 0.6    # aceleracao da gravidade (ay quando no ar)
PHYS_JUMP_VY:  .float -9.0   # velocidade vertical inicial do pulo (pra cima)
PHYS_FRICTION: .float 0.5    # desaceleracao horizontal quando sem input
PHYS_ZERO:     .float 0.0

# Chao provisorio (Y em pixels) enquanto COLLISION_UPDATE nao existe.
# So evita queda infinita. REMOVER quando a colisao com tiles existir.
PHYS_GROUND_Y: .float 160.0

# ==================================================================== #
#  GAME_STATE  --  estado geral, uma instancia                         #
# ==================================================================== #
.eqv GS_scene       0   # word: cena atual (SCENE_*)
.eqv GS_frame       4   # word: frame do bitmap (0 ou 1), alterna todo loop
.eqv GS_frame_time  8   # word: tempo (ms) do inicio do frame anterior
.eqv GS_input_bits  12  # word: ESTADO das teclas (bit ligado = pressionada)
.eqv GS_input_prev  16  # word: input_bits do frame anterior (borda de subida)
.eqv GS_tick        20  # word: contador de frames desde o boot
.eqv GS_kbd_prev    24  # word: buffer anterior (usado pela versao SCANCODE/DE2)
.eqv GS_held_bits   28  # word: teclas de movimento seguradas (versao KDMMIO/PC)
.eqv GS_held_timer  32  # word: frames restantes do auto-hold (versao KDMMIO/PC)

GAME_STATE:
    .word SCENE_GAME    # GS_scene
    .word 0             # GS_frame
    .word 0             # GS_frame_time
    .word 0             # GS_input_bits
    .word 0             # GS_input_prev
    .word 0             # GS_tick
    .word 0             # GS_kbd_prev
    .word 0             # GS_held_bits
    .word 0             # GS_held_timer

# ==================================================================== #
#  COMPONENTE DE FISICA (layout compartilhado por TODAS as entidades)  #
#                                                                      #
#  A engine PHYSICS_STEP opera sobre estes offsets, recebendo o        #
#  ponteiro de uma entidade. Player, inimigos e projeteis DEVEM comecar#
#  seu struct com este bloco nestes mesmos offsets, para que a mesma   #
#  engine sirva a todos (padrao component/system).                     #
#                                                                      #
#  Tudo em float IEEE-754 (RV32F). A posicao float e a FONTE DE VERDADE;#
#  o pixel de render e projetado dela por fcvt.w.s a cada frame, nunca #
#  mantido em paralelo -> sem realimentar erro de arredondamento.      #
#                                                                      #
#    [0]  x   : posicao X (float, em pixels)                           #
#    [4]  y   : posicao Y (float, em pixels)                           #
#    [8]  vx  : velocidade X (float, px/frame)                         #
#    [12] vy  : velocidade Y (float, px/frame)                         #
#    [16] ax  : aceleracao X (float, px/frame^2)                       #
#    [20] ay  : aceleracao Y (float, px/frame^2)  <- gravidade vai aqui#
#    [24] vx_max : |velocidade X| maxima (float, clamp simetrico)      #
#    [28] vy_max : |velocidade Y| maxima (float, clamp simetrico)      #
# ==================================================================== #
.eqv PH_x       0
.eqv PH_y       4
.eqv PH_vx      8
.eqv PH_vy      12
.eqv PH_ax      16
.eqv PH_ay      20
.eqv PH_vx_max  24
.eqv PH_vy_max  28
.eqv PH_SIZE    32   # tamanho do bloco de fisica (bytes)

# -------------------- Struct PLAYER --------------------------------- #
# Comeca com o bloco de fisica (offsets PH_*), depois campos proprios  #
# do jogador (offsets a partir de PH_SIZE).                            #
.eqv PLAYER_dir       32  # word: DIR_RIGHT / DIR_LEFT
.eqv PLAYER_status    36  # word: indice de sprite/animacao (frame)
.eqv PLAYER_on_ground 40  # word: 1 se pisando em tile solido, 0 se no ar
.eqv PLAYER_health    44  # word: pontos de vida atuais
.eqv PLAYER_max_hp    48  # word: vida maxima
.eqv PLAYER_ability   52  # word: habilidade/arma ativa (0 = Buster)
.eqv PLAYER_invuln    56  # word: frames restantes de i-frames

PLAYER:
    # --- bloco de fisica (float) --- #
    .float 80.0         # PH_x   (posicao inicial X, pixels)
    .float 160.0        # PH_y   (posicao inicial Y, pixels)
    .float 0.0          # PH_vx
    .float 0.0          # PH_vy
    .float 0.0          # PH_ax
    .float 0.0          # PH_ay   (o player.s escreve gravidade aqui)
    .float 3.0          # PH_vx_max (px/frame horizontal)
    .float 12.0         # PH_vy_max (px/frame vertical, cobre queda rapida)
    # --- campos do jogador --- #
    .word DIR_RIGHT     # PLAYER_dir
    .word 0             # PLAYER_status
    .word 0             # PLAYER_on_ground
    .word 28            # PLAYER_health
    .word 28            # PLAYER_max_hp
    .word 0             # PLAYER_ability
    .word 0             # PLAYER_invuln

# ==================================================================== #
#  PLAYER_SPRITE  --  PLACEHOLDER 16x16 (256 bytes)                    #
#  Bloco de cor solida so para validar o RENDER_PLAYER e o movimento   #
#  antes de o sprite real do personagem (feito pelo colega) chegar.    #
#  Formato: 1 byte por pixel (indice de cor da paleta OAC), 16x16.     #
#  Cor 40 = tom vivo que contrasta com o mapa. SUBSTITUIR pelo sprite  #
#  real: basta trocar este bloco por .byte's do personagem (mesmo      #
#  tamanho) ou apontar PLAYER_SPRITE para o novo .data.                #
# ==================================================================== #
.eqv PLAYER_W  16
.eqv PLAYER_H  16
PLAYER_SPRITE:
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40
