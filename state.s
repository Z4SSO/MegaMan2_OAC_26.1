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
.eqv SCENE_MENU        0
.eqv SCENE_GAME        1
.eqv SCENE_GAMEOVER    2
.eqv SCENE_WIN         3
.eqv SCENE_TRANSITION  4  # tela preta breve entre 2 mapas (porta), ver level.s

# -------------------- Fases (GS_level) ------------------------------- #
# Identifica qual mapa/fase esta ativa. Usado por DOOR_UPDATE (level.s)
# para saber qual porta checar, e por CAMERA_UPDATE nao usa isto (le a
# largura direto do CURRENT_MAP) -- so quem precisa SABER "em que fase
# estou" (door/musica) usa GS_level.
.eqv LEVEL_W1    0   # 1a area jogavel (Map_W1)
.eqv LEVEL_W2    1   # 2a area jogavel (Map_W2)
.eqv LEVEL_BOSS  2   # arena do chefe (Map_BOSS)

# -------------------- Transicao de fase (porta) ----------------------- #
# DOOR_UPDATE (level.s) so ARMA a transicao (cena vira SCENE_TRANSITION);
# TRANSITION_UPDATE (level.s) conta os frames e so troca de mapa de fato
# quando o timer zera -- da a "tela preta" fluida do MegaMan em vez de
# um corte seco. TRANSITION_DURATION em frames (frame_rate=50ms/frame).
.eqv TRANSITION_DURATION  30   # ~1.5s de tela preta na transicao

# Porta = retangulo de gatilho do tamanho do player (32x48), estatico por
# fase (SEM sprite real ainda -- ver DOOR_SPRITE abaixo). Posicoes
# escolhidas a partir da matriz do mapa (chao solido mais proximo do fim
# de cada fase) -- AJUSTAR apos testar no jogo real se nao bater com o
# chao visualmente (o levantamento foi feito lendo data.s, nao jogando).
.eqv DOOR_W   32
.eqv DOOR_H   48
.eqv DOOR_W1_X  2320   # fim do Map_W1 (150 tiles): coluna ~145, chao solido na linha 14 (y=224)
.eqv DOOR_W1_Y  176    # 224 (chao) - DOOR_H(48)
.eqv DOOR_W2_X  1600   # fim do Map_W2 (110 tiles): coluna ~100, chao solido na linha 8 (y=128)
.eqv DOOR_W2_Y  80     # 128 (chao) - DOOR_H(48)

# Gatilho de VITORIA (placeholder do chefe: ainda nao ha luta real, so um
# ponto arbitrario na arena do boss). Mesma AABB do player. Colocado no
# canto direito da arena, no chao (Map_BOSS e 20x15, tela inteira, sem
# scroll -- ver CAM_MAX_X dinamico em camera.s).
.eqv WIN_TRIGGER_X  272
.eqv WIN_TRIGGER_Y  176
.eqv WIN_TRIGGER_W  32
.eqv WIN_TRIGGER_H  48

# Pontos de spawn do player ao ENTRAR em cada fase (chao solido validado
# lendo a matriz do mapa em data.s -- mesmo criterio do spawn original
# do Map_W1 no handoff).
.eqv SPAWN_W1_X    80
.eqv SPAWN_W1_Y    144
.eqv SPAWN_W2_X    48
.eqv SPAWN_W2_Y    128
.eqv SPAWN_BOSS_X  48
.eqv SPAWN_BOSS_Y  176

# ---- Ids de musica (indices no MUSIC_TABLE de music_data.s) -------- #
# A ORDEM aqui deve casar com a ordem das entradas no MUSIC_TABLE.
.eqv MUS_INICIO      0   # menu / tela inicial
.eqv MUS_ESTAGIO1    1   # 1o estagio jogavel
.eqv MUS_ESTAGIO2    2   # 2a area
.eqv MUS_CHEFAO      3   # luta de chefe
.eqv MUS_GAMEOVER    4   # game over
.eqv MUS_VITORIA     5   # vitoria
.eqv MUS_NONE       -1   # nenhuma musica armada ainda (forca 1o arme)

