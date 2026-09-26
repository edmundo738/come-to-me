# Pesquisa dirigida — núcleo de evasão e perseguição

**Data:** 2026-09-26

**Escopo:** investigar o loop de evasão para o primeiro vertical slice, não escolher antecipadamente a estrutura do jogo completo.

**Estado:** pesquisa consolidada; implementação recomendada abaixo é uma experiência reversível, não uma decisão final de género.

## Síntese executiva

A melhor hipótese para testar não é “adicionar stealth”. É construir um ciclo curto em que o jogador **observa → interpreta → planeia → compromete uma ação → lê a resposta da ameaça → recupera ou muda de plano**.

A pesquisa favorece três propriedades:

1. **Agência por informação utilizável:** comportamento consistente o bastante para o jogador formar uma hipótese e agir intencionalmente; a resposta do mundo confirma ou contradiz essa hipótese de forma legível.
2. **Perseguição com memória limitada:** o inimigo reage ao que percebe, procura a última informação obtida e pode perder a pista. Uma ameaça pode ser imprevisível sem conhecer magicamente a posição atual do jogador.
3. **Falha que altera a situação, sem encerrar imediatamente a tentativa:** ser visto ou cometer um erro deve impor custo e criar pressão, mas ainda permitir improvisação. A recuperação não pode reduzir-se a esconder-se à espera de um cronómetro ou reiniciar o encontro.

**Recomendação concreta:** primeiro corrigir a perseguição que hoje falha em contornar paredes; depois construir uma cena de teste isolada com perceção por linha de visão, perseguição da posição visível, procura breve da última posição vista e um estado de alívio. Usar as paredes já existentes como oclusão, manter os dois escudos como único recurso explícito e comunicar os estados pelo comportamento/forma do perseguidor, sem um medidor de alerta. Sem esconderijos interativos, crafting, inventário, distrações por itens ou diretor dinâmico nesta experiência.

## O que a evidência sugere

### 1. Evasão é antecipação e escolha, não só reação

Nels Anderson descreveu o apelo do stealth como antecipação e planeamento: o jogador compreende sistemas e “provoca” o mundo, em vez de só reagir quando inimigos aparecem. O postmortem de Klei resume o ciclo de stealth que orientou *Mark of the Ninja* como **Observe, Plan, Execute, React** e relata que a equipa construiu níveis para descobrir quais situações realmente criavam decisões interessantes. A lição não é copiar o jogo: é começar pela decisão que queremos provocar e verificar se as regras a tornam possível. [S2][S3]

**Aplicação aqui:** uma sala precisa oferecer pelo menos duas respostas plausíveis à mesma ameaça — por exemplo, mudar de rota, esperar por uma abertura, saltar um obstáculo ou atrair o perseguidor. Se a melhor resposta for sempre afastar-se em linha reta, o loop ainda não entrega a direção acordada.

### 2. Comportamento legível pode produzir tensão sem revelar tudo

Na entrevista sobre *Mark of the Ninja*, Anderson explica que os jogadores não entendiam por que os guardas reagiam. A equipa tornou a propagação do som visível no espaço de jogo. O postmortem relata testes com jogadores novos e ajustes em pistas visuais e posições de luz, em vez de resolver toda a confusão com mais texto tutorial. O GDC Vault descreve a intenção do projeto como levar as escolhas do jogador para o centro do stealth em 2D. [S2][S3][S4]

**Aplicação aqui:** “sem HUD” não significa “sem informação”. O inimigo pode comunicar atenção por orientação corporal, postura, ritmo e som; a parede pode ocultar a linha de visão; o estado de procura pode produzir uma pausa/varredura reconhecível. O efeito azul de som de *Mark of the Ninja* é uma abstração visual dentro do mundo, não uma regra de que todos os indicadores têm de ser diegéticos. Primeiro testamos pistas simples e consistentes; não adicionamos barras, setas ou um mapa de consciência.

### 3. Mistério não precisa de conhecimento omnisciente escondido

