# ==================================================================== #
#  music_data.s  --  TODAS as musicas do jogo (dados)                  #
#                                                                      #
#  Cada musica e um bloco de 3 canais no formato que o PLAY_MUSIC ja   #
#  entende (7 words/canal). Os rotulos sao prefixados por musica       #
#  (INICIO_, ESTAGIO1_, ESTAGIO2_, CHEFAO_, GAMEOVER_, VITORIA_) para  #
#  nao colidirem -- o fpgrars monta TODOS os .s da pasta, entao dois   #
#  "CANAL_1" dariam erro de rotulo duplicado.                          #
#                                                                      #
#  Instrumento/volume foram gravados como LITERAIS em cada struct      #
#  (o .eqv INSTRUMENTOx era global e cada musica usava valores         #
#  diferentes -> colisao). NAO reintroduza .eqv de instrumento aqui.   #
#                                                                      #
#  Cada musica termina com um <PREFIXO>_SONG: tabela de 3 words com    #
#  os enderecos dos 3 canais. O MUSIC_TABLE abaixo indexa as musicas   #
#  por id (MUS_*), e o music_state.s escolhe qual tocar.               #
# ==================================================================== #

.data

# ==== Song: INICIO (gerado de MegaManInicio.data) ====
# Instrumentos e volumes de cada canal

# ------------------------------------------------------------
# Estrutura de um canal (7 words):
#   [0]  ponteiro para a nota atual
#   [4]  timer (momento absoluto do proximo disparo, em ms)
#   [8]  endereco de fim da musica
#   [12] flag (1 = terminou)
#   [16] endereco de inicio (para reset)
#   [20] instrumento MIDI
#   [24] volume (velocity)
# ------------------------------------------------------------

INICIO_CANAL_1:
    .word INICIO_CANAL_1_NOTAS   # [0]
    .word 0               # [4] timer
    .word INICIO_CANAL_1_FIM     # [8] fim
    .word 0               # [12] flag
    .word INICIO_CANAL_1_NOTAS   # [16] inicio
    .word 25    # [20] instrumento
    .word 100         # [24] volume

INICIO_CANAL_1_NOTAS:
    .word 67,400, 66,200, 65,200, 63,200, 65,200, 66,200, 68,200, 67,400
    .word 66,200, 65,200, 63,200, 65,200, 66,200, 68,200, 70,400, 69,200
    .word 68,200, 67,200, 68,200, 69,200, 72,200, 70,400, 69,200, 68,200
    .word 67,200, 68,200, 69,200, 68,200, 67,400, 68,200, 67,200, 65,200
    .word 67,200, 68,200, 70,200, 67,400, 68,200, 67,200, 65,200, 67,200
    .word 68,200, 70,200, 67,400, 65,200, 63,200, 62,200, 63,200, 65,200
    .word 67,200, 63,400, 70,400, 75,400, 70,200, 68,200, 67,800, 68,400
    .word 70,400, 75,800, 72,400, 71,400, 70,800, 67,1600, 70,600, 69,200
    .word 68,800, 72,600, 76,200, 77,800, 74,600, 72,200, 70,2400, 67,600
    .word 70,200, 75,800, 79,600, 77,200, 75,800, 74,400, 75,400, 72,800
    .word 75,1600, 77,600, 75,200, 74,800, 70,600, 72,200, 74,800, 70,600
    .word 74,200, 75,800, 77,200, 75,200, 74,200, 70,200
INICIO_CANAL_1_FIM:

INICIO_CANAL_2:
    .word INICIO_CANAL_2_NOTAS   # [0]
    .word 0               # [4] timer
    .word INICIO_CANAL_2_FIM     # [8] fim
    .word 0               # [12] flag
    .word INICIO_CANAL_2_NOTAS   # [16] inicio
    .word 25    # [20] instrumento
    .word 100         # [24] volume

INICIO_CANAL_2_NOTAS:
    .word 55,1200, 56,400, 55,1200, 56,400, 58,1200, 60,400, 58,1200, 60,400
    .word 55,1200, 56,400, 55,1200, 56,400, 55,800, 53,800, 51,400, 58,400
    .word 63,400, 58,200, 56,200, 55,800, 56,400, 58,400, 63,800, 60,400
    .word 59,400, 58,800, 55,1600, 58,600, 57,200, 56,800, 60,600, 64,200
    .word 65,800, 62,600, 60,200, 58,2400, 55,600, 58,200, 63,800, 67,600
    .word 65,200, 63,800, 62,400, 63,400, 60,800, 63,1600, 65,600, 63,200
    .word 62,800, 58,600, 60,200, 62,800, 58,600, 62,200, 63,800, 65,200
    .word 63,200, 62,200, 58,200
