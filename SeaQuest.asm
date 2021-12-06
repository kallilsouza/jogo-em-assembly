# Jogo seaQuest

.text

main: 
    jal start_game

    
fim: addi $2, $0, 10
     syscall

# FIM de main

#=====================================================
# COMEÇO - Jogo

start_game:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $8, -8($29)
    sw $9, -12($29)
    sw $10, -16($29)
    sw $11, -20($29)
    sw $12, -24($29)
    sw $13, -28($29)
    sw $14, -32($29)
    sw $15, -36($29)
    sw $16, -40($29)
    sw $20, -44($29)
    addi $29, $29, -48

    jal desenharCenario
    lui $13, 0x1001
    addi $13, $13, 15120
    jal desenharSubmarino

    addi $7, $0, 0x00a03d10
    addi $11, $0, 100
    jal desenharBarraOxg_0
    
    addi $11, $0, 0xffff0000   
    lui $20, 0x1001
    addi $20, $20, 15120 # Posição inicial do player (submarino)
    jal desenharLimites    
    
    lui $17, 0x1001
    addi $17, $17, 38000
    sw $0, 100($17) # Posição do tiro
    sw $0, 200($17) # Posição do tubarão 1
    sw $0, 300($17) # Posição do tubarão 2
    sw $0, 400($17) # Posição do tubarão 3
    sw $0, 96($17) # Contador de passos (tubarão 1)
    sw $0, 132($17) # Posição do tiro
    sw $0, 128($17) # Se há tiro
    sw $0, 432($17) # Oxigênio (valor)
    sw $0, 436($17) # Última barra desenhada
    sw $0, 900($17) # Pontuação
    sw $0, 904($17) # Última pontuação desenhada
    
    addi $21, $0, 1
    sw $21, 904($17)
    jal pontos
    
    jal get_random
    sw $21, 200($17)
    jal get_random
    sw $21, 300($17)
    jal get_random
    sw $21, 400($17)    
    
    addi $21, $0, 800
    sw $21, 432($17)  
    
game_loop:
    # DELAY:
    addi $2, $0, 32
    addi $4, $0, 25
    syscall   
    
    # VERIFICA E ATUALIZA PONTUACAO NA TELA
    jal pontos

game_loop_0:    
    
    # Diminui oxigênio:
    lw $21, 432($17) #----------> Le da memoria a quantidade de oxigenio disponivel.
    addi $21, $21, -1#----------> Diminui 1.
    sw $21, 432($17) #----------> Salva valor atualizado.
    jal barra_oxigenio #--------> Chama funcao responsavel por determinar a representacao do nivel de oxigenio a ser exibido na tela.
    beq $21, $0, no_oxg #-------> Se valor de oxigenio = 0, pula para a parte que chama fim de jogo por falta de oxigenio.
    
    # MOVIMENTACAO DO TUBARAO 1
    lw $21, 200($17) #----------> Le da memoria a posicao do tubarao 1 e guarda em $21.
    jal move_tub     #----------> Chama funcao de mover tubarao, passando como parametro a posicao ($21).
    sw $21, 200($17) #----------> Salva na memoria a posicao do tubarao 1.
    
    lw $18, 96($17)  #----------> Contador de passos do tubarao 1 (usado para determinar o momento em que
                     #            os segundo e terceiro tubaroes aparecerao na tela (aparecem em momentos diferentes).
    addi $18, $18, 1 #----------> Adiciona 1.
    sw $18, 96($17)  #----------> Salva valor atualizado.
    
    slti $18, $18, 26 #---------> Se o numero de passos for inferior a 26, o tubarao 2 nao sera criado.
    bne $18, $0, game_loop_2  #-> ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^ 
    
    # MOVIMENTACAO DO TUBARAO 2
    lw $21, 300($17) #----------> Le da memoria a posicao do tubarao 2 e guarda em $21.
    jal move_tub     #----------> Chama funcao de mover tubarao, passando como parametro a posicao ($21)
    sw $21, 300($17) #----------> Salva na memoria a posicao do tubarao 2.
    
game_loop_2:
    lw $18, 96($17)   #---------> Contador de passos do tubarao 1.
    slti $18, $18, 46 #---------> Se o numero de passos for inferior a 46, o tubarao 3 nao sera criado.
    bne $18, $0, game_loop_3  #-> ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^ 
    
    # MOVIMENTACAO DO TUBARAO 3
    lw $21, 400($17) #----------> Le da memoria a posicao do tubarao 3 e guarda em $21.
    jal move_tub     #----------> Chama funcao de mover tubarao, passando como parametro a posicao ($21)
    sw $21, 400($17) #----------> Salva na memoria a posicao do tubarao 3.
    
game_loop_3:
    lw $19, 128($17) #----------> Verifica se ha projetil na tela.
    beq $19, $0, game_loop_4 #--> Se nao houver, pula para game_loop_4.
    lw $19, 132($17) #----------> Se houver, le da memoria a posicao do projetil.
    jal shoot        #----------> Chama a funcao responsavel por mover o projetil na tela.
    sw $19, 132($17) #----------> Salva na memoria a posicao do projetil.
game_loop_4:    
    lw $21, 900($17) #----------> Le da memoria a pontuacao atual.
    beq $21, 500, tela_ganhou #-> Se jogador atingiu a pontuacao necessaria para ganhar, pula para a parte que exibe "you win".
    jal ver_se_atingido #-------> Funcao que verifica se houve colisao entre jogador e tubarao (ret. em $21: 0, se nao, ou 1, se sim).
    bne $21, $0, tela_perdeu #--> Caso sim, pula para parte que exibe "you lose".
    lw $12, 0($11)   #----------> Verifica se jogador pressionou alguma tecla.
    bne $12, $0, get_key #------> Caso sim, chama funcao de identificar qual tecla foi pressionada.
    j game_loop
    
# ENCERRA JOGO:
quit_game: 
    addi $29, $29, +48
    lw $31, 0($29)
    lw $7, -4($29)
    lw $8, -8($29)
    lw $9, -12($29)
    lw $10, -16($29)
    lw $11, -20($29)
    lw $12, -24($29)
    lw $13, -28($29)
    lw $14, -32($29)
    lw $15, -36($29)
    lw $16, -40($29)
    lw $20, -44($29)
    jr $31
    
#=====================================================

#=====================================================
# Funções (jal) começam aqui

# Lista de funções:

# 1 - Desenhar cenario
#     jal desenharCenario

# 2 - Desenhar submarino (player)
#     jal desenharSubmarino
#     (Inserir End. Inicial em $13)

# 3 - Desenhar tubarao (inimigo)
#     jal desenharTubarao 
#     (Inserir End. Inicial em $13)

# 4 - Desenhar tiro
#     jal desenharTiro
#     (Inserir End. Inicial em $13) 

# 5 - Desenhar MiniSubmarino (life)
#     jal desenharMS
#     (Inserir End. Inicial em $13)

# 6 - Desenhar numero 0
#     jal desenharNum_0
#     (Inserir End. Inicial em $13)

# 7 - Desenhar numero 1
#     jal desenharNum_1
#     (Inserir End. Inicial em $13)

# 8 - Desenhar numero 2
#     jal desenharNum_2
#     (Inserir End. Inicial em $13)

# 9 - Desenhar barra de oxigenio (vazia)
#     jal desenharBarraOxg_0

#=====================================================
# COMEÇO -- Desenhar cenario 

desenharCenario: 
    sw $31, 0($29)
    sw $8, -4($29)
    sw $7, -8($29)
    sw $10, -12($29)
    sw $9, -16($29)
    addi $29, $29, -20
    
ceu:
    lui $8, 0x1001
    addi $9, $8, 4608
    addi $7, $0, 0x004047c4
    d_ceu:
        beq $8, $9, fim_d_ceu
        sw $7, 0($8)
        addi $8, $8, 4
        j d_ceu
    fim_d_ceu:
        j ceu_2

ceu_2:
    lui $8, 0x1001
    addi $9, $8, 5120  
    addi $8, $8, 4608     
    addi $7, $0, 0x008337a7
    d_ceu_2:
        beq $8, $9, fim_d_ceu_2
        sw $7, 0($8)
        addi $8, $8, 4
        j d_ceu_2
    fim_d_ceu_2:
        j ceu_3
        
