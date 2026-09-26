import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from skeletal_idle import write_png_rgba8
from spritedna_preview_apng import (
    DISPOSE_BACKGROUND,
    BLEND_SOURCE,
    PNG_SIGNATURE,
    filtered_scanlines,
    write_apng,
)
from validate_sprite_sequence import read_png_rgba8


def read_chunks(data: bytes):
    assert data.startswith(PNG_SIGNATURE)
    position = len(PNG_SIGNATURE)
    chunks = []
    while position < len(data):
        length = struct.unpack_from(">I", data, position)[0]
        kind = data[position + 4 : position + 8]
        start = position + 8
        payload = data[start : start + length]
        crc = struct.unpack_from(">I", data, start + length)[0]
        assert crc == (zlib.crc32(kind + payload) & 0xFFFFFFFF)
        chunks.append((kind, payload))
        position = start + length + 4
        if kind == b"IEND":
            break
    return chunks


class SpriteDNAPreviewTests(unittest.TestCase):
    def test_apng_reproduces_each_full_rgba_frame_and_clears_previous(self):
        with tempfile.TemporaryDirectory() as tmp:
            review = Path(tmp) / "review"
            frames = review / "frames"
            frames.mkdir(parents=True)
            width, height = 3, 2
            samples = [
                bytes([255, 0, 0, 255, 0, 0, 0, 0, 1, 2, 3, 255] * 2),
                bytes([0, 255, 0, 255, 0, 0, 0, 0, 4, 5, 6, 255] * 2),
            ]
            for index, rgba in enumerate(samples, 1):
                write_png_rgba8(frames / f"frame_{index:03d}.png", width, height, rgba)
            output = review / "preview.apng"
            write_apng(frames, output, 12.5)

            chunks = read_chunks(output.read_bytes())
            kinds = [kind for kind, _ in chunks]
            self.assertEqual(kinds.count(b"acTL"), 1)
            self.assertEqual(kinds.count(b"fcTL"), 2)
            self.assertEqual(kinds.count(b"IDAT"), 1)
            self.assertEqual(kinds.count(b"fdAT"), 1)
            self.assertEqual(struct.unpack(">II", next(payload for kind, payload in chunks if kind == b"acTL")), (2, 0))

            controls = [payload for kind, payload in chunks if kind == b"fcTL"]
            for control in controls:
                values = struct.unpack(">IIIIIHHBB", control)
                self.assertEqual((values[-2], values[-1]), (DISPOSE_BACKGROUND, BLEND_SOURCE))
                self.assertEqual((values[1], values[2]), (width, height))

            streams = []
            first_stream = bytearray()
            other_stream = bytearray()
            for kind, payload in chunks:
                if kind == b"IDAT":
                    first_stream.extend(payload)
                elif kind == b"fdAT":
                    other_stream.extend(payload[4:])
            streams.extend([bytes(first_stream), bytes(other_stream)])
            expected_scanlines = []
            for rgba in samples:
                row = bytearray()
                for y in range(height):
                    row.append(0)
                    row.extend(rgba[y * width * 4 : (y + 1) * width * 4])
                expected_scanlines.append(bytes(row))
            self.assertEqual([zlib.decompress(stream) for stream in streams], expected_scanlines)

    def test_archived_walk_apng_round_trips_all_source_pixels(self):
        review = ROOT / "characters/protagonist/review/walk_n_frente_spritedna_01"
        apng = review / "preview.apng"
        frames_dir = review / "frames"
        chunks = read_chunks(apng.read_bytes())
        self.assertEqual(sum(kind == b"fcTL" for kind, _ in chunks), 12)
        compressed_frames = []
        first = bytearray()
        current = bytearray()
        for kind, payload in chunks:
            if kind == b"IDAT":
                first.extend(payload)
            elif kind == b"fdAT":
                current.extend(payload[4:])
                compressed_frames.append(bytes(current))
                current.clear()
        compressed_frames.insert(0, bytes(first))
        self.assertEqual(len(compressed_frames), 12)
        for index, stream in enumerate(compressed_frames, 1):
            width, height, rgba = read_png_rgba8(frames_dir / f"frame_{index:03d}.png")
            self.assertEqual(zlib.decompress(stream), filtered_scanlines(width, height, rgba))

    def test_preview_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            frames = Path(tmp) / "review" / "frames"
            frames.mkdir(parents=True)
            sample = bytes([20, 40, 60, 255])
            write_png_rgba8(frames / "frame_001.png", 1, 1, sample)
            write_png_rgba8(frames / "frame_002.png", 1, 1, bytes([60, 40, 20, 255]))
            output = frames.parent / "preview.apng"
            write_apng(frames, output, 10.0)
            with self.assertRaisesRegex(ValueError, "refusing to overwrite"):
                write_apng(frames, output, 10.0)

    def test_preview_requires_full_canvas_dimensions(self):
        with tempfile.TemporaryDirectory() as tmp:
            frames = Path(tmp) / "review" / "frames"
            frames.mkdir(parents=True)
            write_png_rgba8(frames / "frame_001.png", 1, 1, bytes([0, 0, 0, 255]))
            write_png_rgba8(frames / "frame_002.png", 2, 1, bytes([0, 0, 0, 255] * 2))
            with self.assertRaisesRegex(ValueError, "canvas differs"):
                write_apng(frames, frames.parent / "preview.apng", 10.0)


if __name__ == "__main__":
    unittest.main()