INICIO_CANAL_2_FIM:

INICIO_CANAL_3:
    .word INICIO_CANAL_3_NOTAS   # [0]
    .word 0               # [4] timer
    .word INICIO_CANAL_3_FIM     # [8] fim
    .word 0               # [12] flag
    .word INICIO_CANAL_3_NOTAS   # [16] inicio
    .word 25    # [20] instrumento
    .word 110         # [24] volume

INICIO_CANAL_3_NOTAS:
    .word 43,1200, 44,400, 43,1200, 44,400, 46,1200, 48,400, 46,1200, 48,400
    .word 43,1200, 44,400, 43,1200, 44,400, 43,800, 41,800, 39,400, 46,400
    .word 51,400, 0,400, 43,1200, 46,400, 39,1200, 48,400, 46,1200, 48,400
    .word 41,800, 39,800, 44,800, 48,600, 47,200, 46,800, 43,600, 46,200
    .word 51,400, 50,400, 48,400, 47,400, 46,800, 43,600, 46,200, 48,800
    .word 39,600, 43,200, 46,800, 48,600, 46,200, 41,1200, 42,400, 43,400
    .word 46,400, 48,600, 47,200, 46,800, 43,600, 44,200, 46,800, 43,600
    .word 46,200, 51,800, 53,200, 51,200, 50,200, 46,200
INICIO_CANAL_3_FIM:

.align 2
INICIO_SONG:
    .word INICIO_CANAL_1
    .word INICIO_CANAL_2
    .word INICIO_CANAL_3

# ==== Song: ESTAGIO1 (extraido do musicFunct.s original) ====
# Instrumentos e volumes de cada canal

# ------------------------------------------------------------
# Estrutura de um canal (7 words):
#   [0]  ponteiro para a nota atual
#   [4]  timer (momento absoluto do próximo disparo, em ms)
#   [8]  endereço de fim da música
#   [12] flag (1 = terminou)
#   [16] endereço de início (para reset)
#   [20] instrumento MIDI
#   [24] volume (velocity)
# ------------------------------------------------------------

ESTAGIO1_CANAL_1:
    .word ESTAGIO1_CANAL_1_NOTAS   # [0]
    .word 0               # [4] timer
    .word ESTAGIO1_CANAL_1_FIM     # [8] fim
    .word 0               # [12] flag
    .word ESTAGIO1_CANAL_1_NOTAS   # [16] início
    .word 25    # [20] instrumento
    .word 100         # [24] volume

ESTAGIO1_CANAL_1_NOTAS:
    .word 64,600, 63,200, 67,600, 63,200, 64,400, 69,400, 66,400, 63,400
    .word 64,600, 63,200, 67,600, 63,200, 64,400, 67,400, 66,400, 71,400
    .word 64,600, 63,200, 67,600, 63,200, 64,400, 69,400, 66,400, 63,400
    .word 64,400, 67,400, 66,400, 63,400, 64,800, 67,400, 69,200, 67,200
    .word 66,400, 65,400, 64,400, 63,400, 64,800, 67,400, 69,200, 67,200
    .word 66,400, 70,400, 71,400, 66,400, 67,800, 69,400, 71,200, 69,200
    .word 66,400, 68,200, 69,200, 68,200, 67,200, 65,200, 64,200
    .word 63,800, 66,400, 67,400, 66,400, 67,400, 76,200, 74,200, 72,200, 72,200
    .word 64,600, 66,200, 68,200, 71,200, 69,600, 67,400, 66,200, 64,200, 67,400, 63,200
    .word 64,600, 66,200, 68,200, 71,200, 69,600, 67,400, 66,200, 64,200, 67,400, 63,200
    .word 64,600, 66,200, 68,200, 71,200, 69,600, 67,400, 66,200, 64,200, 67,400, 63,200
    .word 64,600, 66,200, 68,200, 71,200, 69,600, 67,400, 66,200, 64,200, 67,400, 63,200
    .word 64,800, 67,800, 66,800, 71,800, 64,800, 67,800, 66,800, 74,800
    .word 64,800, 67,800, 66,800, 71,800, 64,800, 67,800, 69,800, 76,200, 74,200, 72,200, 72,200
    .word 64,600, 66,200, 68,200, 71,200, 69,600, 67,400, 66,200, 64,200, 67,400, 63,200
    .word 64,600, 66,200, 68,200, 71,200, 69,600, 67,400, 66,200, 64,200, 67,400, 63,200
    .word 64,600, 66,200, 68,200, 71,200, 69,600, 67,400, 66,200, 64,200, 67,400, 63,200
    .word 64,600, 66,200, 68,200, 71,200, 69,600, 67,400, 66,200, 64,200, 67,400, 63,200
    .word 64,800, 67,800, 66,800, 71,800, 64,800, 67,800, 66,800, 74,800
    .word 64,800, 67,800, 66,800, 71,800, 64,800, 67,800, 69,800, 76,200, 74,200, 72,200, 72,200
