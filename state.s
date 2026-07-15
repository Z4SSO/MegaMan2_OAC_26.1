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

# ---- Ids de musica (indices no MUSIC_TABLE de music_data.s) -------- #
# A ORDEM aqui deve casar com a ordem das entradas no MUSIC_TABLE.
.eqv MUS_INICIO      0   # menu / tela inicial
.eqv MUS_ESTAGIO1    1   # 1o estagio jogavel
.eqv MUS_ESTAGIO2    2   # 2a area
.eqv MUS_CHEFAO      3   # luta de chefe
.eqv MUS_GAMEOVER    4   # game over
.eqv MUS_VITORIA     5   # vitoria
.eqv MUS_NONE       -1   # nenhuma musica armada ainda (forca 1o arme)

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
PHYS_GROUND_Y: .float 144.0

# --- Aceleracao/frenagem dos inimigos (modelo igual ao do player:
#     acelera na direcao do alvo, freia quando sem alvo). Valores baixos
#     = mais inercia = reversao mais lenta e natural ao pular por cima. ---
EN_ACCEL:      .float 0.15   # aceleracao horizontal/voo dos inimigos (px/frame^2)
EN_BRAKE:      .float 0.12   # desaceleracao aplicada quando IDLE (freio)
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
# ---- Musica --------------------------------------------------------- #
.eqv GS_music_id    36  # word: id (MUS_*) da musica que DEVE tocar agora.
                        #   Qualquer sistema (door, boss, scene) escreve aqui.
.eqv GS_music_armed 40  # word: id da musica atualmente ARMADA (tocando).
                        #   Se != GS_music_id, o MUSIC_SELECT re-arma. Comeca MUS_NONE.
.eqv GS_music_cur   44  # word: ponteiro p/ a tabela <SONG> da musica armada.
                        #   0 = nenhuma; o MUSIC_LOOP nao toca nada enquanto 0.
# ---- Camera / scroll ----------------------------------------------- #
.eqv GS_cam_x       48  # word: posicao X da camera em PIXELS de mundo.
                        #   O mapa e as entidades sao desenhados deslocados
                        #   de -cam_x. Calculado por CAMERA_UPDATE p/ manter
                        #   o player no centro, travando nas bordas do mapa.

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
    .word MUS_INICIO    # GS_music_id    (comeca pedindo a musica do menu)
    .word MUS_NONE      # GS_music_armed (nada armado -> forca o 1o arme)
    .word 0             # GS_music_cur   (ponteiro nulo ate o 1o MUSIC_SELECT)
    .word 0             # GS_cam_x       (camera comeca em 0 = borda esquerda)

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
    .float 144.0        # PH_y   (posicao inicial Y, pixels -- pe no chao WORLD1)
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
.eqv PLAYER_W  32
.eqv PLAYER_H  48
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

# ==================================================================== #
#  PROJECTILE POOL  --  tiros do Buster (req 2 / base do req 4)         #
#  ------------------------------------------------------------------  #
#  Pool de tamanho fixo (PROJ_MAX). Cada slot e uma struct de 5 words  #
#  (PROJ_STRIDE = 20 bytes). Coordenadas em PIXELS INTEIROS (o tiro    #
#  anda a velocidade constante, sem fisica float -- por isso int).     #
#                                                                      #
#  Layout de um slot (offsets a partir do inicio do slot):             #
#    PR_active  0  : 0 = livre, 1 = em voo                             #
#    PR_x       4  : X na tela (top-left do sprite do tiro)            #
#    PR_y       8  : Y na tela (top-left)                              #
#    PR_vx     12  : velocidade horizontal (px/frame, com sinal)       #
#    PR_type   16  : tipo de arma (0 = Buster). Reservado p/ req 4.    #
#                                                                      #
#  attack.s escreve/avanca; render_entities.s le e desenha.            #
# ==================================================================== #
.eqv PROJ_MAX     8      # numero de slots no pool
.eqv PROJ_STRIDE  20     # bytes por slot (5 words)
.eqv PR_active    0
.eqv PR_x         4
.eqv PR_y         8
.eqv PR_vx        12
.eqv PR_type      16

.eqv PROJ_SPEED   6      # px/frame do tiro do Buster
.eqv PROJ_W       8      # largura do sprite do tiro
.eqv PROJ_H       8      # altura do sprite do tiro