ceu_3:
    lui $8, 0x1001
    addi $9, $8, 5632
    addi $8, $8, 5120
    addi $7, $0, 0x00b33953
    d_ceu_3:
        beq $8, $9, fim_d_ceu_3
        sw $7, 0($8)
        addi $8, $8, 4
        j d_ceu_3
    fim_d_ceu_3:
        j ceu_4
        
ceu_4:
    lui $8, 0x1001
    addi $9, $8, 6144
    addi $8, $8, 5632
    addi $7, $0, 0x00b34e29
    d_ceu_4:
        beq $8, $9, fim_d_ceu_4
        sw $7, 0($8)
        addi $8, $8, 4
        j d_ceu_4
    fim_d_ceu_4:
        j sup
        
sup:
    lui $8, 0x1001
    addi $9, $8, 6656
    addi $8, $8, 6144
    addi $7, $0, 0x00132474
    d_sup:
        beq $8, $9, fim_d_sup
        sw $7, 0($8)
        addi $8, $8, 4
        j d_sup
    fim_d_sup:
        j sup_2
        
sup_2:
    lui $8, 0x1001
    addi $9, $8, 7168
    addi $8, $8, 6656
    addi $7, $0, 0x00223da6
    d_sup_2:
        beq $8, $9, fim_d_sup_2
        sw $7, 0($8)
        addi $8, $8, 4
        j d_sup_2
    fim_d_sup_2:
        j sup_3
        
sup_3:
    lui $8, 0x1001
    addi $9, $8, 7680
    addi $8, $8, 7168
    addi $7, $0, 0x00132474
    d_sup_3:
        beq $8, $9, fim_d_sup_3
        sw $7, 0($8)
        addi $8, $8, 4
        j d_sup_3
    fim_d_sup_3:
        j sup_4
        
sup_4:
    lui $8, 0x1001
    addi $9, $8, 8192
    addi $8, $8, 7680
    addi $7, $0, 0x00223da6
    d_sup_4:
        beq $8, $9, fim_d_sup_4
        sw $7, 0($8)
        addi $8, $8, 4
        j d_sup_4
    fim_d_sup_4:
        j sup_5
        
sup_5:
    lui $8, 0x1001
    addi $9, $8, 8704
    addi $8, $8, 8192
    addi $7, $0, 0x00132474
    d_sup_5:
        beq $8, $9, fim_d_sup_5
        sw $7, 0($8)
        addi $8, $8, 4
        j d_sup_5
    fim_d_sup_5:
        j mar
        
mar:
    lui $8, 0x1001
    addi $9, $8, 26624
    addi $8, $8, 8704
    addi $7, $0, 0x0012208b
    d_mar:
        beq $8, $9, fim_d_mar
        sw $7, 0($8)
        addi $8, $8, 4
        j d_mar
    fim_d_mar:
        j entre_mar_verde
        
entre_mar_verde:
    lui $8, 0x1001
    addi $9, $8, 27136
    addi $8, $8, 26624
    addi $7, $0, 0x00113b3e
    d_emv:
        beq $8, $9, fim_d_emv
        sw $7, 0($8)
        addi $8, $8, 4
        j d_emv
    fim_d_emv:
        j verde

verde:
    lui $8, 0x1001
    addi $9, $8, 27648
    addi $8, $8, 27136
    addi $7, $0, 0x00103f00
    d_verde:
        beq $8, $9, fim_d_verde
        sw $7, 0($8)
        addi $8, $8, 4
        j d_verde
    fim_d_verde:
        j verde_ond
        
verde_ond:
    lui $8, 0x1001
    addi $8, $8, 27648
    addi $7, $0, 0x00103f00
    addi $9, $0, 15
    addi $10, $0, 13
    d_vo:
        beq $10, $9, fim_d_vo
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_vo
    fim_d_vo:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 5
        addi $10, $0, 0
    d_cz:
        beq $10, $9, fim_d_cz
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_cz
    fim_d_cz:
        addi $7, $0, 0x00103f00
        addi $9, $0, 15
        addi $10, $0, 0
    d_vo_2:
        beq $10, $9, fim_d_vo_2
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_vo_2
    fim_d_vo_2:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 5
        addi $10, $0, 0
    d_cz_2:
        beq $10, $9, fim_d_cz_2
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_cz_2
    fim_d_cz_2:
        addi $7, $0, 0x00103f00
        addi $9, $0, 15
        addi $10, $0, 0
    d_vo_3:
        beq $10, $9, fim_d_vo_3
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_vo_3
    fim_d_vo_3:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 5
        addi $10, $0, 0
    d_cz_3:
        beq $10, $9, fim_d_cz_3
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_cz_3
    fim_d_cz_3:
        addi $7, $0, 0x00103f00
        addi $9, $0, 15
        addi $10, $0, 0
    d_vo_4:
        beq $10, $9, fim_d_vo_4
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_vo_4
    fim_d_vo_4:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 5
        addi $10, $0, 0
    d_cz_4:
        beq $10, $9, fim_d_cz_4
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_cz_4
    fim_d_cz_4:
        addi $7, $0, 0x00103f00
        addi $9, $0, 15
        addi $10, $0, 0
    d_vo_5:
        beq $10, $9, fim_d_vo_5
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_vo_5
    fim_d_vo_5:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 5
        addi $10, $0, 0
    d_cz_5:
        beq $10, $9, fim_d_cz_5
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_cz_5
    fim_d_cz_5:
        addi $7, $0, 0x00103f00
        addi $9, $0, 15
        addi $10, $0, 0
    d_vo_6:
        beq $10, $9, fim_d_vo_6
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_vo_6
    fim_d_vo_6:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 5
        addi $10, $0, 0
    d_cz_6:
        beq $10, $9, fim_d_cz_6
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_cz_6
    fim_d_cz_6:
        addi $7, $0, 0x00103f00
        addi $9, $0, 15
        addi $10, $0, 0
    d_vo_7:
        beq $10, $9, fim_d_vo_7
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_vo_7
    fim_d_vo_7:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 5
        addi $10, $0, 0
    d_cz_7:
        beq $10, $9, fim_d_cz_7
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_cz_7
    fim_d_cz_7:
        addi $7, $0, 0x00103f00
        addi $9, $0, 15
        addi $10, $0, 14
    d_vo_8:
        beq $10, $9, fim_d_vo_8
        sw $7, 0($8)
        addi $8, $8, +4
        addi $10, $10, +1
        j d_vo_8
    fim_d_vo_8:
        j verde_ond_2
        

verde_ond_2:
    lui $8, 0x1001
    addi $8, $8, 28160
    addi $7, $0, 0x008c8c8a
    addi $9, $0, 15
    addi $10, $0, 3
    dcz2_1:
        beq $10, $9, fim_dcz2_1
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dcz2_1
    fim_dcz2_1:
        addi $7, $0, 0x00103f00
        addi $10, $0, 0
        addi $9, $0, 5
    dvo2_1:
        beq $10, $9, fim_dvo2_1
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dvo2_1
    fim_dvo2_1:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 15
        addi $10, $0, 0
    dcz2_2:
        beq $10, $9, fim_dcz2_2
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dcz2_2
    fim_dcz2_2:
        addi $7, $0, 0x00103f00
        addi $10, $0, 0
        addi $9, $0, 5
    dvo2_2:
        beq $10, $9, fim_dvo2_2
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dvo2_2
    fim_dvo2_2:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 15
        addi $10, $0, 0
    dcz2_3:
        beq $10, $9, fim_dcz2_3
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dcz2_3
    fim_dcz2_3:
        addi $7, $0, 0x00103f00
        addi $10, $0, 0
        addi $9, $0, 5
    dvo2_3:
        beq $10, $9, fim_dvo2_3
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dvo2_3
    fim_dvo2_3:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 15
        addi $10, $0, 0
    dcz2_4:
        beq $10, $9, fim_dcz2_4
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dcz2_4
    fim_dcz2_4:
        addi $7, $0, 0x00103f00
        addi $10, $0, 0
        addi $9, $0, 5
    dvo2_4:
        beq $10, $9, fim_dvo2_4
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dvo2_4
    fim_dvo2_4:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 15
        addi $10, $0, 0
    dcz2_5:
        beq $10, $9, fim_dcz2_5
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dcz2_5
    fim_dcz2_5:
        addi $7, $0, 0x00103f00
        addi $10, $0, 0
        addi $9, $0, 5
    dvo2_5:
        beq $10, $9, fim_dvo2_5
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dvo2_5
    fim_dvo2_5:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 15
        addi $10, $0, 0
    dcz2_6:
        beq $10, $9, fim_dcz2_6
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dcz2_6
    fim_dcz2_6:
        addi $7, $0, 0x00103f00
        addi $10, $0, 0
        addi $9, $0, 5
    dvo2_6:
        beq $10, $9, fim_dvo2_6
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dvo2_6
    fim_dvo2_6:
        addi $7, $0, 0x008c8c8a
        addi $9, $0, 15
        addi $10, $0, 4
    dcz2_7:
        beq $10, $9, fim_dcz2_7
        sw $7, 0($8)
        addi $8, $8, 4
        addi $10, $10, +1
        j dcz2_7
    fim_dcz2_7:
        j cinza
        
