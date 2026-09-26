# IDLE_N_ESQUERDA — mestre candidato 03

**Estado: SUPERADO pelo feedback sobre leitura facial.** Este rascunho ficou demasiado de perfil para preservar a expressão do personagem. Não é o candidato ativo, não foi aprovado e não tem ciclo de animação. Foi criado um único destino canónico voltado para world LEFT, para reutilização tanto em `IDLE_N_FRENTE → IDLE_N_ESQUERDA` como em `IDLE_N_TRAS → IDLE_N_ESQUERDA`. Não criar variantes `ESQUERDA_FRENTE` e `ESQUERDA_TRAS`.

## Orientação pretendida

Cabeça/gaze, tronco e corpo orientados claramente para a esquerda, em perfil/3⁄4 forte sob a mesma câmera overhead 2.5D. O corpo continua vertical no canvas; não é uma rotação da imagem. Esta pose é um único endpoint cardinal comum às duas aproximações.

## Normalização técnica

A imagem de origem generativa era `864×1232`, com fundo magenta. Foi recortada por alfa, ajustada por vizinho mais próximo à altura de 354 px e colocada no canvas `384×544`, com topo em `y=150`. Pixels de franja magenta conectados à transparência foram neutralizados na cor, preservando a alfa binária. O resultado tem bounds `(127,150,130,354)`, 30.198 pixels alfa e zero pixels de alfa parcial.

## Comparação screen-space (heurística)

Relatórios completos: `PROPORTION_COMPARISON.md` (frente) e `PROPORTION_COMPARISON_BACK.md` (trás).

| Métrica | vs frente aprovada | vs trás aprovada |
|---|---:|---:|
| Altura total | igual (354 px) | igual (354 px) |
| Largura total | −24,4% | −26,1% |
| Área cabeça/pescoço | −4,6% | +11,6% |
| Área ombros/peito | −28,3% | −24,5% |
| Área pélvis/pernas/pés | −14,9% | −15,0% |

A largura menor é esperada ao mudar de frente/costas para uma orientação lateral, por isso o limite de largura calibrado para vistas frontais não é um critério de aprovação para este ângulo. A redução relativa de área do torso ainda precisa de avaliação humana quanto à legibilidade e continuidade da massa corporal; métricas de alfa não aprovam estilo.

## Próximo passo

Revisão do utilizador do mestre isolado. Até haver aprovação visual explícita, não gerar os 12 frames, não copiar para produção e não iniciar outra direção/estado. Godot ainda não foi testado.
