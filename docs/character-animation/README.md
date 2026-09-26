# Come to Me — R&D de perspectiva e animação do protagonista

**Estado:** `IDLE_N_FRENTE` e `IDLE_N_TRAS` (12 PNGs cada) estão aprovados provisoriamente. `IDLE_N_ESQUERDA` (candidato 05) e `IDLE_N_DIREITA` (candidato 02) têm 12 frames cada em revisão, mantendo a orientação cardinal e o rosto legível em 3/4. Nenhum ciclo novo foi copiado para produção; Godot ainda não foi testado.
**Escopo atual:** revisão do candidato direito pedido pelo utilizador; esquerda permanece em revisão. Não criar variantes de transição nem iniciar outra direção/estado em paralelo.
**Fontes aprovadas:** `characters/protagonist/animations/idle_normal/frente/` e `characters/protagonist/animations/idle_normal/tras/`. Revisão esquerda: `characters/protagonist/review/idle_n_esquerda_skeleton_05/`; direita: `characters/protagonist/review/idle_n_direita_skeleton_02/`. Rascunhos substituídos e tentativas rejeitadas permanecem arquivados em `characters/protagonist/review/rejected/`.

## 1. Decisões e correções registadas

### Identidade visual

- `art/young_man_front_back_concept.png` foi aprovada pelo utilizador como referência de identidade, roupa, paleta e aura do personagem.
- Essa folha tem vistas convencionais de frente/costas. **Serve apenas para identidade**; não define a câmera nem deve ser convertida diretamente em animação.

### Câmera

- A câmera desejada é **top-down / overhead / ligeiramente oblíqua 2.5D**.
- O personagem é visto de cima e continua a ser um sprite 2D.
- UP, DOWN, LEFT e RIGHT continuam alinhados com os eixos da tela/mundo; não rodar o mundo para o losango isométrico clássico.
- `docs/character-animation/references/camera_reference_candidate.png` aproxima-se da câmera pretendida, segundo o utilizador, mas inclui cenário. **É referência de perspectiva apenas, nunca um frame de personagem.** Mantivemos a imagem em `references/`, separada dos PNGs individuais de animação. O ângulo exato continua por aprovar/fixar.
- As direções descrevem para onde o personagem está orientado **dentro do mundo**, não uma folha de turnaround de câmera. Em todas as direções continua a ser visto pela mesma câmera superior.

### Rejeições importantes

- As folhas combinadas anteriores (frente/costas/perfil, estados e movimentos misturados) foram rejeitadas. Não reutilizar os seus frames.
- O GIF/storyboard anterior com chão, parede ou cenário incorporado foi rejeitado como asset. **Nenhuma imagem de cenário será exportada como frame de personagem.**
- O teste `IDLE_N_FRENTE` feito ao deslocar máscaras de peito/ombros sobre uma imagem-mestre foi **rejeitado pelo utilizador**: corpo rígido, sensação de estátua e movimento localizado/desconectado. Não reutilizar esses frames nem tentar corrigir apenas a velocidade do GIF.
- A tentativa generativa seguinte também foi retirada: o utilizador relata que o v3 muda formato, estrutura e aparência entre frames; no candidato 02 local, uma comparação encontrou `35.7k–39.6k` pixels opacos com cor diferente em cada par, consistente com forte variação visual. Não reutilizar como animação.
- Os ciclos `IDLE_N_FRENTE` e `IDLE_N_TRAS` estão aprovados provisoriamente pelo utilizador e têm cópias de produção validadas. Isso não substitui o teste pendente no Godot. A rejeição do teste antigo de máscaras descrito acima não se aplica ao ciclo esquelético aprovado.

## 2. Regras invioláveis dos assets

