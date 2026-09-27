# Come to Me — direção atual e Checkpoint 01, Iteração 02

**Fonte:** direção e playtest relatados pelo proprietário em 2026-09-27. Esta nota separa intenção de design da evidência técnica/visual; não é um GDD completo.

## Visão

Exploração primeiro, com **stealth, mistério, sobrevivência e estratégia** sempre presentes. O jogo usa um mundo 3D real para proporcionar exploração espacial e profundidade, mas procura a linguagem visual de **pixel art/2.5D**: figura desenhada com presença espacial convincente, iluminação, oclusão, sombras, escala e movimento coerentes. Não aplicar apenas um filtro pixelado, não copiar propriedade intelectual e não confundir retro com arte deliberadamente feia ou low-poly barato.

As áreas devem poder variar — corredores, labirintos, salas conectadas, caminhos alternativos e regiões mais abertas — mantendo autoria, leitura e exploração. A escala final do mundo não está a ser decidida neste checkpoint.

## Câmara e movimento pretendidos

- Câmara de terceira pessoa, atrás e ligeiramente acima, orbitada livremente pelo rato. Seguimento, colisão/encurtamento em espaços apertados e outros ajustes devem ser suaves e não retirar o controlo normal.
- Movimento físico livre no plano do chão 3D e relativo à câmara: **W** avança na direção da câmara, **S** recua, **A/D** deslocam lateralmente e combinações produzem diagonais.
- Personagem mantém identidade visual 2D/2.5D; a técnica de representação não está escolhida de forma definitiva. Integração espacial é o critério, não “virar o sprite para a câmara”.

## CHECKPOINT 01 — Fundação Visual

Objetivo único: responder visualmente **“o personagem parece existir neste mundo 3D e a câmara, movimento e cenário parecem pertencer ao mesmo jogo?”**

O teste atual está em `experiments/visual_foundation/foundation_room.tscn`, agora cena principal do projeto. É um ambiente manual e editável com piso/colisão, paredes, molduras de passagem, pilares, um banco de pedra, luzes, sombras, profundidade e um personagem físico. O ambiente é geometria e recursos Godot, não desenho integral em `draw_*()`.

**Limites ativos:** sem combate, inimigos, estátuas, demónios, Espelhos, Sombras, Reflexos, stealth/Shift, arremessáveis, áudio, respiração/batimento, HUD, progressão, proceduralização, mundo aberto ou turnos/células.

**Implementado como hipótese reversível:** o personagem usa `AnimatedSprite3D` com os PNGs individuais existentes, orientação vertical Y-facing, luz 3D e sombra alfa; movimento livre `CharacterBody3D` com aceleração, travagem e viragem suavizadas. A seleção entre frente/lateral tem histerese pequena para não oscilar em diagonais; os sprites laterais permanecem candidatos de revisão, e a caminhada rejeitada não é usada. Isto não aprova a técnica nem prova integração espacial. O leve assentamento corporal é derivado da velocidade e não se apresenta como walk cycle.

A câmara orbita por rato e permite ajustar distância pelo scroll. Nesta iteração, alvo, yaw/pitch, posição e resposta à obstrução usam damping separado. O raycast continua simples e pode revelar clipping ou limites em certos ângulos; a prova do proprietário decidirá o próximo ajuste. Não há zoom de combate, cutscenes, alterações de FOV ou comportamento contextual amplo.

## Relato do primeiro playtest do proprietário — 2026-09-27

**FACT — executado:** o proprietário abriu e testou a Fundação Visual num build jogável.

**OBSERVED — relato do proprietário:**
- Movimento livre 3D relativo à câmara funcionou como prova inicial.
- A representação/perspectiva do personagem é promissora para este teste; a técnica 2.5D final continua **UNKNOWN**.
- Mesmo com assets geométricos provisórios, a composição sugeriu um lugar arquitetónico interessante, quase um templo. **Preservar esta fundação; não a descartar.**
- Os assets/proporções ainda são feios, artificiais, geométricos e desproporcionais; ainda não existe linguagem visual coerente nem identidade suficiente de sobrenatural + tecnologia + mistério.
- O movimento é demasiado mecânico/travado; órbita e câmara ainda carecem de damping e de uma resposta de RPG de ação/terror mais refinada.
- Transições de distância/perspectiva devem ser suaves e não expor um limite abrupto do sistema. A prioridade é manter leitura da personagem sem retirar o controlo do rato.

## CHECKPOINT 01 — Iteração 02: camera/character feel

Pequena implementação → build → playtest do proprietário → observação. Escopo exclusivo: **Camera Feel, Character Feel, integração 2.5D, profundidade/iluminação, proporção/escala e uma primeira pista visual sobrenatural-tecnológica.** O cenário deve começar a ler como lugar específico, não como coleção de primitivas.

A iteração refinou a resposta de velocidade em vetor (INPUT → direção desejada → velocidade alvo → aceleração/travagem → movimento), rotação corporal amortecida, seleção de vistas com histerese, damping separado de órbita/seguimento/posição/distância e a forma dos módulos já existentes. O antigo bloco foi redesenhado como banco físico; três cópias redundantes foram removidas; suportes redondos repetidos dão linguagem comum a colunas e passagens; pedra/bronze menos saturados e uma linha teal de baixa energia sugerem, sem partículas, um vestígio tecnológico/sobrenatural. São **hipóteses reversíveis**, não aprovação visual.

**Não adicionar nesta iteração:** combate, criaturas, stealth, arremessáveis, áudio, HUD, progressão ou proceduralização. Não escolher uma técnica 2.5D definitiva nem multiplicar assets para esconder uma linguagem visual fraca.

