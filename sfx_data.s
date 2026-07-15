# ==================================================================== #
#  sfx_data.s  --  TODOS os efeitos sonoros do jogo (DADOS)            #
#  [Requisito 1, junto da musica -- fecha o "e efeitos sonoros"]       #
#                                                                      #
#  >>> ESTE E O ARQUIVO QUE O COMPOSITOR PREENCHE. <<<                 #
#  O motor (sfx.s) e a politica (SFX_PLAY nos subsistemas) ja estao    #
#  prontos e NAO precisam mudar quando os dados reais chegarem: basta  #
#  substituir as notas dos blocos <NOME>_NOTAS abaixo e ajustar o      #
#  instrumento/volume no header. Nada mais.                            #
#                                                                      #
#  ---------------- FORMATO DE UM SFX (5 words) -------------------    #
#  Um SFX e um bloco de 5 words + uma lista de notas. Ele e PARECIDO   #
#  com um canal de musica (music_data.s), mas MAIS SIMPLES: nao tem    #
#  ponteiro/timer/flag mutaveis, porque o estado de reproducao vive    #
#  no SFX_CHANNEL (sfx.s), nao no dado. Isso deixa este arquivo 100%   #
#  constante -- o mesmo SFX pode tocar quantas vezes quiser, e dois    #
#  SFX diferentes nunca corrompem um ao outro.                         #
#                                                                      #
#    [0]  endereco da 1a nota (<NOME>_NOTAS)                           #
#    [4]  endereco de fim das notas (<NOME>_FIM)                       #
#    [8]  instrumento MIDI (mesmo campo do canal de musica)            #
#    [12] volume / velocity (0..127)                                   #
#    [16] prioridade (0 = baixa, 255 = alta) -- ver sfx.s              #
#                                                                      #
#  ---------------- FORMATO DAS NOTAS ------------------------------   #
#  Identico ao da musica: pares (nota, duracao_ms), uma diretiva       #
#  .word por linha (o fpgrars NAO aceita continuacao implicita!).      #
#                                                                      #
#      <NOME>_NOTAS:                                                   #
#          .word 72,40                                                 #
#          .word 79,60                                                 #
#      <NOME>_FIM:                                                     #
#                                                                      #
#  nota 0 = silencio (pausa) -- util pra dar respiro dentro do efeito. #
#                                                                      #
#  ---------------- COMO ADICIONAR UM SFX NOVO ---------------------   #
#  1. Escreva o bloco de 5 words + <NOME>_NOTAS/<NOME>_FIM aqui.       #
#  2. Adicione um .eqv SFX_<NOME> <n> em state.s (n = proximo indice). #
#  3. Ponha o endereco do bloco na SFX_TABLE no fim deste arquivo, na  #
#     MESMA ordem dos .eqv.                                            #
#  4. Atualize SFX_COUNT em state.s.                                   #
#  5. Chame "li a0, SFX_<NOME>; call SFX_PLAY" onde o evento acontece. #
#                                                                      #
#  ---------------- ESTADO ATUAL: PLACEHOLDERS ---------------------   #
#  Todos os efeitos abaixo sao PLACEHOLDERS provisorios (beeps de 1-3  #
#  notas) escritos para o sistema ser testavel/audivel HOJE, antes do  #
#  compositor entregar. Eles ja soam como um "chiptune" simples porque #
#  usam instrumentos percussivos/curtos, mas a intencao e que sejam    #
#  substituidos. Cada bloco marca com "TODO(compositor)" o que se      #
#  espera dele.                                                        #
# ==================================================================== #

.data
.align 2

# -------------------------------------------------------------------- #
#  SFX_SHOOT -- tiro do Buster (attack.s, no spawn do projetil)        #
#  TODO(compositor): "pew" curto e agudo. Curto e o mais importante:   #
#  o player atira MUITO, um efeito longo vira poluicao sonora.         #
#  Alvo: <= 80ms no total.                                             #
# -------------------------------------------------------------------- #
SFX_SHOOT_DATA:
    .word SFX_SHOOT_NOTAS
    .word SFX_SHOOT_FIM
    .word 80          # instrumento: lead square (chiptune classico)
    .word 70          # volume: baixo de proposito (toca demais)
    .word 10          # prioridade baixa: qualquer coisa interrompe
SFX_SHOOT_NOTAS:
    .word 96,40
    .word 91,30
SFX_SHOOT_FIM:

# -------------------------------------------------------------------- #
#  SFX_JUMP -- pulo do chao (player.s)                                 #
#  TODO(compositor): "blip" ascendente curto.                          #
# -------------------------------------------------------------------- #
SFX_JUMP_DATA:
    .word SFX_JUMP_NOTAS
    .word SFX_JUMP_FIM
    .word 80
    .word 75
    .word 20
SFX_JUMP_NOTAS:
    .word 72,35
    .word 79,45
SFX_JUMP_FIM:

# -------------------------------------------------------------------- #
#  SFX_DASH -- habilidade dash (player.s, PU_TRY_DASH)                 #
#  TODO(compositor): "whoosh" -- descendente rapido da a sensacao de   #
#  arranque horizontal.                                                #
# -------------------------------------------------------------------- #
SFX_DASH_DATA:
    .word SFX_DASH_NOTAS
    .word SFX_DASH_FIM
    .word 81          # lead sawtooth: mais "sujo", combina com arranque
    .word 85
    .word 40
SFX_DASH_NOTAS:
    .word 84,30
    .word 76,30
    .word 69,40
