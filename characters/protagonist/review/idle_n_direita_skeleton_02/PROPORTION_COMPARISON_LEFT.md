# Cross-frame sprite proportion comparison

**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.

- Master: `characters/protagonist/review/idle_n_esquerda_skeleton_05/master_candidate.png` — bbox `(127, 150, 130, 354)`, alpha pixels `30136`, centroid `(192.15,323.19)`
- Candidate: `characters/protagonist/review/idle_n_direita_skeleton_02/master_candidate.png` — bbox `(126, 150, 133, 354)`, alpha pixels `31002`, centroid `(192.04,323.85)`

| Metric | Master | Candidate | Delta | Result |
|---|---:|---:|---:|---|
| Whole-sprite height | 354.00 | 354.00 | +0.0% | PASS |
| Whole-sprite width | 130.00 | 133.00 | +2.3% | PASS |
| Head/neck region width | 77.00 | 78.00 | +1.3% | PASS |
| head_neck alpha area | 5416.00 | 5375.00 | -0.8% | PASS |
| shoulders_chest alpha area | 13591.00 | 14159.00 | +4.2% | PASS |
| pelvis_legs_feet alpha area | 11129.00 | 11468.00 | +3.0% | PASS |

## Regional silhouette shares

| Region | Master area / total | Candidate area / total |
|---|---:|---:|
| head_neck | 18.0% | 17.3% |
| shoulders_chest | 45.1% | 45.7% |
| pelvis_legs_feet | 36.9% | 37.0% |

## Warnings

- None