**Playtest pendente:** o proprietário deve observar controlo e easing da câmara, limites/oclusão, arranque/paragem/viragens, mudança de vistas, escala, banco/colisões, materiais, contraste e se a pista de identidade lê sem efeitos em excesso. Iteração 02 não foi executada/observada pelo agente; não declarar sucesso por testes estáticos/headless.

## Direção futura registada — fora do checkpoint atual

Os itens seguintes são **direção declarada pelo proprietário**, não sistemas implementados, não conteúdo do Checkpoint 01 e não prova de diversão/balanço:

- **Stealth do jogador:** manter Shift premido para uma postura que altera animação e velocidade. A relação exata entre essa velocidade, ruído e deteção ainda precisa de teste.
- **Som e arremessáveis:** o jogador poderá apanhar certos objetos arremessáveis para provocar ruído à distância. A ameaça deve investigar a origem/direção aproximada, por vezes permanecer a procurar e depois regressar. O uso repetido pode provocar fúria/alerta e uma procura mais agressiva. Alcances, limiares, duração e conhecimento exato da ameaça continuam por definir.
- **Feedback sem HUD:** o jogador pode ouvir a própria respiração e um batimento cardíaco mais forte como sinal diegético de perigo/progresso. Alguns bosses poderão perceber estes sinais; isso não é uma regra para todas as ameaças.
- **Demónios:** mais curiosos/irritantes; procuram varrendo a atenção em direções diferentes e podem reagir a ruídos altos. Visão/audição, investigação, perda de estímulo, procura e retorno são a base comportamental a testar.
- **Estátuas:** entidades geralmente imóveis até alguém se aproximar demasiado, mas com espécies/combinações diferentes. Foram citadas variantes que exigem mecanismo, que detetam o jogador mas congelam enquanto observadas, que ignoram o jogador salvo quando um Espelho está perto, que protegem contra demónios/Sombras e que podem lançar chamas. Luz e lugares de purificação podem ser meios de as desviar/fazer regressar. Isto não significa combate direto padrão.
- **Espelhos:** criaturas humanoides combatíveis, associadas a mortes/falhas anteriores. Podem comportar-se de forma semelhante aos demónios, fazer ruído/chamar outras ameaças ou conduzir o jogador a demónios/estátuas.
- **Sombras:** distintas dos Espelhos e Reflexos; podem nascer de maldições/permanecer no escuro ou aparecer a atormentar demónios.
- **Reflexos:** distintos dos anteriores; associados a estátuas de luz quando o jogador está amaldiçoado.
- Sombras, fontes de pureza, escudos divinos, luz e armadilhas são elementos possíveis/centrais da fantasia de sobrevivência, mas a forma concreta e a ordem de prototipagem ficam para checkpoints de gameplay.
- Evasion First continua preservado como evidência útil do ciclo de detecção, perseguição, perda de estímulo, investigação, procura e retorno. A implementação antiga por grelha/turnos não entra no teste atual em tempo real.
- Referências de RPGs servem para estudar exploração e sistemas, nunca para copiar assets, personagens, mapas, código, identidade ou música.

## Implementação técnica e renderer

O projeto usa Godot **4.7** como mínimo declarado e seleciona o renderer **Forward+**; em Windows, `rendering/rendering_device/driver.windows="d3d12"` pede o backend Direct3D 12. Godot pode recorrer ao mecanismo de fallback configurado quando necessário. Outras plataformas continuam a usar o driver adequado do Godot. Isto é configuração do projeto, não benchmark de desempenho nem compatibilidade de hardware já medida. Ver a visão geral oficial dos renderers Godot 4.7: https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html

## Evidência e validação

- **FACT — ficheiros:** `project.godot` usa `foundation_room.tscn` como cena F5; há `CharacterBody3D`, `Camera3D`, geometria/colisões/luzes e teste de recursos/movimento/câmara. Experiências anteriores e artes de review permanecem preservadas.
- **FACT — teste executado pelo proprietário:** a Iteração 01 foi aberta e jogada; os relatos qualitativos estão documentados acima. O agente não viu o ecrã nem deve ampliar o relato para além do que foi observado pelo proprietário.
- **MEASURED — headless:** CI compilou Godot 4.7.2 e importou/executou a cena. A run `36328344782` falhou uma asserção de colisão do banco no ponto de teste original (X observado 7.63). Foi alinhado o teste ao centro do banco e o módulo foi remodelado; a correção ainda precisa de rerun. A execução remota não valida o feedback visual.
- **MEASURED — local:** 8 testes Python passaram; `bash -n`, `git diff --check`, caminhos e `load_steps` das 15 cenas/materiais e CRC/descompressão de três PNGs passaram. O workspace do agente não tem binário/display Godot, pelo que não houve segundo playtest local.
- **UNKNOWN:** se a Iteração 02 compila/importa sem erro, se a mudança de aceleração e câmara melhora a sensação ao proprietário, se as transições parecem menos limitadas, e se escala, materiais e pista teal criam coerência sobrenatural-tecnológica em vez de primitivismo.
- Nenhum sucesso visual é inferido do build/headless. O próximo juízo depende do playtest do proprietário com a pasta/arquivo de atualização focado.

**Critério de conclusão:** executar e jogar a cena num display, orbitar a câmara, aproximar/afastar, atravessar diagonais e recuar, testar oclusão e colisões, observar sombras e iluminação a distância normal. Se a integração não convencer, registar precisamente o que falhou e fazer uma correção pequena. Não chamar o checkpoint de aprovado apenas porque compila.
