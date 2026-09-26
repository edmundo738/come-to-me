# IDLE_N_ESQUERDA — ciclo candidato 05

**Estado: sequência criada para revisão; NÃO aprovada e NÃO copiada para produção.** Foi animado o mestre 05 após o pedido do utilizador “FAZ O IDLE”.

## Direção e identidade

O corpo mantém orientação world LEFT. A cabeça fica em 3/4 para a câmera, tornando olhos, sobrancelhas, nariz, boca e barba legíveis e preservando o tom sério/atento da vista frontal aprovada. Há um único endpoint esquerdo, partilhado por `IDLE_N_FRENTE → IDLE_N_ESQUERDA` e `IDLE_N_TRAS → IDLE_N_ESQUERDA`; não existem variantes esquerda-frente/esquerda-trás.

## Sequência e movimento

- 12 PNGs individuais em `frames/`, canvas RGBA `384×544`.
- Respiração em 3,19 s, com oito control keys interpolados em 12 cels; tórax inicia, ombros e braços acompanham com atraso suave.
- Rig de landmarks assimétricos específico para a vista esquerda (`--profile left`); nearest-neighbour, escala fixa e alpha bounds constantes.
- Deslocamento máximo medido: `1,20 px` horizontal e `1,45 px` vertical.
- Coroa/rosto (`y≤226`) e parte inferior/pés (`y≥386`) mantêm-se byte-idênticos ao mestre em todos os frames, para preservar expressão, identidade e apoio.
- Preview: `preview.gif`; folha de contacto: `contact_neutral_review.png`.

## Validação

O validador técnico passou com 12 frames, sem erros nem avisos. Canvas e alpha bounds mantêm-se constantes (`127,150,130,354`); zero pixels de alfa parcial; frames adjacentes e fecho `012→001` diferem. Relatório completo: `SEQUENCE_TECHNICAL_VALIDATION.md`.

A comparação de proporções do mestre está em `PROPORTION_COMPARISON.md` (frente) e `PROPORTION_COMPARISON_BACK.md` (costas). A projeção lateral é mais estreita, e a área regional do torso é menor; essas métricas requerem leitura visual e não equivalem a aprovação artística.

## Estado de produção

Este ciclo permanece em `review/` à espera de avaliação visual. Não promover/c copiar para `animations/` até aprovação explícita do utilizador. Frente e costas aprovados passam os validadores técnicos; Godot não foi executado para este candidato.
