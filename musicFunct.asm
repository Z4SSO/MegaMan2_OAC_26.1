.data
# Instrumentos e volumes de cada canal
.eqv INSTRUMENTO1  25
.eqv VOLUME1       100

.eqv INSTRUMENTO2  25
.eqv VOLUME2       70

.eqv INSTRUMENTO3  25
.eqv VOLUME3       110

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

CANAL_1:
    .word CANAL_1_NOTAS   # [0]
    .word 0               # [4] timer
    .word CANAL_1_FIM     # [8] fim
    .word 0               # [12] flag
    .word CANAL_1_NOTAS   # [16] início
    .word INSTRUMENTO1    # [20] instrumento
    .word VOLUME1         # [24] volume

CANAL_1_NOTAS:
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
CANAL_1_FIM:

CANAL_2:
    .word CANAL_2_NOTAS
    .word 0
    .word CANAL_2_FIM
    .word 0
    .word CANAL_2_NOTAS
    .word INSTRUMENTO2
    .word VOLUME2

CANAL_2_NOTAS:
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
CANAL_2_FIM:

CANAL_3:
    .word CANAL_3_NOTAS
    .word 0
    .word CANAL_3_FIM
    .word 0
    .word CANAL_3_NOTAS
    .word INSTRUMENTO3
    .word VOLUME3

CANAL_3_NOTAS:
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
CANAL_3_FIM:

.text

MUSIC_LOOP:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   a0, CANAL_1
    call PLAY_MUSIC
    mv   t5, a7            # t5 = 1 se CANAL_1 terminou

    la   a0, CANAL_2
    call PLAY_MUSIC
    and  t5, t5, a7        # t5 = 1 se ambos 1 e 2 terminaram

    la   a0, CANAL_3
    call PLAY_MUSIC
    and  t5, t5, a7        # t5 = 1 se os três terminaram

    beqz t5, MUSIC_LOOP_FIM

    la   a0, CANAL_1
    call RESET_CANAL
    la   a0, CANAL_2
    call RESET_CANAL
    la   a0, CANAL_3
    call RESET_CANAL

MUSIC_LOOP_FIM:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

PLAY_MUSIC:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)

    mv   s1, a0              # s1 = base do canal

    lw   t6, 12(s1)
    bnez t6, MUSIC_JA_ACABOU

    lw   t0, 0(s1)           # t0 = ponteiro nota atual
    lw   t3, 4(s1)           # t3 = timer
    lw   t4, 8(s1)           # t4 = endereço fim

    #tempo atual único
    li   a7, 30
    ecall
    mv   s2, a0              # s2 = tempo atual ms

    # Se timer = 0 toca imediatamente
    beqz t3, DISPARA_NOTA

    # se não espera até que o tempo atual >= timer
    blt  s2, t3, NAO_TERMINOU

DISPARA_NOTA:
    lw   a0, 0(t0)           
    lw   a1, 4(t0)          
    lw   a2, 20(s1)          
    lw   a3, 24(s1)          
    li   a7, 31
    ecall

    bgt  t3, s2, usa_t3      # se timer > agora, mantém base
    mv   t3, s2              # senão, usa o momento atual como base
usa_t3:
    add  t3, t3, a1
    sw   t3, 4(s1)

    # Avança o ponteiro para a próxima nota
    addi t0, t0, 8
    sw   t0, 0(s1)

    bge  t0, t4, MARCA_FIM

    li   a7, 0
    j    PLAY_MUSIC_RET

MARCA_FIM:
    li   t6, 1
    sw   t6, 12(s1)

MUSIC_JA_ACABOU:
    li   a7, 1

    j    PLAY_MUSIC_RET

NAO_TERMINOU:
    li   a7, 0

PLAY_MUSIC_RET:
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret


RESET_CANAL:
    mv   t0, a0
    lw   t1, 16(t0)          # endereço inicial da música
    sw   t1, 0(t0)           # reinicia ponteiro
    sw   zero, 4(t0)         # zera timer
    sw   zero, 12(t0)        # zera flag
    ret