ESTAGIO1_CANAL_1_FIM:

ESTAGIO1_CANAL_2:
    .word ESTAGIO1_CANAL_2_NOTAS
    .word 0
    .word ESTAGIO1_CANAL_2_FIM
    .word 0
    .word ESTAGIO1_CANAL_2_NOTAS
    .word 25
    .word 70

ESTAGIO1_CANAL_2_NOTAS:
    .word 40,2000, 39,400, 36,400, 39,400, 40,2000, 39,400, 36,400, 39,400
    .word 40,2000, 39,400, 36,400, 35,400, 33,800, 34,800, 35,800, 45,400, 43,400
    .word 42,400, 41,400, 40,400, 43,400, 42,800, 45,400, 43,400, 42,400, 41,400, 40,800
    .word 35,800, 57,400, 56,400, 57,400, 55,200, 56,200, 55,200, 54,200, 53,200, 52,200
    .word 51,800, 54,400, 55,400, 54,400, 55,400, 48,200, 49,200, 50,200, 51,200
    .word 52,600, 54,600, 57,800, 55,400, 54,400, 55,400
    .word 52,600, 54,600, 57,800, 55,400, 54,400, 55,400
    .word 52,600, 54,600, 57,800, 55,400, 54,400, 55,400
    .word 52,600, 54,600, 57,800, 55,400, 54,400, 55,400
    .word 52,800, 50,200, 48,200, 50,200, 47,200, 50,200, 48,200, 52,200, 50,200, 54,200, 52,200, 55,200, 57,200
    .word 52,800, 50,200, 48,200, 50,200, 47,200, 50,200, 48,200, 52,200, 50,200, 54,200, 52,200, 57,200, 59,200
    .word 52,800, 50,200, 48,200, 50,200, 47,200, 50,200, 48,200, 52,200, 50,200, 54,200, 52,200, 55,200, 57,200
    .word 52,800, 50,200, 48,200, 50,200, 47,200, 50,200, 48,200, 52,200, 50,200, 48,200, 49,200, 50,200, 51,200
    .word 52,600, 54,600, 57,800, 55,400, 54,400, 55,400
    .word 52,600, 54,600, 57,800, 55,400, 54,400, 55,400
    .word 52,600, 54,600, 57,800, 55,400, 54,400, 55,400
    .word 52,600, 54,600, 57,800, 55,400, 54,400, 55,400
    .word 52,800, 50,200, 48,200, 50,200, 47,200, 50,200, 48,200, 52,200, 50,200, 54,200, 52,200, 55,200, 57,200
    .word 52,800, 50,200, 48,200, 50,200, 47,200, 50,200, 48,200, 52,200, 50,200, 54,200, 52,200, 57,200, 59,200
    .word 52,800, 50,200, 48,200, 50,200, 47,200, 50,200, 48,200, 52,200, 50,200, 54,200, 52,200, 55,200, 57,200
    .word 52,800, 50,200, 48,200, 50,200, 47,200, 50,200, 48,200, 52,200, 50,200, 48,200, 49,200, 50,200, 51,200
ESTAGIO1_CANAL_2_FIM:

ESTAGIO1_CANAL_3:
    .word ESTAGIO1_CANAL_3_NOTAS
    .word 0
    .word ESTAGIO1_CANAL_3_FIM
    .word 0
    .word ESTAGIO1_CANAL_3_NOTAS
    .word 25
    .word 110