# ---- Ids de efeito sonoro (indices na SFX_TABLE de sfx_data.s) ----- #
# [Requisito 1, parte "efeitos sonoros"]
# A ORDEM aqui deve casar com a ordem das entradas na SFX_TABLE.
# Para tocar de qualquer subsistema:  li a0, SFX_<NOME>; call SFX_PLAY
.eqv SFX_SHOOT         0   # tiro do Buster (attack.s)
.eqv SFX_JUMP          1   # pulo do chao (player.s)
.eqv SFX_DASH          2   # habilidade dash (player.s)
.eqv SFX_DOUBLEJUMP    3   # habilidade pulo duplo (player.s)
.eqv SFX_HURT          4   # player tomou dano (collision.s)
.eqv SFX_ENEMY_HIT     5   # inimigo levou tiro e sobreviveu (collision.s)
.eqv SFX_ENEMY_DEATH   6   # inimigo morreu (collision.s)
.eqv SFX_ITEM          7   # coletou cura/recarga (items.s)
.eqv SFX_DOOR          8   # entrou na porta (level.s)
.eqv SFX_COUNT         9   # total de efeitos (tamanho da SFX_TABLE)
.eqv SFX_NONE         -1   # nenhum efeito

# ---- Offsets do SFX_CHANNEL (struct em sfx.s) ---------------------- #
# Estado de reproducao do unico canal de efeito. O DADO do efeito
# (sfx_data.s) e constante; o estado mutavel vive aqui -- por isso o
# mesmo efeito pode tocar varias vezes sem se corromper.
.eqv SC_active   0   # word: 1 = tem efeito tocando
.eqv SC_ptr      4   # word: ponteiro pro proximo par (nota, duracao)
.eqv SC_end      8   # word: endereco de fim das notas
.eqv SC_timer   12   # word: momento absoluto (ms) do proximo disparo
.eqv SC_instr   16   # word: instrumento MIDI do efeito atual
.eqv SC_vol     20   # word: volume do efeito atual
.eqv SC_prio    24   # word: prioridade do efeito atual (ver sfx.s)

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
# ---- Fase / transicao de mapa (porta) ------------------------------- #
.eqv GS_level               52  # word: fase atual (LEVEL_*). Ver DOOR_UPDATE.
.eqv GS_transition_timer    56  # word: frames restantes da tela preta (SCENE_TRANSITION)
.eqv GS_transition_target   60  # word: fase (LEVEL_*) que vai carregar quando o timer zerar

GAME_STATE:
    .word SCENE_MENU    # GS_scene       (comeca na tela inicial mock)
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
    .word LEVEL_W1      # GS_level       (default; LEVEL_ENTER_W1 confirma ao sair do menu)
    .word 0             # GS_transition_timer
    .word LEVEL_W1      # GS_transition_target

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
.eqv PLAYER_ability   52  # word: habilidade de movimentacao ATIVA (ABILITY_*).
                          #   Sem 2o tipo de ataque: as 2 habilidades do req 4
                          #   sao pulo duplo e dash, ambas de movimentacao.
.eqv PLAYER_invuln    56  # word: frames restantes de i-frames
# ---- Carga de habilidade de movimentacao (dash / pulo duplo) -------- #
# "Municao" das habilidades de MOVIMENTACAO do req 4 (nao sao ataques:
# sao dash e pulo duplo). Usar uma habilidade gasta carga; itens de
# recarga (items.s) devolvem carga. Max/recarga ALTOS de proposito --
# usar uma habilidade de movimentacao e algo natural que deve ser
# ENCORAJADO; so o "overuse" (spam) deve ser punido.
# ABILITY_UPDATE (ability.s) troca PLAYER_ability na borda de INPUT_SWAP;
# player.s LE/GASTA a carga ao executar o pulo duplo ou o dash.
.eqv PLAYER_ability_charge     60  # word: carga atual (0..PLAYER_ability_charge_max)
.eqv PLAYER_ability_charge_max 64  # word: carga maxima
.eqv PLAYER_ABILITY_CHARGE_MAX 100 # valor da carga maxima (alto: nao deve travar o uso normal)
# ---- Estado do pulo duplo / dash (player.s) ------------------------- #
.eqv PLAYER_air_used   68  # word: 1 = ja usou a habilidade aerea nesta queda/pulo
                            #   (zera ao pisar no chao; permite 1 uso por "voo").
