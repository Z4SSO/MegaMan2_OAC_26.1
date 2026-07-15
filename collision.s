# ==================================================================== #
#  collision.s  --  Colisoes do jogo (COLLISION_UPDATE)   [Bloco 4]    #
#                                                                      #
#  Regra de solidez (guia do mapa): tile != 21 e SOLIDO; 21 e fundo.   #
#  Fora do mapa: lateral/abaixo = solido (parede/rede invisivel --     #
#  isso da o clamp de mundo do player de graca); acima = ar (pulo).    #
#                                                                      #
#  Ordem por frame (chamado apos todo movimento, antes da camera):     #
#    0. tick dos i-frames do player (PLAYER_invuln--)                  #
#    1. player   <-> mapa   (resolve + alimenta PLAYER_on_ground)      #
#    2. inimigos <-> mapa   (corredor ganha chao real; voador paredes) #
#    3. tiros    <-> mapa   (tiro some ao acertar tile solido)         #
#       tiros    <-> inimigos (hp--; hp==0 -> inimigo morre)           #
#    4. player   <-> inimigos (dano 1 + 90 frames de i-frames;         #
#       health==0 -> GS_scene = SCENE_GAMEOVER, musica troca sozinha)  #
#                                                                      #
#  RESOLVE_MAP: resolvedor generico p/ qualquer entidade com bloco     #
#  PH_* no inicio (player e inimigos usam o MESMO codigo). Resolve     #
#  vertical primeiro (pes/cabeca, 3 pontos de amostra na aresta),      #
#  depois horizontal (aresta de avanco conforme sinal de vx). SO       #
#  escreve a posicao de volta quando ha colisao (snap) -- sem colisao, #
#  a posicao float fica intocada (sem perda de sub-pixel).             #
# -------------------------------------------------------------------- #
#  Registradores:                                                      #
#   TILE_SOLID : entra a3=x_px, a4=y_px (mundo); sai a5=1 solido.      #
#                usa t4,t5,t6,a7. NAO toca t0..t3, a0..a2, a6.         #
#   RESOLVE_MAP: entra a0=ptr PH_*, a1=W, a2=H; sai a0=1 se no chao.   #
#                usa t0..t4, a6, ft0..ft3. Salva ra (chama TILE_SOLID).#
# ==================================================================== #

.text

# -------------------------------------------------------------------- #
#  TILE_SOLID -- consulta de solidez no CURRENT_MAP                    #
# -------------------------------------------------------------------- #
TILE_SOLID:
    bltz a3, TS_SOLID          # x < 0: parede esquerda do mundo
    bltz a4, TS_AIR            # y < 0: acima do mapa = ar (pulo livre)

    la   t4, CURRENT_MAP
    lw   t4, 0(t4)             # t4 = endereco do mapa ativo
    lbu  t5, 1(t4)             # t5 = largura (tiles)
    srai t6, a3, 4             # t6 = coluna (x/16)
    bge  t6, t5, TS_SOLID      # alem da borda direita: parede

    lbu  a5, 2(t4)             # a5 = altura (tiles) [scratch temporario]
    srai a7, a4, 4             # a7 = linha (y/16)
    bge  a7, a5, TS_SOLID      # abaixo do mapa: solido (rede de seguranca)

    mul  a7, a7, t5            # linha * largura
    add  a7, a7, t6            # + coluna
    add  t4, t4, a7
    lbu  t6, 3(t4)             # tile = mapa[3 + linha*largura + coluna]
    li   t5, 21
    beq  t6, t5, TS_AIR        # 21 = fundo (sem colisao)
TS_SOLID:
    li   a5, 1
    ret
TS_AIR:
    li   a5, 0
    ret

# -------------------------------------------------------------------- #
#  RESOLVE_MAP -- resolve entidade (a0=PH_*, a1=W, a2=H) contra o mapa #
# -------------------------------------------------------------------- #
RESOLVE_MAP:
    addi sp, sp, -4
    sw   ra, 0(sp)

    flw  ft0, PH_x(a0)
    fcvt.w.s t0, ft0           # t0 = x (int, mundo)
    flw  ft1, PH_y(a0)
    fcvt.w.s t1, ft1           # t1 = y (int)
    li   a6, 0                 # a6 = flag "no chao" (retorno)

    # ================ VERTICAL (pes ou cabeca) ====================== #
    flw  ft2, PH_vy(a0)
    la   t2, PHYS_ZERO
    flw  ft3, 0(t2)
    flt.s t2, ft2, ft3         # vy < 0 ? (subindo)
    bnez t2, RM_UP

