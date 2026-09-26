# Cross-frame sprite proportion comparison

**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.

- Master: `characters/protagonist/animations/idle_normal/frente/frame_001.png` — bbox `(106, 150, 172, 354)`, alpha pixels `37787`, centroid `(191.89,322.80)`
- Candidate: `characters/protagonist/review/idle_n_esquerda_skeleton_03/master_candidate.png` — bbox `(127, 150, 130, 354)`, alpha pixels `30198`, centroid `(192.11,323.04)`

| Metric | Master | Candidate | Delta | Result |
|---|---:|---:|---:|---|
| Whole-sprite height | 354.00 | 354.00 | +0.0% | PASS |
| Whole-sprite width | 172.00 | 130.00 | -24.4% | REVIEW |
| Head/neck region width | 129.00 | 77.00 | -40.3% | REVIEW |
| head_neck alpha area | 5724.00 | 5459.00 | -4.6% | PASS |
| shoulders_chest alpha area | 18972.00 | 13602.00 | -28.3% | REVIEW |
| pelvis_legs_feet alpha area | 13091.00 | 11137.00 | -14.9% | REVIEW |

## Regional silhouette shares

| Region | Master area / total | Candidate area / total |
|---|---:|---:|
| head_neck | 15.1% | 18.1% |
| shoulders_chest | 50.2% | 45.0% |
| pelvis_legs_feet | 34.6% | 36.9% |

## Warnings

- Whole-sprite width differs by -24.4% (limit ±4.0%)
- Head/neck region width differs by -40.3% (limit ±25.0%)
- shoulders_chest alpha area differs by -28.3% (limit ±10.0%)
- pelvis_legs_feet alpha area differs by -14.9% (limit ±10.0%)
