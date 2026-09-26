# Cross-frame sprite proportion comparison

**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.

- Master: `characters/protagonist/review/idle_n_esquerda_skeleton_05/master_candidate.png` — bbox `(127, 150, 130, 354)`, alpha pixels `30136`, centroid `(192.15,323.19)`
- Candidate: `characters/protagonist/review/idle_n_direita_skeleton_01/master_candidate.png` — bbox `(109, 150, 167, 354)`, alpha pixels `36779`, centroid `(193.44,322.22)`

| Metric | Master | Candidate | Delta | Result |
|---|---:|---:|---:|---|
| Whole-sprite height | 354.00 | 354.00 | +0.0% | PASS |
| Whole-sprite width | 130.00 | 167.00 | +28.5% | REVIEW |
| Head/neck region width | 77.00 | 108.00 | +40.3% | REVIEW |
| head_neck alpha area | 5416.00 | 5715.00 | +5.5% | PASS |
| shoulders_chest alpha area | 13591.00 | 18235.00 | +34.2% | REVIEW |
| pelvis_legs_feet alpha area | 11129.00 | 12829.00 | +15.3% | REVIEW |

## Regional silhouette shares

| Region | Master area / total | Candidate area / total |
|---|---:|---:|
| head_neck | 18.0% | 15.5% |
| shoulders_chest | 45.1% | 49.6% |
| pelvis_legs_feet | 36.9% | 34.9% |

## Warnings

- Whole-sprite width differs by +28.5% (limit ±4.0%)
- Head/neck region width differs by +40.3% (limit ±25.0%)
- shoulders_chest alpha area differs by +34.2% (limit ±10.0%)
- pelvis_legs_feet alpha area differs by +15.3% (limit ±10.0%)
