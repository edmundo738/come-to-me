# Come to Me — direção atual e Checkpoint 01

**Fonte:** direção confirmada pelo proprietário em 2026-09-27. Esta nota separa intenção de design da evidência técnica/visual; não é um GDD completo.

## Visão

Exploração primeiro, com **stealth, mistério, sobrevivência e estratégia** sempre presentes. O jogo usa um mundo 3D real para proporcionar exploração espacial e profundidade, mas procura a linguagem visual de **pixel art/2.5D**: figura desenhada com presença espacial convincente, iluminação, oclusão, sombras, escala e movimento coerentes. Não aplicar apenas um filtro pixelado, não copiar propriedade intelectual e não confundir retro com arte deliberadamente feia ou low-poly barato.

As áreas devem poder variar — corredores, labirintos, salas conectadas, caminhos alternativos e regiões mais abertas — mantendo autoria, leitura e exploração. A escala final do mundo não está a ser decidida neste checkpoint.

## Câmara e movimento pretendidos

- Câmara de terceira pessoa, atrás e ligeiramente acima, orbitada livremente pelo rato. Seguimento, colisão/encurtamento em espaços apertados e outros ajustes devem ser suaves e não retirar o controlo normal.
- Movimento físico livre no plano do chão 3D e relativo à câmara: **W** avança na direção da câmara, **S** recua, **A/D** deslocam lateralmente e combinações produzem diagonais.
- Personagem mantém identidade visual 2D/2.5D; a técnica de representação não está escolhida de forma definitiva. Integração espacial é o critério, não “virar o sprite para a câmara”.

## CHECKPOINT 01 — Fundação Visual

Objetivo único: responder visualmente **“o personagem parece existir neste mundo 3D e a câmara, movimento e cenário parecem pertencer ao mesmo jogo?”**

O teste atual está em `experiments/visual_foundation/foundation_room.tscn`, agora cena principal do projeto. É um ambiente pequeno, manual e editável com piso/colisão, paredes, arcos, pilares, obstáculos, luzes, sombras, profundidade e um personagem físico. O ambiente é geometria e recursos Godot, não desenho integral em `draw_*()`.

**Limites ativos:** sem combate, inimigos, estátuas, demónios, Espelhos, Sombras, Reflexos, stealth/Shift, arremessáveis, áudio, respiração/batimento, HUD, progressão, proceduralização, mundo aberto ou turnos/células.

**Implementado como hipótese reversível:** o personagem usa `AnimatedSprite3D` com os PNGs individuais existentes, orientação vertical Y-facing, luz 3D e sombra alfa; movimento livre `CharacterBody3D` com aceleração e um pequeno bob temporário. Os sprites laterais permanecem candidatos de revisão; a caminhada rejeitada não é usada. Isto não aprova essa técnica nem prova que o personagem está integrado; se parecer uma figura colada ou deslizar, substituir/corrigir a hipótese.

A câmara atual orbita por rato, permite ajustar distância pelo scroll, acompanha com suavização e comprime o percurso perante geometria por raycast. Isso testa a base, não implementa toda a linguagem cinematográfica futura: não há zoom de combate, cutscenes, alterações de FOV ou comportamento contextual amplo.

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

- **FACT — ficheiros:** a cena nova, `CharacterBody3D`, câmera orbitável, meshes, materiais, colisões, sombras, texturas pixel-blockout e teste headless foram adicionados. `project.godot` aponta F5 para a fundação visual.
- **FACT — preservação:** `scenes/main.tscn`, `experiments/manual_3d_room/`, Evasion First, procedural e arte/review antigos continuam no repositório; a sala manual anterior é evidência técnica, não referência visual final.
- **OBSERVED — relato do proprietário:** o slice procedural não foi divertido/suspenseful/coerente; o relato permanece em `experiments/procedural_first_level/README.md`. O procedural é evidência, não a base de expansão deste checkpoint.
- **MEASURED — validação local deste checkpoint:** nenhuma execução Godot foi possível neste workspace; não há binário Godot nem display/GUI disponível. Shell/XML/verificações estáticas não demonstram funcionamento visual.
- **UNKNOWN:** importação/parsing e execução da cena nova; resposta física real, mouse, colisão da câmara, iluminação, sombras, aparência à distância normal, leitura e desempenho. Também é UNKNOWN se a personagem parece integrada ou se o movimento parece deslizar.
- A Actions run `36315052254` da versão anterior concluiu com falha no smoke headless após compilar Godot; o download do log falhou com TLS/EOF. A causa/sub-suite exata continuam UNKNOWN. Uma nova execução é necessária, e um smoke headless não substitui playtest visual com display.

**Critério de conclusão:** executar e jogar a cena num display, orbitar a câmara, aproximar/afastar, atravessar diagonais e recuar, testar oclusão e colisões, observar sombras e iluminação a distância normal. Se a integração não convencer, registar precisamente o que falhou e fazer uma correção pequena. Não chamar o checkpoint de aprovado apenas porque compila.
