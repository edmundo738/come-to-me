# Study 01 — IDLE_NORMAL

**Emotional read:** composed, alert, alive; normal breathing under restrained tension.
**Estado atual:** `IDLE_N_FRENTE` e `IDLE_N_TRAS` aprovados provisoriamente; `IDLE_N_ESQUERDA` e `IDLE_N_DIREITA` têm ciclos candidatos em revisão. O foco agora é testar no Godot o seletor das quatro direções.
**Não iniciar agora:** caminhada, medo, piscada como ação separada ou gestos até concluir a revisão dos idles.

## What the player should perceive

The protagonist is standing still and breathing; he is not bobbing, walking in place, nodding, or changing his footing. This should read at the actual gameplay scale. On the overhead sprite, breathing is communicated by small upper-torso silhouette/shading changes; do not depend on a large visible front chest or a face-only change.

## Pose map: 8 distinct authored frames

| Frame | Pose intention | What changes | What stays locked |
|---|---|---|---|
| 001 | Quiet rest after exhale | Baseline shape and cloth shading | Feet/ground pivot, head direction, camera |
| 002 | Inhale begins | Chest/upper jacket starts to expand | Legs, hands, head anchor |
| 003 | Inhale continues | Ribcage contour/shading expands slightly more | Foot contact, overall identity |
| 004 | Upper body follows | Shoulders/collar rise a little after chest; sleeves lag | Hips and planted feet |
| 005 | Inhale peak | Small held maximum; not a new pose | Camera, face direction, legs |
| 006 | Exhale begins | Chest compresses toward baseline; shoulders remain briefly raised | Ground pivot |
| 007 | Exhale continues | Shoulder/sleeve follow-through settles after chest | Legs and direction |
| 008 | Near-rest transition | Almost back to frame 001; tiny residual settling so loop closes without a duplicate-frame pause | Character envelope and pivot |

These are a **pose plan**, not a request to make eight random variations. Frames 001–008 must be drawn/edited as an intentional cycle and reviewed individually. If the breathing cannot be read at gameplay scale, change the amplitude/timing or simplify; do not add unrelated limb motion.

## Teste 01 — `IDLE_N_FRENTE` (REJEITADO)

O utilizador rejeitou este ciclo: **“o idle é travado, nada realista; uma parte do corpo se move e o resto parece uma estátua; nada agradável para gameplay.”** A avaliação é correta: deslocar máscaras de peito e ombros sobre uma imagem parada criou movimento localizado e desconectado, em vez de respiração corporal. Cabeça, braços, pernas e roupa ficaram congelados, enfatizando a rigidez. Não usar como animação, não tentar salvá-lo só alterando FPS e não mover estes frames de volta à pasta de produção.

Foi um teste screen-down derivado de uma imagem-mestre: a máscara de peito e a de ombros foram deslocadas por offsets. Os números a seguir documentam **somente essa tentativa rejeitada** e não são uma receita para o próximo ciclo.

Offsets de edição nesta prova (eixo Y da imagem, valores negativos = para cima):

| Frame | Peito | Ombros | Leitura |
|---|---:|---:|---|
| 001 | 0 px | 0 px | repouso |
| 002 | -2 px | 0 px | início de inspiração |
| 003 | -4 px | -1 px | tórax expande; ombros começam a seguir |
| 004 | -6 px | -3 px | inspiração/seguimento |
| 005 | -8 px | -4 px | pico/hold |
| 006 | -6 px | -4 px | expiração começa; ombros ainda sustentam |
| 007 | -3 px | -2 px | ombros e tórax assentam |
| 008 | +1 px | 0 px | passagem mínima pelo repouso para fechar o loop sem frame copiado |

O teste arquivado usava durações variáveis em GIF: `0.65, 0.25, 0.25, 0.25, 0.45, 0.25, 0.35, 0.65 s` (ciclo de 3.10 s). Os oito PNGs, o GIF e a folha de contacto foram movidos para `characters/protagonist/review/rejected/idle_n_frente_mask_displacement_01/`. São evidência do teste rejeitado, não fonte oficial nem previews de uma animação utilizável.