cinza:
    lui $8, 0x1001
    addi $9, $8, 32768
    addi $8, $8, 28672
    addi $7, $0, 0x008c8c8a
    d_cinza:
        beq $8, $9, fim_d_cinza
        sw $7, 0($8)
        addi $8, $8, +4
        j d_cinza
    fim_d_cinza:
        j fim_DC
fim_DC:
    addi $29, $29, +20
    lw $31, 0($29)
    lw $8, -4($29)
    lw $7, -8($29)
    lw $10, -12($29)
    lw $9, -16($29)
    jr $31

# FIM -- Desenhar cenario   
#=====================================================

#=====================================================
# COMEÇO - Desenhar linhas (limite)

desenharLimites:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $8, -8($29)
    sw $9, -12($29)
    addi $29, $29, -16

    lui $8, 0x1001
    
dlimit_left:
    addi $7, $0, 0x00132475
    #addi $7, $0, 0x00132474
    #addi $7, $0, 0x00ff0000
    sw $7, 6144($8)
    sw $7, 7168($8)
    sw $7, 8192($8)
    addi $7, $0, 0x00223da7
    #addi $7, $0, 0x00223da6
    #addi $7, $0, 0x0000ff00
    sw $7, 6656($8)
    sw $7, 7680($8)
    addi $9, $8, 26624
    addi $8, $8, 8704
    addi $7, $0, 0x0012208c
    #addi $7, $0, 0x0012208b
    #addi $7, $0, 0x000000ff
    dlimit_left_col:
        beq $8, $9, fim_dlimit_left_col
        sw $7, 0($8)
        addi $8, $8, 512
        j dlimit_left_col

fim_dlimit_left_col:
    lui $8, 0x1001
    addi $9, $8, 27132
    addi $8, $8, 9212
    addi $7, $0, 0x0012208c
    #addi $7, $0, 0x0012208b
    #addi $7, $0, 0x000000ff
    dlimit_right_col:
        beq $8, $9, fim_dlimit_right_col
        sw $7, 0($8)
        addi $8, $8, 512
        j dlimit_right_col

fim_dlimit_right_col:
    lui $8, 0x1001
    addi $7, $0, 0x00132475
    #addi $7, $0, 0x00132474
    #addi $7, $0, 0x00ff0000
    sw $7, 6652($8)
    sw $7, 7676($8)
    sw $7, 8700($8)
    addi $7, $0, 0x00223da7
    #addi $7, $0, 0x00223da6
    #addi $7, $0, 0x0000ff00
    sw $7, 7164($8)
    sw $7, 8188($8)
    lui $8, 0x1001
    addi $9, $8, 6656
    addi $8, $8, 6144
    addi $7, $0, 0x00132475
    #addi $7, $0, 0x00132474
    #addi $7, $0, 0x00ff0000
    dlimit_top:
        beq $8, $9, fim_dlimit_top
        sw $7, 0($8)
        addi $8, $8, 4
        j dlimit_top

fim_dlimit_top:
    lui $8, 0x1001
    addi $7, $0, 0x0012208c
    #addi $7, $0, 0x0012208b
    #addi $7, $0, 0x000000ff
    addi $9, $8, 26624
    addi $8, $8, 26112
    dlimit_bottom:
        beq $8, $9, fim_dlimit_bottom
        sw $7, 0($8)
        addi $8, $8, 4
        j dlimit_bottom
        
fim_dlimit_bottom:

fim_dlimit:
    addi $29, $29, +16
    lw $31, 0($29)
    lw $7, -4($29)
    lw $8, -8($29)
    lw $9, -12($29)
    jr $31

# FIM - Desenhar linhas (limite)
#=====================================================

#=====================================================
# COMEÇO - Desenhar submarino (player)
# Entrada: $13 <-- recebe o endereço inicial
#                  (canto superior esquerdo)

desenharSubmarino:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $13, -8($29)
    sw $10, -12($29)
    sw $14, -16($29)
    sw $15, -20($29)
    sw $16, -24($29)
    addi $29, $29, -28
    
    lui $16, 0x1001
    addi $16, $16, 35000
    addi $7, $0, 0x00bebc31
d_sub: 
    lw $15, 24($13)
    sw $15, 0($16)
    sw $7, 24($13)
    lw $15, 28($13)
    sw $15, 4($16)
    sw $7, 28($13)
    lw $15, 532($13)
    sw $15, 8($16)
    sw $7, 532($13)
    lw $15, 536($13)
    sw $15, 12($16)
    sw $7, 536($13)
    lw $15, 540($13)
    sw $15, 16($16)
    sw $7, 540($13)
    lw $15, 1024($13)
    sw $15, 20($16)
    sw $7, 1024($13)
    addi $14, $13, 1032
    addi $10, $13, 1064
    addi $16, $16, 24
    d_sub_loop_1:
        beq $14, $10, d_sub_2
        lw $15, 0($14)
        sw $15, 0($16)
        addi $16, $16, 4
        sw $7, 0($14)
        addi $14, $14, 4
        j d_sub_loop_1
d_sub_2:
    addi $14, $13, 1536
    addi $10, $13, 1576
    d_sub_loop_2:
        beq $14, $10, fim_d_sub
        lw $15, 0($14)
        sw $15, 0($16)
        addi $16, $16, 4
        sw $7, 0($14)
        addi $14, $14, 4
        j d_sub_loop_2
fim_d_sub:
    addi $29, $29, +28
    lw $31, 0($29)
    lw $7, -4($29)
    lw $13, -8($29)
    lw $10, -12($29)
    lw $14, -16($29)
    lw $15, -20($29)
    lw $16, -24($29)
    jr $31

# FIM - Desenhar submarino (player)    
#=====================================================

#=====================================================
# COMEÇO - Apagar submarino (player)
# Entrada: $13 <- posicao (endereco)

apagarSubmarino:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $13, -8($29)
    sw $10, -12($29)
    sw $14, -16($29)
    sw $15, -20($29)
    sw $16, -24($29)
    addi $29, $29, -28
    
    lui $16, 0x1001
    addi $16, $16, 35000
a_sub:      
    lw $7, 0($16)
    sw $7, 24($13)
    lw $7, 4($16)
    sw $7, 28($13)
    lw $7, 8($16)
    sw $7, 532($13)
    lw $7, 12($16)
    sw $7, 536($13)
    lw $7, 16($16)
    sw $7, 540($13)
    lw $7, 20($16)
    sw $7, 1024($13)
    addi $14, $13, 1032
    addi $10, $13, 1064
    addi $16, $16, 24
    a_sub_loop_1:
        beq $14, $10, a_sub_2
        lw $7, 0($16)
        addi $16, $16, 4
        sw $7, 0($14)
        addi $14, $14, 4
        j a_sub_loop_1
a_sub_2:
    addi $14, $13, 1536
    addi $10, $13, 1576
    a_sub_loop_2:
        beq $14, $10, fim_a_sub
        lw $7, 0($16)
        addi $16, $16, 4
        sw $7, 0($14)
        addi $14, $14, 4
        j a_sub_loop_2