ESTAGIO1_CANAL_3_NOTAS:
    .word 0,24000
    .word 28,600, 31,600, 33,800, 35,400, 31,400, 33,400
    .word 28,600, 31,600, 33,800, 35,400, 36,400, 35,400
    .word 28,600, 31,600, 33,800, 35,400, 31,400, 33,400
    .word 28,600, 31,600, 33,800, 35,400, 36,400, 35,400
    .word 28,800, 31,800, 33,800, 31,800
    .word 28,800, 31,800, 33,800, 35,800
    .word 28,800, 31,800, 33,800, 31,800
    .word 28,800, 31,800, 33,800, 0,800
    .word 28,600, 31,600, 33,800, 35,400, 31,400, 33,400
    .word 28,600, 31,600, 33,800, 35,400, 36,400, 35,400
    .word 28,600, 31,600, 33,800, 35,400, 31,400, 33,400
    .word 28,600, 31,600, 33,800, 35,400, 36,400, 35,400
    .word 28,800, 31,800, 33,800, 31,800
    .word 28,800, 31,800, 33,800, 35,800
    .word 28,800, 31,800, 33,800, 31,800
    .word 28,800, 31,800, 33,800, 0,800
ESTAGIO1_CANAL_3_FIM:


.align 2
ESTAGIO1_SONG:
    .word ESTAGIO1_CANAL_1
    .word ESTAGIO1_CANAL_2
    .word ESTAGIO1_CANAL_3

# ==== Song: ESTAGIO2 (gerado de MegaManEstagio2.data) ====
# Instrumentos e volumes de cada canal

# ------------------------------------------------------------
# Estrutura de um canal (7 words):
#   [0]  ponteiro para a nota atual
#   [4]  timer (momento absoluto do proximo disparo, em ms)
#   [8]  endereco de fim da musica
#   [12] flag (1 = terminou)
#   [16] endereco de inicio (para reset)
#   [20] instrumento MIDI
#   [24] volume (velocity)
# ------------------------------------------------------------

ESTAGIO2_CANAL_1:
    .word ESTAGIO2_CANAL_1_NOTAS   # [0]
    .word 0               # [4] timer
    .word ESTAGIO2_CANAL_1_FIM     # [8] fim
    .word 0               # [12] flag
    .word ESTAGIO2_CANAL_1_NOTAS   # [16] inicio
    .word 4    # [20] instrumento
    .word 100         # [24] volume

ESTAGIO2_CANAL_1_NOTAS:
    .word 73,2400, 74,800, 76,600, 77,600, 81,800, 83,400, 81,800, 80,1600
    .word 81,400, 80,400, 83,800, 79,600, 80,600, 83,800, 81,400, 84,800
    .word 85,1600, 88,400, 87,400, 88,400, 87,400, 85,2400, 83,800, 85,2400
    .word 87,800, 85,2400, 83,800, 85,2400, 87,800, 81,400, 79,400, 82,400
    .word 84,400, 79,400, 77,400, 79,400, 82,400, 81,400, 79,400, 82,400
    .word 84,400, 79,400, 77,400, 79,400, 82,400, 79,400, 77,400, 80,400
    .word 82,400, 77,400, 75,400, 77,400, 80,400, 79,400, 77,400, 80,400
    .word 82,400, 77,400, 75,400, 77,400, 80,400, 85,2400, 83,800, 85,2400
    .word 87,800, 85,2400, 83,800, 85,2400, 87,800, 81,400, 79,400, 82,400
    .word 84,400, 79,400, 77,400, 79,400, 82,400, 81,400, 79,400, 82,400
    .word 84,400, 79,400, 77,400, 79,400, 82,400, 79,400, 77,400, 80,400
    .word 82,400, 77,400, 75,400, 77,400, 80,400, 79,400, 77,400, 80,400
    .word 82,400, 77,400, 75,400, 77,400, 80,400, 85,800, 83,800, 81,800
    .word 80,800, 85,800, 83,800, 81,800, 80,800, 77,600, 80,600, 85,400
    .word 74,600, 81,600, 83,400, 78,600, 86,600, 85,400, 83,400, 81,400
    .word 76,800
ESTAGIO2_CANAL_1_FIM:

ESTAGIO2_CANAL_2:
    .word ESTAGIO2_CANAL_2_NOTAS   # [0]
    .word 0               # [4] timer
    .word ESTAGIO2_CANAL_2_FIM     # [8] fim
    .word 0               # [12] flag
    .word ESTAGIO2_CANAL_2_NOTAS   # [16] inicio
    .word 4    # [20] instrumento
    .word 100         # [24] volume