.eqv PLAYER_dash_timer 72  # word: frames restantes do dash em andamento (0 = parado)
# ---- Animacao do player (req 3) ------------------------------------- #
.eqv PLAYER_shoot_timer 76 # word: frames restantes da pose de tiro (PLAYER_SHOOT).
                           #   attack.s arma no spawn do projetil; player.s
                           #   decrementa; render_player.s mostra a pose enquanto >0.
.eqv PLAYER_SHOOT_ANIM_FRAMES 6  # duracao da pose de tiro (6 frames a 50ms = 300ms)

# --- Habilidades de movimentacao (req 4): so estas 2, sem ataque extra --- #
.eqv ABILITY_DOUBLEJUMP  0  # 2o pulo no ar (mesma vy do pulo normal)
.eqv ABILITY_DASH        1  # rajada horizontal, trava vy=0 por DASH_DURATION frames

.eqv ABILITY_COST_JUMP  20  # carga gasta por pulo duplo (de 100 max)
.eqv ABILITY_COST_DASH  15  # carga gasta por dash (de 100 max)
.eqv DASH_DURATION       8  # frames com vx travado em DASH_SPEED_F (sem gravidade)
DASH_SPEED_F:  .float 7.0   # px/frame durante o dash (vx_max normal e 3.0)
PLAYER_VX_MAX_DEFAULT: .float 3.0  # valor pra restaurar PH_vx_max quando o dash acaba

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
    .word ABILITY_DOUBLEJUMP  # PLAYER_ability (comeca com pulo duplo equipado)
    .word 0             # PLAYER_invuln
    .word PLAYER_ABILITY_CHARGE_MAX  # PLAYER_ability_charge (comeca cheia)
    .word PLAYER_ABILITY_CHARGE_MAX  # PLAYER_ability_charge_max
    .word 0             # PLAYER_air_used
    .word 0             # PLAYER_dash_timer
    .word 0             # PLAYER_shoot_timer

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

# ==================================================================== #
#  ANIMACAO (req 3) -- tabelas de frames + alinhamento sprite/hitbox   #
#                                                                      #
#  A caixa de FISICA/COLISAO nunca muda (player 32x48, corredor 32x48, #
#  voador 32x32). O que muda por frame de animacao e so o CANVAS do    #
#  sprite: os frames RUN tem 64 de largura e JUMP/SHOOT tem 48, com o  #
#  personagem centralizado e os pes na base (verificado pixel a pixel  #
#  nos .data do artista). Logo o render desenha o sprite DESLOCADO:    #
#     draw_x = x_fisica - (spriteW - hitboxW)/2   (centraliza)          #
#     draw_y = y_fisica + hitboxH - spriteH       (alinha os pes)       #
#  Para os sprites atuais spriteH == hitboxH sempre -> draw_y = y.     #
#  Offsets pre-calculados (o fpgrars nao faz aritmetica de .eqv):      #
.eqv ANIM_OFF_64 16   # (64-32)/2: frames de 64 de largura (RUN player/EN1)
.eqv ANIM_OFF_48 8    # (48-32)/2: frames de 48 (PLAYER_JUMP/SHOOT)
#                                                                      #
#  Se um frame LARGO nao couber inteiro na tela (cull), o render cai   #
#  de volta pro IDLE de 32 (que cabe mais vezes) antes de desistir --  #
#  senao o player/inimigo sumiria a 16px das bordas do mapa.           #
#                                                                      #
#  Velocidade da animacao: contador>>1 a 20fps = troca a cada 100ms.   #
#  Player usa GS_tick; inimigos usam EN_anim (contador por entidade    #
#  que ja existia em enemies.s e nao era consumido por ninguem).       #
# ==================================================================== #
.align 2
PLAYER_RUN_TABLE:           # 6 frames de corrida, todos 64x48
    .word PLAYER_RUN1
    .word PLAYER_RUN2
    .word PLAYER_RUN3
    .word PLAYER_RUN4
    .word PLAYER_RUN5
    .word PLAYER_RUN6
EN1_RUN_TABLE:              # corredor: 3 frames de corrida, todos 64x48
    .word EN1_RUN1
    .word EN1_RUN2
    .word EN1_RUN3