RM_DOWN:                       # caindo/parado: testa a linha dos pes
    add  t3, t1, a2            # t3 = y + H (1a linha abaixo do corpo)
    addi a3, t0, 2             # amostra 1: perto da esquerda
    mv   a4, t3
    call TILE_SOLID
    bnez a5, RM_DOWN_HIT
    srai t4, a1, 1             # W/2
    add  a3, t0, t4            # amostra 2: centro
    mv   a4, t3
    call TILE_SOLID
    bnez a5, RM_DOWN_HIT
    add  a3, t0, a1
    addi a3, a3, -2            # amostra 3: perto da direita
    mv   a4, t3
    call TILE_SOLID
    bnez a5, RM_DOWN_HIT
    j    RM_HORIZ              # nada sob os pes: segue no ar

RM_DOWN_HIT:
    andi t3, t3, -16           # topo da linha de tile atingida
    sub  t1, t3, a2            # y = topo_do_tile - H (assenta os pes)
    fcvt.s.w ft1, t1
    fsw  ft1, PH_y(a0)
    la   t2, PHYS_ZERO
    flw  ft3, 0(t2)
    fsw  ft3, PH_vy(a0)        # zera vy
    li   a6, 1                 # no chao!
    j    RM_HORIZ

RM_UP:                         # subindo: testa a linha da cabeca
    addi a3, t0, 2
    mv   a4, t1
    call TILE_SOLID
    bnez a5, RM_UP_HIT
    srai t4, a1, 1
    add  a3, t0, t4
    mv   a4, t1
    call TILE_SOLID
    bnez a5, RM_UP_HIT
    add  a3, t0, a1
    addi a3, a3, -2
    mv   a4, t1
    call TILE_SOLID
    bnez a5, RM_UP_HIT
    j    RM_HORIZ

RM_UP_HIT:
    andi t3, t1, -16
    addi t1, t3, 16            # y = comeco da linha livre abaixo do teto
    fcvt.s.w ft1, t1
    fsw  ft1, PH_y(a0)
    la   t2, PHYS_ZERO
    flw  ft3, 0(t2)
    fsw  ft3, PH_vy(a0)        # bateu a cabeca: corta a subida

    # ================ HORIZONTAL (aresta de avanco) ================= #
RM_HORIZ:
    flw  ft2, PH_vx(a0)
    la   t2, PHYS_ZERO
    flw  ft3, 0(t2)
    flt.s t2, ft2, ft3         # vx < 0 ? (indo p/ esquerda)
    bnez t2, RM_LEFT
    flt.s t2, ft3, ft2         # vx > 0 ?
    beqz t2, RM_DONE           # vx == 0: sem checagem horizontal

RM_RIGHT:                      # indo p/ direita: testa aresta x+W
    add  t3, t0, a1            # t3 = x + W
    mv   a3, t3
    addi a4, t1, 2             # amostra 1: perto do topo
    call TILE_SOLID
    bnez a5, RM_RIGHT_HIT
    srai t4, a2, 1
    add  a4, t1, t4            # amostra 2: meio do corpo
    mv   a3, t3
    call TILE_SOLID
    bnez a5, RM_RIGHT_HIT
    add  a4, t1, a2
    addi a4, a4, -2            # amostra 3: perto dos pes
    mv   a3, t3
    call TILE_SOLID
    bnez a5, RM_RIGHT_HIT
    j    RM_DONE
RM_RIGHT_HIT:
    andi t3, t3, -16           # borda esquerda do tile atingido
    sub  t0, t3, a1            # x = borda - W (encosta na parede)
    fcvt.s.w ft0, t0
    fsw  ft0, PH_x(a0)
    la   t2, PHYS_ZERO
    flw  ft3, 0(t2)
    fsw  ft3, PH_vx(a0)
    j    RM_DONE