.data
.align 2
PROJ_POOL:
    # PROJ_MAX slots x PROJ_STRIDE bytes, zerados (todos livres no boot)
    .space 160    # 8 * 20

# ------------------------------------------------------------------- #
#  BUSTER_SPRITE -- placeholder 8x8 (64 bytes), 1 byte/pixel.          #
#  Bolinha de cor viva (indice 40) com cantos vazios (0 = preto) pra   #
#  dar formato arredondado. SUBSTITUIR pelo sprite real depois.        #
# ------------------------------------------------------------------- #
BUSTER_SPRITE:
    .byte  0, 0,40,40,40,40, 0, 0
    .byte  0,40,40,40,40,40,40, 0
    .byte 40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40
    .byte 40,40,40,40,40,40,40,40
    .byte  0,40,40,40,40,40,40, 0
    .byte  0, 0,40,40,40,40, 0, 0

# ==================================================================== #
#  ENEMY POOL  --  inimigos (req 8: >=3 tipos c/ IAs diferentes)       #
#  ------------------------------------------------------------------  #
#  Pool fixo de EN_MAX slots. Cada slot COMECA com o bloco de fisica   #
#  PH_* (32 bytes) para poder ser passado direto ao PHYSICS_STEP -- o  #
#  inimigo CORREDOR reusa a gravidade/integracao do player. O VOADOR   #
#  ignora PH_ax/ay e escreve PH_vx/vy direto (voo livre em X e Y).     #
#                                                                      #
#  Depois do bloco PH_* vem os campos proprios do inimigo:             #
#    EN_active   32  : 0 = slot livre, 1 = vivo                        #
#    EN_type     36  : ENT_FLYER / ENT_RUNNER                          #
#    EN_fsm      40  : ENF_IDLE / ENF_SPOTTED (estado da IA)           #
#    EN_hp       44  : pontos de vida                                  #
#    EN_dir      48  : DIR_RIGHT / DIR_LEFT (p/ espelhar sprite)       #
#    EN_anim     52  : contador de frames p/ animacao                  #
#  EN_STRIDE = 56 bytes por slot (32 fisica + 24 proprios).            #
# ==================================================================== #
.eqv EN_MAX      8
.eqv EN_STRIDE   56
# --- campos proprios (offset a partir do inicio do slot) --- #
.eqv EN_active   32
.eqv EN_type     36
.eqv EN_fsm      40
.eqv EN_hp       44
.eqv EN_dir      48
.eqv EN_anim     52

# --- tipos de inimigo --- #
.eqv ENT_FLYER   0   # voador (caveira): persegue em X e Y
.eqv ENT_RUNNER  1   # corredor (camera): persegue so em X, preso ao chao

# --- estados da FSM --- #
.eqv ENF_IDLE     0  # parado (nao avistou o player)
.eqv ENF_SPOTTED  1  # avistou: persegue

# --- parametros de comportamento --- #
.eqv EN_SIGHT_RADIUS  60    # era 120
# --- Movimento por ACELERACAO: a IA escreve PH_ax/ay (via EN_ACCEL/
#     EN_BRAKE, floats la em cima) e a engine integra vx/vy com clamp em
#     vx_max/vy_max. Isso da INERCIA: ao pular por cima, o inimigo
#     desacelera, para e so entao inverte -- nao troca de direcao
#     instantaneamente. Os VMAX abaixo viram PH_vx_max/PH_vy_max. ---
.eqv EN_FLYER_VMAX     2    # velocidade maxima do voador (px/frame por eixo)
.eqv EN_RUNNER_VMAX    2    # velocidade maxima horizontal do corredor
.eqv EN_VYMAX_FALL    12    # teto de queda (vy_max) p/ o corredor cair
.eqv EN_VYMAX_FLY      2    # teto vertical do voador (voo suave em Y)
.eqv EN_FLYER_W       32     # voador (EN2) 32x32
.eqv EN_FLYER_H       32
.eqv EN_RUNNER_W      32     # corredor (EN1) 32x48
.eqv EN_RUNNER_H      48
# EN_W/EN_H genericos (usados na checagem de visibilidade pelo centro).
# Uso o menor (32x32) como caixa de referencia -- aproximacao boa o
# suficiente p/ "maioria na tela". Colisao real vem no Bloco 4.
.eqv EN_W             32
.eqv EN_H             32
# Visibilidade usa o CENTRO do inimigo (x+EN_W/2, y+EN_H/2) contra os
# limites SCREEN_* -> ele so perde o spotted quando a maioria do corpo
# saiu da tela. Ver a checagem em enemies.s (EU_LOOP).
.eqv EN_FLYER_HP       3
.eqv EN_RUNNER_HP      4
# --- Dano de contato por tipo (subtraido de PLAYER_health no toque).
#     Vida do player = 28 -> voador(4) mata em 7 toques, corredor(6) em 5.
#     Sao os botoes de balanceamento: suba p/ deixar mais punitivo.
.eqv EN_FLYER_DMG      4
.eqv EN_RUNNER_DMG     6

