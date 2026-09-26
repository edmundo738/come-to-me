# IDLE_N_DIREITA — ciclo candidato 02

**Estado: sequência criada para revisão; NÃO aprovada e NÃO copiada para produção.** Este ciclo segue a abordagem visual de `IDLE_N_ESQUERDA` e foi gerado após o pedido do utilizador para avançar com a direita.

## Direção e identidade

Corpo, cabeça e pés orientam-se claramente para world RIGHT. A cabeça em 3/4 mantém olhos, sobrancelhas, nariz, boca, barba e expressão calma/atenta visíveis, na mesma família visual da esquerda e da frente aprovada. É uma única pose canónica para world RIGHT; não usar a tentativa 01, arquivada por yaw demasiado frontal e escala mais larga que a esquerda.

## Continuidade com a esquerda

Comparação do mestre direito com `IDLE_N_ESQUERDA` candidato 05 (`PROPORTION_COMPARISON_LEFT.md`): altura idêntica (354 px), largura `+2,3%`, largura cabeça/pescoço `+1,3%`, área cabeça/pescoço `−0,8%`, ombros/peito `+4,2%`, região inferior `+3,0%`. Todos esses valores ficaram dentro do gate geométrico configurado; isso não substitui revisão visual de estilo/câmera.

## Sequência

- 12 PNGs RGBA individuais em `frames/`, canvas `384×544`.
- Ciclo de respiração subtil de `3,19 s`, com 8 control keys em 12 cels, tórax iniciando e ombros/braços acompanhando.
- Perfil esquelético específico `right`; escala global fixa e bounds alfa constantes.
- Face/coroa (`y≤226`) e pernas/pés (`y≥386`) ficam byte-idênticos ao mestre para manter expressão e apoio.
- Preview: `preview.gif`; folha de contacto: `contact_neutral_review.png`.

Validador técnico: `SEQUENCE_TECHNICAL_VALIDATION.md` — 12 frames, sem erros nem avisos; alpha bounds `133×354`, sem alfa parcial, frames consecutivos e fecho diferem. Comparação face à frente aprovada em `PROPORTION_COMPARISON_FRONT.md`; a projeção lateral naturalmente estreita torna esse relatório apenas comparativo, não gate de rejeição.

## Estado de produção

Manter em `review/` até aprovação visual explícita; não copiar para `animations/`. Godot ainda não foi testado.