RM_LEFT:                       # indo p/ esquerda: testa aresta x
    mv   t3, t0
    mv   a3, t3
    addi a4, t1, 2
    call TILE_SOLID
    bnez a5, RM_LEFT_HIT
    srai t4, a2, 1
    add  a4, t1, t4
    mv   a3, t3
    call TILE_SOLID
    bnez a5, RM_LEFT_HIT
    add  a4, t1, a2
    addi a4, a4, -2
    mv   a3, t3
    call TILE_SOLID
    bnez a5, RM_LEFT_HIT
    j    RM_DONE
RM_LEFT_HIT:
    andi t3, t3, -16
    addi t0, t3, 16            # x = borda direita do tile + encosta
    fcvt.s.w ft0, t0
    fsw  ft0, PH_x(a0)
    la   t2, PHYS_ZERO
    flw  ft3, 0(t2)
    fsw  ft3, PH_vx(a0)

RM_DONE:
    mv   a0, a6                # retorna flag "no chao"
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# ==================================================================== #
#  COLLISION_UPDATE -- orquestrador (1x por frame)                     #
# ==================================================================== #
COLLISION_UPDATE:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s0, 8(sp)
    sw   s1, 4(sp)
    sw   s2, 0(sp)

    # ---- 0. tick dos i-frames --------------------------------------- #
    la   t0, PLAYER
    lw   t1, PLAYER_invuln(t0)
    beqz t1, CU_PLAYER_MAP
    addi t1, t1, -1
    sw   t1, PLAYER_invuln(t0)

    # ---- 1. player <-> mapa ----------------------------------------- #
CU_PLAYER_MAP:
    la   a0, PLAYER
    li   a1, PLAYER_W
    li   a2, PLAYER_H
    call RESOLVE_MAP
    la   t0, PLAYER
    sw   a0, PLAYER_on_ground(t0)   # chao REAL alimenta o pulo

    # ---- 2. inimigos <-> mapa --------------------------------------- #
    la   s0, ENEMY_POOL
    li   s1, EN_MAX
CU_EN_LOOP:
    lw   t0, EN_active(s0)
    beqz t0, CU_EN_NEXT
    mv   a0, s0
    lw   t1, EN_type(s0)
    li   t2, ENT_FLYER
    li   a1, EN_FLYER_W
    li   a2, EN_FLYER_H
    beq  t1, t2, CU_EN_RES
    li   a1, EN_RUNNER_W
    li   a2, EN_RUNNER_H
CU_EN_RES:
    call RESOLVE_MAP
CU_EN_NEXT:
    addi s0, s0, EN_STRIDE
    addi s1, s1, -1
    bnez s1, CU_EN_LOOP

    # ---- 3. tiros <-> mapa e <-> inimigos ---------------------------- #
    la   s0, PROJ_POOL
    li   s1, PROJ_MAX
CU_PR_LOOP:
    lw   t0, PR_active(s0)
    beqz t0, CU_PR_NEXT
    lw   t1, PR_x(s0)
    lw   t2, PR_y(s0)
    # tiro vs mapa: testa o centro do projetil (8x8 -> +4,+4)
    addi a3, t1, 4
    addi a4, t2, 4
    call TILE_SOLID
    beqz a5, CU_PR_VS_EN
    sw   zero, PR_active(s0)       # bateu na parede: some
    j    CU_PR_NEXT

CU_PR_VS_EN:                       # tiro vs inimigos (AABB)
    la   s2, ENEMY_POOL
    li   t3, EN_MAX
CU_PE_LOOP:
    lw   t4, EN_active(s2)
    beqz t4, CU_PE_NEXT
    flw  ft0, PH_x(s2)
    fcvt.w.s t4, ft0               # t4 = inimigo x
    flw  ft1, PH_y(s2)
    fcvt.w.s t5, ft1               # t5 = inimigo y
    lw   t0, EN_type(s2)           # altura por tipo (largura 32 p/ ambos)
    li   t6, EN_FLYER_H
    li   a6, ENT_FLYER
    beq  t0, a6, CU_PE_BOX
    li   t6, EN_RUNNER_H
