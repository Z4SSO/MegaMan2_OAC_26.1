# ==================================================================== #
#  input.s  --  Leitura do teclado via KDMMIO (PADRAO, PC + DE2)       #
#                                                                      #
#  Le o KDMMIO (teclado traduzido para ASCII) e monta a bitmask das    #
#  teclas ativas em GAME_STATE.input_bits. Funciona no RARS, no        #
#  FPGRARS (PC) E na DE2 -- o KDMMIO e emulado em todos os ambientes,  #
#  entao esta e a versao PADRAO para desenvolvimento e apresentacao.   #
#                                                                      #
#  (Existe tambem input_scancode.s, que le o Buffer0Teclado com estado #
#  real por tecla, mas SO funciona na DE2 fisica -- ver aquele arquivo.#
#  So um dos dois deve ser incluido no main.s por vez.)                #
#                                                                      #
#  LIMITACAO DO KDMMIO: e um buffer de eventos, nao estado de tecla.   #
#  Segurar uma tecla gera auto-repeat com intervalos, e outra tecla    #
#  interrompe esse repeat. Sem tratamento, o movimento picotaria e uma #
#  direcao "sumiria" apos um pulo. Mitigamos com AUTO-HOLD por timeout:#
#  teclas de MOVIMENTO ficam ativas por HELD_TIMEOUT frames apos o     #
#  ultimo evento; teclas de ACAO (pulo/tiro/troca) valem so no frame   #
#  do evento. Nao e estado perfeito como o scancode, mas funciona em   #
#  todo ambiente e deixa o controle jogavel.                           #
# ==================================================================== #

# -------------------- Timeout de tecla segurada --------------------- #
.eqv HELD_TIMEOUT  8    # frames que uma tecla de movimento persiste

# -------------------- Mapa de teclas (ASCII, KDMMIO) ---------------- #
.eqv KEY_LEFT   97    # 'a'
.eqv KEY_RIGHT  100   # 'd'
.eqv KEY_UP     119   # 'w'
.eqv KEY_DOWN   115   # 's'
.eqv KEY_JUMP   32    # barra de espaco (space)
.eqv KEY_SHOOT  106   # 'j'
.eqv KEY_SWAP   108   # 'l'

# Movimento = LEFT|RIGHT|DOWN|UP = 0x01|0x02|0x20|0x40 = 0x63
.eqv MOVE_MASK  0x63

.text

INPUT_READ:
    la   t4, GAME_STATE

    # ---- Ha evento de tecla este frame? (bit 0 do KDMMIO_Ctrl) ----- #
    li   t0, KDMMIO_Ctrl
    lw   t1, 0(t0)
    andi t1, t1, 1
    beqz t1, IR_NO_EVENT

    # ---- Le a tecla ASCII e monta a mascara deste frame ------------ #
    li   t0, KDMMIO_Data
    lw   t2, 0(t0)               # t2 = tecla ASCII
    li   t3, 0

    li   t0, KEY_LEFT
    bne  t2, t0, IR_CHK_RIGHT
    ori  t3, t3, INPUT_LEFT
    j    IR_HAVE_MASK
IR_CHK_RIGHT:
    li   t0, KEY_RIGHT
    bne  t2, t0, IR_CHK_UP
    ori  t3, t3, INPUT_RIGHT
    j    IR_HAVE_MASK
IR_CHK_UP:
    li   t0, KEY_UP
    bne  t2, t0, IR_CHK_DOWN
    ori  t3, t3, INPUT_UP
    j    IR_HAVE_MASK
IR_CHK_DOWN:
    li   t0, KEY_DOWN
    bne  t2, t0, IR_CHK_JUMP
    ori  t3, t3, INPUT_DOWN
    j    IR_HAVE_MASK
IR_CHK_JUMP:
    li   t0, KEY_JUMP
    bne  t2, t0, IR_CHK_SHOOT
    ori  t3, t3, INPUT_JUMP
    j    IR_HAVE_MASK
IR_CHK_SHOOT:
    li   t0, KEY_SHOOT
    bne  t2, t0, IR_CHK_SWAP
    ori  t3, t3, INPUT_SHOOT
    j    IR_HAVE_MASK
IR_CHK_SWAP:
    li   t0, KEY_SWAP
    bne  t2, t0, IR_HAVE_MASK
    ori  t3, t3, INPUT_SWAP

IR_HAVE_MASK:
    # Parte de MOVIMENTO -> vira held_bits e recarrega o timer.
    li   t0, MOVE_MASK
    and  t5, t3, t0
    beqz t5, IR_STORE            # evento foi acao pura (sem movimento)
    sw   t5, GS_held_bits(t4)
    li   t0, HELD_TIMEOUT
    sw   t0, GS_held_timer(t4)

IR_STORE:
    # input_bits = mascara deste evento OR movimento ainda segurado.
    lw   t0, GS_held_bits(t4)
    or   t3, t3, t0
    sw   t3, GS_input_bits(t4)
    ret

    # ---- Sem evento: decai o auto-hold do movimento ---------------- #
IR_NO_EVENT:
    lw   t0, GS_held_timer(t4)
    beqz t0, IR_NO_HOLD
        addi t0, t0, -1
        sw   t0, GS_held_timer(t4)
        lw   t1, GS_held_bits(t4)
        sw   t1, GS_input_bits(t4)
        ret
IR_NO_HOLD:
    sw   zero, GS_held_bits(t4)
    sw   zero, GS_input_bits(t4)
    ret
