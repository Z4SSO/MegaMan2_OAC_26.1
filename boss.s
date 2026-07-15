# ==================================================================== #
#  boss.s  --  CHEFAO (req 8, 3o tipo de inimigo)                      #
#                                                                      #
#  Padrao de movimento inspirado no Savage Beastfly (Hollow Knight:    #
#  Silksong): o chefe fica num canto da arena, ajusta a altura, trava  #
#  a mira, e da uma VARREDURA horizontal ate a parede oposta. Repete   #
#  alternando o modo de mira num ciclo de 4 passos (BS_step):          #
#                                                                      #
#    passo 0: TRACKING  -- persegue o Y do player em tempo real        #
#             (ataque 1 do concept: mira viva, trava, dash)            #
#    passo 1: CHAO      -- varredura rasteira (pule por cima!)         #
#    passo 2: ALTO      -- do lado oposto, passa POR CIMA do player    #
#             em pe (fique parado / nao pule!)                         #
#    passo 3: CHAO      -- rasteira de novo                            #
#             ...e volta ao passo 0.                                   #
#  Os passos 1-3 sao o "ataque 2" do concept: alturas fixas, e o lado  #
#  de origem alterna sozinho porque cada varredura termina na parede   #
#  oposta.                                                             #
#                                                                      #
#  ------------------- FSM (campo EN_fsm do slot) -------------------  #
#    BF_TRACK -> sprite BOSS_IDLE    : no canto, ajustando o Y-alvo    #
#    BF_AIM   -> sprite BOSS_PREPARE : mira TRAVADA, telegrafa parado  #
#    BF_DASH  -> sprite BOSS_ATTACK  : varredura ate a parede oposta   #
#  (o render_entities.s mapeia estado->sprite; valores BF_* nao        #
#   colidem com ENF_* porque o TIPO ja separa os automatos)            #
#                                                                      #
#  ------------------- POR QUE CINEMATICO ---------------------------  #
#  O boss NAO usa PHYSICS_STEP nem RESOLVE_MAP: a posicao e movida     #
#  diretamente (velocidade constante, alvos clampados nas constantes   #
#  BOSS_* medidas da matriz do Map_BOSS). Motivo: o padrao e todo      #
#  coreografado -- gravidade o derrubaria do voo e a colisao de mapa   #
#  pararia a varredura na parede com "snap" de tile em vez de no       #
#  ponto exato do canto. ENEMY_UPDATE e a secao 2 do collision.s       #
#  PULAM o tipo ENT_BOSS por isso.                                     #
#                                                                      #
#  ------------------- O QUE VEM DO POOL ----------------------------  #
#  O boss vive num slot do ENEMY_POOL (tipo ENT_BOSS). De graca:       #
#  tiro<->boss (secao 3 da colisao, com caixa 64x64), contato<->player #
#  (secao 4, dano BOSS_DMG) e o desenho na 2a passada do               #
#  render_entities.s. A MORTE do boss (hp<=0 na secao 3) seta          #
#  SCENE_WIN direto -- e a condicao de vitoria do jogo.                #
# -------------------------------------------------------------------- #
#  Convencao: prologo/epilogo de pilha; offsets .eqv; flt.s (nunca     #
#  fgt.s); s0 = slot do boss (callee-saved, sobrevive a calls).        #
# ==================================================================== #

.text

# ==================================================================== #
#  BOSS_SPAWN  --  poe o chefao no pool. Chamado por LEVEL_ENTER_BOSS  #
#  (level.s) DEPOIS do POOL_CLEAR_ALL -> o slot 0 esta garantidamente  #
#  livre, entao escreve direto nele.                                   #
#  Nao recebe argumentos (posicao/hp vem das constantes BOSS_*).       #
# ==================================================================== #
BOSS_SPAWN:
    la   t0, ENEMY_POOL          # slot 0 (pool recem-limpo)

    li   t1, ENT_BOSS
    sw   t1, EN_type(t0)
    li   t1, 1
    sw   t1, EN_active(t0)
    li   t1, BF_TRACK            # comeca perseguindo o Y do player
    sw   t1, EN_fsm(t0)
    li   t1, BOSS_HP
    sw   t1, EN_hp(t0)
    li   t1, DIR_LEFT            # na parede direita -> proxima varredura
    sw   t1, EN_dir(t0)          # vai para a ESQUERDA
    sw   zero, EN_anim(t0)

    # posicao inicial (parede direita, meia altura), int -> float
    li   t1, BOSS_SPAWN_X
    fcvt.s.w ft0, t1
    fsw  ft0, PH_x(t0)
    li   t1, BOSS_SPAWN_Y
    fcvt.s.w ft0, t1
    fsw  ft0, PH_y(t0)

    # zera o resto do bloco de fisica (ninguem integra o boss, mas
    # deixar lixo em vx/vy seria bomba-relogio se algo mudar)
    la   t1, PHYS_ZERO
    flw  ft0, 0(t1)
    fsw  ft0, PH_vx(t0)
    fsw  ft0, PH_vy(t0)
    fsw  ft0, PH_ax(t0)
    fsw  ft0, PH_ay(t0)
    fsw  ft0, PH_vx_max(t0)
    fsw  ft0, PH_vy_max(t0)

    # estado do padrao: passo 0 (tracking), timer cheio, alvo = spawn Y
    la   t1, BOSS_STATE
    sw   zero, BS_step(t1)
    li   t2, BOSS_TRACK_FRAMES
    sw   t2, BS_timer(t1)
    li   t2, BOSS_SPAWN_Y
    sw   t2, BS_target_y(t1)
    ret

