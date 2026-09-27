# Come to Me — direção de trabalho atual

**Fonte:** decisão do proprietário, 2026-09-27. Esta nota guarda decisões ativas e o próximo teste; não é um GDD completo.

## Identidade

**Jogo de estratégia com evasão, suspense, sobrevivência e exploração atmosférica.** O foco é leitura do espaço, decisões simples mas significativas, movimento compreensível, reação do inimigo, objetivo claro, improvisação e progresso durante uma situação. Não reduzir a experiência a fugir em linha reta de um monstro.

A versão antiga associada ao Claudio foi relatada como mais divertida. O que nela funcionava ainda é **UNKNOWN**; não copiar sua implementação sem descobrir a razão através de comparação e teste.

## Base de comportamento aceita

**Evasion First é base de comportamento, não experimento a esquecer.** Preservar a lógica existente:

**ver → perseguir → perder visão → investigar → procurar → recuperar**

O código-fonte continua em `experiments/evasion_first_slice/evasion_enemy_state.gd`; a nova sala chama essa mesma classe, sem a reescrever. Não criar tipos adicionais de inimigo antes de um funcionar bem. As decisões estratégicas que o espaço oferece importam tanto quanto a inteligência do inimigo.

## Próximo protótipo: uma sala manual e editável

Abrir `experiments/manual_3d_room/manual_3d_room.tscn` no Godot e executar a cena atual com **F6**. A árvore contém `Environment` (Floor, Walls, Props, Decals, Doors), `Gameplay` (Player, Enemy) e `CameraRig`. Piso, segmentos de parede, pilares, colisões, materiais, porta e câmera são Nodes/Scenes/Meshes editáveis; os bloqueadores de grelha são calculados a partir das mesmas instâncias visíveis que têm colisão.

O mundo 3D + personagens 2D, o ângulo da câmera, a escala, o decal e a silhueta da estátua são **HIPÓTESES** para revisão, não direção de arte aprovada. A câmera mantém esquerda/direita alinhados ao eixo X e cima/baixo ao eixo Z; a leitura real tem de ser observada.

O jogador é um `CharacterBody3D` e percorre o espaço continuamente. Só cruzar para outra célula consome uma unidade estratégica e move o inimigo uma vez; andar dentro da célula não avança o turno. `E` espera uma unidade. WASD/setas movimentam; `R` reinicia. A animação usa os frames de idle existentes e um pequeno movimento corporal; **não** usa a caminhada rejeitada. Ainda é UNKNOWN se esse movimento parece caminhar ou deslizar.

## Evidência, limites e próximo passo

- **OBSERVED — relato de playtest do proprietário sobre o procedural:** tecnicamente corria, mas não era divertido, assustador ou visualmente coerente; parecia PNGs numa arena, com profundidade/perspectivas incompatíveis, deslocamento como teletransporte e pouca sensação de espaço real. O relato integral está em `experiments/procedural_first_level/README.md`.
- O procedural e o seu kit ficam preservados como evidência. Não o estender nem o usar para disfarçar dúvidas de design; primeiro validar esta situação manual.
- **OBSERVED — validação técnica anterior:** Actions run `36311764605` compilou o Godot, mas falhou na etapa do smoke headless; o download do log falhou com TLS/EOF. A sub-suite e a causa são **UNKNOWN**. Não declarar que o teste procedural passou.
- **Ainda não testado:** parsing/importação e execução da nova sala; colisões 3D; movimento no limite da célula; transições Evasion First no cenário; coerência visual, diversão ou suspense. O ambiente atual não tem Godot GUI/binário local.

Próxima observação: no editor, verificar primeiro a câmera e escala; depois mover sem explicar, cruzar uma célula, perder a linha de visão atrás de um pilar e esperar. Corrigir apenas o que essa sala demonstrar. Sem mais sistemas, conteúdo procedural ou HUD nesta fase.
