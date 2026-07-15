# ==================================================================== #
#  level.s  --  Transicao de fase / porta (DOOR_UPDATE)   [Requisito 7]#
#                                                                      #
#  Fluxo do jogo (pedido explicito do usuario):                       #
#    MENU -> Map_W1 -> (porta) -> Map_W2 -> (porta) -> Map_BOSS ->     #
#    (gatilho placeholder) -> WIN                                     #
#  NAO existe porta de volta -- uma vez que LEVEL_ENTER_W2 troca o     #
#  CURRENT_MAP, o Map_W1 simplesmente deixa de existir para o jogo     #
#  (nao ha nenhum codigo que aponte de volta pra ele). Trocar de fase  #
#  para tras exigiria escrever esse codigo, que nao existe -- e assim  #
#  que a garantia "nao da pra voltar" e cumprida.                      #
#                                                                      #
#  Transicao FLUIDA (como no MegaMan): a porta nao troca o mapa na     #
#  hora. DOOR_UPDATE so ARMA a transicao (GS_scene = SCENE_TRANSITION, #
#  guarda o alvo em GS_transition_target, comeca o timer). O GAME_LOOP #
#  entao renderiza tela preta e chama TRANSITION_UPDATE a cada frame;  #
#  quando o timer zera, o mapa/spawn/musica trocam de fato e a cena    #
#  volta a SCENE_GAME -- da o "corte" preto que o MegaMan usa nas      #
#  portas, sem precisar de crop/scroll especial.                       #
#                                                                      #
#  Responsabilidades deste arquivo:                                    #
#    DOOR_UPDATE         -- chamado 1x/frame durante SCENE_GAME. Testa #
#                           a porta (ou o gatilho de vitoria, na fase   #
#                           do boss) e ARMA a transicao/vitoria.        #
#    TRANSITION_UPDATE   -- chamado 1x/frame durante SCENE_TRANSITION. #
#                           conta os frames e dispara o LEVEL_ENTER_*   #
#                           correspondente quando o tempo acaba.        #
#    LEVEL_ENTER_W1/W2/BOSS -- trocam CURRENT_MAP, reposicionam o       #
#                           player, arma a musica da fase, zeram        #
#                           camera e limpam os pools (POOL_CLEAR_ALL).  #
#    DU_PLAYER_HITS_RECT -- AABB generica player x retangulo (porta ou  #
#                           gatilho de vitoria).                        #
#    POOL_CLEAR_ALL      -- libera todos os slots de inimigo/tiro/item  #
#                           (evita que entidades da fase antiga           #
#                           apareçam na fase nova).                      #
# -------------------------------------------------------------------- #
#  Coordenadas de porta/spawn (DOOR_*_X/Y, SPAWN_*_X/Y, WIN_TRIGGER_*)  #
#  vivem em state.s, junto dos outros .eqv de constantes. Foram         #
#  escolhidas lendo a matriz de cada mapa em data.s (procurando chao    #
#  solido perto do fim de cada fase) -- AJUSTAR conforme necessario    #
#  depois de ver no jogo real (nao ha como validar visualmente daqui).  #
# ==================================================================== #

.text

# ==================================================================== #
#  DOOR_UPDATE -- testa a porta da fase atual (ou o gatilho de vitoria #
#  na arena do boss). So roda durante SCENE_GAME (o GAME_LOOP so chama #
#  este subsistema nesse estado).                                      #
# ==================================================================== #
DOOR_UPDATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, GAME_STATE
    lw   t1, GS_level(t0)

    li   t2, LEVEL_W1
    beq  t1, t2, DU_DOOR_W1
    li   t2, LEVEL_W2
    beq  t1, t2, DU_DOOR_W2
    # LEVEL_BOSS: sem porta/gatilho aqui -- vitoria so pela morte do boss (collision.s)
    j    DU_END                # GS_level desconhecido: nao faz nada (defensivo)

DU_DOOR_W1:
    li   a1, DOOR_W1_X
    li   a2, DOOR_W1_Y
    li   a3, DOOR_W
    li   a4, DOOR_H
    call DU_PLAYER_HITS_RECT
    beqz a0, DU_END
    li   a0, LEVEL_W2
    call DU_ARM_TRANSITION
    j    DU_END