ESTAGIO2_CANAL_2_NOTAS:
    .word 69,2400, 70,800, 69,2400, 68,800, 69,2400, 70,800, 69,2400, 68,800
    .word 69,1600, 63,400, 65,400, 69,400, 68,400, 81,2400, 79,800, 81,2400
    .word 83,800, 81,2400, 79,800, 81,2400, 83,800, 65,600, 67,600, 68,600
    .word 70,600, 72,400, 70,400, 65,600, 67,600, 68,600, 70,600, 72,400
    .word 70,400, 63,600, 65,600, 66,600, 68,600, 70,400, 68,400, 63,600
    .word 65,600, 66,600, 68,600, 70,400, 68,400, 81,2400, 79,800, 81,2400
    .word 83,800, 81,2400, 79,800, 81,2400, 83,800, 65,600, 67,600, 68,600
    .word 70,600, 72,400, 70,400, 65,600, 67,600, 68,600, 70,600, 72,400
    .word 70,400, 63,600, 65,600, 66,600, 68,600, 70,400, 68,400, 63,600
    .word 65,600, 66,600, 68,600, 70,400, 68,400, 81,800, 79,800, 77,800
    .word 75,800, 81,800, 79,800, 77,800, 75,800, 65,1200, 68,400, 67,1200
    .word 68,400, 65,1200, 68,400, 67,1600
ESTAGIO2_CANAL_2_FIM:

ESTAGIO2_CANAL_3:
    .word ESTAGIO2_CANAL_3_NOTAS   # [0]
    .word 0               # [4] timer
    .word ESTAGIO2_CANAL_3_FIM     # [8] fim
    .word 0               # [12] flag
    .word ESTAGIO2_CANAL_3_NOTAS   # [16] inicio
    .word 4    # [20] instrumento
    .word 110         # [24] volume

ESTAGIO2_CANAL_3_NOTAS:
    .word 65,2400, 66,800, 65,2400, 63,800, 65,2400, 66,800, 65,2400, 63,800
    .word 65,1600, 0,1600, 65,600, 67,600, 68,800, 70,600, 67,600, 65,600
    .word 67,600, 68,800, 70,600, 67,600, 65,600, 67,600, 68,800, 70,600
    .word 67,600, 65,600, 67,600, 68,800, 70,600, 67,600, 0,12800, 65,600
    .word 67,600, 68,800, 70,600, 67,600, 65,600, 67,600, 68,800, 70,600
    .word 67,600, 65,600, 67,600, 68,800, 70,600, 67,600, 65,600, 67,600
    .word 68,800, 70,600, 67,600, 0,12800, 65,600, 67,600, 68,800, 70,600
    .word 67,600, 65,600, 67,600, 68,800, 70,600, 67,600, 61,1200, 64,400
    .word 62,1200, 64,400, 61,1200, 64,400, 62,1600
ESTAGIO2_CANAL_3_FIM:

.align 2
ESTAGIO2_SONG:
    .word ESTAGIO2_CANAL_1
    .word ESTAGIO2_CANAL_2
    .word ESTAGIO2_CANAL_3

# ==== Song: CHEFAO (gerado de MegaManChefao.data) ====
# Instrumentos e volumes de cada canal

# ------------------------------------------------------------
# Estrutura de um canal (7 words):
#   [0]  ponteiro para a nota atual
#   [4]  timer (momento absoluto do proximo disparo, em ms)
#   [8]  endereco de fim da musica
#   [12] flag (1 = terminou)
#   [16] endereco de inicio (para reset)
#   [20] instrumento MIDI
#   [24] volume (velocity)
# ------------------------------------------------------------

CHEFAO_CANAL_1:
    .word CHEFAO_CANAL_1_NOTAS   # [0]
    .word 0               # [4] timer
    .word CHEFAO_CANAL_1_FIM     # [8] fim
    .word 0               # [12] flag
    .word CHEFAO_CANAL_1_NOTAS   # [16] inicio
    .word 25    # [20] instrumento
    .word 100         # [24] volume

CHEFAO_CANAL_1_NOTAS:
    .word 36,400, 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400
    .word 36,400, 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400
    .word 36,400, 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400
    .word 36,400, 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400
    .word 36,400, 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400
    .word 36,400, 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400
    .word 36,800, 39,400, 38,400, 35,1200, 38,400, 36,800, 39,400, 36,400
    .word 38,1200, 39,400, 36,800, 39,400, 38,400, 35,1200, 38,400, 36,800
    .word 39,400, 38,400, 41,800, 43,200, 41,200, 39,200, 38,200, 36,400
    .word 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400, 36,400
    .word 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400, 36,400
    .word 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400, 36,400
    .word 39,400, 36,400, 39,400, 35,400, 38,400, 35,400, 38,400, 36,800
    .word 39,400, 38,400, 35,1200, 38,400, 36,800, 39,400, 36,400, 38,1200
    .word 39,400, 36,800, 39,400, 38,400, 35,1200, 38,400, 36,800, 39,400
    .word 38,400, 41,800, 43,200, 41,200, 39,200, 38,200, 36,400, 35,400
    .word 38,400, 37,400, 36,400, 35,400, 38,400, 37,400, 36,400, 35,400
    .word 38,400, 37,400, 36,400, 35,400, 36,400, 35,400