1. **Um PNG por frame.** A folha/spritesheet é apenas uma exportação opcional; os PNG individuais são a fonte oficial.
2. Formato **PNG RGBA**, com transparência real. O canal alfa deixa visível apenas o personagem; não usar fundo cinzento/preto quadriculado, cenário, chão, parede, texto, rótulo, seta, UI ou moldura.
3. Mesmas dimensões de canvas, escala, pivô de contacto com o chão e lógica de iluminação em todos os frames de uma sequência.
4. O ponto de contacto/pivô permanece fixo; alterações de pose não podem fazer o personagem saltar de lugar.
5. Pixel art deliberado: clusters coerentes, silhueta legível, paleta e contorno consistentes. Não reduzir uma ilustração grande para fingir pixel art.
6. Só desenhar sombra própria/material quando ela pertence ao sprite. **Sombra projetada no chão e oclusão ambiental pertencem ao jogo**, não ao PNG.
7. Uma direção e uma animação por pasta. Nunca combinar idle + walk, normal + fear, ou direções diferentes na mesma sequência de frames.
8. Cada loop tem **no mínimo 8 frames desenhados com diferenças intencionais**. Um número maior só é útil quando acrescenta movimento legível. Não criar clones quase idênticos para atingir contagem.
9. A aprovação da identidade não aprova automaticamente a perspectiva, animação ou integração em Godot.

## 3. Referências de produção

A imagem do utilizador com personagem em várias poses é referência de **organização de frames separados e consistência de personagem**; não copiar o personagem, roupa ou estilo do exemplo.

### Árvore de pastas

```text
characters/
└── protagonist/
    └── animations/
        ├── idle_normal/
        │   ├── frente/frame_001.png ... frame_008.png
        │   ├── tras/frame_001.png ...
        │   ├── esquerda/frame_001.png ...
        │   └── direita/frame_001.png ...
        ├── idle_fear/
        │   ├── frente/ ...
        │   ├── tras/ ...
        │   ├── esquerda/ ...
        │   └── direita/ ...
        ├── walk_fear/
        │   ├── frente/ ...
        │   ├── tras/ ...
        │   ├── esquerda/ ...
        │   └── direita/ ...
        └── walk_normal/
            ├── frente/ ...
            ├── tras/ ...
            ├── esquerda/ ...
            └── direita/ ...
```

Nomes de animação: `IDLE_N_FRENTE`, `IDLE_N_TRAS`, `IDLE_N_ESQUERDA`, `IDLE_N_DIREITA`; `IDLE_FEAR_*`; `WALK_FEAR_*`; `WALK_N_*`. Cada sequência mantém PNGs numerados `frame_001.png` em diante.

**Convenção de orientação:** FRENTE = direção mundial DOWN; TRAS = UP; ESQUERDA = LEFT; DIREITA = RIGHT. Confirmar visualmente essa convenção no protótipo de câmera e mantê-la em nomes, input e Godot.

## 4. Processo: uma sequência de cada vez

```text
PESQUISA
  → LOCK DA CÂMERA
  → REFERÊNCIA-MESTRE DO PERSONAGEM
  → PLANO DE POSES DA ANIMAÇÃO
  → DESENHO DOS PNGS INDIVIDUAIS
  → VALIDATOR TÉCNICO
  → ONION-SKIN / INSPEÇÃO FRAME A FRAME
  → PRÉ-VISUALIZAÇÃO EM GODOT
  → CORREÇÃO
  → REVISÃO HUMANA
  → APROVAÇÃO EXPLÍCITA
  → PRÓXIMA SEQUÊNCIA
```

`IDLE_N_FRENTE` e `IDLE_N_TRAS` estão aprovados provisoriamente. O candidato esquerdo 05 e o direito 02 têm 12 frames cada em review, corpos virados para a direção cardinal e rostos legíveis em 3/4. Cada um é um endpoint único; não criar variantes para transições. Ambos aguardam aprovação visual e não devem ser copiados para produção. Fear/walk continuam bloqueados.

## 5. Perspectiva-mestre e personagem

### Perspectiva

- Manter a câmera superior ligeiramente inclinada usada na referência de perspectiva, depois de confirmada pelo utilizador.
- Mostrar topo da cabeça, superfícies superiores dos ombros/roupa e relação do corpo com o chão.
- O personagem não pode parecer uma figura fotografada ao nível dos olhos; também não pode virar um boneco num losango isométrico diagonal.
- A mesma inclinação, foreshortening, centro visual, escala e direção de luz devem persistir ao virar o personagem.
- A arte precisa ser testada à escala real de gameplay; zoom de inspeção serve para limpeza, não para aprovar a silhueta final.