fim_a_sub:
    addi $29, $29, +28
    lw $31, 0($29)
    lw $7, -4($29)
    lw $13, -8($29)
    lw $10, -12($29)
    lw $14, -16($29)
    lw $15, -20($29)
    lw $16, -24($29)
    jr $31
        

# FIM - Apagar submarino (player)    
#=====================================================
                 
#=====================================================
# COMEÇO - Desenhar tubarao (inimigo)
# Entrada: $13 <- recebe o endereço inicial
#                 (canto superior esquerdo)

desenharTubarao:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $10, -8($29)
    sw $14, -12($29)
    sw $13, -16($29)
    sw $15, -20($29)
    sw $16, -24($29)
    addi $29, $29, -28

    #lui $16, 0x1001
    #addi $16, $16, 35500
    addi $7, $0, 0x0067bc5d
d_tub:
    #lw $15, 8($13)
    #sw $15, 0($16)
    sw $7, 8($13)
    #lw $15, 24($13)
    #sw $15, 4($16)
    sw $7, 24($13)
    addi $14, $13, 512
    addi $10, $13, 536
    #addi $16, $16, +8
    d_tub_loop_1:
        beq $14, $10, d_tub_2
        #lw $15, 0($14)
        #sw $15, 0($16)
        #addi $16, $16, 4        
        sw $7, 0($14)
        addi $14, $14, 4
        j d_tub_loop_1
d_tub_2:
    #lui $16, 0x1001
    #addi $16, $16, 35500
    #lw $15, 1024($13)
    #sw $15, 8($16)
    sw $7, 1024($13)
    #lw $15, 1028($13)
    #sw $15, 12($16)
    sw $7, 1028($13)
    #lw $15, 1036($13)
    #sw $15, 16($16)
    sw $7, 1036($13)
    #lw $15, 1044($13)
    #sw $15, 20($16)
    sw $7, 1044($13)
    #lw $15, 1048($13)
    #sw $15, 24($16)
    sw $7, 1048($13)

fim_d_tub:
    addi $29, $29, +28
    lw $31, 0($29)
    lw $7, -4($29)
    lw $10, -8($29)
    lw $14, -12($29)
    lw $13, -16($29)
    lw $15, -20($29)
    lw $16, -24($29)
    jr $31
    
# FIM - Desenhar tubarão (inimigo)    
#=====================================================

#=====================================================
# COMEÇO - Apaga tubarão

apagarTubarao:
    sw $31, 0($29)
    sw $8, -4($29)
    sw $9, -8($29)
    sw $10, -12($29)
    sw $13, -16($29)
    sw $7, -20($29)
    sw $2, -24($29)
    sw $4, -28($29)
    addi $29, $29, -32
    
a_tub:
    addi $7, $0, 0x0012208b
    addi $9, $0, 7
    addi $10, $0, 0
    
d_blue:
    beq $10, 3, fim_d_blue
    addi $8, $0, 0
    d_blue_loop:
        beq $8, $9, fim_d_blue_loop
        sw $7, 0($13)
        addi $13, $13, 4
        addi $8, $8, 1
        j d_blue_loop
    fim_d_blue_loop:
        addi $10, $10, 1
        addi $13, $13, 484
        j d_blue

fim_d_blue:
    addi $29, $29, +32
    lw $31, 0($29)
    lw $8, -4($29)
    lw $9, -8($29)
    lw $10, -12($29)
    lw $13, -16($29)
    lw $7, -20($29)
    lw $2, -24($29)
    lw $4, -28($29)
    jr $31        

# FIM - Apaga tubarão
#=====================================================

#=====================================================
# COMEÇO - Desenhar MiniSubarino (life)
# Entrada: $13 - Endereço inicial (canto superior esq)

desenharMS:
    sw $31, 0($29)
    sw $13, -4($29)
    sw $7, -8($29)
    addi $29, $29, -12
    
    addi $7, $0, 0x00bebc31
d_msub:
    sw $7, 12($13)
    sw $7, 512($13)
    sw $7, 516($13)
    sw $7, 520($13)
    sw $7, 524($13)
    #sw $7, 1024($13)
    #sw $7, 1040($13)
    
fim_d_msub:
    addi $29, $29, +12
    lw $31, 0($29)
    lw $13, -4($29)
    lw $7, -8($29)
    jr $31

# FIM - Desenhar MiniSubmarino (life)   
#=====================================================   

#=====================================================
# COMEÇO - Desenhar numero 0
# Entrada - $13 <- Endereço inicial (canto sup. esq.)

desenharNum_0:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_0:
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 512($13)
    sw $7, 524($13)
    sw $7, 1024($13)
    sw $7, 1036($13)
    sw $7, 1536($13)
    sw $7, 1548($13)
    sw $7, 2052($13)
    sw $7, 2056($13)
    
fimDesenharNum_0:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31

# FIM - Desenhar numero 0   
#===================================================== 

#===================================================== 
# COMEÇO - Desenhar numero 1
# Entrada: $13 <- Endereço inicial (canto sup. esq.)

desenharNum_1:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_1:
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 520($13)
    sw $7, 1032($13)
    sw $7, 1544($13)
    sw $7, 2056($13)
    
fimDesenhaNum_1:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31

# FIM - Desenhar numero 1   
#=====================================================

#===================================================== 
# COMEÇO - Desenhar numero 2
# Entrada: $13 <- Endereço inicial (canto sup. esq.)   

desenharNum_2:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_2:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 520($13)
    sw $7, 1032($13)
    sw $7, 1028($13)
    sw $7, 1024($13)
    sw $7, 1536($13)
    sw $7, 2048($13)
    sw $7, 2052($13)
    sw $7, 2056($13)
    
fimDesenharNum_2:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31
    
# FIM - Desenhar numero 2   
#=====================================================

#=====================================================
# COMEÇO - Desenhar numero 3

desenharNum_3:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_3:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 520($13)
    sw $7, 1024($13)
    sw $7, 1028($13)
    sw $7, 1032($13)
    sw $7, 1544($13)
    sw $7, 2048($13)
    sw $7, 2052($13)
    sw $7, 2056($13)
    
fimDesenharNum_3:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31

# FIM - Desenhar numero 3   
#=====================================================

#=====================================================
# COMEÇO - Desenhar numero 4

desenharNum_4:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_4:
    sw $7, 0($13)
    sw $7, 8($13)
    sw $7, 512($13)
    sw $7, 520($13)
    sw $7, 1024($13)
    sw $7, 1028($13)
    sw $7, 1032($13)
    sw $7, 1544($13)
    sw $7, 2056($13)
    
fimDesenharNum_4:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31
    
# FIM - Desenhar numero 4
#=====================================================

#=====================================================
# COMEÇO - Desenhar numero 5

desenharNum_5:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_5:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 512($13)
    sw $7, 1024($13)
    sw $7, 1028($13)
    sw $7, 1032($13)
    sw $7, 1544($13)
    sw $7, 2048($13)
    sw $7, 2052($13)
    sw $7, 2056($13)
    
fimDesenharNum_5:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31

# FIM - Desenhar numero 5   
#=====================================================

#=====================================================
# COMEÇO - Desenhar numero 6

desenharNum_6:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_6:
    sw $7, 0($13)
    sw $7, 512($13)
    sw $7, 1024($13)
    sw $7, 1028($13)
    sw $7, 1032($13)
    sw $7, 1536($13)
    sw $7, 1544($13)
    sw $7, 2048($13)
    sw $7, 2052($13)
    sw $7, 2056($13)
    
fimDesenharNum_6:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31

# FIM - Desenhar numero 6   
#=====================================================

#=====================================================
# COMEÇO - Desenhar numero 7

desenharNum_7:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_7:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 520($13)
    sw $7, 1032($13)
    sw $7, 1544($13)
    sw $7, 2056($13)
    
fimDesenharNum_7:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31

# FIM - Desenhar numero 7   
#=====================================================

#=====================================================
# COMEÇO - Desenhar numero 8

desenharNum_8:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_8:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 512($13)
    sw $7, 520($13)
    sw $7, 1024($13)
    sw $7, 1028($13)
    sw $7, 1032($13)
    sw $7, 1536($13)
    sw $7, 1544($13)
    sw $7, 2048($13)
    sw $7, 2052($13)
    sw $7, 2056($13)
    
fimDesenharNum_8:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31

