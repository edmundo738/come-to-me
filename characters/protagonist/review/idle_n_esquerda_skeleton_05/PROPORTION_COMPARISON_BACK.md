# Cross-frame sprite proportion comparison

**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.

- Master: `characters/protagonist/animations/idle_normal/tras/frame_001.png` — bbox `(104, 150, 176, 354)`, alpha pixels `36016`, centroid `(191.56,326.69)`
- Candidate: `characters/protagonist/review/idle_n_esquerda_skeleton_05/master_candidate.png` — bbox `(127, 150, 130, 354)`, alpha pixels `30136`, centroid `(192.15,323.19)`

| Metric | Master | Candidate | Delta | Result |
|---|---:|---:|---:|---|
| Whole-sprite height | 354.00 | 354.00 | +0.0% | PASS |
| Whole-sprite width | 176.00 | 130.00 | -26.1% | REVIEW |
| Head/neck region width | 72.00 | 77.00 | +6.9% | PASS |
| head_neck alpha area | 4893.00 | 5416.00 | +10.7% | PASS |
| shoulders_chest alpha area | 18026.00 | 13591.00 | -24.6% | REVIEW |
| pelvis_legs_feet alpha area | 13097.00 | 11129.00 | -15.0% | REVIEW |

## Regional silhouette shares

| Region | Master area / total | Candidate area / total |
|---|---:|---:|
| head_neck | 13.6% | 18.0% |
| shoulders_chest | 50.0% | 45.1% |
| pelvis_legs_feet | 36.4% | 36.9% |

## Warnings

- Whole-sprite width differs by -26.1% (limit ±4.0%)
- shoulders_chest alpha area differs by -24.6% (limit ±10.0%)
- pelvis_legs_feet alpha area differs by -15.0% (limit ±10.0%)