### Identidade

Usar a referência aprovada para manter: homem negro angolano, 26 anos, cabelo curto/coçado, barba curta, corpo adulto esguio, casaco utilitário gasto cinza-oliva, camada interna teal discreta, detalhe âmbar contido, calças e botas práticas. Luto e vício são tratados com humanidade e sutileza; nunca usar objetos de consumo como atalho visual nem estigmatizar.

### Consistência de produção

Manter um desenho-mestre e guias de proporção: altura total, largura da cabeça/ombros, comprimento do tronco/pernas, contorno do casaco, posição do detalhe âmbar e pivô. Criar frames por desenho/edição incremental do mesmo modelo, com onion skin; não pedir a um gerador imagens independentes e presumir que serão o mesmo personagem. Qualquer assistência generativa é rascunho, não autoridade de consistência.

## 6. Contagem, timing e ciclo

- **Piso do projeto: 8 frames por animação.** Começar por 8 poses-chave/in-betweens realmente úteis; considerar 10–12 se o playback mostrar saltos que não se resolvem com timing.
- O número de frames e a velocidade são variáveis diferentes. Preview inicial a 6, 8, 10, 12 e 15 FPS; escolher pela observação na escala do jogo.
- Para idle, usar durações por frame para desacelerar a aproximação/saída e manter uma pequena pausa respiratória. Não tornar cada frame igualmente espaçado por conveniência.
- Para walk, preservar os apoios dos pés nos frames de contacto. O ciclo termina em pose/velocidade que liga ao primeiro sem duplicar o primeiro frame como pausa artificial.
- Cada frame deve ter uma intenção descrita no plano. “Diferente” significa progressão de movimento deliberada, não ruído aleatório no desenho.
- Godot `SpriteFrames` permite frames a partir de imagens individuais, velocidade/loop por animação e durações por frame; a sequência pode ser controlada/testada em `AnimatedSprite2D` sem achatar as imagens num cenário ([guia oficial](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html), [API de SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html)).

## 7. Plano de inspeção e ferramentas

### Revisão visual obrigatória

Para cada sequência, rever:

- cada PNG sozinho em fundo claro e escuro (para inspecionar alfa);
- reprodução em loop;
- passos quadro a quadro;
- onion skin dos frames anterior/atual/seguinte;
- loop `último → primeiro` e `primeiro → segundo`;
- leitura ao tamanho real de gameplay e em zoom;
- as quatro direções lado a lado **apenas na revisão**, nunca como uma única animação misturada.