A análise qualitativa de Jaroslav Švelch sobre discussões de jogadores de *Alien: Isolation* descreve a tensão entre um monstro misterioso e um adversário que os jogadores tentam compreender. Parte dos jogadores considerou injusto o conhecimento “psíquico”, a aparente teletransportação ou o monstro “preso” à posição do jogador, especialmente porque o papel do Diretor não era visível. É um estudo de receção de um jogo, não prova que todo jogador rejeite direção oculta; é evidência de um risco de perceção de injustiça. [S5]

**Aplicação aqui:** o primeiro teste não deve usar um Diretor omnisciente, teleporte ou aleatoriedade invisível. A surpresa deve vir das opções e do espaço; a causa do movimento do perseguidor deve poder ser reconstruída pelo jogador.

### 4. A falha deve manter o jogo em movimento

O postmortem de Klei enfatiza iterar cedo sobre os motivos que levam jogadores a agir, não aceitar sugestões de forma literal. A análise de *Invisible, Inc.* publicada pela Game Developer oferece um contraponto útil: um estado de deteção torna-se tedioso se só manda o jogador esperar ou reiniciar. Essa segunda fonte é crítica/opinião, não uma regra validada universalmente; ainda assim, ajuda a formular o nosso teste: depois de um erro, que decisão nova o jogador pode tomar? [S3][S7]

**Aplicação aqui:** deteção deve poder escalar para procura, mas a procura precisa de uma ação/risco/opção de reposicionamento — não apenas um cronómetro de esconderijo. Os dois escudos existentes já são uma hipótese de recuperação; mantê-los como único recurso inicial permite testar o custo sem criar inventário ou consumíveis.

### 5. Pressão precisa de contraste

Os materiais da palestra de Michael Booth sobre o Diretor de *Left 4 Dead* descrevem estados de build-up, sustentação do pico, redução da ameaça e relaxamento. Booth explica o valor de pausas de tensão/quietude entre confrontos e de poder recompor-se. O sistema foi concebido para uma campanha cooperativa de hordas; os seus intervalos numéricos e a geração procedural não devem ser transplantados para este jogo. [S6]

**Aplicação aqui:** desenhar um ritmo manual curto: espaço relativamente calmo → sinal de ameaça → perseguição/decisão → quebra de contato e recuperação → descoberta/objetivo. Como o protótipo é por turnos, a ameaça avança quando o jogador confirma uma ação, não enquanto ele pensa. Isso favorece planeamento tático; não devemos adicionar um relógio em tempo real antes de observar se falta pressão.

### 6. Espaço e narrativa podem carregar tensão sem competir com ela

Um estudo académico sobre *Amnesia: The Dark Descent* analisa como espaço confinado, cantos e campo de visão limitado contribuem para ansiedade. A perspetiva é first-person e a nossa é uma grelha top-down screen-aligned, portanto a transferência é qualitativa: a geometria pode criar antecipação, mas não devemos sacrificar a leitura do tabuleiro. A palestra de GDC sobre *Firewatch* confirma, em contexto diferente e sem combate, que exploração, escolhas e narrativa podem ser trabalhadas pelo desenho de mundo e de níveis. [S8][S9]

**Aplicação aqui:** usar um recanto ou rota de recuperação para colocar contexto ambiental opcional, em vez de interromper o pico da perseguição com exposição. Nesta primeira experiência, a prioridade é validar o encontro; uma pista narrativa pode ser adicionada quando o ritmo de pressão estiver legível.

## Evidência específica do protótipo

**FACTS DO CÓDIGO:** a sala tem 11×9 células, paredes bloqueiam movimento, o jogador move uma célula/salta duas/espera, há dois escudos, fragmentos opcionais e uma saída. O perseguidor atual escolhe um passo que reduz distância Manhattan, com desempate direita/baixo/esquerda/cima; não tem perceção, memória ou estados de procura.

