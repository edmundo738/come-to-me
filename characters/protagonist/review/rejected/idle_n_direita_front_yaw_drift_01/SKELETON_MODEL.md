# Skeletal breathing review — right profile

Canonical source: `characters/protagonist/review/idle_n_direita_skeleton_01/master_candidate.png`
Rig profile: `right` screen-space landmarks.
Method: 8 bounded control keys interpolated periodically into 12 cels with Catmull-Rom; fixed-root 2D landmarks, constant-length shoulder→elbow→wrist rotations, Gaussian-weighted inverse displacement, nearest-neighbour pixel sampling.
Preview timing: (27, 25, 25, 25, 27, 30, 30, 30, 25, 25, 25, 25) centiseconds (total 3.19s).
Bone rule: p' = s' + R(theta)(p-s), so each shoulder→elbow and elbow→wrist length is invariant under its rotation.
Skinning field: w_j(q)=exp(-||q-j||²/(2σ_j²)); D(q)=Σ(w_jΔ_j)/Σw_j + D_rib(q). For each output pixel p, solve q=p-D(q) by four fixed-point iterations, then sample the nearest source pixel.
Rib expansion is a small Gaussian around the chest center, scaled by the chest phase; joint phase curves make the chest lead, shoulders lag, and arms follow.
Global scale is exactly 1.0. The outer silhouette envelope is pinned horizontally; crown (`y<=226`) and lower body/feet (`y>=386`) are byte-identical to the source in all frames. The script asserts unchanged alpha bounds and no exact duplicate frames. This is a review prototype, not an artistic approval.

| Frame | Chest phase | Shoulder phase | Arm phase | Max horizontal displacement | Max vertical displacement |
|---:|---:|---:|---:|---:|---:|
| 001 | 0.00 | 0.00 | 0.00 | 0.00px | 0.00px |
| 002 | 0.48 | 0.00 | 0.00 | 0.50px | 0.68px |
| 003 | 0.77 | 0.06 | 0.04 | 0.81px | 1.11px |
| 004 | 0.78 | 0.14 | 0.10 | 0.83px | 1.13px |
| 005 | 0.86 | 0.27 | 0.20 | 0.93px | 1.26px |
| 006 | 0.95 | 0.44 | 0.33 | 1.06px | 1.40px |
| 007 | 1.00 | 0.62 | 0.50 | 1.20px | 1.50px |
| 008 | 0.87 | 0.82 | 0.74 | 1.20px | 1.35px |
| 009 | 0.69 | 0.88 | 0.88 | 1.20px | 1.44px |
| 010 | 0.50 | 0.85 | 0.88 | 1.20px | 1.39px |
| 011 | 0.28 | 0.62 | 0.69 | 1.20px | 1.05px |
| 012 | 0.08 | 0.31 | 0.36 | 0.70px | 0.53px |