**Medição técnica do teste rejeitado:** 8/8 PNGs tinham canvas `384×544`, canal `sRGBA`, alfa não opaco e bounding box igual (`336×491`, origem `(+24,+27)`); pernas/pés não mudavam. Isto só prova que as imagens tinham dimensões coerentes e pixels diferentes — o feedback do utilizador confirma que esses números não medem qualidade de movimento. A falha de articulação é decisiva, não um detalhe a afinar.

**Diretriz para redesenho:** não mover recortes/máscaras sobre um corpo congelado. Criar poses consecutivas em que tórax/jaqueta, linha dos ombros, mangas/braços e dobras do tecido respondam como um conjunto ligado, com atraso subtil entre partes. Manter peso e pés apoiados, sem transladar o personagem inteiro ou fazê-lo saltar.

## Redesign 02 — REJEITADO por inconsistência entre frames

Foi gerada uma segunda folha 4×2 e extraída para `characters/protagonist/review/rejected/idle_n_frente_interframe_drift_02/frames/`. O magenta foi eliminado para alfa; os oito PNGs foram alinhados num canvas `384×544`, com altura normalizada por escala nearest-neighbor e âncora dos pés em `y=504`. Os previews e contacto estão no mesmo arquivo, apenas como evidência do teste rejeitado.

**FACT técnico:** o validador encontra 8 PNGs RGBA8 com canvas igual, alfa transparente e frames adjacentes diferentes. As larguras alfa variam com a pose (`172–193 px` após key/normalização), e o relatório regista avisos de contorno. Comparação extra de cor encontrou cerca de `35.7k–39.6k` pixels opacos com RGB diferente em cada par, sinal de possível cintilação/reinterpretação de textura entre células. **Não foram testados em Godot e ainda não são um ciclo limpo.**

**Falha/estado:** o redesign 02 está rejeitado. Apesar do alfa e do canvas alinhados, comparação encontrou cerca de `35.7k–39.6k` pixels opacos com RGB diferente em cada par — variação ampla de textura/desenho, não uma sequência visualmente estável. O utilizador reporta ainda que o v3 altera formato, estrutura e aparência entre frames. Os ficheiros v3 citados no histórico não estão nesta cópia do workspace, então não afirmo ter medido essa versão. Não promover nenhuma tentativa à pasta de produção nem começar outra sequência.

## Prototype 03 — skeletal breathing (APROVADO provisoriamente pelo utilizador)

Para combater simultaneamente o encolhimento/crescimento e a deriva de textura, foi criado o gerador determinístico `tools/skeletal_idle.py`. Parte de **um só sprite canónico** (`frame_001.png` do arquivo 02); não volta a desenhar roupa ou personagem em cada frame. Os 12 PNGs de produção estão em `characters/protagonist/animations/idle_normal/frente/`; preview e notas ficam em `characters/protagonist/review/idle_n_frente_skeleton_03/`. O utilizador aprovou este ciclo para uso provisório, com possíveis ajustes futuros.

O esqueleto screen-space usa âncoras de cabeça/pescoço, ombros, cotovelos, pulsos, tórax, cintura, quadril e pés. Os comprimentos dos ossos dos braços são preservados por rotação rígida: `p' = s' + R(θ)(p-s)`. A deformação local usa pesos Gaussianos normalizados, `wᵢ(q)=exp(-||q-jᵢ||²/(2σᵢ²))` e `D(q)=ΣwᵢΔᵢ/Σwᵢ + D_tórax(q)`; o inverse map resolve `q=p-D(q)` por quatro iterações, depois amostra com nearest-neighbour. A fase do tórax começa primeiro, ombros atrasam e braços acompanham depois.