CHEFAO_CANAL_1_FIM:

CHEFAO_CANAL_2:
    .word CHEFAO_CANAL_2_NOTAS   # [0]
    .word 0               # [4] timer
    .word CHEFAO_CANAL_2_FIM     # [8] fim
    .word 0               # [12] flag
    .word CHEFAO_CANAL_2_NOTAS   # [16] inicio
    .word 4    # [20] instrumento
    .word 100         # [24] volume

CHEFAO_CANAL_2_NOTAS:
    .word 0,6400, 67,200, 55,200, 67,200, 55,200, 67,200, 55,200, 67,200
    .word 55,200, 66,200, 54,200, 66,200, 54,200, 66,200, 54,200, 66,200
    .word 54,200, 67,200, 66,200, 67,200, 66,200, 67,200, 68,200, 69,200
    .word 70,200, 69,200, 68,200, 67,200, 66,200, 67,200, 66,200, 67,200
    .word 66,200, 67,200, 55,200, 67,200, 55,200, 67,200, 55,200, 67,200
    .word 55,200, 66,200, 54,200, 66,200, 54,200, 66,200, 54,200, 66,200
    .word 54,200, 67,200, 66,200, 67,200, 66,200, 67,200, 68,200, 69,200
    .word 70,200, 69,200, 68,200, 67,200, 66,200, 67,200, 66,200, 67,200
    .word 66,200, 68,200, 67,200, 60,400, 63,400, 62,400, 59,400, 62,200
    .word 63,200, 66,200, 65,200, 62,400, 68,200, 67,200, 60,400, 63,400
    .word 60,400, 65,400, 62,200, 63,200, 66,200, 65,200, 62,400, 68,200
    .word 67,200, 60,400, 63,400, 62,400, 59,400, 62,200, 63,200, 66,200
    .word 65,200, 62,400, 68,200, 67,200, 60,400, 63,400, 60,400, 65,400
    .word 62,200, 63,200, 67,200, 65,200, 63,200, 62,200, 67,200, 55,200
    .word 67,200, 55,200, 67,200, 55,200, 67,200, 55,200, 66,200, 54,200
    .word 66,200, 54,200, 66,200, 54,200, 66,200, 54,200, 67,200, 66,200
    .word 67,200, 66,200, 67,200, 68,200, 69,200, 70,200, 69,200, 68,200
    .word 67,200, 66,200, 67,200, 66,200, 67,200, 66,200, 67,200, 55,200
    .word 67,200, 55,200, 67,200, 55,200, 67,200, 55,200, 66,200, 54,200
    .word 66,200, 54,200, 66,200, 54,200, 66,200, 54,200, 67,200, 66,200
    .word 67,200, 66,200, 67,200, 68,200, 69,200, 70,200, 69,200, 68,200
    .word 67,200, 66,200, 67,200, 66,200, 67,200, 66,200, 68,200, 67,200
    .word 60,400, 63,400, 62,400, 59,400, 62,200, 63,200, 66,200, 65,200
    .word 62,400, 68,200, 67,200, 60,400, 63,400, 60,400, 65,400, 62,200
    .word 63,200, 66,200, 65,200, 62,400, 68,200, 67,200, 60,400, 63,400
    .word 62,400, 59,400, 62,200, 63,200, 66,200, 65,200, 62,400, 68,200
    .word 67,200, 60,400, 63,400, 60,400, 65,400, 62,200, 63,200, 67,200
    .word 65,200, 63,200, 62,200, 60,400, 64,400, 59,400, 63,400, 58,400
    .word 62,400, 57,400, 61,400, 60,400, 64,400, 59,400, 63,400, 58,400
    .word 62,400, 60,400, 59,400
CHEFAO_CANAL_2_FIM:

CHEFAO_CANAL_3:
    .word CHEFAO_CANAL_3_NOTAS   # [0]
    .word 0               # [4] timer
    .word CHEFAO_CANAL_3_FIM     # [8] fim
    .word 0               # [12] flag
    .word CHEFAO_CANAL_3_NOTAS   # [16] inicio
    .word 4    # [20] instrumento
    .word 110         # [24] volume

