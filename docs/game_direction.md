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
- O perseguidor usa uma perseguição determinística por distância Manhattan, evita paredes e desempata na ordem direita, baixo, esquerda, cima. A intenção seguinte não é mostrada como marcador; o jogador deve aprender observando os movimentos.
- Mover-se pode atrair o perseguidor para a célula que o jogador acabou de deixar; isso já oferece uma forma básica de despiste, não um sistema geral de distração.
- Há dois escudos fixos, colisões têm consequências, existem fragmentos opcionais e uma saída/portal.
- As paredes bloqueiam movimento. Não há ainda mecânica implementada de esconder-se/cobertura, distração por objetos/ruído, inventário de sobrevivência, níveis ou narrativa ambiental interativa.

Estes pontos descrevem o código do protótipo; não provam que o loop seja divertido, suficientemente tenso ou legível para novos jogadores.

## Próximo passo recomendado — testar o loop antes de ampliar sistemas

Refinar **uma única sala curta** para testar se a evasão já oferece escolhas legíveis usando os verbos atuais: observar, escolher rota, mover, esperar, saltar e atrair o perseguidor. Manter os fragmentos como possível desvio de risco/recompensa e a saída como objetivo claro. Usar o ambiente para sugerir contexto sem interromper o encontro.

Na revisão dessa sala, observar com o proprietário/jogadores:

- se fica claro quando a ameaça avança e como aprender o padrão sem revelar uma seta de intenção;
- se há decisões significativas além de simplesmente afastar-se;
- se o espaço dá oportunidade de planejar, baitar e recuperar-se de um erro;
- se os escudos tornam o risco compreensível, sem trivializar ou punir injustamente;
- se procurar um fragmento cria uma escolha real entre recompensa e segurança;
- se atmosfera e descoberta reforçam a tensão sem atrasar o loop.

**Recomendação:** não implementar simultaneamente esconderijo, ruído, inventário e outros sistemas. Primeiro observar o que a sala e as ações existentes já conseguem produzir; depois escolher uma única capacidade ausente, caso a evidência mostre que ela acrescenta uma decisão necessária.

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