EN2_FLY_TABLE:              # voador: 6 frames de voo, todos 32x32
    .word EN2_A1
    .word EN2_A2
    .word EN2_A3
    .word EN2_A4
    .word EN2_A5
    .word EN2_A6
# limiar de |vx| p/ considerar o player "correndo" (senao friccao
# residual manteria a animacao de corrida apos soltar a tecla)
PANIM_VX_MIN: .float 0.5
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
.eqv ENT_BOSS    2   # chefao (req 8): FSM propria em boss.s, cinematico
                     #   (ENEMY_UPDATE e o resolve de mapa PULAM este tipo)

# --- estados da FSM --- #
.eqv ENF_IDLE     0  # parado (nao avistou o player)
.eqv ENF_SPOTTED  1  # avistou: persegue
# ---- Estados de FSM do CHEFAO (mesmo campo EN_fsm; valores disjuntos -- #
# ---- dos ENF_* porque o tipo ja separa os automatos) ------------------ #
.eqv BF_TRACK     2  # no canto: persegue o Y-alvo (player ou fixo)
.eqv BF_AIM       3  # mira travada: telegrafa parado (sprite PREPARE)
.eqv BF_DASH      4  # varredura horizontal ate a parede oposta

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

# ---- Chefao (req 8, 3o tipo; padrao "Savage Beastfly") -------------- #
# Arena = Map_BOSS 20x15 (medida da matriz em data.s): paredes nas
# colunas 0/19, chao na linha 14 (topo em y=224), teto irregular so nas
# linhas 0-4. Interior util p/ um corpo 64x64:
.eqv BOSS_W        64
.eqv BOSS_H        64
.eqv BOSS_HP       20   # buster da 1/hit -> 20 tiros
.eqv BOSS_DMG      8    # contato: pior que o corredor (6) -- e o chefe
.eqv BOSS_X_LEFT   16   # parede esq (col 0 solida)
.eqv BOSS_X_RIGHT  240  # 304 (parede dir) - 64 de largura
.eqv BOSS_Y_MIN    80   # abaixo das saliencias do teto (linhas 0-4)
.eqv BOSS_Y_MAX    160  # 224 (topo do chao) - 64 de altura
.eqv BOSS_GROUND_Y 160  # passada rasteira: barriga no chao (pula por cima)
.eqv BOSS_HIGH_Y   104  # passada alta: base em 168 < 176 (cabeca do player
                        #   em pe) -> passa por cima com 8px de folga
.eqv BOSS_TRACK_FRAMES 40  # ~2s de perseguicao do alvo Y antes de mirar
.eqv BOSS_AIM_FRAMES   16  # ~0.8s de telegraph parado (janela de leitura)
.eqv BOSS_SPAWN_X  240  # nasce encostado na parede direita...
.eqv BOSS_SPAWN_Y  104  # ...a meia altura
# velocidades (float: o movimento do boss e cinematico, sem PHYSICS_STEP)
BOSS_TRACK_SPD: .float 2.0    # px/frame no eixo Y durante o TRACK
BOSS_DASH_SPD:  .float 10.0   # px/frame na varredura (~26 frames a arena)

# ---- Estado extra do chefao (1 so boss -> struct dedicada) ---------- #
# O slot do pool guarda o generico (pos/hp/fsm/dir); aqui fica o que so
# o chefao tem: em qual passo do padrao ele esta e o Y-alvo travado.
.eqv BS_step     0   # word: passo do padrao 0..3
                     #   0 = tracking do Y do player  (ataque 1 do concept)
                     #   1 = rente ao chao            (ataque 2, varredura 1)
                     #   2 = por cima do player       (ataque 2, varredura 2)
                     #   3 = rente ao chao de novo    (ataque 2, varredura 3)
.eqv BS_timer    4   # word: frames restantes do estado atual (TRACK/AIM)
.eqv BS_target_y 8   # word: Y-alvo (int) sendo perseguido/travado
.align 2
BOSS_STATE:
    .word 0   # BS_step
    .word 0   # BS_timer
    .word 0   # BS_target_y

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
.eqv CAM_MAX_X      2080  # ORFA desde que passamos a trocar de mapa em tempo
                          #   real (level.s): camera.s agora calcula o limite
                          #   dinamicamente a partir do CURRENT_MAP (2080 so
                          #   valia p/ Map_W1). Pode apagar esta linha na
                          #   proxima limpeza (ver PHYS_GROUND_Y, mesma classe
                          #   de sobra do handoff).

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

