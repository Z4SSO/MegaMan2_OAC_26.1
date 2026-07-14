# ==================================================================== #
#  music_state.s  --  Selecao de musica por estado (MUSIC_SELECT)      #
#                                                                      #
#  Camada de POLITICA da musica. Decide QUAL musica deve tocar e       #
#  re-arma o motor (MUSIC_LOOP) so quando ela MUDA -- sem isso, a      #
#  cada frame a musica reiniciaria e nunca soaria.                     #
#                                                                      #
#  Fonte da decisao: GS_music_id (um id MUS_*). Qualquer subsistema    #
#  pode escrever ali: o DOOR_UPDATE ao trocar de area, o ENEMY_UPDATE  #
#  ao iniciar o chefe, etc. Para as cenas terminais (menu, game over,  #
#  vitoria) derivamos o id de GS_scene automaticamente, para funcionar #
#  antes mesmo de esses sistemas existirem.                            #
#                                                                      #
#  Re-arme (quando GS_music_id != GS_music_armed):                     #
#    1. Busca o endereco da musica em MUSIC_TABLE[id].                 #
#    2. Da RESET nos 3 canais dela (volta ao inicio, zera flags).      #
#    3. Aponta GS_music_cur para a tabela <SONG> dela.                 #
#    4. Marca GS_music_armed = id.                                     #
#  O MUSIC_LOOP (musicFunct.s) so LE GS_music_cur e toca.              #
#                                                                      #
#  Chamado uma vez por frame pelo GAME_LOOP, ANTES do MUSIC_LOOP.      #
# -------------------------------------------------------------------- #
#  Convencao: chama RESET_CANAL -> salva ra. Usa t0..t4, s0..s1.       #
# ==================================================================== #

.text

MUSIC_SELECT:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   s0, 4(sp)
    sw   s1, 0(sp)

    la   s0, GAME_STATE

    # ---- 1. Deriva GS_music_id das cenas terminais ---------------- #
    # Menu / GameOver / Win tem musica fixa: forcamos o id a partir da
    # cena. SCENE_GAME NAO forca nada -- ali quem manda e quem escreveu
    # GS_music_id (door/boss). Assim Estagio1/2/Chefao convivem no jogo.
    lw   t0, GS_scene(s0)

    li   t1, SCENE_MENU
    bne  t0, t1, MS_CHK_GAMEOVER
        li   t2, MUS_INICIO
        sw   t2, GS_music_id(s0)
        j    MS_ARM
MS_CHK_GAMEOVER:
    li   t1, SCENE_GAMEOVER
    bne  t0, t1, MS_CHK_WIN
        li   t2, MUS_GAMEOVER
        sw   t2, GS_music_id(s0)
        j    MS_ARM
MS_CHK_WIN:
    li   t1, SCENE_WIN
    bne  t0, t1, MS_ARM
        li   t2, MUS_VITORIA
        sw   t2, GS_music_id(s0)
        # cai em MS_ARM

    # ---- 2. Re-arma so se a musica pedida mudou ------------------- #
MS_ARM:
    lw   t0, GS_music_id(s0)     # id pedido
    lw   t1, GS_music_armed(s0)  # id armado
    beq  t0, t1, MS_END          # nada mudou: nao reinicia

    # id fora da tabela? (defensivo) -> ignora
    bltz t0, MS_END              # MUS_NONE ou negativo
    li   t2, 6                   # numero de musicas no MUSIC_TABLE
    bge  t0, t2, MS_END

    # Endereco da musica = MUSIC_TABLE + id*4
    la   t2, MUSIC_TABLE
    slli t3, t0, 2               # id * 4 bytes
    add  t2, t2, t3
    lw   s1, 0(t2)               # s1 = <PREFIXO>_SONG (tabela de 3 canais)

    # ---- 3. Reseta os 3 canais da nova musica --------------------- #
    lw   a0, 0(s1)               # CANAL_1
    call RESET_CANAL
    lw   a0, 4(s1)               # CANAL_2
    call RESET_CANAL
    lw   a0, 8(s1)               # CANAL_3
    call RESET_CANAL

    # ---- 4. Publica a nova musica como a armada ------------------- #
    la   s0, GAME_STATE          # (recarrega base: call pode ter mexido em t0)
    sw   s1, GS_music_cur(s0)    # motor passa a tocar esta
    lw   t0, GS_music_id(s0)
    sw   t0, GS_music_armed(s0)  # marca como armada

MS_END:
    lw   ra, 8(sp)
    lw   s0, 4(sp)
    lw   s1, 0(sp)
    addi sp, sp, 12
    ret
