# ==================================================================== #
#  items.s  --  Itens coletaveis de cura/recarga (req 6, 0,5)          #
#                                                                      #
#  Duas responsabilidades, ambas chamadas por collision.s (o item e    #
#  fundamentalmente uma colisao -- mesmo padrao do plano em "Pendencias"#
#  do handoff: "pool simples estilo projetil + AABB com player"):      #
#                                                                      #
#    1. ITEM_DROP (chamada 1x por morte de inimigo, de dentro de       #
#       COLLISION_UPDATE/CU_PE_BOX): ocupa um slot livre do ITEM_POOL  #
#       centralizado na caixa do inimigo morto. Tipo sorteado 50/50.   #
#    2. ITEM_PICKUP_UPDATE (chamada 1x por frame, novo passo 5 de      #
#       COLLISION_UPDATE): AABB player x cada item ativo; ao colidir,  #
#       aplica o efeito por tipo e libera o slot.                      #
#                                                                      #
#  Itens sao ESTATICOS (sem fisica/velocidade) -- ficam parados no ar  #
#  onde o inimigo morreu ate serem coletados. Sem timeout por ora.     #
# -------------------------------------------------------------------- #
#  Structs/constantes (ITEM_POOL, IT_*, ITEM_TYPE_*, ITEM_*_AMOUNT,    #
#  sprites) vivem em state.s, mesmo padrao do PROJ_POOL/ENEMY_POOL.    #
# ==================================================================== #

.text

# -------------------------------------------------------------------- #
#  ITEM_DROP -- spawna 1 item no centro da caixa de um inimigo morto   #
#  Entrada: a0=x, a1=y, a2=w, a3=h (caixa do inimigo, mundo, pixel     #
#           inteiro -- o chamador ja converteu float->int).            #
#  Se o ITEM_POOL estiver cheio (6 itens ja no chao), o drop e         #
#  perdido silenciosamente -- nao trava o jogo, so um dropo raro some. #
#  Chama Random2 (SYSTEMv24.s): salva ra/s0..s2.                       #
# -------------------------------------------------------------------- #
ITEM_DROP:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s0, 8(sp)
    sw   s1, 4(sp)
    sw   s2, 0(sp)

    # centro do inimigo (independe de qual slot vamos usar)
    srai t0, a2, 1
    add  s0, a0, t0          # s0 = centro X
    srai t0, a3, 1
    add  s1, a1, t0          # s1 = centro Y

    # ---- procura o 1o slot livre do ITEM_POOL ----------------------- #
    la   t0, ITEM_POOL
    li   t1, ITEM_MAX
ID_FIND:
    lw   t2, IT_active(t0)
    beqz t2, ID_SPAWN
    addi t0, t0, ITEM_STRIDE
    addi t1, t1, -1
    bnez t1, ID_FIND
    j    ID_END               # pool cheio: descarta este drop

ID_SPAWN:
    mv   s2, t0                # s2 = slot escolhido (sobrevive ao call)

    li   a1, 2                 # sorteia tipo: Random2(bound=2) -> 0 ou 1
    call Random2                #   0 = ITEM_TYPE_HEAL, 1 = ITEM_TYPE_CHARGE
    sw   a0, IT_type(s2)

    li   t2, 1
    sw   t2, IT_active(s2)

    li   t2, ITEM_W
    srai t2, t2, 1
    sub  t3, s0, t2             # x = centro_x - ITEM_W/2
    sw   t3, IT_x(s2)

    li   t2, ITEM_H
    srai t2, t2, 1
    sub  t3, s1, t2             # y = centro_y - ITEM_H/2
    sw   t3, IT_y(s2)

ID_END:
    lw   ra, 12(sp)
    lw   s0, 8(sp)
    lw   s1, 4(sp)
    lw   s2, 0(sp)
    addi sp, sp, 16
    ret

