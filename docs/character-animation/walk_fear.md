# Study 03 — WALK_FEAR

**Dependency:** begin only after the overhead camera, directional base, `IDLE_N`, and normal walk mechanics are understood.
**Emotional read:** the same protagonist walks while wary/afraid, protecting himself and listening to danger.
**Not in this study:** random shaking, sprinting, a color-only filter, or a different person.

## Motion study

Keep the physical logic of a walk cycle (contact, weight/down, passing, up/push-off) and alter its timing, stride and acting. A fearful walk may shorten steps, keep shoulders raised, draw elbows closer, lean slightly away from perceived danger, hesitate before a contact, and keep the head attentive. It still needs two coherent steps and grounded foot support. Fear must not make the limbs jitter independently.

This is a project acting hypothesis; the walk-cycle anatomy comes from general animation practice and must be evaluated in the project's top-down camera.

## Frame plan: 8-frame first study

1. Guarded contact A: smaller reaching step; upper body remains protected.
2. Cautious down A: weight lands carefully, not with a confident bounce.
3. Passing A: rear foot passes close to the planted leg; elbows stay near torso.
4. Hesitant up A: brief contained recovery before the next step.
5. Guarded contact B: opposite foot leads; preserve asymmetric tension.
6. Cautious down B: absorb weight with limited stride and raised shoulders.
7. Passing B: head/upper body make a small listening adjustment only if it remains readable.
8. Recovery toward contact A: end in a motion that joins the loop without a frozen duplicate.

If the gait requires 10–12 frames to show a hesitation or breath catch clearly, add those as intentional timing poses. Do not add filler frames. Set longer holds on the cautious checks and quicker transitions where the body commits to moving.

## Difference from WALK_NORMAL

- Normal walk: balanced stride, relaxed arm counter-swing, regular timing.
- Fear walk: shorter stride, reduced arm swing, shoulders/forearms guarded, weight more cautious, timing less even but loop still coherent.
- Identity, camera, anatomy, palette and materials remain the same. Do not signal fear by changing color alone.

## Evaluation

Play normal and fear loops at the same character scale and compare. The fear state should read before the player notices color. Check that the fearful stride still covers the same gameplay cell duration; if the legs move slower while the root moves at normal speed, avoid visible sliding by retiming or choosing a different movement tween.

## Failure conditions

- Continuous trembling in every frame; walk no longer has readable support phases.
- Fear is indistinguishable from normal after removing color.
- Overly tiny steps cause foot skating relative to grid movement.
- Head/torso direction changes independently in a way that breaks anatomy.
- Any direction is shown at eye-level or with a different camera.