# FIM - Desenhar numero 8   
#=====================================================

#=====================================================
# COMEÇO - Desenhar numero 9

desenharNum_9:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    addi $7, $0, 0x00bebc31
d_Num_9:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 512($13)
    sw $7, 520($13)
    sw $7, 1024($13)
    sw $7, 1028($13)
    sw $7, 1032($13)
    sw $7, 1544($13)
    sw $7, 2056($13)
    
fimDesenharNum_9:
    addi $29, $29, +8
    sw $31, 0($29)
    sw $7, -4($29)
    jr $31

# FIM - Desenhar numero 9   
#=====================================================

#=====================================================
# COMEÇO - Desenha tiro
# Entrada: $13 <- Endereço inicial (esq. p/ dir.)

desenharTiro:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    
    addi $7, $0, 0x00707c56
d_tiro:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 12($13)
    sw $7, 16($13)
    
fim_d_tiro:
    addi $29, $29, +8
    lw $31, 0($29)
    lw $7, -4($29)
    jr $31
    
# FIM - Desenhar tiro  
#=====================================================

#=====================================================
# COMEÇO - Apaga tiro

apagarTiro:
    sw $31, 0($29)
    sw $7, -4($29)
    addi $29, $29, -8
    
    addi $7, $0, 0x0012208b
d_apT:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 8($13)
    sw $7, 12($13)
    sw $7, 16($13)
    
fim_apagarTiro:
    addi $29, $29, +8
    lw $31, 0($29)
    lw $7, -4($29)
    jr $31

# FIM - Apagar Tiro 
#=====================================================    

#=====================================================
# COMEÇO - Desenhar barra de oxigenio (vazia)

desenharBarraOxg_0:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $8, -8($29)
    sw $9, -12($29)
    sw $16, -16($29)
    addi $29, $29, -20

    #addi $7, $0, 0x00a03d10
    addi $16, $0, 352
    
d_barraOxg_0_p1:
    lui $8, 0x1001      
dbc100:
    bne $11, 100, dbc80
    addi $9, $8, 29520  
    j dbc
dbc80:
    bne $11, 80, dbc60
    addi $9, $8, 29488
    addi $16, $16, +32
    j dbc
dbc60:
    bne $11, 60, dbc40
    addi $9, $8, 29456
    addi $16, $16, +64
    j dbc
dbc40:
    bne $11, 40, dbc20
    addi $9, $8, 29424
    addi $16, $16, +96
    j dbc
dbc20:
    bne $11, 20, dbc0
    addi $9, $8, 29392
    addi $16, $16, +128
    j dbc    
dbc0:
    addi $9, $8, 29360
    addi $16, $16, +160
    j dbc 
dbc:
    addi $8, $8, 29360
d_barraOxg_0_loop_1:
    beq $8, $9, d_barraOxg_0_p2
    sw $7, 0($8)
    addi $8, $8, 4
    j d_barraOxg_0_loop_1

d_barraOxg_0_p2:
    add $8, $8, $16
    addi $9, $9, 512

d_barraOxg_0_loop_2:
    beq $8, $9, fim_d_barraOxg_0
    sw $7, 0($8)
    addi $8, $8, 4
    j d_barraOxg_0_loop_2

fim_d_barraOxg_0:
    addi $29, $29, +20
    lw $31, 0($29)
    lw $7, -4($29)
    lw $8, -8($29)
    lw $9, -12($29)
    lw $16, -16($29)
    jr $31
    
# FIM - Desenha barra de oxigenio (vazia)
#=====================================================

#=====================================================
# COMEÇO - Pontuação

pontos:
    sw $31, 0($29)
    sw $8, -4($29)
    sw $9, -8($29)
    sw $20, -12($29)
    sw $21, -16($29)
    sw $22, -20($29)
    sw $23, -24($29)
    sw $14, -28($29)
    sw $10, -32($29)
    sw $15, -36($29)
    addi $29, $29, -40

pts_1:
    lw $8, 900($17)
    lw $9, 904($17)
    beq $8, $9, fim_pontos
    add $9, $8, $0
    sw $9, 904($17)
    jal apagarPontos
    slti $20, $8, 999
    bne $20, $0, pts_2
    addi $8, $0, 999
pts_2:
    addi $10, $0, 10
    div $8, $10
    mfhi $23
    mflo $8
    div $8, $10
    mfhi $22
    mflo $21   
    add $14, $21, $0
    lui $15, 0x1001
    addi $15, $15, 788
    jal d_pts
    add $14, $22, $0
    addi $15, $15, 20
    jal d_pts
    add $14, $23, $0
    addi $15, $15, 20
    jal d_pts
    j fim_pontos
    
fim_pontos:
    addi $29, $29, +40
    lw $31, 0($29)
    lw $8, -4($29)
    lw $9, -8($29)
    lw $20, -12($29)
    lw $21, -16($29)
    lw $22, -20($29)
    lw $23, -24($29)
    lw $14, -28($29)
    lw $10, -32($29)
    lw $15, -36($29)
    jr $31
    
d_pts:
    sw $14, 0($29)
    sw $15, -4($29)
    sw $13, -8($29)
    sw $31, -12($29)
    addi $29, $29, -16
    
d_pts_x:
    beq $14, $0, d_pts_0
    beq $14, 1, d_pts_1
    beq $14, 2, d_pts_2
    beq $14, 3, d_pts_3
    beq $14, 4, d_pts_4
    beq $14, 5, d_pts_5
    beq $14, 6, d_pts_6
    beq $14, 7, d_pts_7
    beq $14, 8, d_pts_8
    beq $14, 9, d_pts_9
    
d_pts_0:
    add $13, $15, $0
    jal desenharNum_0
    j f_d_pts
    
d_pts_1:
    add $13, $15, $0
    jal desenharNum_1
    j f_d_pts
    
d_pts_2:
    add $13, $15, $0
    jal desenharNum_2
    j f_d_pts
    
d_pts_3:
    add $13, $15, $0
    jal desenharNum_3
    j f_d_pts
    
d_pts_4:
    add $13, $15, $0
    jal desenharNum_4
    j f_d_pts
    
d_pts_5:
    add $13, $15, $0
    jal desenharNum_5
    j f_d_pts
    
d_pts_6:
    add $13, $15, $0
    jal desenharNum_6
    j f_d_pts
    
d_pts_7:
    add $13, $15, $0
    jal desenharNum_7
    j f_d_pts
    
d_pts_8:
    add $13, $15, $0
    jal desenharNum_8
    j f_d_pts
    
d_pts_9:
    add $13, $15, $0
    jal desenharNum_9
    j f_d_pts
    
f_d_pts:
    addi $29, $29, +16
    lw $14, 0($29)
    lw $15, -4($29)
    lw $13, -8($29)
    lw $31, -12($29)
    jr $31
    
# FIM - Pontuação
#=====================================================
# COMEÇO - Apagar pontuação

apagarPontos:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $8, -8($29)
    sw $9, -12($29)
    sw $10, -16($29)
    sw $11, -20($29)
    addi $29, $29, -24
            
a_pts:
    addi $7, $0, 0x004047c4
    lui $10, 0x1001
    addi $10, $10, 788
    addi $11, $0, 0
    addi $9, $0, 15

a_pts_linha:
    beq $11, 5, fim_apagarPontos
    addi $8, $0, 0
    a_pts_coluna:
        beq $8, $9, fim_a_pts_coluna
        sw $7, 0($10)
        addi $10, $10, +4
        addi $8, $8, 1
        j a_pts_coluna
    fim_a_pts_coluna:
        addi $11, $11, 1
        addi $10, $10, 452
        j a_pts_linha
        
fim_apagarPontos:
    addi $29, $29, +24
    lw $31, 0($29)
    lw $7, -4($29)
    lw $8, -8($29)
    lw $9, -12($29)
    lw $10, -16($29)
    lw $11, -20($29)
    jr $31
    
# FIM - Apagar pontos
#=====================================================

#=====================================================
# COMEÇO - Desenhar "you"

desenharYou:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $13, -8($29)
    sw $14, -12($29)
    sw $15, -16($29)
    sw $8, -20($29)
    addi $29, $29, -24

