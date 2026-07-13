# ==================================================================== #
#  physics.s  --  Engine de fisica generica (RV32F)                    #
#                                                                      #
#  PHYSICS_STEP integra o movimento de UMA entidade qualquer (player,  #
#  inimigo, projetil) a partir do seu componente de fisica (offsets    #
#  PH_* definidos em state.s). E burra de proposito: so aplica o vetor #
#  de movimento; nao conhece "pulo", "chao", "gravidade" nem tipos.    #
#  Toda a esperteza (gravidade assimetrica, coyote, etc.) fica no      #
#  caller, que escreve ax/ay/vx/vy antes de chamar esta rotina.        #
#                                                                      #
#  Modelo (integracao de Euler):                                       #
#    vx += ax ; clamp(vx, +/- vx_max)                                  #
#    vy += ay ; clamp(vy, +/- vy_max)                                  #
#    x  += vx                                                          #
#    y  += vy                                                          #
#                                                                      #
#  PRECISAO: a integracao e so soma de floats (fadd.s). Para as        #
#  magnitudes de um jogo (posicoes ~milhares, velocidades pequenas) o  #
#  erro por frame do float simples e ~1e-4 px, desprezivel. O clamp e  #
#  feito com fmin.s/fmax.s (sem branch, sem multiplicacao). Nenhuma    #
#  multiplicacao/divisao aqui -> nada de perda por ordem de operacao.  #
#  A posicao float e a fonte de verdade; o pixel de render e projetado #
#  dela (fcvt.w.s) no render, recalculado por frame, nunca realimenta. #
# -------------------------------------------------------------------- #
#  Args:  a0 = ponteiro para a entidade (inicio do bloco PH_*)         #
#  Usa:   ft0..ft4 (caller-saved float temporaries). Nao toca fs*.     #
#         Nao chama ninguem -> nao salva ra. So le/escreve memoria.    #
# ==================================================================== #

.text

PHYSICS_STEP:
    # ---- Eixo X: vx += ax, depois clamp em +/- vx_max -------------- #
    flw   ft0, PH_vx(a0)         # ft0 = vx
    flw   ft1, PH_ax(a0)         # ft1 = ax
    fadd.s ft0, ft0, ft1         # vx += ax   (soma exata o suficiente)

    flw   ft2, PH_vx_max(a0)     # ft2 = +vx_max
    fneg.s ft3, ft2              # ft3 = -vx_max
    fmin.s ft0, ft0, ft2         # vx = min(vx, +max)
    fmax.s ft0, ft0, ft3         # vx = max(vx, -max)  -> clamp simetrico
    fsw   ft0, PH_vx(a0)         # guarda vx clampeado (ft0 reusado abaixo)

    # ---- Eixo Y: vy += ay, depois clamp em +/- vy_max -------------- #
    flw   ft1, PH_vy(a0)         # ft1 = vy
    flw   ft4, PH_ay(a0)         # ft4 = ay
    fadd.s ft1, ft1, ft4         # vy += ay

    flw   ft2, PH_vy_max(a0)     # ft2 = +vy_max
    fneg.s ft3, ft2              # ft3 = -vy_max
    fmin.s ft1, ft1, ft2         # vy = min(vy, +max)
    fmax.s ft1, ft1, ft3         # vy = max(vy, -max)
    fsw   ft1, PH_vy(a0)         # guarda vy clampeado

    # ---- Integra posicao: x += vx, y += vy ------------------------- #
    # ft0 ainda tem vx, ft1 ainda tem vy (clampeados).
    flw   ft2, PH_x(a0)
    fadd.s ft2, ft2, ft0         # x += vx
    fsw   ft2, PH_x(a0)

    flw   ft3, PH_y(a0)
    fadd.s ft3, ft3, ft1         # y += vy
    fsw   ft3, PH_y(a0)

    ret