# ==================================================================== #
#  BOSS_UPDATE  --  avanca a FSM do chefao. Chamado 1x/frame pelo      #
#  GAME_LOOP, logo apos o ENEMY_UPDATE. Se nao ha boss ativo no pool   #
#  (fases W1/W2, ou boss morto), retorna imediatamente.                #
# ==================================================================== #
BOSS_UPDATE:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # ---- procura o boss no pool (1 no maximo) ----------------------- #
    la   s0, ENEMY_POOL
    li   t1, EN_MAX
BU_FIND:
    lw   t2, EN_active(s0)
    beqz t2, BU_FIND_NEXT
    lw   t2, EN_type(s0)
    li   t3, ENT_BOSS
    beq  t2, t3, BU_FOUND
BU_FIND_NEXT:
    addi s0, s0, EN_STRIDE
    addi t1, t1, -1
    bnez t1, BU_FIND
    j    BU_END                  # sem boss nesta fase: nada a fazer

BU_FOUND:
    lw   t0, EN_fsm(s0)
    li   t1, BF_TRACK
    beq  t0, t1, BU_TRACK
    li   t1, BF_AIM
    beq  t0, t1, BU_AIM
    li   t1, BF_DASH
    beq  t0, t1, BU_DASH
    j    BU_END                  # estado desconhecido (defensivo)

# ==================== BF_TRACK: persegue o Y-alvo =================== #
BU_TRACK:
    # ---- 1. de que lado estou? define a direcao da PROXIMA varredura #
    # (o sprite ja se vira para o alvo; parede esq -> vai p/ direita)
    flw  ft0, PH_x(s0)
    fcvt.w.s t1, ft0             # t1 = x atual (int)
    li   t2, 128                 # meio da faixa util [16, 240]
    li   t3, DIR_LEFT            # na parede direita: varre p/ esquerda
    bgt  t1, t2, BU_TRK_DIR_OK
    li   t3, DIR_RIGHT           # na parede esquerda: varre p/ direita
BU_TRK_DIR_OK:
    sw   t3, EN_dir(s0)

    # ---- 2. calcula o Y-alvo conforme o passo do padrao ------------- #
    la   t0, BOSS_STATE
    lw   t1, BS_step(t0)
    beqz t1, BU_TRK_Y_PLAYER     # passo 0: tracking do player
    li   t2, 2
    beq  t1, t2, BU_TRK_Y_HIGH   # passo 2: passada alta
    li   t2, BOSS_GROUND_Y       # passos 1 e 3: rasteira
    j    BU_TRK_Y_SET
BU_TRK_Y_HIGH:
    li   t2, BOSS_HIGH_Y
    j    BU_TRK_Y_SET
BU_TRK_Y_PLAYER:
    # alvo = centro do player alinhado ao centro do boss:
    #   target = (player.y + PLAYER_H/2) - BOSS_H/2 = player.y + 24 - 32
    la   t3, PLAYER
    flw  ft1, PH_y(t3)
    fcvt.w.s t2, ft1
    addi t2, t2, -8              # 24 - 32 = -8
    # clamp na faixa voavel [BOSS_Y_MIN, BOSS_Y_MAX]
    li   t3, BOSS_Y_MIN
    bge  t2, t3, BU_TRK_CLMP_HI
    mv   t2, t3
BU_TRK_CLMP_HI:
    li   t3, BOSS_Y_MAX
    ble  t2, t3, BU_TRK_Y_SET
    mv   t2, t3
BU_TRK_Y_SET:
    sw   t2, BS_target_y(t0)     # (re)mira -- no passo 0 muda todo frame

    # ---- 3. move o Y na direcao do alvo (velocidade constante) ------ #
    flw  ft0, PH_y(s0)
    fcvt.w.s t3, ft0             # t3 = y atual (int)
    sub  t4, t2, t3              # t4 = alvo - atual
    li   t5, 2                   # |passo| do TRACK em int (== 2.0 float)
    blt  t4, t5, BU_TRK_CHK_NEG
    # alvo bem abaixo: desce
    la   t5, BOSS_TRACK_SPD
    flw  ft1, 0(t5)
    fadd.s ft0, ft0, ft1
    fsw  ft0, PH_y(s0)
    j    BU_TRK_TIMER