**Invariantes medidos/assertados pelo script:** escala global `1.0`; caixa alfa idêntica em todos os frames (`172×354`, mesma origem); cor/pixels de `y≤226` e `y≥386` são byte a byte iguais ao mestre, incluindo pernas/pés; nenhuma cópia exata adjacente nem no fecho do loop. Para reduzir a rigidez sem aumentar a amplitude, os **8 control keys** agora são interpolados suavemente em **12 cels**, com limite de overshoot; deslocamento máximo continua `1.20 px` horizontal e `1.52 px` vertical. Preview total: `3.19 s`. Ver `SKELETON_MODEL.md` e `VALIDATION.md` na pasta do candidato.

O utilizador considerou a respiração suficientemente boa para uso provisório, com possibilidade de retomar ajustes. A verificação matemática confirma as invariantes, não perfeição artística. A integração/escala no Godot continua sem teste neste ambiente.

## `IDLE_N_TRAS` — APROVADO provisoriamente

Após `IDLE_N_FRENTE`, o utilizador aprovou também o ciclo independente voltado para world UP. Os 12 PNGs RGBA estão em `characters/protagonist/animations/idle_normal/tras/`; o sprite-mestre, preview e medições permanecem em `characters/protagonist/review/idle_n_tras_skeleton_01/`. Mantém a mesma câmera superior, canvas `384×544`, altura alfa `354 px`, root e ferramenta esquelética. O bounds traseiro mede 4 px a mais de largura (`176×354` vs `172×354` no frente; +2.3%), aceite provisoriamente sem escala não uniforme. Godot ainda não foi testado.

## `IDLE_N_ESQUERDA` — tentativa 01 REJEITADA

O utilizador observou estilo diferente, proporção atarracada e falta de continuidade com as vistas frontal/traseira. A sequência e o mestre foram arquivados em `characters/protagonist/review/rejected/idle_n_esquerda_proportion_drift_01/`; não usar nem promover esses PNGs.

O utilizador reportou head/neck `+24.7%` em largura e `+27.9%` em área, e pernas/pés `+12.1%` em área. O comparador local com regiões normalizadas também sinalizou deriva: cabeça/pescoço `+19.9%` em área e pelvis/pernas/pés `+11.1%`, em relação ao mestre frontal. Relatórios: `VALIDATION.md` (anota a avaliação e medidas reportadas) e `PROPORTION_COMPARISON.md` (método reproduzível local).

**Pré-candidato 02 também bloqueado:** mestre arquivado em `characters/protagonist/review/rejected/idle_n_esquerda_proportion_drift_02/`. Foi comparado com a frente aprovada antes de gerar qualquer ciclo; falhou largura total (−23,3%), cabeça (largura −34,9%), torso (área −25,2%) e região inferior (área −18,7%). Também divergiu no acabamento pixel-art. Não foram produzidos frames.

## Mestre candidato 03 — SUPERADO por leitura facial insuficiente

O utilizador observou que o rosto e a expressão não se liam como nas outras vistas. O rascunho 03 estava demasiado de perfil; foi mantido apenas como histórico em `characters/protagonist/review/idle_n_esquerda_skeleton_03/`.

## Ciclo candidato 05 — esquerda 3/4 com rosto legível (EM REVISÃO)

A correção mantém ombros, tronco e pés orientados para world LEFT, mas volta ligeiramente a cabeça para a câmera: olhos/sobrancelhas, nariz, boca e barba ficam visíveis, preservando a expressão séria e atenta da frente aprovada. É um único endpoint canónico para `IDLE_N_FRENTE → IDLE_N_ESQUERDA` e `IDLE_N_TRAS → IDLE_N_ESQUERDA`; não criar variantes esquerda-frente/esquerda-trás.

O mestre, 12 frames, previews e comparações estão em `characters/protagonist/review/idle_n_esquerda_skeleton_05/`. O ciclo usa rig específico para a silhueta lateral, respiração subtil e contínua, mantendo rosto e pernas/pés fixos. Validador técnico passou sem erros nem avisos. A projeção regional mostra torso menor do que nas vistas frontais/traseiras, então proporção, estilo e leitura da expressão ainda exigem revisão humana.

