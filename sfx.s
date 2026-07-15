# ==================================================================== #
#  sfx.s  --  MOTOR de efeitos sonoros (SFX_PLAY / SFX_UPDATE)         #
#  [Requisito 1 -- "musica E EFEITOS SONOROS"]                         #
#                                                                      #
#  Mesma arquitetura de 3 camadas da musica, so que sem o arquivo de   #
#  politica (a "politica" do SFX e o proprio evento que o dispara):    #
#    DADOS   -> sfx_data.s   (o compositor mexe so nesse)              #
#    MOTOR   -> sfx.s        (este arquivo)                            #
#    GATILHO -> os subsistemas chamam SFX_PLAY no momento do evento    #
#                                                                      #
#  ------------------- POR QUE NAO REUSAR O PLAY_MUSIC ---------------  #
#  O PLAY_MUSIC (musicFunct.s) guarda o estado de reproducao DENTRO do #
#  dado do canal (ponteiro/timer/flag mutaveis). Isso funciona pra     #
#  musica (1 instancia por canal, sempre a mesma), mas quebraria pro   #
#  SFX: o mesmo efeito dispara varias vezes e nao pode carregar        #
#  estado, senao um tiro cortaria o ponteiro do tiro anterior. Aqui o  #
#  estado vive no SFX_CHANNEL (abaixo), e o dado fica CONSTANTE.       #
#                                                                      #
#  ------------------- CANAL RESERVADO -------------------------------  #
#  A musica usa 3 canais logicos; o SFX usa UM canal proprio, que      #
#  nunca e tocado pelo MUSIC_LOOP. Como a ecall 31 do FPGRARS nao      #
#  recebe numero de canal MIDI (so nota/duracao/instrumento/volume),   #
#  a separacao e por INSTRUMENTO e por tempo: o SFX toca notas curtas  #
#  com instrumentos distintos dos da musica, e a ecall 31 e            #
#  fire-and-forget (nao bloqueia), entao musica e SFX simplesmente     #
#  soam sobrepostos -- que e o comportamento desejado.                 #
#                                                                      #
#  ------------------- 1 SFX POR VEZ (com prioridade) ----------------  #
#  Ha um unico SFX_CHANNEL: so um efeito soa por vez. Se um SFX novo   #
#  chega enquanto outro toca, quem tem PRIORIDADE >= vence (o novo     #
#  interrompe). Sem isso, o tiro (que dispara toda hora) abafaria o    #
#  som de dano. Prioridades vivem no dado (sfx_data.s, word [16]).     #
#  Isso e proposital e suficiente pro escopo: um mixer multi-slot      #
#  soaria confuso em MIDI monofonico e custaria complexidade a toa.    #
#                                                                      #
#  ------------------- NAO BLOQUEIA ----------------------------------  #
#  SFX_UPDATE roda 1x/frame e retorna na hora: ele so dispara a nota   #
#  quando o relogio (ecall 30, ms) passa do timer, exatamente como o   #
#  PLAY_MUSIC faz. Nunca espera em loop -- travaria o jogo.            #
# -------------------------------------------------------------------- #
#  Convencao: SFX_PLAY e leaf (sem pilha). SFX_UPDATE chama ecall,     #
#  entao salva ra.                                                     #
# ==================================================================== #

.data
.align 2

# -------------------------------------------------------------------- #
#  SFX_CHANNEL -- estado de reproducao do UNICO canal de efeito.       #
#  Offsets nomeados em state.s (SC_*), como todo struct do projeto.    #
#    [0]  SC_active   1 = tem efeito tocando agora                     #
#    [4]  SC_ptr      ponteiro pra proxima nota (par nota,duracao)     #
#    [8]  SC_end      endereco de fim das notas                        #
#    [12] SC_timer    momento absoluto (ms) do proximo disparo         #
#    [16] SC_instr    instrumento MIDI do efeito atual                 #
#    [20] SC_vol      volume do efeito atual                           #
#    [24] SC_prio     prioridade do efeito atual (pra comparar)        #
# -------------------------------------------------------------------- #
SFX_CHANNEL:
    .word 0    # SC_active
    .word 0    # SC_ptr
    .word 0    # SC_end
    .word 0    # SC_timer
    .word 0    # SC_instr
    .word 0    # SC_vol
    .word 0    # SC_prio

.text