DU_DOOR_W2:
    li   a1, DOOR_W2_X
    li   a2, DOOR_W2_Y
    li   a3, DOOR_W
    li   a4, DOOR_H
    call DU_PLAYER_HITS_RECT
    beqz a0, DU_END
    li   a0, LEVEL_BOSS
    call DU_ARM_TRANSITION
    j    DU_END

DU_END:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# -------------------------------------------------------------------- #
#  DU_ARM_TRANSITION -- entra em SCENE_TRANSITION rumo a fase a0        #
# -------------------------------------------------------------------- #
DU_ARM_TRANSITION:
    # Passou a chamar SFX_PLAY -> precisa de pilha pro ra (era leaf).
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   t0, GAME_STATE
    li   t1, SCENE_TRANSITION
    sw   t1, GS_scene(t0)
    sw   a0, GS_transition_target(t0)
    li   t1, TRANSITION_DURATION
    sw   t1, GS_transition_timer(t0)
    li   a0, SFX_DOOR              # som da porta (sfx.s), junto da tela preta
    call SFX_PLAY
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# -------------------------------------------------------------------- #
#  DU_PLAYER_HITS_RECT -- AABB: player (32x48) vs retangulo arbitrario  #
#  Entrada: a1=rect x, a2=rect y, a3=rect w, a4=rect h (mundo, px)      #
#  Saida:   a0 = 1 se colide, 0 caso contrario.                        #
#  Leaf (nao chama ninguem). Usa t0..t3.                                #
# -------------------------------------------------------------------- #
DU_PLAYER_HITS_RECT:
    la   t0, PLAYER
    flw  ft0, PH_x(t0)
    fcvt.w.s t1, ft0            # t1 = player x (mundo, int)
    flw  ft1, PH_y(t0)
    fcvt.w.s t2, ft1            # t2 = player y

    add  t3, a1, a3
    bge  t1, t3, DPH_NO         # player a direita do retangulo
    addi t3, t1, PLAYER_W
    bge  a1, t3, DPH_NO         # retangulo a direita do player

    add  t3, a2, a4
    bge  t2, t3, DPH_NO         # player abaixo do retangulo
    addi t3, t2, PLAYER_H
    bge  a2, t3, DPH_NO         # retangulo abaixo do player

    li   a0, 1
    ret
DPH_NO:
    li   a0, 0
    ret

# ==================================================================== #
#  TRANSITION_UPDATE -- conta a tela preta da porta e troca de mapa    #
#  quando o timer zera. So roda durante SCENE_TRANSITION.              #
# ==================================================================== #
TRANSITION_UPDATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, GAME_STATE
    lw   t1, GS_transition_timer(t0)
    addi t1, t1, -1
    sw   t1, GS_transition_timer(t0)
    bgtz t1, TU_END             # ainda contando: so a tela preta mesmo

    lw   t2, GS_transition_target(t0)
    li   t3, LEVEL_W2
    beq  t2, t3, TU_GO_W2
    li   t3, LEVEL_BOSS
    beq  t2, t3, TU_GO_BOSS
    j    TU_END                 # alvo invalido (defensivo): nao faz nada

TU_GO_W2:
    call LEVEL_ENTER_W2
    j    TU_END
TU_GO_BOSS:
    call LEVEL_ENTER_BOSS

TU_END:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# ==================================================================== #
#  LEVEL_ENTER_W1/W2/BOSS -- carregam a fase de fato (mapa + spawn +    #
#  musica + camera + pools). Chamadas por MENU_UPDATE (scene.s, ao sair#
#  do menu) e por TRANSITION_UPDATE (ao zerar o timer da porta).       #
# ==================================================================== #
LEVEL_ENTER_W1:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   a0, Map_W1
    li   a1, SPAWN_W1_X
    li   a2, SPAWN_W1_Y
    li   a3, LEVEL_W1
    li   a4, MUS_ESTAGIO1
    call LEVEL_ENTER_COMMON
    call ENEMY_SPAWN_INIT       # repovoa os inimigos de teste da fase 1
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

