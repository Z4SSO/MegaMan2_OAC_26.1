# ==================================================================== #
#  musicFunct.s  --  MOTOR de reproducao de musica (sem dados)         #
#                                                                      #
#  Os DADOS das musicas foram movidos para music_data.s (um bloco de   #
#  3 canais por musica, rotulos prefixados, + MUSIC_TABLE). A POLITICA #
#  de qual musica tocar mora em music_state.s (MUSIC_SELECT). Aqui     #
#  ficou so o motor generico: toca a musica atualmente ARMADA.         #
#                                                                      #
#  Contrato: MUSIC_SELECT ja rodou neste frame e deixou em             #
#  GS_music_cur o endereco da tabela <SONG> (3 words = enderecos dos   #
#  canais 1,2,3) da musica ativa -- ou 0 se nenhuma. O MUSIC_LOOP le   #
#  esse ponteiro e avanca os 3 canais; quando os 3 terminam, faz loop  #
#  (reset) da PROPRIA musica ativa.                                    #
#                                                                      #
#  PLAY_MUSIC e RESET_CANAL sao os mesmos de sempre (nao mudaram):     #
#  operam sobre UM canal cujo endereco vem em a0.                      #
# ==================================================================== #

.text

# -------------------------------------------------------------------- #
#  MUSIC_LOOP  --  avanca a musica armada (GS_music_cur). Sem musica    #
#  armada (ponteiro 0), retorna sem tocar nada.                        #
# -------------------------------------------------------------------- #
MUSIC_LOOP:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   s0, 4(sp)

    la   t0, GAME_STATE
    lw   s0, GS_music_cur(t0)   # s0 = tabela <SONG> da musica ativa
    beqz s0, MUSIC_LOOP_FIM     # nenhuma musica armada: nada a fazer

    lw   a0, 0(s0)              # CANAL_1
    call PLAY_MUSIC
    mv   t5, a7                 # t5 = 1 se CANAL_1 terminou

    lw   a0, 4(s0)             # CANAL_2
    call PLAY_MUSIC
    and  t5, t5, a7            # t5 = 1 se 1 e 2 terminaram

    lw   a0, 8(s0)            # CANAL_3
    call PLAY_MUSIC
    and  t5, t5, a7            # t5 = 1 se os tres terminaram

    beqz t5, MUSIC_LOOP_FIM

    # Loop da musica: reseta os 3 canais DELA (s0 sobreviveu ao call)
    lw   a0, 0(s0)
    call RESET_CANAL
    lw   a0, 4(s0)
    call RESET_CANAL
    lw   a0, 8(s0)
    call RESET_CANAL

MUSIC_LOOP_FIM:
    lw   ra, 0(sp)
    lw   s0, 4(sp)
    addi sp, sp, 8
    ret

# -------------------------------------------------------------------- #
#  PLAY_MUSIC  --  avanca UM canal (a0 = base do canal). Retorna em a7  #
#  1 se o canal ja terminou, 0 caso contrario. INALTERADO.             #
# -------------------------------------------------------------------- #
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
    lw   t4, 8(s1)           # t4 = endereco fim

    #tempo atual unico
    li   a7, 30
    ecall
    mv   s2, a0              # s2 = tempo atual ms

    # Se timer = 0 toca imediatamente
    beqz t3, DISPARA_NOTA

    # se nao espera ate que o tempo atual >= timer
    blt  s2, t3, NAO_TERMINOU

DISPARA_NOTA:
    lw   a0, 0(t0)
    lw   a1, 4(t0)
    lw   a2, 20(s1)
    lw   a3, 24(s1)
    li   a7, 31
    ecall

    bgt  t3, s2, usa_t3      # se timer > agora, mantem base
    mv   t3, s2              # senao, usa o momento atual como base
usa_t3:
    add  t3, t3, a1
    sw   t3, 4(s1)

    # Avanca o ponteiro para a proxima nota
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


# -------------------------------------------------------------------- #
#  RESET_CANAL  --  volta UM canal (a0) ao inicio. INALTERADO.         #
# -------------------------------------------------------------------- #
RESET_CANAL:
    mv   t0, a0
    lw   t1, 16(t0)          # endereco inicial da musica
    sw   t1, 0(t0)           # reinicia ponteiro
    sw   zero, 4(t0)         # zera timer
    sw   zero, 12(t0)        # zera flag
    ret
