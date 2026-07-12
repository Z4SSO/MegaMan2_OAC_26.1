.data
CANAL_1:        .word CANAL_1_NOTAS   # [0] ponteiro pra nota atual
                .word 0               # [4] timer
                .word CANAL_1_FIM     # [8] endereço de fim
                .word 0               # [12] flag: 1 = já terminou, esperando
                .word CANAL_1_NOTAS   # [16] início da música                
CANAL_1_NOTAS:  .word 0 250 64 250 64 250 64 250 64 750 64 250 62 500 59 250 55 1000 57 250 64 500 64 500 62 250 60 250 62 2500 0 500 65 500 65 500 65 250 64 500 62 500 60 750 0 250 60 250 64 500 64 250 62 500 60 250 64 1500 0 1500 64 250 64 250 64 250 64 500 64 250 62 500 59 250 55 1000 57 250 64 250 64 500 64 250 62 500 60 250 62 2250 0 250 65 250 65 250 65 250 65 750 65 250 64 500 62 250 60 750 60 250 62 250 64 500 64 250 62 500 60 250 64 1500 0 250 64 250 67 250 69 750 64 500 67 250 69 500 69 500 67 1750 0 750 69 250 69 250 71 250 72 250 71 500 69 500 67 500 64 250 67 250 69 750 69 1000 67 250 69 250 67 250 64 500 62 1000 60 125 62 125 64 500 64 250 62 500 60 250 64 1500 0 250 64 250 67 250 69 750 64 500 67 250 69 500 69 500 67 250 69 500 67 500 67 125 69 625 0 250 69 250 69 250 71 250 72 250 71 500 69 500 67 1000 67 250 65 250 72 500 72 750 65 250 67 500 72 500 72 1250 72 750 72 750 72 250 71 750 
CANAL_1_FIM:

CANAL_2:        .word CANAL_2_NOTAS
                .word 0
                .word CANAL_2_FIM
                .word 0
                .word CANAL_2_NOTAS

CANAL_2_NOTAS:
.word
36 1000 43 1000 36 1000 43 1000 38 1000 43 1000 36 1000 31 1000
36 1000 43 1000 36 1000 43 1000 40 1000 45 1000 43 1000 38 1000
36 1000 43 1000 36 1000 43 1000 38 1000 43 1000 36 1000 31 1000
36 1000 43 1000 40 1000 45 1000 43 1000 38 1000 36 1000 43 1000
36 500 38 500 40 500 43 500 45 500 43 500 40 500 38 500
36 1000 43 1000 47 1000 43 1000 40 1000 45 1000 43 1000 38 1000
36 1000 43 1000 48 1000 47 1000 45 1000 43 1000 40 1000 38 1000
36 1000 43 1000 36 1000 43 1000 38 1000 43 1000 36 2000

CANAL_2_FIM:

.text
MUSIC_LOOP:
    addi sp, sp, -4
    sw ra, 0(sp)

    la a0, CANAL_1
    call PLAY_MUSIC
    mv  t5, a7            # guarda se CANAL_1 terminou

    la a0, CANAL_2
    call PLAY_MUSIC
    and t5, t5, a7         # só é "1" se AMBOS terminaram

    beqz t5, MUSIC_LOOP_FIM

    # os dois terminaram -> reinicia tudo junto
    la  a0, CANAL_1
    call RESET_CANAL
    la  a0, CANAL_2
    call RESET_CANAL

MUSIC_LOOP_FIM:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

PLAY_MUSIC:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)

    mv   s1, a0
    lw   t6, 12(s1)
    bnez t6, MUSIC_JA_ACABOU     # já tinha terminado -> só avisa e não faz nada

    lw   t0, 0(s1)
    lw   t3, 4(s1)
    lw   t4, 8(s1)

    beqz t3, TOCA_NOTA
    li a7,30
    ecall
    mv t2,a0              # guarda o tempo atual
    blt t2,t3,NAO_TERMINOU
    
    addi t0,t0,8
    sw   t0, 0(s1)
    bge  t0, t4, MARCA_FIM

TOCA_NOTA:
    lw   a0, 0(t0)
    lw   a1, 4(t0)
    li   a2, 0
    li   a3, 100
    li a7,31
    ecall
    
    add s0,t2,a1
    sw  s0,4(s1)

NAO_TERMINOU:
    li   a7, 0                    # sinaliza: ainda não terminou
    j    PLAY_MUSIC_RET

MARCA_FIM:
    li   t6, 1
    sw   t6, 12(s1)                # marca esse canal como terminado

MUSIC_JA_ACABOU:
    li   a7, 1                    # sinaliza: terminou (ou já tinha terminado)

PLAY_MUSIC_RET:
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 12
    ret

RESET_CANAL:
    mv   t0, a0

    lw   t1, 16(t0)         # endereço inicial da música
    sw   t1, 0(t0)          # reinicia ponteiro

    sw   zero, 4(t0)        # zera timer
    sw   zero, 12(t0)       # zera flag de "terminou"

    ret