BU_TRK_CHK_NEG:
    li   t5, -2
    bgt  t4, t5, BU_TRK_SNAP     # |diff| < 2: chegou (snap)
    # alvo bem acima: sobe
    la   t5, BOSS_TRACK_SPD
    flw  ft1, 0(t5)
    fsub.s ft0, ft0, ft1
    fsw  ft0, PH_y(s0)
    j    BU_TRK_TIMER
BU_TRK_SNAP:
    fcvt.s.w ft0, t2             # cola exatamente no alvo (sem oscilar)
    fsw  ft0, PH_y(s0)

BU_TRK_TIMER:
    # ---- 4. timer do estado; so avanca p/ AIM se JA chegou no alvo -- #
    # (passos fixos: garante que a rasteira sai rente ao chao mesmo se
    #  o timer estourar antes de a altura ser alcancada)
    lw   t1, BS_timer(t0)
    beqz t1, BU_TRK_TRY_AIM
    addi t1, t1, -1
    sw   t1, BS_timer(t0)
    j    BU_END
BU_TRK_TRY_AIM:
    # Passo 0 (tracking do player): trava ONDE ESTIVER quando o timer
    # zera -- exigir "chegou" deixaria um player saltitante adiar o
    # lock para sempre (o alvo se move todo frame). E o "trava a mira"
    # do concept: perseguiu por BOSS_TRACK_FRAMES, mirou, foi.
    lw   t1, BS_step(t0)
    beqz t1, BU_GOTO_AIM
    # Passos fixos (chao/alto): so trava quando CHEGOU na altura -- a
    # rasteira tem que sair rente ao chao mesmo que o timer estoure
    # antes. t4 = (alvo - y) medido ANTES do movimento deste frame;
    # apos o snap de um frame anterior ele vale exatamente 0.
    bnez t4, BU_END
BU_GOTO_AIM:
    li   t1, BF_AIM
    sw   t1, EN_fsm(s0)
    li   t1, BOSS_AIM_FRAMES
    sw   t1, BS_timer(t0)
    j    BU_END

# ==================== BF_AIM: telegrafa parado ====================== #
BU_AIM:
    la   t0, BOSS_STATE
    lw   t1, BS_timer(t0)
    beqz t1, BU_GOTO_DASH
    addi t1, t1, -1
    sw   t1, BS_timer(t0)
    j    BU_END
BU_GOTO_DASH:
    li   t1, BF_DASH
    sw   t1, EN_fsm(s0)
    # TODO(compositor): trocar por um SFX_BOSS_DASH proprio quando o
    # efeito chegar; por ora reusa o whoosh do dash do player.
    li   a0, SFX_DASH
    call SFX_PLAY                # (s0 e callee-saved: sobrevive)
    j    BU_END

# ==================== BF_DASH: varredura horizontal ================= #
BU_DASH:
    la   t1, BOSS_DASH_SPD
    flw  ft1, 0(t1)
    flw  ft0, PH_x(s0)
    lw   t2, EN_dir(s0)
    li   t3, DIR_LEFT
    beq  t2, t3, BU_DASH_LEFT

    # ---- varrendo para a DIREITA ------------------------------------ #
    fadd.s ft0, ft0, ft1
    fsw  ft0, PH_x(s0)
    fcvt.w.s t2, ft0
    li   t3, BOSS_X_RIGHT
    blt  t2, t3, BU_END          # ainda em transito
    fcvt.s.w ft0, t3             # chegou: cola na parede direita
    fsw  ft0, PH_x(s0)
    j    BU_ARRIVE

BU_DASH_LEFT:
    fsub.s ft0, ft0, ft1
    fsw  ft0, PH_x(s0)
    fcvt.w.s t2, ft0
    li   t3, BOSS_X_LEFT
    bgt  t2, t3, BU_END          # ainda em transito
    fcvt.s.w ft0, t3             # chegou: cola na parede esquerda
    fsw  ft0, PH_x(s0)

BU_ARRIVE:
    # proxima etapa do padrao: passo = (passo + 1) & 3, volta ao TRACK
    la   t0, BOSS_STATE
    lw   t1, BS_step(t0)
    addi t1, t1, 1
    andi t1, t1, 3               # 0,1,2,3,0,1,... (padrao ciclico)
    sw   t1, BS_step(t0)
    li   t1, BOSS_TRACK_FRAMES
    sw   t1, BS_timer(t0)
    li   t1, BF_TRACK
    sw   t1, EN_fsm(s0)
    # (EN_dir sera recalculado no 1o frame do TRACK pela posicao)

BU_END:
    lw   ra, 4(sp)
    lw   s0, 0(sp)
    addi sp, sp, 8
    ret