# --- limites de visibilidade na tela (hoje = coords de tela, tp=0) --- #
# Quando o scroll entrar, SCREEN_LEFT vira a posicao X da camera.
.eqv SCREEN_LEFT    0
.eqv SCREEN_RIGHT   320
.eqv SCREEN_TOP     0
.eqv SCREEN_BOT     240
# --- Camera: constantes de scroll horizontal ------------------------ #
.eqv SCREEN_W_PX    320   # largura da tela em pixels
.eqv CAM_MARGIN     144   # SCREEN_W_PX/2 - PLAYER_W/2 = 160 - 16 = 144
                          #   -> desloc. p/ manter o player centralizado.
.eqv CAM_MAX_X      2080  # limite direito: map_w(150)*16 - 320 = 2080.
                          #   (recalcular se a largura do mapa mudar!)

.data
.align 2
ENEMY_POOL:
    .space 448    # EN_MAX(8) * EN_STRIDE(56)

# ------------------------------------------------------------------- #
#  Sprites placeholder 16x16 (256 bytes cada), 1 byte/pixel.          #
#  SUBSTITUIR pelos sprites reais (imagens do enunciado) via           #
#  bmp2oac3.exe depois. Cores: indice 48 (voador), 16 (corredor).     #
# ------------------------------------------------------------------- #
FLYER_SPRITE:
    .byte  0, 0, 0,48,48,48,48,48,48,48,48, 0, 0, 0, 0, 0
    .byte  0, 0,48,48,48,48,48,48,48,48,48,48, 0, 0, 0, 0
    .byte  0,48,48,48,48,48,48,48,48,48,48,48,48, 0, 0, 0
    .byte  0,48,48, 0, 0,48,48,48,48, 0, 0,48,48, 0, 0, 0
    .byte 48,48,48, 0, 0,48,48,48,48, 0, 0,48,48,48, 0, 0
    .byte 48,48,48,48,48,48,48,48,48,48,48,48,48,48, 0, 0
    .byte 48,48,48,48,48,48,48,48,48,48,48,48,48,48, 0, 0
    .byte  0,48,48,48,48,48,48,48,48,48,48,48,48, 0, 0, 0
    .byte  0,48, 0,48, 0,48, 0,48, 0,48, 0,48, 0, 0, 0, 0
    .byte  0, 0,48, 0,48, 0,48, 0,48, 0,48, 0, 0, 0, 0, 0
    .byte  0, 0, 0,48, 0,48, 0,48, 0,48, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0,48, 0,48, 0,48, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0,48, 0,48, 0, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0,48, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

RUNNER_SPRITE:
    .byte  0, 0,16,16,16,16,16,16,16,16, 0, 0, 0, 0, 0, 0
    .byte  0,16,16,16,16,16,16,16,16,16,16, 0, 0, 0, 0, 0
    .byte 16,16, 0, 0,16,16,16,16, 0, 0,16,16, 0, 0, 0, 0
    .byte 16,16, 0, 0,16,16,16,16, 0, 0,16,16, 0, 0, 0, 0
    .byte 16,16,16,16,16,16,16,16,16,16,16,16, 0, 0, 0, 0
    .byte 16,16,16,16,16,16,16,16,16,16,16,16, 0, 0, 0, 0
    .byte  0,16,16,16,16,16,16,16,16,16,16, 0, 0, 0, 0, 0
    .byte  0, 0,16,16,16,16,16,16,16,16, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0,16,16, 0, 0,16,16, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0,16,16, 0, 0, 0, 0,16,16, 0, 0, 0, 0, 0, 0
    .byte  0,16,16, 0, 0, 0, 0, 0, 0,16,16, 0, 0, 0, 0, 0
    .byte 16,16, 0, 0, 0, 0, 0, 0, 0, 0,16,16, 0, 0, 0, 0
    .byte 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,16, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