CHEFAO_CANAL_3_NOTAS:
    .word 0,9600, 55,200, 54,200, 55,200, 54,200, 55,200, 54,200, 53,200
    .word 52,200, 53,200, 54,200, 55,200, 56,200, 55,200, 54,200, 55,200
    .word 54,200, 0,3200, 55,200, 54,200, 55,200, 54,200, 55,200, 54,200
    .word 53,200, 52,200, 53,200, 54,200, 55,200, 56,200, 55,200, 54,200
    .word 55,200, 54,200, 63,200, 62,200, 55,400, 58,400, 57,400, 54,400
    .word 57,200, 58,200, 61,200, 60,200, 57,400, 63,200, 62,200, 55,400
    .word 58,400, 55,400, 60,400, 57,200, 58,200, 61,200, 60,200, 57,400
    .word 63,200, 62,200, 55,400, 58,400, 57,400, 54,400, 57,200, 58,200
    .word 61,200, 60,200, 57,400, 63,200, 62,200, 55,400, 58,400, 55,400
    .word 60,400, 57,200, 58,200, 62,200, 60,200, 58,200, 57,200, 0,3200
    .word 55,200, 54,200, 55,200, 54,200, 55,200, 54,200, 53,200, 52,200
    .word 53,200, 54,200, 55,200, 56,200, 55,200, 54,200, 55,200, 54,200
    .word 0,3200, 55,200, 54,200, 55,200, 54,200, 55,200, 54,200, 53,200
    .word 52,200, 53,200, 54,200, 55,200, 56,200, 55,200, 54,200, 55,200
    .word 54,200, 63,200, 62,200, 55,400, 58,400, 57,400, 54,400, 57,200
    .word 58,200, 61,200, 60,200, 57,400, 63,200, 62,200, 55,400, 58,400
    .word 55,400, 60,400, 57,200, 58,200, 61,200, 60,200, 57,400, 63,200
    .word 62,200, 55,400, 58,400, 57,400, 54,400, 57,200, 58,200, 61,200
    .word 60,200, 57,400, 63,200, 62,200, 55,400, 58,400, 55,400, 60,400
    .word 57,200, 58,200, 62,200, 60,200, 58,200, 57,200, 53,400, 57,400
    .word 52,400, 56,400, 51,400, 55,400, 50,400, 54,400, 53,400, 57,400
    .word 52,400, 56,400, 51,400, 55,400, 0,800
CHEFAO_CANAL_3_FIM:

.align 2
CHEFAO_SONG:
    .word CHEFAO_CANAL_1
    .word CHEFAO_CANAL_2
    .word CHEFAO_CANAL_3

# ==== Song: GAMEOVER (gerado de MegaManGameOver.data) ====
# Instrumentos e volumes de cada canal

# ------------------------------------------------------------
# Estrutura de um canal (7 words):
#   [0]  ponteiro para a nota atual
#   [4]  timer (momento absoluto do proximo disparo, em ms)
#   [8]  endereco de fim da musica
#   [12] flag (1 = terminou)
#   [16] endereco de inicio (para reset)
#   [20] instrumento MIDI
#   [24] volume (velocity)
# ------------------------------------------------------------

GAMEOVER_CANAL_1:
    .word GAMEOVER_CANAL_1_NOTAS   # [0]
    .word 0               # [4] timer
    .word GAMEOVER_CANAL_1_FIM     # [8] fim
    .word 0               # [12] flag
    .word GAMEOVER_CANAL_1_NOTAS   # [16] inicio
    .word 0    # [20] instrumento
    .word 100         # [24] volume

GAMEOVER_CANAL_1_NOTAS:
    .word 76,400, 74,400, 73,400, 70,200, 71,200, 66,400, 67,200, 69,200
    .word 64,400, 62,200, 64,200, 61,400, 62,200, 64,200, 66,200, 67,200
    .word 69,200, 71,200, 61,3200
GAMEOVER_CANAL_1_FIM:

GAMEOVER_CANAL_2:
    .word GAMEOVER_CANAL_2_NOTAS   # [0]
    .word 0               # [4] timer
    .word GAMEOVER_CANAL_2_FIM     # [8] fim
    .word 0               # [12] flag
    .word GAMEOVER_CANAL_2_NOTAS   # [16] inicio
    .word 0    # [20] instrumento
    .word 100         # [24] volume