# ==================================================================== #
#  ITEM POOL  --  colecionaveis de cura/recarga (req 6)                #
#  ------------------------------------------------------------------  #
#  Dropados por ITEM_DROP (items.s) quando um inimigo morre em         #
#  collision.s (CU_PE_BOX, "morreu: libera o slot"). Estaticos (sem    #
#  fisica/velocidade -- ficam parados ate serem coletados). Coletados  #
#  por ITEM_PICKUP_UPDATE (items.s), chamado no fim de COLLISION_UPDATE#
#  como um novo passo (5. player <-> itens).                           #
#                                                                      #
#  Layout de um slot (offsets a partir do inicio do slot):             #
#    IT_active  0  : 0 = livre, 1 = no chao esperando coleta           #
#    IT_x       4  : X de MUNDO (top-left, pixel inteiro)              #
#    IT_y       8  : Y de MUNDO (top-left, pixel inteiro)              #
#    IT_type   12  : ITEM_TYPE_HEAL ou ITEM_TYPE_CHARGE                #
#  ITEM_STRIDE = 16 bytes por slot.                                    #
# ==================================================================== #
.eqv ITEM_MAX      6      # slots simultaneos de item no chao
.eqv ITEM_STRIDE   16     # bytes por slot (4 words)
.eqv IT_active     0
.eqv IT_x          4
.eqv IT_y          8
.eqv IT_type       12

.eqv ITEM_TYPE_HEAL    0  # restaura PLAYER_health (clamp em max_hp)
.eqv ITEM_TYPE_CHARGE  1  # restaura PLAYER_ability_charge (clamp em max)

.eqv ITEM_W   16     # dimensoes do sprite/AABB do item
.eqv ITEM_H   16

# --- Botoes de balanceamento do drop ---------------------------------#
# Cura moderada (nem trivializa, nem obriga farm); recarga de habilidade
# ALTA de proposito (usar dash/pulo duplo deve ser natural -- ver nota
# em PLAYER_ability_charge_max no struct PLAYER, acima).
.eqv ITEM_HEAL_AMOUNT    10  # pontos de vida restaurados (de 28 max)
.eqv ITEM_CHARGE_AMOUNT  40  # pontos de carga restaurados (de 100 max)

.data
.align 2
ITEM_POOL:
    .space 96    # ITEM_MAX(6) * ITEM_STRIDE(16)

# ------------------------------------------------------------------- #
#  Sprites placeholder 16x16 (256 bytes cada), 1 byte/pixel, mesmo     #
#  estilo dos outros placeholders deste arquivo (cor solida + cantos   #
#  pretos p/ dar silhueta -- SEM cor 199, isso e so para sprites reais #
#  ja integrados). SUBSTITUIR quando o sprite do item chegar.          #
#  HEAL = cruz verde (indice 28). CHARGE = losango ciano (indice 31).  #
# ------------------------------------------------------------------- #
ITEM_HEAL_SPRITE:
    .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
    .byte  9, 98, 116, 116, 116, 116, 116, 116, 116, 116, 116, 126, 126, 116, 126,  9
    .byte  9, 98, 116, 116, 116, 116, 126, 126, 126, 126, 116, 116, 116, 116, 116,  9
    .byte  9, 98, 116, 116, 116, 116, 126, 126, 126, 126, 116, 116, 116, 116, 126,  9
    .byte  9, 98, 116, 116, 116, 98, 126, 126, 126, 126, 98, 116, 116, 116, 116,  9
    .byte  9, 98, 116, 116, 98, 98, 126, 126, 126, 126, 98, 98, 116, 116, 116,  9
    .byte  9, 98, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 116,  9
    .byte  9, 98, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 116,  9
    .byte  9, 98, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 116,  9
    .byte  9, 98, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 126, 116,  9
    .byte  9, 98, 116, 116, 98, 98, 126, 126, 126, 126, 98, 98, 116, 116, 116,  9
    .byte  9, 98, 116, 116, 116, 98, 126, 126, 126, 126, 98, 116, 116, 116, 116,  9
    .byte  9, 98, 116, 116, 116, 116, 126, 126, 126, 126, 116, 116, 116, 116, 116,  9
    .byte  9, 98, 116, 116, 116, 116, 126, 126, 126, 126, 116, 116, 116, 116, 116,  9
    .byte  9, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98,  9
    .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9

