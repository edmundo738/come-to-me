# Cross-frame sprite proportion comparison

**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.

- Master: `characters/protagonist/animations/idle_normal/frente/frame_001.png` — bbox `(106, 150, 172, 354)`, alpha pixels `37787`, centroid `(191.89,322.80)`
- Candidate: `characters/protagonist/review/idle_n_direita_skeleton_02/master_candidate.png` — bbox `(126, 150, 133, 354)`, alpha pixels `31002`, centroid `(192.04,323.85)`

| Metric | Master | Candidate | Delta | Result |
|---|---:|---:|---:|---|
| Whole-sprite height | 354.00 | 354.00 | +0.0% | PASS |
| Whole-sprite width | 172.00 | 133.00 | -22.7% | REVIEW |
| Head/neck region width | 129.00 | 78.00 | -39.5% | REVIEW |
| head_neck alpha area | 5724.00 | 5375.00 | -6.1% | PASS |
| shoulders_chest alpha area | 18972.00 | 14159.00 | -25.4% | REVIEW |
| pelvis_legs_feet alpha area | 13091.00 | 11468.00 | -12.4% | REVIEW |

## Regional silhouette shares

| Region | Master area / total | Candidate area / total |
|---|---:|---:|
| head_neck | 15.1% | 17.3% |
| shoulders_chest | 50.2% | 45.7% |
| pelvis_legs_feet | 34.6% | 37.0% |

## Warnings

- Whole-sprite width differs by -22.7% (limit ±4.0%)
- Head/neck region width differs by -39.5% (limit ±25.0%)
- shoulders_chest alpha area differs by -25.4% (limit ±10.0%)
- pelvis_legs_feet alpha area differs by -12.4% (limit ±10.0%)
