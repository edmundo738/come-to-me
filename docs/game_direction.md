# Direção do jogo — primeiro vertical slice

**Estado:** direção aprovada pelo proprietário para orientar a próxima fase de planificação. Não é um GDD completo nem congela decisões futuras.

## Hierarquia da experiência

1. **Evasão tática / horror — eixo principal.** O jogador percebe a ameaça, aprende o comportamento do perseguidor e, sob pressão, decide rotas, quando fugir, esperar, despistar ou arriscar. O espaço deve oferecer decisões e oportunidades de evasão; correr em linha reta não basta.
2. **Survival horror — camada de suporte.** Vulnerabilidade, recursos/condições limitadas, consequências, perigo e incerteza devem dar peso às escolhas. Não adicionar sistemas tradicionais por hábito: cada um precisa reforçar a tensão e as decisões de evasão/exploração.
3. **Exploração narrativa / atmosférica — presente, mas subordinada neste slice.** Lugares, descoberta, contexto, narrativa ambiental e momentos de menor pressão devem despertar curiosidade sem tirar o protagonismo do loop de evasão e sobrevivência.

Essa ordem é uma prioridade relativa, não uma percentagem nem três modos separados. O slice deve misturar os três, com evasão tática claramente à frente.

## Base existente — FACTS DO CÓDIGO

- Projeto Godot com grelha screen-aligned de `11 × 9`; a sala atual é fixa e desenhada em código.
- O jogador pode mover-se uma célula, saltar duas células na última direção escolhida, ou esperar. Um movimento bloqueado não consome turno.
- O perseguidor tenta reduzir a distância Manhattan e desempata na ordem direita, baixo, esquerda, cima; isto não é pathfinding e, no mapa atual, a simulação confirma que ele pode parar numa parede apesar de existir rota. A intenção seguinte não é mostrada como marcador. A investigação e o próximo experimento estão em `docs/gameplay_core_research.md`.
- Mover-se pode atrair o perseguidor para a célula que o jogador acabou de deixar; isso já oferece uma forma básica de despiste, não um sistema geral de distração.
- Há dois escudos fixos, colisões têm consequências, existem fragmentos opcionais e uma saída/portal.
- As paredes bloqueiam movimento. Não há ainda mecânica implementada de esconder-se/cobertura, distração por objetos/ruído, inventário de sobrevivência, níveis ou narrativa ambiental interativa.

Estes pontos descrevem o código do protótipo; não provam que o loop seja divertido, suficientemente tenso ou legível para novos jogadores.

## Experiência implementada; teste humano pendente

A pesquisa em `docs/gameplay_core_research.md` encontrou um bloqueador antes de avaliar diversão: a perseguição atual pode parar numa parede. Para manter a experiência aditiva, o BFS e o ciclo **linha de visão → perseguição → perda de visão → investigação da última posição → procura breve → alívio** estão isolados em `experiments/evasion_first_slice/`; `scenes/main.tscn` e o `EnemyState` original permanecem como baseline.

A variante reutiliza ações existentes (mover, esperar, saltar), paredes, dois escudos e o fragmento. Não adiciona esconderijo, distrações, inventário ou Diretor dinâmico. Alcance, duração da procura e pista dos olhos são parâmetros provisórios. O smoke Godot headless passou, incluindo os 7.482 pares de pathfinding, transições e integração da cena; não confirma diversão nem legibilidade. O próximo passo é execução visual e playtest sem explicar a solução ao participante. Critérios estão em `docs/gameplay_core_research.md`.

## UNKNOWN / ainda não decidido

- Se esconder, despistar por interação ambiental ou outro verbo será a primeira nova capacidade de evasão.
- Como e quando introduzir narrativa ambiental e os temas do protagonista no primeiro slice.
- Duração-alvo da sala, progressão entre salas e estrutura do jogo completo.
- Se a configuração atual de escudos permanece ou evolui após teste humano.
- Diversão, tensão e legibilidade do loop para pessoas que não conhecem o protótipo. A validação headless não responde a essas questões.

## Limites e continuidade

- Não promover animações em revisão nem tocar no material rejeitado; a aprovação visual continua separada da validação técnica (`docs/character-animation/README.md`).
- Esta direção orienta o primeiro slice. Rever decisões à luz de playtest, sem expandir o CRES nem transformar esta nota num processo burocrático.
- Depois de um teste humano, registar somente o que foi observado, o que falhou e a próxima alteração concreta.
