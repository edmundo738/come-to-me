import math
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from spritedna_walk import FRAME_COUNT, frame_pose


class SpriteDNAWalkTests(unittest.TestCase):
    def test_leg_bone_lengths_remain_fixed_for_all_rendered_frames(self):
        for frame in range(FRAME_COUNT):
            pose = frame_pose(frame)
            for side in ("l", "r"):
                with self.subTest(frame=frame + 1, side=side):
                    upper = math.dist(pose[f"hip_{side}"], pose[f"knee_{side}"])
                    lower = math.dist(pose[f"knee_{side}"], pose[f"ankle_{side}"])
                    self.assertAlmostEqual(upper, 38.0, places=6)
                    self.assertAlmostEqual(lower, 31.0, places=6)

    def test_left_and_right_feet_alternate(self):
        first = frame_pose(0)
        opposite = frame_pose(FRAME_COUNT // 2)
        self.assertGreater(first["ankle_l"][1], first["ankle_r"][1])
        self.assertLess(opposite["ankle_l"][1], opposite["ankle_r"][1])

    def test_source_root_is_not_encoded_as_world_travel(self):
        first = frame_pose(0)
        opposite = frame_pose(FRAME_COUNT // 2)
        # Pelvis sway is a small weight shift; the root/master registration stays fixed.
        self.assertLess(abs(first["head"][0] - opposite["head"][0]), 0.01)
        self.assertLess(abs(first["head"][1] - opposite["head"][1]), 1.0)

    def test_cycle_has_no_large_control_point_pop_at_wrap(self):
        last = frame_pose(FRAME_COUNT - 1)
        first = frame_pose(0)
        for landmark in ("head", "chest", "hip_l", "hip_r", "ankle_l", "ankle_r"):
            with self.subTest(landmark=landmark):
                self.assertLess(math.dist(last[landmark], first[landmark]), 8.0)


if __name__ == "__main__":
    unittest.main()