d_y:
    sw $7, 0($13)
    sw $7, 4($13)
    sw $7, 16($13)
    sw $7, 20($13)
    sw $7, 512($13)
    sw $7, 516($13)
    sw $7, 528($13)
    sw $7, 532($13)
    sw $7, 1024($13)
    sw $7, 1028($13)
    sw $7, 1040($13)
    sw $7, 1044($13)
    sw $7, 1536($13)
    sw $7, 1540($13)
    sw $7, 1544($13)
    sw $7, 1548($13)
    sw $7, 1552($13)
    sw $7, 1556($13)
    sw $7, 2052($13)
    sw $7, 2056($13)
    sw $7, 2060($13)
    sw $7, 2064($13)
    sw $7, 2568($13)
    sw $7, 2572($13)
    sw $7, 3080($13)
    sw $7, 3084($13)
    sw $7, 3592($13)
    sw $7, 3596($13)
    
d_o:
    addi $14, $13, 28
    addi $8, $0, 0
    addi $15, $0, 0

d_o_loop_1:
    beq $8, 8, d_o_loop_r
    sw $7, 0($14)
    addi $14, $14, +512
    addi $8, $8, +1
    j d_o_loop_1
d_o_loop_r:
    addi $15, $15, 1
    beq $15, 1, d_o_loop_r1
    beq $15, 2, d_o_loop_r2
    beq $15, 3, d_o_loop_r3
    j fim_d_o_loop    

    
d_o_loop_r1:
    addi $14, $13, 32
    j d_o_loop_xx
    
d_o_loop_r2:
    addi $14, $13, 44
    j d_o_loop_xx
    
d_o_loop_r3:
    addi $14, $13, 48
    j d_o_loop_xx
    
d_o_loop_xx:
    add $8, $0, $0
    j d_o_loop_1
    
fim_d_o_loop:
    sw $7, 36($13)
    sw $7, 40($13)
    sw $7, 548($13)
    sw $7, 552($13)
    sw $7, 3108($13)
    sw $7, 3112($13)
    sw $7, 3620($13)
    sw $7, 3624($13)

d_u:
    addi $14, $13, 56
    addi $8, $0, 0
    addi $15, $0, 0
    
d_u_loop:
    beq $8, 8, d_u_loop_r
    sw $7, 0($14)
    addi $14, $14, +512
    addi $8, $8, +1
    j d_u_loop
    
d_u_loop_r:
    addi $15, $15, 1
    beq $15, 1, d_u_loop_r1
    beq $15, 2, d_u_loop_r2
    beq $15, 3, d_u_loop_r3
    j fim_d_u_loop

d_u_loop_r1:
    addi $14, $13, 60
    j d_u_loop_xx
d_u_loop_r2:
    addi $14, $13, 72
    j d_u_loop_xx
d_u_loop_r3:
    addi $14, $13, 76
    j d_u_loop_xx
    
d_u_loop_xx:  
    addi $8, $0, 0
    j d_u_loop
 
fim_d_u_loop:
    sw $7, 3136($13)
    sw $7, 3140($13)
    sw $7, 3648($13)
    sw $7, 3652($13)
    
fim_you:
    addi $29, $29, +24
    sw $31, 0($29)
    sw $7, -4($29)
    sw $13, -8($29)
    sw $14, -12($29)
    sw $15, -16($29)
    sw $8, -20($29)
    jr $31
 
# FIM - Desenhar "you"
#=====================================================

#=====================================================
# COMEÇO - Desenhar "win"

desenharWin:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $8, -8($29)
    sw $13, -12($29)
    sw $14, -16($29)
    sw $15, -20($29)
    sw $16, -24($29)
    addi $29, $29, -28
    
d_w:
    addi $15, $0, 0
    addi $8, $0, 0
    add $14, $13, $0
    
d_w_loop:
    beq $8, 7, d_w_loop_r
    sw $7($14)
    addi $14, $14, +512
    addi $8, $8, 1
    j d_w_loop
    
d_w_loop_r:
    addi $15, $15, 1
    beq $15, 1, d_w_loop_r1
    beq $15, 2, d_w_loop_r2
    beq $15, 3, d_w_loop_r3
    beq $15, 4, d_w_loop_r4
    beq $15, 5, d_w_loop_r5
    j fim_d_w_loop

d_w_loop_r1:
    addi $14, $13, 4
    j d_w_loop_xx

d_w_loop_r2:
    addi $14, $13, 12
    j d_w_loop_xx
    
d_w_loop_r3:
    addi $14, $13, 16
    j d_w_loop_xx
    
d_w_loop_r4:
    addi $14, $13, 24
    j d_w_loop_xx
    
d_w_loop_r5:
    addi $14, $13, 28
    j d_w_loop_xx
    
d_w_loop_xx:
    addi $8, $0, 0
    j d_w_loop
    
fim_d_w_loop:
    sw $7, 3080($13)
    sw $7, 3592($13)
    sw $7, 3596($13)
    sw $7, 3600($13)
    sw $7, 3092($13)
    sw $7, 3604($13)

d_i:
    sw $7, 40($13)
    sw $7, 44($13)
    sw $7, 552($13)
    sw $7, 556($13)
    sw $7, 1576($13)
    sw $7, 1580($13)
    sw $7, 2088($13)
    sw $7, 2092($13)
    sw $7, 2600($13)
    sw $7, 2604($13)
    sw $7, 3112($13)
    sw $7, 3116($13)
    sw $7, 3624($13)
    sw $7, 3628($13)
    
d_n:
    addi $14, $13, 56
    addi $16, $0, 8
    addi $15, $0, 0
    addi $8, $0, 0

d_n_loop:
    beq $8, $16, d_n_loop_r
    sw $7, 0($14)
    addi $14, $14, +512
    addi $8, $8, 1
    j d_n_loop

d_n_loop_r:
    addi $15, $15, 1
    beq $15, 1, d_n_loop_r1
    beq $15, 2, d_n_loop_r2
    beq $15, 3, d_n_loop_r3
    j fim_d_n_loop
    
d_n_loop_r1:
    addi $14, $13, 60
    j d_n_loop_xx

d_n_loop_r2:
    addi $14, $13, 1096
    addi $16, $0, 6
    j d_n_loop_xx
    
d_n_loop_r3:
    addi $14, $13, 1100
    j d_n_loop_xx

d_n_loop_xx:
    addi $8, $0, 0
    j d_n_loop
    
fim_d_n_loop:
    sw $7, 64($13)
    sw $7, 68($13)
    sw $7, 576($13)
    sw $7, 580($13)
    
fim_win:
    addi $29, $29, +28
    lw $31, 0($29)
    lw $7, -4($29)
    lw $8, -8($29)
    lw $13, -12($29)
    lw $14, -16($29)
    lw $15, -20($29)
    lw $16, -24($29)
    jr $31
    
# FIM - Desenhar "win"
#=====================================================

#=====================================================
# COMEÇO - Desenhar "lose"

desenharLose:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $8, -8($29)
    sw $13, -12($29)
    sw $14, -16($29)
    sw $15, -20($29)
    addi $29, $29, -24
    
d_L:
    addi $8, $0, 0
    addi $15, $0, 0
    add $14, $13, $0

d_L_loop:
    beq $8, 8, d_L_loop_r
    sw $7, 0($14)
    addi $14, $14, +512
    addi $8, $8, 1
    j d_L_loop
    
d_L_loop_r:
    addi $15, $15, 1
    beq $15, 2, fim_d_L_loop
    addi $14, $13, 4
    addi $8, $0, 0
    j d_L_loop

fim_d_L_loop:
    sw $7, 3080($13)
    sw $7, 3084($13)
    sw $7, 3088($13)
    sw $7, 3092($13)
    sw $7, 3592($13)
    sw $7, 3596($13)
    sw $7, 3600($13)
    sw $7, 3604($13)

d_o2:
    addi $14, $13, 28
    addi $8, $0, 0
    addi $15, $0, 0

d_o2_loop_1:
    beq $8, 8, d_o2_loop_r
    sw $7, 0($14)
    addi $14, $14, +512
    addi $8, $8, +1
    j d_o2_loop_1
d_o2_loop_r:
    addi $15, $15, 1
    beq $15, 1, d_o2_loop_r1
    beq $15, 2, d_o2_loop_r2
    beq $15, 3, d_o2_loop_r3
    j fim_d_o2_loop    

    
