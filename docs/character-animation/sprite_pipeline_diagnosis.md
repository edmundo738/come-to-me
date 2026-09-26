# Diagnóstico do pipeline de sprites — WALK experiment 01

**Estado:** `WALK_N_FRENTE` SpriteDNA experiment 01 rejeitado após revisão visual do utilizador. O material fica arquivado como evidência; não reutilizar como animação de gameplay.

## Factos, medições e hipótese

### FACT — não houve spritesheet no caminho de geração

O gerador produziu 12 PNGs RGBA independentes, canvas completo `384×544`, a partir de `IDLE_N_FRENTE/frame_001.png`. A cena de teste carregava cada PNG como uma textura individual em `SpriteFrames`; não usava `hframes`, `vframes`, retângulos de atlas ou cortes de spritesheet. A documentação do Godot suporta precisamente animação com imagens individuais, bem como spritesheets; o projeto não precisa empacotar frames para reproduzi-los. [Godot — 2D sprite animation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)

### MEASURED — os PNGs e a prévia GIF têm problemas diferentes

- As 12 imagens têm canvas igual `384×544`, alfa binário e uma componente conectada de personagem por frame. Não foi medida uma sombra isolada/desligada nas imagens PNG.
- Os bounds de alfa variam: largura `168–178 px` face aos `172 px` do mestre; altura `352–354 px`. O validador regista warnings, não erros. Isto mostra mudança de silhueta durante a deformação e precisa de revisão artística; não prova por si só um erro de corte de atlas.
- A diferença entre PNGs consecutivos foi de `12.785–31.419` pixels. O gerador deformava a imagem inteira, portanto movimento localizado alterava muitos pixels texturados. A sequência pode parecer reinterpretação/distorção mesmo sem componentes duplicadas.
- A prévia entregue era `preview.gif`; o `identify` mediu `Dispose: Undefined` nos 12 frames. O GIF tinha transparência e deslocamento de pixels, mas o comando não especificava descarte do frame anterior. O comportamento de disposal determina como frames transparentes se acumulam; a documentação do ImageMagick descreve especificamente as diferenças entre `None`, `Background`, `Previous` e a coalescência. [ImageMagick — animation disposal/coalesce](https://usage.imagemagick.org/bugs/animation_bgnd/)

### HIPÓTESE MAIS FORTE PARA O “CLONE/SOMBRA” NA PRÉVIA

A acumulação visual do GIF é uma causa plausível e mensurável: disposal indefinido + transparência + movimento. Ainda não afirmo que explique sozinho a crítica de animação “horrível”. Mesmo com disposal corrigido, o método de deformação da imagem inteira continua inadequado e o walk 01 permanece rejeitado.

### UNKNOWN

Não foi possível executar a cena no Godot neste ambiente, porque o binário/editor não está instalado. Assim, não afirmo que o editor tenha renderizado o ciclo nem que exista um bug de slicing no motor.

## Correção de pipeline aplicada

`tools/spritedna_preview_apng.py` monta uma prévia APNG a partir dos PNGs sem os alterar:

- conserva RGBA e cores sem quantização GIF;
- mantém cada frame no canvas completo, sem trim ou packing;
- usa blend `SOURCE` e disposal `BACKGROUND` para substituir/limpar o frame anterior;
- recusa sobrescrever ficheiros e escrever fora de `review/`;
- tem testes que verificam CRC, sequência de chunks APNG, canvas, disposal/blend e pixels descomprimidos idênticos aos frames de origem.

A prévia GIF antiga foi renomeada e mantida como `preview_gif_rejected_undefined_disposal.gif` para preservar a evidência. A nova prévia sem perdas é `preview.apng`.

## Decisão de engenharia

1. Manter os PNGs individuais numerados como fonte de verdade. A referência deste estudo usa canvas fixo `384×544`; o contrato de origem registra o pivô/root em `(192, 504)` e não corta transparência por frame.
2. Não usar o gerador de deformação integral do walk 01 para arte de produção. O gerador e a cena foram movidos para `experiments/spritedna/walk_01_rejected/`; nenhuma imagem de idle aprovada foi alterada.
3. Não criar outro ciclo de caminhada às cegas. O próximo protótipo precisa de poses desenhadas em sequência ou uma fonte de personagem separada em layers, com regras de oclusão/overlap e regiões escondidas reconstruídas conscientemente. Uma imagem achatada não contém os pixels ocultos necessários para desocluir um membro com fidelidade.
4. Se houver atlas no futuro, exportá-lo apenas após aprovação, com metadados de retângulo, duração e origem/pivô por frame; fazer round-trip atlas→PNGs e exigir igualdade pixel a pixel. A API de export do Aseprite oferece opções explícitas de trim e padding e saída de metadata, portanto elas precisam fazer parte do contrato em vez de serem defaults implícitos. [Aseprite — ExportSpriteSheet API](https://www.aseprite.org/api/command/ExportSpriteSheet)
5. Separar sempre: `integrity da imagem` (canvas, alfa, componentes), `registration` (pivô/âncoras), `motion` (poses/continuidade) e `review artística`. Métrica de diferença de pixels não pode, sozinha, aprovar ou rejeitar qualidade de movimento.

## Próximo teste aceitável

Antes de voltar a gerar `WALK_N_FRENTE`:

- rever, com o utilizador, uma folha de poses-chave ou um ficheiro-fonte em layers; não inventar pixels ocultos;
- fixar câmara, orientação world-DOWN, canvas e root;
- desenhar/definir primeiro contacto, down, passing e up, depois as poses opostas;
- validar a prévia com APNG/preview de frames individuais, nunca com um GIF de disposal indefinido;
- rever no Godot à escala de gameplay e passo a passo;
- manter os resultados em `review/` até aprovação explícita.

## Fontes consultadas

- [Godot — animação 2D com imagens individuais ou spritesheet](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)
- [ImageMagick — disposal, transparência e coalescência de animações](https://usage.imagemagick.org/bugs/animation_bgnd/)
- [Aseprite — opções de export de spritesheet (trim, padding, metadata)](https://www.aseprite.org/api/command/ExportSpriteSheet)
