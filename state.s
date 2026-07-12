# ==================================================================== #
#  state.s  --  Estado global do jogo (structs em memoria)             #
#  Incluido dentro da secao .data (via .include no main.s).            #
#                                                                      #
#  Filosofia: o estado do jogo vive AQUI, nao em registradores s*.     #
#  Cada subsistema le/escreve estes campos por offset nomeado (.eqv).  #
#  NUNCA use numeros magicos de offset no codigo -- use os .eqv.       #
# ==================================================================== #

.data

# -------------------- Endereco de hardware do bitmap ---------------- #
# Registrador que seleciona qual frame (0/1) o bitmap display mostra.
# Definido aqui para NAO depender do MACROSv24.s (que traz codigo de
# setup de excecao no inicio do .text e nao e necessario neste projeto).
.eqv BITMAP_FRAME_SELECT  0xFF200604

# -------------------- Enderecos do teclado (KDMMIO) ----------------- #
# Mesmo esquema: definidos localmente para nao depender do MACROSv24.s.
#   KDMMIO_CTRL: bit 0 = 1 quando ha tecla disponivel para ler.
#   KDMMIO_DATA: valor ASCII da tecla (ler consome o caractere).
.eqv KDMMIO_CTRL  0xFF200000
.eqv KDMMIO_DATA  0xFF200004

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

# -------------------- Constantes de fisica -------------------------- #
# Valores inteiros em pixels/frame. Ajuste fino depois de ver na tela.
.eqv PLAYER_SPEED     2    # velocidade horizontal (px por frame)
.eqv PLAYER_JUMP_VY  -8    # impulso inicial do pulo (negativo = pra cima)
.eqv GRAVITY          1    # aceleracao da gravidade (px/frame por frame)
.eqv MAX_FALL_VY      10   # velocidade terminal de queda (limita vy)

# Chao provisorio (Y em pixels na tela) enquanto COLLISION_UPDATE nao
# existe. So evita queda infinita para dar pra ver o pulo funcionando.
# Quando a colisao com tiles estiver pronta, REMOVA este uso em player.s.
.eqv TEMP_GROUND_Y   160  # Y do "chao" de teste (bordo inferior do player)

# ==================================================================== #
#  GAME_STATE  --  estado geral, uma instancia                         #
# ==================================================================== #
.eqv GS_scene       0   # word: cena atual (SCENE_*)
.eqv GS_frame       4   # word: frame do bitmap (0 ou 1), alterna todo loop
.eqv GS_frame_time  8   # word: tempo (ms) do inicio do frame anterior
.eqv GS_input_bits  12  # word: bitmask das teclas pressionadas neste frame
.eqv GS_input_prev  16  # word: bitmask do frame anterior (p/ detectar "acabou de apertar")
.eqv GS_tick        20  # word: contador de frames desde o boot (p/ animacoes/timers)

GAME_STATE:
    .word SCENE_GAME    # GS_scene
    .word 0             # GS_frame
    .word 0             # GS_frame_time
    .word 0             # GS_input_bits
    .word 0             # GS_input_prev
    .word 0             # GS_tick

# ==================================================================== #
#  PLAYER  --  estado do Mega Man, uma instancia                       #
#  Posicao guardada em coordenadas de MATRIZ (tile) + offset em pixel, #
#  no mesmo esquema que MAP_INFO ja usa no data.s original.            #
# ==================================================================== #
.eqv PLAYER_mat_x     0   # word: X na matriz do mapa (em tiles)
.eqv PLAYER_mat_y     4   # word: Y na matriz do mapa (em tiles)
.eqv PLAYER_off_x     8   # word: offset X em pixels dentro do tile (0..15)
.eqv PLAYER_off_y     12  # word: offset Y em pixels dentro do tile (0..15)
.eqv PLAYER_scr_x     16  # word: X na TELA em pixels (onde desenhar)
.eqv PLAYER_scr_y     20  # word: Y na TELA em pixels (onde desenhar)
.eqv PLAYER_dir       24  # word: DIR_RIGHT / DIR_LEFT
.eqv PLAYER_status    28  # word: indice de sprite/animacao (frame da anim)
.eqv PLAYER_on_ground 32  # word: 1 se pisando em tile solido, 0 se no ar
.eqv PLAYER_health    36  # word: pontos de vida atuais
.eqv PLAYER_max_hp    40  # word: vida maxima
.eqv PLAYER_ability   44  # word: habilidade/arma ativa (0 = Buster, 1.. = outras)
.eqv PLAYER_vy        48  # word: velocidade vertical em ponto fixo (ver nota)
.eqv PLAYER_invuln    52  # word: frames restantes de invulnerabilidade (i-frames)

# NOTA sobre vy: comecar em INTEIRO (px/frame) para simplicidade. Se a fisica
# precisar de precisao (pulo suave), migrar para float (fs*) como o Metroid fez
# na fisica da Samus/Ridley -- mas so quando o pulo inteiro nao bastar.

PLAYER:
    .word 5             # PLAYER_mat_x   (posicao inicial de exemplo)
    .word 10            # PLAYER_mat_y
    .word 0             # PLAYER_off_x
    .word 0             # PLAYER_off_y
    .word 80            # PLAYER_scr_x   (px na tela)
    .word 160           # PLAYER_scr_y
    .word DIR_RIGHT     # PLAYER_dir
    .word 0             # PLAYER_status
    .word 0             # PLAYER_on_ground
    .word 28            # PLAYER_health
    .word 28            # PLAYER_max_hp
    .word 0             # PLAYER_ability (0 = Mega Buster)
    .word 0             # PLAYER_vy
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