**Estado:** sequência em review, ainda não aprovada e não copiada para produção. O utilizador pediu avançar para `IDLE_N_DIREITA`, seguindo esta abordagem.

## `IDLE_N_DIREITA` — ciclo candidato 02 (EM REVISÃO)

Foi criado um mestre 3/4 voltado para world RIGHT e um ciclo de 12 frames, mantendo face/expressão visíveis e respirando com o mesmo ritmo/amplitude subtil. O primeiro rascunho amplo/frontal foi arquivado; candidato ativo e frames estão em `characters/protagonist/review/idle_n_direita_skeleton_02/`.

O mestre direito compara-se de perto com o esquerdo candidato 05: altura igual, largura `+2,3%`, cabeça/área `−0,8%`, tronco `+4,2%` e região inferior `+3,0%`. O gate técnico da sequência passou sem erros nem avisos; ainda precisa de revisão visual e não foi testado no Godot.

**Estado:** ciclo em review, ainda não aprovado e não copiado para produção. Usar um único endpoint canónico world RIGHT; não criar variantes de transição direita-frente/direita-trás.

## Timing starting hypothesis

Test a relaxed 3–4 second cycle at 6, 8, 10, 12 and 15 FPS. Hold the inhale/exhale extrema longer than their transition frames; tune per-frame durations in Godot `SpriteFrames`. Do not declare the timing final until the loop is observed at gameplay scale. At low resolution, one pixel can be a large proportion of a small sprite; determine pixel offsets from actual final canvas size, not a fixed recipe.

## Directional rules

Convenção: FRENTE = world DOWN; TRAS = world UP; ESQUERDA = world LEFT; DIREITA = world RIGHT, sempre sob a mesma câmera overhead/oblíqua. Cada direção usa um endpoint canónico único: a mesma pose esquerda serve ao virar tanto de frente como de trás; a mesma regra vale para direita. Não criar variantes frente-esquerda/costas-esquerda ou frente-direita/costas-direita. As transições podem ter origem diferente, mas convergem para o endpoint da direção cardinal. Não interpretar “frente” como retrato ao nível dos olhos nem espelhar PNGs aprovados sem revisão: casaco e detalhes de identidade são assimétricos.

## Failure conditions

- Feet/anchor drift or body translates vertically as one block.
- The sprite appears to hop or walk in place.
- Head bob is larger than the breathing cue, or the face becomes an eye-level portrait.
- The loop has an obvious freeze/pop at the final frame → 001.
- Frames differ only by noise/lighting flicker, not a coherent inhale/exhale.
- Any frame includes floor, shadow, wall, background or UI.

## Research basis

The pixel-art tutorial begins with chest motion, small pixel shifts and altered chest shading; it slows the peak frames to avoid a mechanical equal-timing loop ([Tsugumo](http://www.gas13.ru/v3/tutorials/sywtbapa_breathing_life_into_sprites.php)). The general follow-through idea—chest first, shoulders and arms responding slightly later—is adapted cautiously from [AnimSchool's breathing demonstration](https://blog.animschool.edu/2024/11/15/breathing-life-into-your-animation/). See [research.md](research.md) for limitations and sources.

## Acceptance checklist

- [x] Exactly one direction, `IDLE_N_FRENTE`, in its own folder.
- [x] 12 separate RGBA PNG frames; same canvas and transparent background.
- [x] User confirms the breathing reads well enough for provisional use; lower body/feet are mathematically locked.
- [x] Canvas, silhouette bounds, scale and root remain stable.
- [ ] All frames reviewed in onion skin; loop preview reviewed by user.
- [x] PNG metrics report run; no bounds or alpha errors/warnings.
- [ ] Tested at 6/8/10/12/15 FPS in Godot; engine test remains pending.
- [x] User explicitly approved this sequence before `IDLE_N_TRAS` starts.
