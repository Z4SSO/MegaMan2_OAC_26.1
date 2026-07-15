# ==================================================================== #
#  ability.s  --  Troca de habilidade ativa (subsistema ABILITY_UPDATE)#
#  [Requisito 4, 1,5 -- minimo de 2 habilidades trocaveis]             #
#                                                                      #
#  So 2 habilidades, as duas de MOVIMENTACAO (sem 2o tipo de ataque):  #
#    ABILITY_DOUBLEJUMP -- 2o pulo no ar (player.s, PU_AIRBORNE)       #
#    ABILITY_DASH       -- rajada horizontal (player.s, PU_TRY_DASH)   #
#  ABILITY_UPDATE so faz a TROCA (alterna 0<->1 na borda de subida de  #
#  INPUT_SWAP); quem LE PLAYER_ability e GASTA PLAYER_ability_charge   #
#  ao executar a habilidade e o player.s. A carga (req 5) ja aparece   #
#  no HUD (render_hud.s) -- passa a se mexer de verdade a partir de    #
#  agora, que existe algo gastando ela.                                #
#                                                                      #
#  Borda de subida: mesmo padrao de attack.s (GS_input_prev e salvo    #
#  ANTES do INPUT_READ, entao aqui prev = frame anterior).             #
# -------------------------------------------------------------------- #
#  Leaf (nao chama ninguem): sem pilha. Usa t0..t3.                    #
# ==================================================================== #

.text

ABILITY_UPDATE:
    la   t0, GAME_STATE
    lw   t1, GS_input_bits(t0)      # t1 = teclas deste frame
    lw   t2, GS_input_prev(t0)      # t2 = teclas do frame anterior

    andi t3, t1, INPUT_SWAP         # bit de troca neste frame
    beqz t3, AB_END                 # nao esta pressionando: nada a fazer
    andi t3, t2, INPUT_SWAP         # bit de troca no frame anterior
    bnez t3, AB_END                 # ja estava pressionado: nao e borda

    # ---- Borda de subida: alterna a habilidade (so ha 2: 0 e 1) ---- #
    la   t0, PLAYER
    lw   t1, PLAYER_ability(t0)
    xori t1, t1, 1                  # ABILITY_DOUBLEJUMP(0) <-> ABILITY_DASH(1)
    sw   t1, PLAYER_ability(t0)

AB_END:
    ret
