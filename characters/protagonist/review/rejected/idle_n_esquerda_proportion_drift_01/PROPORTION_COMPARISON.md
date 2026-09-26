# Cross-frame sprite proportion comparison

**Scope:** screen-space geometry heuristic; direction/camera changes require a human-calibrated tolerance. This does not judge art style or natural acting.

- Master: `characters/protagonist/animations/idle_normal/frente/frame_001.png` — bbox `(106, 150, 172, 354)`, alpha pixels `37787`, centroid `(191.89,322.80)`
- Candidate: `characters/protagonist/review/rejected/idle_n_esquerda_proportion_drift_01/master_candidate.png` — bbox `(108, 150, 167, 354)`, alpha pixels `39113`, centroid `(188.68,322.37)`

| Metric | Master | Candidate | Delta | Result |
|---|---:|---:|---:|---|
| Whole-sprite height | 354.00 | 354.00 | +0.0% | PASS |
| Whole-sprite width | 172.00 | 167.00 | -2.9% | PASS |
| Head/neck region width | 129.00 | 108.00 | -16.3% | PASS |
| head_neck alpha area | 5724.00 | 6863.00 | +19.9% | REVIEW |
| shoulders_chest alpha area | 18972.00 | 17708.00 | -6.7% | PASS |
| pelvis_legs_feet alpha area | 13091.00 | 14542.00 | +11.1% | REVIEW |

## Regional silhouette shares

| Region | Master area / total | Candidate area / total |
|---|---:|---:|
| head_neck | 15.1% | 17.5% |
| shoulders_chest | 50.2% | 45.3% |
| pelvis_legs_feet | 34.6% | 37.2% |

## Warnings

- head_neck alpha area differs by +19.9% (limit ±15.0%)
- pelvis_legs_feet alpha area differs by +11.1% (limit ±10.0%)