Aseprite documenta timeline, duração individual dos frames, preview e onion skin como ferramentas para comparar cels e rever a sequência ([animação](https://www.aseprite.org/docs/animation/), [onion skin](https://www.aseprite.org/docs/onion-skinning/)).

### Validador técnico

Existe agora `tools/validate_sprite_sequence.py`, sem dependências externas (Python standard library). Para PNGs RGBA8 não interlaçados, lê os pixels e reporta:

- contagem, nomes e ordenação sequencial dos frames;
- dimensões consistentes e formato RGBA8 não interlaçado;
- bounding box alfa, quantidade de pixels com alfa e alfa parcial, mais centróide alfa;
- número de pixels alterados entre cada par adjacente e entre último → primeiro;
- frames adjacentes idênticos e divergência de bounding box entre frames (aviso).

O relatório dá **avisos**, não vereditos artísticos. As medidas toleradas têm de ser calibradas depois de confirmar tamanho de sprite/câmera. Para idle, mudanças do contorno devem ser pequenas e explicáveis; para walk, contorno e centro de massa variam intencionalmente, mas o contacto/pé apoiado e o pivô de gameplay precisam permanecer coerentes.

Uso:

```sh
python tools/validate_sprite_sequence.py characters/protagonist/animations/idle_normal/frente \\
  --report characters/protagonist/review/IDLE_N_FRENTE_VALIDATION.md
```

Relatórios rejeitados: `characters/protagonist/review/rejected/idle_n_frente_mask_displacement_01/IDLE_N_FRENTE_VALIDATION.md` e `characters/protagonist/review/rejected/idle_n_frente_interframe_drift_02/VALIDATION.md`. O ciclo aprovado `IDLE_N_FRENTE` tem medições em `characters/protagonist/review/idle_n_frente_skeleton_03/VALIDATION.md`, cópia de produção validada em `characters/protagonist/review/IDLE_N_FRENTE_PRODUCTION_VALIDATION.md` e modelo em `SKELETON_MODEL.md`. `IDLE_N_TRAS` tem relatório de sequência em `characters/protagonist/review/idle_n_tras_skeleton_01/VALIDATION.md` e cópia de produção em `characters/protagonist/review/IDLE_N_TRAS_PRODUCTION_VALIDATION.md`. `IDLE_N_ESQUERDA` tentativa 01 rejeitada: `characters/protagonist/review/rejected/idle_n_esquerda_proportion_drift_01/VALIDATION.md`; tentativa 02 arquivada: `characters/protagonist/review/rejected/idle_n_esquerda_proportion_drift_02/`. O mestre 03 foi superado após feedback de leitura facial. Ciclo candidato esquerdo 05: `characters/protagonist/review/idle_n_esquerda_skeleton_05/`; ciclo candidato direito 02: `characters/protagonist/review/idle_n_direita_skeleton_02/`. Ambos aguardam revisão humana e teste em Godot.

### Revisão em Godot — cena preparada, execução pendente

A cena `scenes/animation_review.tscn` usa `AnimatedSprite2D`/`SpriteFrames` para testar um ciclo por vez: FRENTE e TRÁS aprovados, mais os candidatos LEFT e RIGHT em revisão. Carrega 12 PNGs por direção, durations por frame e filtro `Nearest`. Para abrir, importar o projeto no Godot, abrir `scenes/animation_review.tscn` e usar **F6 (Run Current Scene)**. Controles: `1` frente, `2` trás, `3` esquerda, `4` direita; `Space` play/pause; setas esquerda/direita avançam um frame e pausam; setas cima/baixo ajustam velocidade; `R` reinicia.

**Resultado neste sandbox:** não foi possível executar em Godot: não há binário `godot`/`godot4` instalado e a tentativa de obter o motor falhou porque os mirrors de pacotes e o CDN do release não estão acessíveis. A cena e o script estão preparados, mas a validação no motor permanece pendente; os GIFs e validadores Python não substituem esse teste.

## 8. Portão de aprovação

Uma sequência só passa se todas as respostas forem “sim”:

1. A câmera realmente vê o personagem de cima, na mesma perspectiva em todos os frames?
2. A direção mundial pretendida é legível sem transformar a vista numa pose frontal/lateral tradicional?
3. É claramente a mesma pessoa, com roupa, anatomia e paleta estáveis?
4. O ciclo comunica precisamente a ação/emoção nomeada?
5. Existem pelo menos oito frames intencionais e diferenças de pose legíveis na escala final?
6. O contacto/pivô não salta sem intenção?
7. O último frame fecha para o primeiro sem pop, congelamento ou deslocamento?
8. PNGs individuais têm alfa verdadeiro, dimensões iguais e só o personagem?
9. Validator e revisão visual foram feitos? Os problemas encontrados foram corrigidos?
10. O utilizador aprovou explicitamente essa sequência?

**Implementado ≠ reproduzível ≠ tecnicamente válido ≠ visualmente aprovado.** Registar cada estado separadamente.

## 9. Pesquisa consultada

As conclusões e limites das fontes são resumidos em [research.md](research.md); os planos artísticos independentes estão em [idle_normal.md](idle_normal.md), [idle_fear.md](idle_fear.md), [walk_fear.md](walk_fear.md) e [walk_normal.md](walk_normal.md).
