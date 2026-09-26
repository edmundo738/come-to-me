# Cross-frame sprite proportion comparison

**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.

- Master: `characters/protagonist/animations/idle_normal/frente/frame_001.png` — bbox `(106, 150, 172, 354)`, alpha pixels `37787`, centroid `(191.89,322.80)`
- Candidate: `characters/protagonist/review/rejected/idle_n_esquerda_proportion_drift_02/master_candidate.png` — bbox `(126, 150, 132, 354)`, alpha pixels `29995`, centroid `(191.55,321.73)`

| Metric | Master | Candidate | Delta | Result |
|---|---:|---:|---:|---|
| Whole-sprite height | 354.00 | 354.00 | +0.0% | PASS |
| Whole-sprite width | 172.00 | 132.00 | -23.3% | REVIEW |
| Head/neck region width | 129.00 | 84.00 | -34.9% | REVIEW |
| head_neck alpha area | 5724.00 | 5169.00 | -9.7% | PASS |
| shoulders_chest alpha area | 18972.00 | 14184.00 | -25.2% | REVIEW |
| pelvis_legs_feet alpha area | 13091.00 | 10642.00 | -18.7% | REVIEW |

## Regional silhouette shares

| Region | Master area / total | Candidate area / total |
|---|---:|---:|
| head_neck | 15.1% | 17.2% |
| shoulders_chest | 50.2% | 47.3% |
| pelvis_legs_feet | 34.6% | 35.5% |

## Warnings

- Whole-sprite width differs by -23.3% (limit ±4.0%)
- Head/neck region width differs by -34.9% (limit ±25.0%)
- shoulders_chest alpha area differs by -25.2% (limit ±10.0%)
- pelvis_legs_feet alpha area differs by -18.7% (limit ±10.0%)
