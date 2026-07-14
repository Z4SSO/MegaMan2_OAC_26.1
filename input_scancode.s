# ==================================================================== #
#  input_scancode.s  --  Leitura por scancode PS/2 (SO PARA A DE2)     #
#                                                                      #
#  !!! ATENCAO: esta versao le o Buffer0Teclado, um periferico que so  #
#  existe na PLACA DE2 FISICA. No RARS e no FPGRARS rodando no PC o     #
#  buffer nao e emulado -> o teclado NAO funciona. Use este arquivo    #
#  APENAS ao rodar na DE2. Para desenvolver no PC, use input.s (KDMMIO)#
#                                                                      #
#  Para trocar: no main.s, comente '.include "input.s"' e descomente  #
#  '.include "input_scancode.s"'. So um dos dois por vez (ambos       #
#  definem o label INPUT_READ).                                        #
#                                                                      #
#  Vantagem (na DE2): estado real por tecla via make/break, sem o bug  #
#  do 'd sumir depois do pulo', com multi-tecla verdadeiro.            #
# ==================================================================== #

# -------------------- Scancodes PS/2 (make codes) ------------------- #
# Trocar o layout de controles = mudar SO estes scancodes.
.eqv SC_LEFT   0x1C   # 'a'
.eqv SC_RIGHT  0x23   # 'd'
.eqv SC_UP     0x1D   # 'w'
.eqv SC_DOWN   0x1B   # 's'
.eqv SC_JUMP   0x29   # barra de espaco (space)
.eqv SC_SHOOT  0x3B   # 'j'
.eqv SC_SWAP   0x4B   # 'l'

.eqv BREAK_PREFIX  0xF0   # byte que marca "tecla solta" no scancode anterior

.text

# -------------------------------------------------------------------- #
#  INPUT_READ                                                          #
#  Efeito: atualiza GS_input_bits (estado persistente das teclas) a    #
#  partir de um evento novo do Buffer0Teclado, se houver.              #
#  Usa t0..t6. Nao chama ninguem -> nao salva ra.                      #
# -------------------------------------------------------------------- #
INPUT_READ:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   t6, GAME_STATE

    # ---- Le o buffer e ve se mudou desde a ultima leitura ---------- #
    li   t0, Buffer0Teclado
    lw   t1, 0(t0)               # t1 = valor atual do buffer
    lw   t2, GS_kbd_prev(t6)     # t2 = valor anterior
    beq  t1, t2, IR_END          # nao mudou -> nenhum evento novo; estado persiste
    sw   t1, GS_kbd_prev(t6)     # atualiza o "anterior" para a proxima vez

    # ---- Houve evento: e make (pressao) ou break (soltura)? -------- #
    srli t3, t1, 8
    andi t3, t3, 0xFF            # t3 = scancode anterior (bits 8-15)
    li   t4, BREAK_PREFIX
    andi t5, t1, 0xFF            # t5 = scancode recente (bits 0-7) = a tecla
    beq  t3, t4, IR_RELEASE      # anterior == 0xF0 -> tecla t5 foi SOLTA

    # ---- MAKE: liga o bit da tecla em input_bits ------------------- #
    mv   t0, t5
    call IR_SCAN_TO_MASK         # retorna mascara em a0 (0 se nao mapeada)
    lw   t1, GS_input_bits(t6)
    or   t1, t1, a0              # liga o bit (tecla pressionada)
    sw   t1, GS_input_bits(t6)
    j    IR_END

    # ---- BREAK: desliga o bit da tecla em input_bits --------------- #
IR_RELEASE:
    mv   t0, t5
    call IR_SCAN_TO_MASK         # mascara em a0
    not  a1, a0                  # a1 = ~mascara
    lw   t1, GS_input_bits(t6)
    and  t1, t1, a1              # desliga o bit (tecla solta)
    sw   t1, GS_input_bits(t6)

IR_END:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# -------------------------------------------------------------------- #
#  IR_SCAN_TO_MASK  (sub-rotina folha interna)                         #
#  Entrada: t0 = scancode.  Saida: a0 = mascara INPUT_* (0 se nenhuma).#
#  Nao toca outros registradores alem de a0. Chamada com jal ra.       #
# -------------------------------------------------------------------- #
IR_SCAN_TO_MASK:
    li   a0, 0

    li   t1, SC_LEFT
    bne  t0, t1, ISM_R
    li   a0, INPUT_LEFT
    ret
ISM_R:
    li   t1, SC_RIGHT
    bne  t0, t1, ISM_U
    li   a0, INPUT_RIGHT
    ret
ISM_U:
    li   t1, SC_UP
    bne  t0, t1, ISM_D
    li   a0, INPUT_UP
    ret
ISM_D:
    li   t1, SC_DOWN
    bne  t0, t1, ISM_J
    li   a0, INPUT_DOWN
    ret
ISM_J:
    li   t1, SC_JUMP
    bne  t0, t1, ISM_SH
    li   a0, INPUT_JUMP
    ret
ISM_SH:
    li   t1, SC_SHOOT
    bne  t0, t1, ISM_SW
    li   a0, INPUT_SHOOT
    ret
ISM_SW:
    li   t1, SC_SWAP
    bne  t0, t1, ISM_NONE
    li   a0, INPUT_SWAP
    ret
ISM_NONE:
    ret                          # a0 = 0 (tecla nao mapeada)
