# Cross-frame sprite proportion comparison

**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.

- Master: `characters/protagonist/animations/idle_normal/frente/frame_001.png` — bbox `(106, 150, 172, 354)`, alpha pixels `37787`, centroid `(191.89,322.80)`
- Candidate: `characters/protagonist/review/idle_n_direita_skeleton_01/master_candidate.png` — bbox `(109, 150, 167, 354)`, alpha pixels `36779`, centroid `(193.44,322.22)`

| Metric | Master | Candidate | Delta | Result |
|---|---:|---:|---:|---|
| Whole-sprite height | 354.00 | 354.00 | +0.0% | PASS |
| Whole-sprite width | 172.00 | 167.00 | -2.9% | PASS |
| Head/neck region width | 129.00 | 108.00 | -16.3% | PASS |
| head_neck alpha area | 5724.00 | 5715.00 | -0.2% | PASS |
| shoulders_chest alpha area | 18972.00 | 18235.00 | -3.9% | PASS |
| pelvis_legs_feet alpha area | 13091.00 | 12829.00 | -2.0% | PASS |

## Regional silhouette shares

| Region | Master area / total | Candidate area / total |
|---|---:|---:|
| head_neck | 15.1% | 15.5% |
| shoulders_chest | 50.2% | 49.6% |
| pelvis_legs_feet | 34.6% | 34.9% |

## Warnings

- None