# ==================================================================== #
#  SFX_PLAY  --  dispara o efeito de id a0 (um SFX_* de state.s).      #
#                                                                      #
#  Entrada: a0 = id do efeito (indice na SFX_TABLE).                   #
#  Saida:   nada. Nao toca a nota aqui -- so ARMA o canal; quem toca   #
#           e o SFX_UPDATE no fim do frame. Assim o custo no ponto do  #
#           evento (dentro da colisao, do tiro...) e minimo, e o som   #
#           sai sempre no mesmo ponto do frame.                        #
#                                                                      #
#  Se ja ha efeito tocando, so substitui se a prioridade do novo for   #
#  >= a do atual (>= e nao > de proposito: dois tiros seguidos devem   #
#  reiniciar o som do tiro, senao o 2o tiro sairia mudo).              #
#                                                                      #
#  Leaf: nao chama ninguem, nao precisa de pilha. Usa t0..t5.          #
#  Seguro chamar de qualquer subsistema, inclusive de dentro de loops. #
# ==================================================================== #
SFX_PLAY:
    # ---- valida o id (defensivo: id fora da tabela = ignora) -------- #
    bltz a0, SP_END
    li   t0, SFX_COUNT
    bge  a0, t0, SP_END

    # ---- busca o bloco de dados: SFX_TABLE + id*4 ------------------- #
    la   t0, SFX_TABLE
    slli t1, a0, 2
    add  t0, t0, t1
    lw   t0, 0(t0)              # t0 = endereco do bloco de 5 words

    lw   t5, 16(t0)             # t5 = prioridade do efeito NOVO

    # ---- ha efeito tocando? compara prioridade ---------------------- #
    la   t1, SFX_CHANNEL
    lw   t2, SC_active(t1)
    beqz t2, SP_ARM             # canal livre: arma direto
    lw   t3, SC_prio(t1)
    blt  t5, t3, SP_END         # novo tem prioridade MENOR: descarta

SP_ARM:
    lw   t2, 0(t0)              # ponteiro da 1a nota
    sw   t2, SC_ptr(t1)
    lw   t2, 4(t0)              # fim das notas
    sw   t2, SC_end(t1)
    lw   t2, 8(t0)              # instrumento
    sw   t2, SC_instr(t1)
    lw   t2, 12(t0)             # volume
    sw   t2, SC_vol(t1)
    sw   t5, SC_prio(t1)        # prioridade
    sw   zero, SC_timer(t1)     # timer 0 = dispara na 1a chance
    li   t2, 1
    sw   t2, SC_active(t1)      # ligado: o SFX_UPDATE assume daqui

SP_END:
    ret

# ==================================================================== #
#  SFX_UPDATE  --  avanca o efeito armado. Chamado 1x/frame pelo       #
#  GAME_LOOP (passo 14), logo depois do MUSIC_LOOP.                    #
#                                                                      #
#  Mesma logica de tempo do PLAY_MUSIC: compara o relogio absoluto     #
#  (ecall 30) com o timer; se ainda nao chegou a hora, retorna sem     #
#  fazer nada (NAO bloqueia). Quando a lista de notas acaba, desliga   #
#  o canal (SC_active = 0) e o proximo SFX_PLAY pode usa-lo.           #
#                                                                      #
#  Chama ecall -> salva ra. Usa t0..t4, a0..a3, a7.                    #
# ==================================================================== #
SFX_UPDATE:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    la   s0, SFX_CHANNEL
    lw   t0, SC_active(s0)
    beqz t0, SU_END              # nenhum efeito tocando: nada a fazer

    # ---- ja passou a hora da proxima nota? -------------------------- #
    li   a7, 30
    ecall                        # a0 = tempo atual em ms
    mv   t1, a0                  # t1 = agora

    lw   t2, SC_timer(s0)
    beqz t2, SU_FIRE             # timer 0 = 1a nota, dispara imediatamente
    blt  t1, t2, SU_END          # ainda nao deu a hora: espera o proximo frame

SU_FIRE:
    # ---- acabou a lista de notas? ----------------------------------- #
    lw   t3, SC_ptr(s0)
    lw   t4, SC_end(s0)
    bge  t3, t4, SU_FINISH

    # ---- toca a nota: ecall 31 (a0 nota, a1 dur, a2 instr, a3 vol) -- #
    lw   a0, 0(t3)               # nota
    lw   a1, 4(t3)               # duracao (ms)
    lw   a2, SC_instr(s0)
    lw   a3, SC_vol(s0)
    li   a7, 31
    ecall                        # fire-and-forget: nao bloqueia o frame

    # ---- agenda a proxima nota: timer = base + duracao -------------- #
    # base = max(timer_antigo, agora) -- mesmo criterio do PLAY_MUSIC:
    # se o efeito atrasou (frame longo), reancora no relogio pra nao
    # acumular divida de tempo e sair tudo de uma vez.
    lw   t2, SC_timer(s0)
    bge  t2, t1, SU_BASE_OK
    mv   t2, t1
SU_BASE_OK:
    add  t2, t2, a1
    sw   t2, SC_timer(s0)

    addi t3, t3, 8               # proximo par (nota, duracao)
    sw   t3, SC_ptr(s0)
    j    SU_END

SU_FINISH:
    sw   zero, SC_active(s0)     # efeito terminou: libera o canal
    sw   zero, SC_prio(s0)

SU_END:
    lw   ra, 4(sp)
    lw   s0, 0(sp)
    addi sp, sp, 8
    ret