ITEM_CHARGE_SPRITE:
    .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9
    .byte  9, 94, 111, 111, 111, 111, 111, 111, 111, 111, 111, 183, 183, 111, 183,  9
    .byte  9, 94, 111, 111, 111, 111, 183, 183, 183, 183, 111, 111, 111, 111, 111,  9
    .byte  9, 94, 111, 111, 111, 111, 183, 183, 183, 183, 111, 111, 111, 111, 183,  9
    .byte  9, 94, 111, 111, 111, 94, 183, 183, 183, 183, 94, 111, 111, 111, 111,  9
    .byte  9, 94, 111, 111, 94, 94, 183, 183, 183, 183, 94, 94, 111, 111, 111,  9
    .byte  9, 94, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 111,  9
    .byte  9, 94, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 111,  9
    .byte  9, 94, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 111,  9
    .byte  9, 94, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 111,  9
    .byte  9, 94, 111, 111, 94, 94, 183, 183, 183, 183, 94, 94, 111, 111, 111,  9
    .byte  9, 94, 111, 111, 111, 94, 183, 183, 183, 183, 94, 111, 111, 111, 111,  9
    .byte  9, 94, 111, 111, 111, 111, 183, 183, 183, 183, 111, 111, 111, 111, 111,  9
    .byte  9, 94, 111, 111, 111, 111, 183, 183, 183, 183, 111, 111, 111, 111, 111,  9
    .byte  9, 94, 94, 94, 94, 94, 94, 94, 94, 94, 94, 94, 94, 94, 94,  9
    .byte  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9

# ==================================================================== #
#  DOOR_SPRITE -- PLACEHOLDER da porta de transicao (req 7)            #
#  32x48 (tamanho do player, DOOR_W x DOOR_H), 1 byte/pixel.           #
#  Ainda NAO ha sprite real (o amigo do grupo vai desenhar; deve virar #
#  um dos tiles "dummy" do tileset). Por ora: retangulo cor 52 (roxo   #
#  vivo, destaca do cenario) com moldura escura (cor 0) pra parecer um #
#  vao/porta em vez de um bloco solido qualquer.                      #
#  SUBSTITUIR: basta trocar estes .byte por um sprite 32x48 real ou    #
#  apontar DOOR_SPRITE para o novo .data (mesmo padrao do PLAYER_SPRITE#
#  quando o sprite do personagem chegou).                              #
# ==================================================================== #
DOOR_SPRITE:
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,52,0
    .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

# ==================================================================== #
#  WIN_MARKER_SPRITE -- PLACEHOLDER visual do gatilho de vitoria       #
#  (req 8, ainda sem luta de chefe real). 16x16, cor 63 (amarelo vivo) #
#  em X pra ficar bem visivel na arena durante o teste. Remover/trocar #
#  quando o chefao de verdade existir (o gatilho vira "morte do boss").#
# ==================================================================== #
WIN_MARKER_SPRITE:
    .byte 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,63
    .byte  0,63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,63, 0
    .byte  0, 0,63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,63, 0, 0
    .byte  0, 0, 0,63, 0, 0, 0, 0, 0, 0, 0, 0,63, 0, 0, 0
    .byte  0, 0, 0, 0,63, 0, 0, 0, 0, 0, 0,63, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0,63, 0, 0, 0, 0,63, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0,63, 0, 0,63, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0, 0,63,63, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0, 0,63,63, 0, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0, 0,63, 0, 0,63, 0, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0, 0,63, 0, 0, 0, 0,63, 0, 0, 0, 0, 0
    .byte  0, 0, 0, 0,63, 0, 0, 0, 0, 0, 0,63, 0, 0, 0, 0
    .byte  0, 0, 0,63, 0, 0, 0, 0, 0, 0, 0, 0,63, 0, 0, 0
    .byte  0, 0,63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,63, 0, 0
    .byte  0,63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,63, 0
    .byte 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,63