# -------------------------------------------------------------------- #
#  ITEM_PICKUP_UPDATE -- player <-> item (AABB), aplica cura/recarga   #
#  Chamada 1x por frame por COLLISION_UPDATE (passo 5, depois do dano  #
#  de contato). Leaf: nao chama ninguem, sem pilha.                    #
#  Cura clampa em PLAYER_max_hp; recarga clampa em                     #
#  PLAYER_ability_charge_max (valores altos de proposito -- ver        #
#  comentario em state.s: usar habilidade de movimentacao e natural e  #
#  deve ser encorajado, so o overuse e punido).                        #
#  Usa t0..t6, a3..a6.                                                 #
# -------------------------------------------------------------------- #
ITEM_PICKUP_UPDATE:
    # Passou a CHAMAR SFX_PLAY (som de item coletado) -> deixou de ser leaf:
    # precisa de pilha pro ra. O cursor do loop (t3) e o contador (t4) sao
    # temporarios e o SFX_PLAY usa t0..t5, entao eles migraram para s0/s1
    # (callee-saved), que sobrevivem ao call.
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s0, 4(sp)
    sw   s1, 0(sp)

    la   t0, PLAYER
    flw  ft0, PH_x(t0)
    fcvt.w.s t1, ft0           # t1 = player x (mundo, int)
    flw  ft1, PH_y(t0)
    fcvt.w.s t2, ft1           # t2 = player y

    la   s0, ITEM_POOL
    li   s1, ITEM_MAX
IPU_LOOP:
    lw   t5, IT_active(s0)
    beqz t5, IPU_NEXT

    lw   t6, IT_x(s0)
    # sobreposicao X: player(t1,PLAYER_W) vs item(t6,ITEM_W)
    addi a3, t6, ITEM_W
    bge  t1, a3, IPU_NEXT       # player a direita do item
    addi a3, t1, PLAYER_W
    bge  t6, a3, IPU_NEXT       # item a direita do player

    lw   a4, IT_y(s0)
    # sobreposicao Y: player(t2,PLAYER_H) vs item(a4,ITEM_H)
    addi a3, a4, ITEM_H
    bge  t2, a3, IPU_NEXT
    addi a3, t2, PLAYER_H
    bge  a4, a3, IPU_NEXT

    # COLETOU: libera o slot e aplica o efeito conforme IT_type
    sw   zero, IT_active(s0)
    lw   a5, IT_type(s0)
    li   a6, ITEM_TYPE_HEAL
    bne  a5, a6, IPU_CHARGE

IPU_HEAL:
    la   a6, PLAYER
    lw   a3, PLAYER_health(a6)
    li   a4, ITEM_HEAL_AMOUNT
    add  a3, a3, a4
    lw   a4, PLAYER_max_hp(a6)
    blt  a3, a4, IPU_HEAL_SET
    mv   a3, a4                 # clamp no maximo
IPU_HEAL_SET:
    sw   a3, PLAYER_health(a6)
    li   a0, SFX_ITEM           # som de item coletado (sfx.s)
    call SFX_PLAY
    j    IPU_NEXT

IPU_CHARGE:
    la   a6, PLAYER
    lw   a3, PLAYER_ability_charge(a6)
    li   a4, ITEM_CHARGE_AMOUNT
    add  a3, a3, a4
    lw   a4, PLAYER_ability_charge_max(a6)
    blt  a3, a4, IPU_CHARGE_SET
    mv   a3, a4                 # clamp no maximo
IPU_CHARGE_SET:
    sw   a3, PLAYER_ability_charge(a6)
    li   a0, SFX_ITEM           # som de item coletado (sfx.s)
    call SFX_PLAY

IPU_NEXT:
    # o SFX_PLAY acima pode ter destruido t0..t2 (player x/y); recarrega
    # antes da proxima iteracao comparar a caixa do player com outro item.
    la   t0, PLAYER
    flw  ft0, PH_x(t0)
    fcvt.w.s t1, ft0
    flw  ft1, PH_y(t0)
    fcvt.w.s t2, ft1

    addi s0, s0, ITEM_STRIDE
    addi s1, s1, -1
    bnez s1, IPU_LOOP

IPU_END:
    lw   ra, 8(sp)
    lw   s0, 4(sp)
    lw   s1, 0(sp)
    addi sp, sp, 12
    ret