SFX_DASH_FIM:

# -------------------------------------------------------------------- #
#  SFX_DOUBLEJUMP -- 2o pulo no ar (player.s, PU_AIRBORNE)             #
#  TODO(compositor): parecido com o pulo, mas mais agudo/"etereo" --   #
#  o player precisa DISTINGUIR de ouvido que a habilidade disparou     #
#  (e nao que ele so apertou pulo a toa sem carga).                    #
# -------------------------------------------------------------------- #
SFX_DOUBLEJUMP_DATA:
    .word SFX_DOUBLEJUMP_NOTAS
    .word SFX_DOUBLEJUMP_FIM
    .word 80
    .word 80
    .word 40
SFX_DOUBLEJUMP_NOTAS:
    .word 79,30
    .word 84,30
    .word 88,40
SFX_DOUBLEJUMP_FIM:

# -------------------------------------------------------------------- #
#  SFX_HURT -- player toma dano (collision.s, CU_PL_DMG)               #
#  TODO(compositor): som "feio"/dissonante e descendente. Tem que      #
#  cortar a musica na percepcao do jogador -- por isso prioridade alta.#
# -------------------------------------------------------------------- #
SFX_HURT_DATA:
    .word SFX_HURT_NOTAS
    .word SFX_HURT_FIM
    .word 30          # distortion guitar: agressivo
    .word 100
    .word 200         # prioridade alta: dano sempre avisa
SFX_HURT_NOTAS:
    .word 55,60
    .word 49,80
SFX_HURT_FIM:

# -------------------------------------------------------------------- #
#  SFX_ENEMY_HIT -- inimigo levou tiro mas NAO morreu (collision.s)    #
#  TODO(compositor): "tick"/"clink" seco e curtissimo. E o feedback    #
#  de "acertei" -- sem ele o jogador nao sabe se o tiro fez efeito.    #
# -------------------------------------------------------------------- #
SFX_ENEMY_HIT_DATA:
    .word SFX_ENEMY_HIT_NOTAS
    .word SFX_ENEMY_HIT_FIM
    .word 115         # woodblock: percussivo, corta bem
    .word 90
    .word 30
SFX_ENEMY_HIT_NOTAS:
    .word 84,25
SFX_ENEMY_HIT_FIM:

# -------------------------------------------------------------------- #
#  SFX_ENEMY_DEATH -- inimigo morreu (collision.s, antes do ITEM_DROP) #
#  TODO(compositor): "explosaozinha". No MegaMan e um ruido branco     #
#  curto; com MIDI, instrumento percussivo grave resolve.              #
# -------------------------------------------------------------------- #
SFX_ENEMY_DEATH_DATA:
    .word SFX_ENEMY_DEATH_NOTAS
    .word SFX_ENEMY_DEATH_FIM
    .word 127         # gunshot (GM 128): ruidoso, serve de explosao
    .word 100
    .word 100
SFX_ENEMY_DEATH_NOTAS:
    .word 60,50
    .word 48,70
SFX_ENEMY_DEATH_FIM:

# -------------------------------------------------------------------- #
#  SFX_ITEM -- coletou item de cura ou recarga (items.s)               #
#  TODO(compositor): arpejo ascendente "positivo" (o classico som de   #
#  item pego). 2-3 notas subindo ja resolve.                           #
# -------------------------------------------------------------------- #
SFX_ITEM_DATA:
    .word SFX_ITEM_NOTAS
    .word SFX_ITEM_FIM
    .word 9           # glockenspiel: som de "recompensa"
    .word 95
    .word 120
SFX_ITEM_NOTAS:
    .word 79,50
    .word 84,50
    .word 91,70
SFX_ITEM_FIM:

# -------------------------------------------------------------------- #
#  SFX_DOOR -- entrou na porta / transicao de fase (level.s)           #
#  TODO(compositor): som de porta abrindo/"whoosh" grave. Toca junto   #
#  do inicio da tela preta.                                            #
# -------------------------------------------------------------------- #
SFX_DOOR_DATA:
    .word SFX_DOOR_NOTAS
    .word SFX_DOOR_FIM
    .word 87          # lead bass+lead
    .word 90
    .word 150
SFX_DOOR_NOTAS:
    .word 48,80
    .word 55,80
    .word 60,120
SFX_DOOR_FIM:

# ==================================================================== #
#  SFX_TABLE  --  registro de efeitos, indexado por SFX_* (state.s)    #
#  Cada entrada = endereco do bloco de 5 words daquele efeito.         #
#  A ORDEM AQUI DEVE CASAR COM OS .eqv SFX_* EM state.s.               #
#  (mesmo padrao do MUSIC_TABLE em music_data.s)                       #
# ==================================================================== #
.align 2
SFX_TABLE:
    .word SFX_SHOOT_DATA        # 0 = SFX_SHOOT
    .word SFX_JUMP_DATA         # 1 = SFX_JUMP
    .word SFX_DASH_DATA         # 2 = SFX_DASH
    .word SFX_DOUBLEJUMP_DATA   # 3 = SFX_DOUBLEJUMP
    .word SFX_HURT_DATA         # 4 = SFX_HURT
    .word SFX_ENEMY_HIT_DATA    # 5 = SFX_ENEMY_HIT
    .word SFX_ENEMY_DEATH_DATA  # 6 = SFX_ENEMY_DEATH
    .word SFX_ITEM_DATA         # 7 = SFX_ITEM
    .word SFX_DOOR_DATA         # 8 = SFX_DOOR
