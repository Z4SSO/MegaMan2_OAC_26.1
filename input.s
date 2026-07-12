# ==================================================================== #
#  input.s  --  Leitura do teclado (subsistema INPUT_READ)            #
#                                                                      #
#  Le o teclado via KDMMIO e monta uma bitmask das teclas ativas em    #
#  GAME_STATE.input_bits. Os outros subsistemas consultam essa mascara #
#  (nunca leem o hardware direto), o que mantem o input desacoplado.   #
#                                                                      #
#  Deteccao de "acabou de apertar" (borda de subida): NAO e feita aqui.#
#  O GAME_LOOP salva o input do frame anterior em GS_input_prev antes  #
#  de chamar INPUT_READ; quem precisa de borda faz:                    #
#      borda = input_bits AND (NOT input_prev)                         #
#                                                                      #
#  LIMITACAO DO HARDWARE (honesta): o KDMMIO entrega UMA tecla por     #
#  leitura (o ultimo caractere digitado), nao um conjunto de teclas    #
#  simultaneas. Logo, num mesmo frame, so uma tecla e reconhecida.     #
#  Isso e o mesmo que o projeto Metroid enfrentava. Para andar-e-pular #
#  ao mesmo tempo de forma fluida, uma evolucao futura seria manter    #
#  estado "held" por tecla com timeout; por ora, seguimos o modelo     #
#  simples de uma tecla por frame.                                     #
# ==================================================================== #

# -------------------- Mapa de teclas (reconfiguravel) --------------- #
# Trocar o layout de controles = mudar SO estas constantes.
# Valores ASCII numericos (o RARS nao aceita literais 'a' em .eqv).
.eqv KEY_LEFT   97    # 'a'
.eqv KEY_RIGHT  100   # 'd'
.eqv KEY_UP     119   # 'w'
.eqv KEY_DOWN   115   # 's'
.eqv KEY_JUMP   107   # 'k'
.eqv KEY_SHOOT  106   # 'j'
.eqv KEY_SWAP   108   # 'l'

.text

# -------------------------------------------------------------------- #
#  INPUT_READ                                                          #
#  Args: nenhum.                                                       #
#  Efeito: escreve a bitmask das teclas ativas em GS_input_bits.       #
#  Registradores: usa apenas t0..t4 (caller-saved); nao toca s*.       #
#  Nao chama outra rotina -> nao precisa salvar ra.                    #
# -------------------------------------------------------------------- #
INPUT_READ:
    la   t4, GAME_STATE

    # Zera a mascara deste frame. Se nenhuma tecla for lida, fica 0
    # (= nada pressionado), que e o comportamento correto.
    sw   zero, GS_input_bits(t4)

    # 1. Ha alguma tecla disponivel? (bit 0 de KDMMIO_CTRL)
    li   t0, KDMMIO_CTRL
    lw   t1, 0(t0)
    andi t1, t1, 1
    beqz t1, INPUT_READ_END      # sem tecla -> mascara fica 0

    # 2. Le o valor ASCII da tecla (consome o caractere do buffer)
    li   t0, KDMMIO_DATA
    lw   t2, 0(t0)               # t2 = tecla ASCII

    # 3. Compara com o mapa de teclas e liga o bit correspondente.
    #    t3 acumula a mascara resultante.
    li   t3, 0

    li   t0, KEY_LEFT
    bne  t2, t0, INPUT_CHK_RIGHT
    ori  t3, t3, INPUT_LEFT
    j    INPUT_STORE

INPUT_CHK_RIGHT:
    li   t0, KEY_RIGHT
    bne  t2, t0, INPUT_CHK_UP
    ori  t3, t3, INPUT_RIGHT
    j    INPUT_STORE

INPUT_CHK_UP:
    li   t0, KEY_UP
    bne  t2, t0, INPUT_CHK_DOWN
    ori  t3, t3, INPUT_UP
    j    INPUT_STORE

INPUT_CHK_DOWN:
    li   t0, KEY_DOWN
    bne  t2, t0, INPUT_CHK_JUMP
    ori  t3, t3, INPUT_DOWN
    j    INPUT_STORE

INPUT_CHK_JUMP:
    li   t0, KEY_JUMP
    bne  t2, t0, INPUT_CHK_SHOOT
    ori  t3, t3, INPUT_JUMP
    j    INPUT_STORE

INPUT_CHK_SHOOT:
    li   t0, KEY_SHOOT
    bne  t2, t0, INPUT_CHK_SWAP
    ori  t3, t3, INPUT_SHOOT
    j    INPUT_STORE

INPUT_CHK_SWAP:
    li   t0, KEY_SWAP
    bne  t2, t0, INPUT_STORE     # tecla nao mapeada -> mascara 0
    ori  t3, t3, INPUT_SWAP

INPUT_STORE:
    sw   t3, GS_input_bits(t4)

INPUT_READ_END:
    ret