d_o2_loop_r1:
    addi $14, $13, 32
    j d_o2_loop_xx
    
d_o2_loop_r2:
    addi $14, $13, 44
    j d_o2_loop_xx
    
d_o2_loop_r3:
    addi $14, $13, 48
    j d_o2_loop_xx
    
d_o2_loop_xx:
    add $8, $0, $0
    j d_o2_loop_1
    
fim_d_o2_loop:
    sw $7, 36($13)
    sw $7, 40($13)
    sw $7, 548($13)
    sw $7, 552($13)
    sw $7, 3108($13)
    sw $7, 3112($13)
    sw $7, 3620($13)
    sw $7, 3624($13)
    
d_s:
    addi $14, $13, 60
    addi $8, $0, 0
    addi $15, $0, 0
    
d_s_loop:
    beq $8, 6, d_s_loop_r
    sw $7, 0($14)
    addi $14, $14, +4
    addi $8, $8, 1
    j d_s_loop
    
d_s_loop_r:
    addi $15, $15, 1
    beq $15, 1, d_s_loop_r1
    beq $15, 2, d_s_loop_r2
    beq $15, 3, d_s_loop_r3
    beq $15, 4, d_s_loop_r4
    beq $15, 5, d_s_loop_r5
    j fim_d_s_loop
    
d_s_loop_r1:
    addi $14, $13, 572
    j d_s_loop_xx

d_s_loop_r2:
    addi $14, $13, 1596
    j d_s_loop_xx

d_s_loop_r3:
    addi $14, $13, 2108
    j d_s_loop_xx

d_s_loop_r4:
    addi $14, $13, 3132
    j d_s_loop_xx

d_s_loop_r5:
    addi $14, $13, 3644
    j d_s_loop_xx
    
d_s_loop_xx:
    addi $8, $0, 0
    j d_s_loop
    
fim_d_s_loop:
    sw $7, 1084($13)
    sw $7, 1088($13)
    sw $7, 2636($13)
    sw $7, 2640($13)
    
d_e:
    addi $14, $13, 88
    addi $15, $0, 0
    addi $8, $0, 0
    
d_e_loop:
    beq $8, 6, d_e_loop_r
    sw $7, 0($14)
    addi $14, $14, +4
    addi $8, $8, 1
    j d_e_loop
    
d_e_loop_r:
    addi $15, $15, 1
    beq $15, 1, d_e_loop_r1
    beq $15, 2, d_e_loop_r2
    beq $15, 3, d_e_loop_r3
    beq $15, 4, d_e_loop_r4
    beq $15, 5, d_e_loop_r5
    j fim_d_e_loop
    
d_e_loop_r1:
    addi $14, $13, 600
    j d_e_loop_xx
    
d_e_loop_r2:
    addi $14, $13, 1624
    j d_e_loop_xx
    
d_e_loop_r3:
    addi $14, $13, 2136
    j d_e_loop_xx
    
d_e_loop_r4:
    addi $14, $13, 3160
    j d_e_loop_xx
    
d_e_loop_r5:
    addi $14, $13, 3672
    j d_e_loop_xx
    
d_e_loop_xx:
    addi $8, $0, 0
    j d_e_loop
    
fim_d_e_loop:
    sw $7, 1112($13)
    sw $7, 1116($13)
    sw $7, 2648($13)
    sw $7, 2652($13)
    
fim_lose:
    addi $29, $29, +24
    lw $31, 0($29)
    lw $7, -4($29)
    lw $8, -8($29)
    lw $13, -12($29)
    lw $14, -16($29)
    lw $15, -20($29)
    jr $31    

# FIM - Desenhar "lose"
#=====================================================  

    
#============================================================
# COMEÇO - Verifica se houver colisao entre jogador e tubarao
    
ver_se_atingido:
    sw $31, 0($29)
    sw $7, -4($29)
    sw $15, -8($29)
    addi $29, $29, -12    
    
vsa:
    addi $7, $0, 0x0067bc5d
    lw $15, 32($20)
    beq $15, $7, vsa_pos
    lw $15, 548($20)
    beq $15, $7, vsa_pos
    lw $15, 1064($20)
    beq $15, $7, vsa_pos
    addi $21, $0, 0
    j fim_vsa
vsa_pos:
    addi $21, $0, 1

fim_vsa:
    addi $29, $29, +12
    lw $31, 0($29)
    lw $7, -4($29)
    lw $15, -8($29)
    jr $31

# FIM - Verifica se houve colisao entre jogador e tubarao
#============================================================

#============================================================
# COMEÇO - Move tubarao
# Entrada: $21 (posicao do tubarao)

move_tub: 
    sw $31, 0($29)
    sw $13, -4($29)       
    sw $19, -8($29)
    sw $22, -12($29)
    sw $16, -16($29)
    addi $29, $29, -20
    add $13, $21, $0 
    jal apagarTubarao
    lw $19, 508($13)
    addi $22, $0, 0x0012208c
    beq $19, $22, fim_tub
    lw $19, 508($13)
    addi $22, $0, 0x00707c56
    beq $19, $22, tub_atingido
    lw $19, 1020($13)
    beq $19, $22, tub_atingido
    lw $19, 0($13)
    beq $19, $22, tub_atingido
    lw $19, 4($13)
    beq $19, $22, tub_atingido
    j ctub
tub_atingido:    
    lw $16, 900($17)
    addi $16, $16, 20
    sw $16, 900($17)
    sw $0, 128($17)
    sw $13, 140($17)
    lw $13, 132($17)
    jal apagarTiro
    lw $13, 140($17)
    j fim_tub
ctub:   
    addi $21, $21, -4
    add $13, $21, $0    
    jal desenharTubarao    
    j fim_tub2    
    
fim_tub:
    jal get_random
    
fim_tub2:
    addi $29, $29, +20
    lw $31, 0($29)
    lw $13, -4($29)       
    lw $19, -8($29)
    lw $22, -12($29)
    lw $16, -16($29)
    jr $31

# FIM - Move tubarao    
#============================================================

#============================================================
# COMEÇO - Posicao aleatoria do tubarao
                
get_random:
    sw $31, 0($29)
    sw $2, -4($29)
    sw $4, -8($29)
    sw $5, -12($29)
    addi $29, $29, -16
    addi $2, $0, 42
    addi $5, $0, 34
    syscall
    sll $21, $4, 9
    addi $21, $21, 8672
    lui $4, 0x1001
    add $21, $21, $4
    addi $29, $29, +16
    lw $31, 0($29)
    lw $2, -4($29)
    lw $4, -8($29)
    lw $5, -12($29)
    jr $31

# FIM - Posicao aleatoria do tubarao    
#============================================================
    
#============================================================
# COMECO - Barra de oxigenio
        
barra_oxigenio:
    sw $31, 0($29)
    sw $8, -4($29)
    sw $10, -8($29)
    sw $11, -12($29)
    sw $7, -16($29)
    addi $29, $29, -20
    
    addi $7, $0, 0x00b34e29
    lw $8, 32($20)
    bne $7, $8, s_oxg
    addi $8, $0, 800
    sw $8, 432($17)
    
s_oxg:
    lw $8, 432($17)
    srl $8, $8, 3
    
oxg_check:
    slti $10, $8, 80
    beq $10, $0, d_oxg_100
    slti $10, $8, 60
    beq $10, $0, d_oxg_80
    slti $10, $8, 40
    beq $10, $0, d_oxg_60
    slti $10, $8, 20
    beq $10, $0, d_oxg_40
    slti $10, $8, 0
    beq $10, $0, d_oxg_20
    j d_oxg_0

d_oxg_100:
    lw $8, 436($17)
    beq $8, 100, fim_barra_oxigenio
    addi $8, $0, 100
    sw $8, 436($17)
    addi $7, $0, 0x00a03d10
    addi $11, $0, 100
    jal desenharBarraOxg_0
    addi $7, $0, 0x00ffffff
    jal desenharBarraOxg_0
    j fim_barra_oxigenio
    