CU_PE_BOX:
    # sobreposicao X: proj(t1,8) vs inimigo(t4,32)
    addi a6, t4, 32
    bge  t1, a6, CU_PE_NEXT        # proj a direita do inimigo
    addi a6, t1, PROJ_W
    bge  t4, a6, CU_PE_NEXT        # inimigo a direita do proj
    # sobreposicao Y: proj(t2,8) vs inimigo(t5,t6)
    add  a6, t5, t6
    bge  t2, a6, CU_PE_NEXT
    addi a6, t2, PROJ_H
    bge  t5, a6, CU_PE_NEXT
    # ACERTOU: tiro some, hp--; hp==0 -> inimigo morre
    sw   zero, PR_active(s0)
    lw   a6, EN_hp(s2)
    addi a6, a6, -1
    sw   a6, EN_hp(s2)
    bgtz a6, CU_PR_NEXT
    sw   zero, EN_active(s2)       # morreu: libera o slot
    j    CU_PR_NEXT
CU_PE_NEXT:
    addi s2, s2, EN_STRIDE
    addi t3, t3, -1
    bnez t3, CU_PE_LOOP
CU_PR_NEXT:
    addi s0, s0, PROJ_STRIDE
    addi s1, s1, -1
    bnez s1, CU_PR_LOOP

    # ---- 4. player <-> inimigos (dano com i-frames) ------------------ #
    la   t0, PLAYER
    lw   t1, PLAYER_invuln(t0)
    bnez t1, CU_END                # invulneravel: sem dano neste frame
    flw  ft0, PH_x(t0)
    fcvt.w.s t1, ft0               # t1 = player x
    flw  ft1, PH_y(t0)
    fcvt.w.s t2, ft1               # t2 = player y
    la   s0, ENEMY_POOL
    li   s1, EN_MAX
CU_PL_LOOP:
    lw   t3, EN_active(s0)
    beqz t3, CU_PL_NEXT
    flw  ft0, PH_x(s0)
    fcvt.w.s t3, ft0               # t3 = inimigo x
    flw  ft1, PH_y(s0)
    fcvt.w.s t4, ft1               # t4 = inimigo y
    lw   t5, EN_type(s0)
    li   t6, EN_FLYER_H
    li   a6, ENT_FLYER
    beq  t5, a6, CU_PL_BOX
    li   t6, EN_RUNNER_H
CU_PL_BOX:
    # sobreposicao: player(t1,t2,32,48) vs inimigo(t3,t4,32,t6)
    addi a6, t3, 32
    bge  t1, a6, CU_PL_NEXT
    addi a6, t1, PLAYER_W
    bge  t3, a6, CU_PL_NEXT
    add  a6, t4, t6
    bge  t2, a6, CU_PL_NEXT
    addi a6, t2, PLAYER_H
    bge  t4, a6, CU_PL_NEXT
    # DANO por TIPO (voador != corredor), + 90 frames de i-frames.
    # (t5 ainda tem EN_type: reusa em vez de reler do slot)
    li   a6, ENT_FLYER
    li   t3, EN_FLYER_DMG
    beq  t5, a6, CU_PL_DMG
    li   t3, EN_RUNNER_DMG
CU_PL_DMG:
    la   t5, PLAYER
    lw   t6, PLAYER_health(t5)
    sub  t6, t6, t3                # health -= dano do tipo
    sw   t6, PLAYER_health(t5)
    li   a6, 90
    sw   a6, PLAYER_invuln(t5)
    bgtz t6, CU_END                # ainda vivo
    la   t5, GAME_STATE            # morreu: cena GAMEOVER
    li   t6, SCENE_GAMEOVER        # (a musica troca sozinha via MUSIC_SELECT)
    sw   t6, GS_scene(t5)
    j    CU_END
CU_PL_NEXT:
    addi s0, s0, EN_STRIDE
    addi s1, s1, -1
    bnez s1, CU_PL_LOOP

CU_END:
    lw   ra, 12(sp)
    lw   s0, 8(sp)
    lw   s1, 4(sp)
    lw   s2, 0(sp)
    addi sp, sp, 16
    ret