LEVEL_ENTER_W2:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   a0, Map_W2
    li   a1, SPAWN_W2_X
    li   a2, SPAWN_W2_Y
    li   a3, LEVEL_W2
    li   a4, MUS_ESTAGIO2
    call LEVEL_ENTER_COMMON
    # (sem ENEMY_SPAWN_INIT: inimigos da 2a fase ainda nao tem posicoes
    #  definidas -- fica vazia ate essa tabela existir. Ver Pendencias.)
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

LEVEL_ENTER_BOSS:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   a0, Map_BOSS
    li   a1, SPAWN_BOSS_X
    li   a2, SPAWN_BOSS_Y
    li   a3, LEVEL_BOSS
    li   a4, MUS_CHEFAO
    call LEVEL_ENTER_COMMON
    call BOSS_SPAWN            # (fix) faltava spawnar o chefao no pool
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# -------------------------------------------------------------------- #
#  LEVEL_ENTER_COMMON -- rotina compartilhada pelas 3 acima.            #
#  Entrada: a0=endereco do mapa (Map_W1/W2/BOSS)                        #
#           a1=spawn x (int, px)   a2=spawn y (int, px)                 #
#           a3=GS_level a atribuir (LEVEL_*)                            #
#           a4=GS_music_id a pedir (MUS_*)                              #
#  Reseta o player para um estado "limpo" (posicao, velocidade, vida    #
#  cheia, sem i-frames, carga de habilidade cheia) -- consistente com   #
#  um "recomeco de fase", nao um respawn parcial.                       #
# -------------------------------------------------------------------- #
LEVEL_ENTER_COMMON:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, CURRENT_MAP
    sw   a0, 0(t0)

    la   t0, PLAYER
    fcvt.s.w ft0, a1
    fsw  ft0, PH_x(t0)
    fcvt.s.w ft0, a2
    fsw  ft0, PH_y(t0)
    la   t1, PHYS_ZERO
    flw  ft1, 0(t1)
    fsw  ft1, PH_vx(t0)
    fsw  ft1, PH_vy(t0)
    fsw  ft1, PH_ax(t0)
    fsw  ft1, PH_ay(t0)
    li   t2, DIR_RIGHT
    sw   t2, PLAYER_dir(t0)
    sw   zero, PLAYER_status(t0)
    sw   zero, PLAYER_on_ground(t0)
    li   t2, 28
    sw   t2, PLAYER_health(t0)
    sw   t2, PLAYER_max_hp(t0)
    sw   zero, PLAYER_invuln(t0)
    li   t2, PLAYER_ABILITY_CHARGE_MAX
    sw   t2, PLAYER_ability_charge(t0)

    la   t0, GAME_STATE
    sw   zero, GS_cam_x(t0)
    sw   a3, GS_level(t0)
    sw   a4, GS_music_id(t0)
    li   t2, SCENE_GAME
    sw   t2, GS_scene(t0)

    call POOL_CLEAR_ALL

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# ==================================================================== #
#  POOL_CLEAR_ALL -- libera todos os slots de inimigo/tiro/item.        #
#  Chamado em toda troca de fase para a fase nova nao herdar entidades  #
#  da fase anterior. Leaf (nao chama ninguem).                          #
# ==================================================================== #
POOL_CLEAR_ALL:
    la   t0, ENEMY_POOL
    li   t1, EN_MAX
PCA_EN:
    sw   zero, EN_active(t0)
    addi t0, t0, EN_STRIDE
    addi t1, t1, -1
    bnez t1, PCA_EN

    la   t0, PROJ_POOL
    li   t1, PROJ_MAX
PCA_PR:
    sw   zero, PR_active(t0)
    addi t0, t0, PROJ_STRIDE
    addi t1, t1, -1
    bnez t1, PCA_PR

    la   t0, ITEM_POOL
    li   t1, ITEM_MAX
PCA_IT:
    sw   zero, IT_active(t0)
    addi t0, t0, ITEM_STRIDE
    addi t1, t1, -1
    bnez t1, PCA_IT

    ret