d_oxg_80:
    lw $8, 436($17)
    beq $8, 80, fim_barra_oxigenio
    addi $8, $0, 80
    sw $8, 436($17)
    addi $7, $0, 0x00a03d10
    addi $11, $0, 100
    jal desenharBarraOxg_0
    addi $7, $0, 0x00ffffff
    addi $11, $0, 80
    jal desenharBarraOxg_0
    j fim_barra_oxigenio
    
d_oxg_60:
    lw $8, 436($17)
    beq $8, 60, fim_barra_oxigenio
    addi $8, $0, 60
    sw $8, 436($17)
    addi $7, $0, 0x00a03d10
    addi $11, $0, 100
    jal desenharBarraOxg_0
    addi $7, $0, 0x00ffffff
    addi $11, $0, 60
    jal desenharBarraOxg_0
    j fim_barra_oxigenio
    
d_oxg_40:
    lw $8, 436($17)
    beq $8, 40, fim_barra_oxigenio
    addi $8, $0, 40
    sw $8, 436($17)
    addi $7, $0, 0x00a03d10
    addi $11, $0, 100
    jal desenharBarraOxg_0
    addi $7, $0, 0x00ffffff
    addi $11, $0, 40
    jal desenharBarraOxg_0
    j fim_barra_oxigenio
    
d_oxg_20:
    lw $8, 436($17)
    beq $8, 20, fim_barra_oxigenio
    addi $8, $0, 20
    sw $8, 436($17)
    addi $7, $0, 0x00a03d10
    addi $11, $0, 100
    jal desenharBarraOxg_0
    addi $7, $0, 0x00ffffff
    addi $11, $0, 20
    jal desenharBarraOxg_0
    j fim_barra_oxigenio
    
d_oxg_0:
    lw $8, 436($17)
    beq $8, 0, fim_barra_oxigenio
    addi $8, $0, 0
    sw $8, 436($17)
    addi $7, $0, 0x00a03d10
    addi $11, $0, 100
    jal desenharBarraOxg_0    
    j fim_barra_oxigenio
    
fim_barra_oxigenio:
    addi $29, $29, +20
    lw $31, 0($29)
    lw $8, -4($29)
    lw $10, -8($29)
    lw $11, -12($29)
    lw $7, -16($29)
    jr $31
    
    
# FIM - Barra de oxigenio
#============================================================

#============================================================
# COMEÇO - Cria tiro
    
create_shot:
    sw $31, 0($29)
    sw $19, -4($29)
    sw $8, -8($29)
    sw $9, -12($29)
    addi $29, $29, -16
    
    addi $8, $0, 0x0012208b
    lw $9, 1064($20)
    bne $9, $8, fim_cshot
    
cshot:
    addi $19, $0, 1
    sw $19, 128($17)
    addi $19, $20, 1064
    sw $19, 132($17)

fim_cshot:
    addi $29, $29, +16
    lw $31, 0($29)
    lw $19, -4($29)
    lw $8, -8($29)
    lw $9, -12($29)
    j return2game  

# FIM - Cria tiro    
#============================================================

#============================================================
# COMEÇO - Move projetil
  
shoot:
    sw $31, 0($29)
    sw $13, -4($29)
    sw $11, -8($29)
    sw $12, -12($29)
    addi $29, $29, -16

d_sh:
    add $13, $19, $0
    jal apagarTiro
    addi $13, $13, +16
    addi $11, $0, 0x0012208c
    lw $12, 524($13)
    beq $11, $12, s_borda
    lw $12, 532($13)
    beq $11, $12, s_borda
    jal desenharTiro
    addi $19, $19, +16
    j fim_shoot
s_borda:
    sw $0, 128($17)
fim_shoot:
    addi $29, $29, +16
    lw $31, 0($29)
    lw $13, -4($29)
    lw $11, -8($29)
    lw $12, -12($29)
    jr $31
    
# FIM - Move projetil
#============================================================

#============================================================
# COMEÇO - Identifica tecla pressionada
        
get_key:
    sw $21, 0($29)
    sw $22, -4($29)
    sw $23, -8($29)
    sw $24, -12($29)
    addi $29, $29, -16
    addi $21, $0, 0x00132475
    addi $22, $0, 0x00223da7
    addi $23, $0, 0x0012208c
    addi $24, $0, 0x00b33953
    lb $12, 4($11)
    beq $12, 'a', move_player_left
    beq $12, 'd', move_player_right
    beq $12, 'w', move_player_up
    beq $12, 's', move_player_down
    bne $12, 'k', vq    
vcs:
    lw $19, 128($17)
    beq $19, $0, create_shot
vq:
    beq $12, 'q', quit_game
return2game: 
    addi $29, $29, +16
    lw $21, 0($29)
    lw $22, -4($29)
    lw $23, -8($29)
    lw $24, -12($29)
    j game_loop

# FIM - Identifica tecla pressionada        
#============================================================
    
#============================================================
# COMECO - Movimentacoes possiveis (left, right, up, down)   
    
move_player_left:
    add $13, $20, $0
    lw $19, 1020($13)
    beq $19, $21, return2game
    beq $19, $22, return2game
    beq $19, $23, return2game
    jal apagarSubmarino
    addi $20, $20, -8
    add $13, $20, $0
    jal desenharSubmarino
    j return2game
move_player_right:
    add $13, $20, $0
    lw $19, 1064($13)
    beq $19, $21, return2game
    beq $19, $22, return2game
    beq $19, $23, return2game
    jal apagarSubmarino
    addi $20, $20, +8
    add $13, $20, $0
    jal desenharSubmarino
    j return2game
move_player_up:
    add $13, $20, $0
    lw $19, -488($13)
    beq $19, $24, return2game
    jal apagarSubmarino
    addi $20, $20, -1024
    add $13, $20, $0
    jal desenharSubmarino
    j return2game
move_player_down:
    add $13, $20, $0
    lw $19, 2068($13)
    beq $19, $23, return2game
    jal apagarSubmarino
    addi $20, $20, 1024
    add $13, $20, $0
    jal desenharSubmarino
    j return2game  

# FIM - Movimentacoes possiveis    
#============================================================

#============================================================
# COMECO - Sem oxigenio

no_oxg:
    addi $11, $0, 100
    addi $7, $0, 0x00a03d10
    jal desenharBarraOxg_0
    j tela_perdeu
    
# FIM - Sem oxigenio    
#============================================================

#============================================================
# COMEÇO - Tela "you lose"

tela_perdeu:
    addi $7, $0, 0x00ff0000
    lui $13, 0x1001
    addi $13, $13, 11976
    jal desenharYou
    lui $13, 0x1001
    addi $13, $13, 16584
    jal desenharLose
    j quit_game
    
# FIM - Tela "you lose"    
#============================================================

#============================================================
# COMEÇO - Tela "you win"
        
tela_ganhou:
    addi $7, $0, 0x0000ff00
    lui $13, 0x1001
    addi $13, $13, 11976
    jal desenharYou
    lui $13, 0x1001
    addi $13, $13, 16584
    jal desenharWin
    j quit_game
    
# FIM - Tela "you win"    
#============================================================
    
#===============================================

check_limites_cenario_player:
    sw $31, 0($29)
    sw $13, -4($29)
    sw $15, -8($29)
    sw $16, -12($29)
    sw $17, -16($29)
    sw $19, -20($29)
    addi $29, $29, -24
    
    addi $15, $0, 0x00132475
    addi $16, $0, 0x00223da7
    addi $17, $0, 0x0012208c
clcp_01:
    lw $19, 1020($13)
    beq $19, $15, clcp_pos
    beq $19, $16, clcp_pos
    beq $19, $17, clcp_pos
    lw $19, 2064($13)
    beq $19, $17, clcp_pos
    lw $19, -488($13)
    beq $19, $15, clcp_pos
    lw $19, 1064($13)
    beq $19, $15, clcp_pos
    beq $19, $16, clcp_pos
    beq $19, $17, clcp_pos
    j clcp_neg
    
clcp_pos:
    addi $18, $0, 1
    j fim_check_limites_cenario_player

clcp_neg:
    addi $18, $0, 0

fim_check_limites_cenario_player:
    addi $29, $29, +24
    lw $31, 0($29)
    lw $13, -4($29)
    lw $15, -8($29)
    lw $16, -12($29)
    lw $17, -16($29)
    lw $19, -20($29)    
    jr $31
    
    
    
    
    
    
    
    
    
    