**MEDIDO POR SIMULAÇÃO DO ALGORITMO E MAPA EXISTENTES:** há 87 células transitáveis e 7.482 pares ordenados de origem/destino transitáveis alcançáveis. Em 136 pares (1,8%), a regra gulosa fica parada embora exista um caminho; em 400 pares escolhe um primeiro passo que não pertence a uma rota mínima. Na situação inicial concreta, a sequência é `(9,1) → (8,1) → (7,1) → (6,1)` e para: a parede em `(5,1)` impede continuar, apesar de existir caminho por `(6,2)`. Isto foi medido por uma pequena simulação das mesmas regras em Python, não por playtest nem por execução Godot.

**CONSEQUÊNCIA:** o teste atual não é uma base fiável para julgar perseguição: na configuração inicial o inimigo pode parar na parede. Uma implementação de procura/linha de visão antes de corrigir rotas confundiria dois problemas.

## Primeiro experimento de produção recomendado

### Parte A — tornar o movimento válido

Substituir o passo guloso por BFS na grelha para obter um próximo passo de um caminho mínimo, preservando desempate determinístico. A sala tem somente 99 células; isto é simples, fácil de testar e suficiente — não há benefício demonstrado para navegação avançada. Teste objetivo: para todos os pares alcançáveis, o perseguidor progride e a distância restante diminui conforme o caminho mínimo; nenhuma rota válida deve parar numa parede.

### Parte B — testar perseguição baseada em leitura

Numa cena/variante de encontro isolada, manter uma única ameaça e adicionar somente:

1. **Persegue:** quando tem linha de visão desobstruída para o jogador, segue a posição observada pelo caminho mínimo.
2. **Investiga/procura:** ao perder visão, guarda a última célula vista, desloca-se para lá e procura por um pequeno número configurável de ações do jogador. Se recuperar linha de visão, volta a perseguir.
3. **Alívio:** se não reacquirir o jogador, interrompe a perseguição ativa/retorna a um ponto de guarda. O tempo é contado em turnos confirmados, nunca em segundos enquanto o jogador pensa.

As paredes existentes podem bloquear a linha de visão no experimento; não é preciso botão de esconderijo. Dar início ao encontro com perseguidor visível e incluir uma obstrução que permita escolher entre uma rota exposta/curta e uma rota protegida/mais longa. Valores de alcance e duração são **parâmetros experimentais**, não valores aprovados; começar com uma procura curta e ajustá-la após jogo observado.

Manter inicialmente os dois escudos e os fragmentos como estão. Usar sinais visuais simples do corpo/orientação e ritmo do inimigo para distinguir perseguição, investigação e alívio; evitar HUD novo. Sem áudio novo nesta primeira passagem: primeiro testar se o comportamento visual e a geometria explicam a causa. Se não, o playtest dirá qual pista está faltando.

### Critérios de playtest

Com o proprietário e pelo menos uma pessoa que não esteja a programar o encontro, observar sem explicar a solução:

- O jogador reconhece que foi visto e percebe quando o perseguidor perdeu a linha de visão?
- As escolhas de rota/espera/salto alteram a situação de forma compreensível?
- Depois de perder a linha de visão, o perseguidor procura a última informação conhecida em vez de seguir magicamente a posição atual?
- Um erro custa algo, mas ainda deixa uma resposta viável? O jogador tenta adaptar-se ou apenas espera/reinicia?
- A leitura funciona sem seta/barra de alerta? Algum sinal do inimigo está a ser confundido?
- A sala tem um intervalo em que a pressão diminui e o espaço pode despertar curiosidade?

Registar ações observadas e respostas do jogador, não só “gostei/não gostei”. Se o jogador não percebe os estados, alterar pistas/geométrica antes de adicionar sistemas. Se há só uma resposta dominante ou a procura vira espera passiva, rever o comportamento/layout. A aprovação continua desconhecida até ao playtest.

## Limites da conclusão