GAMEOVER_CANAL_2_NOTAS:
    .word 52,400, 50,400, 49,400, 46,200, 47,200, 42,400, 43,200, 45,200
    .word 40,400, 38,200, 40,200, 37,400, 38,200, 40,200, 42,200, 43,200
    .word 45,200, 47,200, 37,3200
GAMEOVER_CANAL_2_FIM:

GAMEOVER_CANAL_3:
    .word GAMEOVER_CANAL_3_NOTAS   # [0]
    .word 0               # [4] timer
    .word GAMEOVER_CANAL_3_FIM     # [8] fim
    .word 0               # [12] flag
    .word GAMEOVER_CANAL_3_NOTAS   # [16] inicio
    .word 0    # [20] instrumento
    .word 0         # [24] volume

GAMEOVER_CANAL_3_NOTAS:
    .word 0,8000
GAMEOVER_CANAL_3_FIM:

.align 2
GAMEOVER_SONG:
    .word GAMEOVER_CANAL_1
    .word GAMEOVER_CANAL_2
    .word GAMEOVER_CANAL_3

# ==== Song: VITORIA (gerado de MegaManVitoria.data) ====
# Instrumentos e volumes de cada canal

# ------------------------------------------------------------
# Estrutura de um canal (7 words):
#   [0]  ponteiro para a nota atual
#   [4]  timer (momento absoluto do proximo disparo, em ms)
#   [8]  endereco de fim da musica
#   [12] flag (1 = terminou)
#   [16] endereco de inicio (para reset)
#   [20] instrumento MIDI
#   [24] volume (velocity)
# ------------------------------------------------------------

VITORIA_CANAL_1:
    .word VITORIA_CANAL_1_NOTAS   # [0]
    .word 0               # [4] timer
    .word VITORIA_CANAL_1_FIM     # [8] fim
    .word 0               # [12] flag
    .word VITORIA_CANAL_1_NOTAS   # [16] inicio
    .word 25    # [20] instrumento
    .word 100         # [24] volume

VITORIA_CANAL_1_NOTAS:
    .word 67,231, 65,115, 63,115, 67,462, 69,231, 67,115, 65,115, 69,462
    .word 70,231, 69,115, 67,115, 70,462, 72,2769
VITORIA_CANAL_1_FIM:

VITORIA_CANAL_2:
    .word VITORIA_CANAL_2_NOTAS   # [0]
    .word 0               # [4] timer
    .word VITORIA_CANAL_2_FIM     # [8] fim
    .word 0               # [12] flag
    .word VITORIA_CANAL_2_NOTAS   # [16] inicio
    .word 25    # [20] instrumento
    .word 100         # [24] volume

VITORIA_CANAL_2_NOTAS:
    .word 55,231, 53,115, 51,115, 55,462, 57,231, 55,115, 53,115, 57,462
    .word 58,231, 57,115, 55,115, 58,462, 60,2769
VITORIA_CANAL_2_FIM:

VITORIA_CANAL_3:
    .word VITORIA_CANAL_3_NOTAS   # [0]
    .word 0               # [4] timer
    .word VITORIA_CANAL_3_FIM     # [8] fim
    .word 0               # [12] flag
    .word VITORIA_CANAL_3_NOTAS   # [16] inicio
    .word 25    # [20] instrumento
    .word 110         # [24] volume

VITORIA_CANAL_3_NOTAS:
    .word 48,231, 46,115, 44,115, 48,462, 50,231, 48,115, 46,115, 50,462
    .word 51,231, 50,115, 48,115, 50,462, 52,2769
VITORIA_CANAL_3_FIM:

.align 2
VITORIA_SONG:
    .word VITORIA_CANAL_1
    .word VITORIA_CANAL_2
    .word VITORIA_CANAL_3

# ==================================================================== #
#  MUSIC_TABLE  --  registro de musicas, indexado por MUS_* (state.s)  #
#  Cada entrada e o endereco da tabela <SONG> daquela musica.          #
#  A ordem AQUI deve casar com os .eqv MUS_* em state.s.               #
# ==================================================================== #
.align 2
MUSIC_TABLE:
    .word INICIO_SONG      # MUS_INICIO   (0) - menu
    .word ESTAGIO1_SONG    # MUS_ESTAGIO1 (1) - 1o estagio jogavel
    .word ESTAGIO2_SONG    # MUS_ESTAGIO2 (2) - 2a area
    .word CHEFAO_SONG      # MUS_CHEFAO   (3) - luta de chefe
    .word GAMEOVER_SONG    # MUS_GAMEOVER (4) - game over
    .word VITORIA_SONG     # MUS_VITORIA  (5) - vitoria
