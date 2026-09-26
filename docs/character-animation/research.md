# Pesquisa — perspectiva, pixel art e animação

Esta nota separa **evidência consultada**, **decisão de projeto** e **incógnitas a testar**. A pesquisa não valida por si só qualquer imagem gerada.

## 1. Fontes e força da evidência

### Pixel art: respiração

- Tsugumo, [“Breathing Life Into Your Sprites”](http://www.gas13.ru/v3/tutorials/sywtbapa_breathing_life_into_sprites.php), tutorial prático de pixel art. Trabalha primeiro o tórax, desloca pequenos grupos de pixels em vez de redesenhar tudo, altera ligeiramente o shading para sugerir expansão e usa holds mais longos no pico para evitar uma sensação mecânica. Também chama atenção para a proporção entre deslocamento e tamanho do sprite: um pixel num sprite pequeno pode representar movimento exagerado.
- AnimSchool, [“Breathing Life Into Your Animation”](https://blog.animschool.edu/2024/11/15/breathing-life-into-your-animation/), demonstração de animação 3D/rig. A transferência para sprite 2D é **princípio, não receita literal**: começar pelo peito, deixar os ombros reagirem um pouco depois, dar follow-through discreto aos braços e manter cabeça/pescoço mais estáveis.

**Decisão para Come to Me:** a respiração de `IDLE_N` parte do tórax/parte superior do casaco; ombros e mangas respondem com pequeno atraso; cabeça, mãos, pernas e ponto de contacto permanecem estáveis, salvo se um teste mostrar que algum detalhe secundário ajuda a leitura. O desenho será ajustado ao tamanho real do sprite, não a um número universal de pixels.

### Animação quadro a quadro e consistência

- A documentação oficial do Aseprite, [Animation](https://www.aseprite.org/docs/animation/), organiza desenho na timeline, avanço quadro a quadro, preview, tags e duração individual.
- A documentação oficial do Aseprite, [Onion Skinning](https://www.aseprite.org/docs/onion-skinning/), explica sobrepor frames anteriores/seguintes para usar como referência ao desenhar o atual.
- A documentação oficial do Aseprite, [Sprite Sheets](https://www.aseprite.org/docs/sprite-sheet/), distingue sequência horizontal, vertical e matriz. O atlas é formato de transporte; não obriga a misturar estados ou direções na fonte editável.

**Decisão para Come to Me:** PNG individuais numerados são a fonte editável/auditável. Uma spritesheet é só exportação opcional depois de as sequências independentes estarem aprovadas. Onion skin será obrigatório para reduzir drift de silhueta e pivô.

### Caminhada

- O guia prático [Walk Cycle Animation — Spotlight FX](https://spotlightfx.com/blog/walk-cycle-animation-beginners-guide-to-creating-realistic-movement) descreve quatro poses de suporte: contacto, down/absorção de peso, passing e up/push-off. Um ciclo completo repete esses eventos para o passo oposto; braços geralmente contrabalançam as pernas. É uma fonte secundária de fundamentos, não uma especificação de pixel art para Come to Me.
- A síntese visual desses fundamentos para este projeto está em [walk_normal.md](walk_normal.md) e [walk_fear.md](walk_fear.md).

**Decisão para Come to Me:** as poses são referências anatómicas a traduzir para a câmera superior oblíqua. Não copiar uma caminhada lateral de perfil. Em gameplay por grelha, deslocamento lógico e animação corporal são canais separados; o sprite não desliza os pés para simular deslocamento da célula.

### Perspectiva e custo de direções

- O ensaio [How many sprites do different perspectives need?](https://cxong.github.io/2022/03/how-many-sprites-do-different-perspectives-need) compara top-down vertical, oblíquo e oito direções, mostrando o trade-off prático: quanto mais oblíqua e específica a projeção, mais desenhos direcionais costumam ser necessários. É uma análise independente de pipeline, útil para antecipar custo, não uma autoridade artística universal.
- Uma [aula universitária de Cornell sobre perspectiva em jogos 2D](https://www.cs.cornell.edu/courses/cs3152/2020sp/lectures/15-Perspective.pdf) distingue projeções paralelas (ortográfica, axonométrica e oblíqua) e aponta que vista superior pura simplifica 2D, mas reduz a leitura de profundidade. Isso sustenta testar uma pequena obliquidade em vez de assumir um ângulo sem validação.

**Decisão para Come to Me:** bloquear primeiro a câmera usando a referência mais próxima aprovada pelo utilizador. A câmera não muda quando o personagem vira; as vistas direcionais continuam a mostrar topo de cabeça/ombros e o mesmo foreshortening. “FRENTE” nomeia orientação no mundo (screen-down), não uma câmera à altura dos olhos.

### Godot e entrega

- O tutorial oficial Godot [2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html) mostra animação com imagens individuais ou spritesheet através de `AnimatedSprite2D`/`SpriteFrames` e preview no editor.
- A classe oficial [`SpriteFrames`](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html) permite acrescentar texturas individuais, definir velocidade/loop e duração por frame.
- [`AnimatedSprite2D`](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html) mantém frames como texturas e expõe frame atual/progresso/playback.
- [`CanvasItem`](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) documenta modos de filtragem de textura, incluindo `Nearest`, para evitar interpolação borrada quando o pixel art é ampliado.

**Decisão para Come to Me:** importar imagens individuais em `SpriteFrames`, preview no Godot real e filtro `Nearest`; compressão sem perdas. FPS e duração de cada frame serão ajustáveis, não presumidos.

## 2. O que a pesquisa NÃO prova

- Não há contagem de frames universalmente “correta”. O piso de **8 frames** vem do requisito do projeto, não de uma lei de animação. Muitos idles de pixel art usam menos; aqui o orçamento maior é justificado apenas se cada quadro trouxer progressão útil.
- Um deslocamento fixo de 1–2 px pode ser enorme num sprite pequeno e invisível num sprite grande. Primeiro medir a dimensão final e observar em escala de gameplay.
- Uma imagem atraente ou um GIF suave não prova que frames isolados têm alfa correto, pivô estável, câmera coerente ou anatomia consistente.
- As fontes de caminhada consultadas descrevem fundamentos geralmente em visão lateral/3D. Contact/down/passing/up precisam ser reinterpretados para a vista overhead; não copiar automaticamente a silhueta lateral.
- Nenhuma fonte externa consegue decidir o ângulo preferido pelo utilizador. Esse é um portão visual humano.

## 3. Método de teste derivado

1. Fixar e aprovar uma única câmera/célula de teste — mas exportar depois apenas o personagem com alpha.
2. Guardar um desenho-mestre de personagem, paleta, contorno e pivô.
3. Planejar poses-chave em papel/tabela antes de desenhar frames intermédios.
4. Desenhar incrementalmente com onion skin e referência do frame-mestre; comparar a silhueta em overlay.
5. Exportar um PNG RGBA por frame com canvas idêntico.
6. Medir bounds/pivô/diferença por frame; investigar, não esconder, anomalias.
7. Ver os PNGs isolados, rodar em loop e pausar em cada frame.
8. Testar 6, 8, 10, 12 e 15 FPS; afinar duração por frame em vez de acelerar um desenho incoerente.
9. Integrar num preview Godot separado e sem cenário dentro dos PNGs.
10. Pedir aprovação humana explícita; só então começar a próxima sequência.