- **RECOMENDAÇÃO:** BFS + memória de última posição + linha de visão bloqueada por paredes é o experimento menor que ataca a falha medida e testa agência/recuperação/ambiente.
- **NÃO É DECISÃO FINAL:** estes três estados não definem o jogo completo nem garantem que furtividade seja o núcleo final. O teste pode levar a simplificar, alterar ou remover a mecânica.
- **UNKNOWN:** diversão, suspense, legibilidade visual do perseguidor e duração ideal da procura; precisam de playtest humano. A validação headless não confirma estética.
- **LIMITAÇÃO ATUAL:** o checkout sincronizado não tem Godot no `PATH`. O CI headless do checkpoint anterior passou e publicou artefactos, mas download/restauração ainda não foi demonstrado; a revisão visual exige um ambiente com display.

## Referências

- **[S1]** Robin Hunicke, Marc LeBlanc, Robert Zubek, “MDA: A Formal Approach to Game Design and Game Research” (2004). Framework de tradução entre mecânicas, dinâmicas e experiência, com iteração qualitativa/quantitativa. https://users.cs.northwestern.edu/~hunicke/MDA.pdf
- **[S2]** Nels Anderson, “Reinventing stealth in 2D with *Mark of the Ninja*”, *Game Developer* (2012). Entrevista sobre antecipação, planeamento e tornar a causalidade de sistemas compreensível. https://www.gamedeveloper.com/design/reinventing-stealth-in-2d-with-i-mark-of-the-ninja-i-
- **[S3]** Nels Anderson e Jamie Cheng, “Classic Postmortem: Klei Entertainment’s *Mark of the Ninja*”, *Game Developer* (2017). Relato dos autores sobre playtests, ciclo Observe/Plan/Execute/React, foco no núcleo e erros de escopo. https://www.gamedeveloper.com/design/classic-postmortem-klei-entertainment-s-i-mark-of-the-ninja-i-
- **[S4]** Nels Anderson, “Of Choice and Breaking New Ground: Designing *Mark of the Ninja*”, GDC 2013. A página pública resume o foco em escolha do jogador; vídeo sujeito a acesso do GDC Vault. https://gdcvault.com/play/1017791/Of-Choice-and-Breaking-New
- **[S5]** Jaroslav Švelch, “Should the Monster Play Fair?: Reception of Artificial Intelligence in *Alien: Isolation*”, *Game Studies* 20(2), 2020. Estudo qualitativo de receção; útil como risco de injustiça percebida, não como lei universal. https://gamestudies.org/2002/articles/jaroslav_svelch
- **[S6]** Michael Booth, Valve, “The AI Systems of *Left 4 Dead*” / “Replayable Cooperative Game Design: Left 4 Dead”, GDC 2009; material de palestra transcrito e analisado por AiGameDev.com. A transferência usada aqui é apenas contraste de pressão/relaxamento; não se copiam timers nem Diretor. https://www.cs.drexel.edu/~so367/teaching/2012/CS680/papers/11%20Secrets%20about%20LEFT%204%20DEAD%E2%80%99s%20AI%20Director%20and%20its%20Procedural%20Zombie%20Population%20%7c%20AiGameDev.com.pdf
- **[S7]** Brock Granger, “Lesson: The Problems of Modern Stealth Design, and How *Invisible, Inc.* Solves Them”, *Game Developer* (2019). Perspetiva crítica/opinião sobre estados de procura passivos e custo do reinício; usada para formular perguntas de playtest. https://www.gamedeveloper.com/design/lesson-the-problems-of-modern-stealth-design-and-how-invisible-inc-solves-them
- **[S8]** Charles Lee, “Running scared: Fear and space in *Amnesia: The Dark Descent*”, *Journal of Gaming & Virtual Worlds* 13(1), 2021. Análise académica de espaço/cantos em first-person; transferência para grelha top-down é limitada. https://doi.org/10.1386/jgvw_00030_1
- **[S9]** Nels Anderson e Jake Rodkin, “Designing for Exploration and Choice in *Firewatch*”, GDC 2015. Página pública resume escolhas de exploração/narrativa orientadas por mundo e níveis, sem combate. https://gdcvault.com/play/1022108/Designing-for-Exploration-and-Choice
