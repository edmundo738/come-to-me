extends SceneTree

const ANIMATION_REVIEW_SCENE := "res://scenes/animation_review.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"
const EXPECTED_DURATIONS := [0.27, 0.25, 0.25, 0.25, 0.27, 0.30, 0.30, 0.30, 0.25, 0.25, 0.25, 0.25]
const SEQUENCES := {
	"FRONT": "res://characters/protagonist/animations/idle_normal/frente/",
	"BACK": "res://characters/protagonist/animations/idle_normal/tras/",
	"LEFT": "res://characters/protagonist/review/idle_n_esquerda_skeleton_05/frames/",
	"RIGHT": "res://characters/protagonist/review/idle_n_direita_skeleton_02/frames/",
}
const RGBA_FORMATS := [Image.FORMAT_RGBA8, Image.FORMAT_RGBA4444, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH]

var failure_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_engine_api_and_minimal_fix()
	var first_pair: Array[Image] = []
	_test_png_integrity(first_pair)

	var review_packed := load(ANIMATION_REVIEW_SCENE) as PackedScene
	_check(review_packed != null, "animation_review.tscn loads as PackedScene")
	if review_packed == null:
		_finish()
		return

	var review := review_packed.instantiate()
	root.add_child(review)
	await process_frame
	var sprite := review.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(sprite != null, "animation_review contains AnimatedSprite2D")
	if sprite == null or sprite.sprite_frames == null:
		_finish()
		return

	var frames := sprite.sprite_frames
	_test_sprite_frames(frames)
	await _test_animated_sprite_playback(sprite)
	_test_resource_save(frames)
	await _test_headless_capture()
	await _test_main_scene_load()
	_finish()

func _test_engine_api_and_minimal_fix() -> void:
	var native_ellipse := false
	for method_info in ClassDB.class_get_method_list("CanvasItem"):
		if method_info.get("name", "") == "draw_ellipse":
			native_ellipse = true
			print("[FACT] CanvasItem.draw_ellipse API args: ", method_info.get("args", []))
			break
	_check(native_ellipse, "Godot 4.7.2 exposes CanvasItem.draw_ellipse")

	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_check(source.contains("func draw_shadow_ellipse("), "main.gd uses the specific draw_shadow_ellipse helper")
	_check(not source.contains("func draw_ellipse("), "main.gd no longer overrides CanvasItem.draw_ellipse")

func _test_png_integrity(first_pair: Array[Image]) -> void:
	for direction in SEQUENCES:
		var base_path: String = SEQUENCES[direction]
		var expected_size := Vector2i.ZERO
		for index in range(12):
			var frame_path := "%sframe_%03d.png" % [base_path, index + 1]
			_check(FileAccess.file_exists(frame_path), "%s frame %02d exists" % [direction, index + 1])
			if not FileAccess.file_exists(frame_path):
				continue

			var image := Image.load_from_file(ProjectSettings.globalize_path(frame_path))
			_check(not image.is_empty(), "%s frame %02d decodes" % [direction, index + 1])
			if image.is_empty():
				continue
			_check(RGBA_FORMATS.has(image.get_format()), "%s frame %02d is RGBA" % [direction, index + 1])
			if expected_size == Vector2i.ZERO:
				expected_size = image.get_size()
			else:
				_check(image.get_size() == expected_size, "%s frame %02d matches sequence dimensions" % [direction, index + 1])

			var texture := load(frame_path) as Texture2D
			_check(texture != null, "%s frame %02d loads as Texture2D" % [direction, index + 1])
			if direction == "FRONT" and index < 2:
				first_pair.append(image)
		print("[MEASURED] %s: 12 PNG frames, dimensions %s" % [direction, expected_size])

	if first_pair.size() == 2:
		_test_pixel_comparison(first_pair[0], first_pair[1])
	else:
		_check(false, "front sequence supplied two frames for pixel comparison")

func _test_pixel_comparison(first: Image, second: Image) -> void:
	var changed_pixels := 0
	var rgba_a := first.duplicate()
	var rgba_b := second.duplicate()
	rgba_a.convert(Image.FORMAT_RGBA8)
	rgba_b.convert(Image.FORMAT_RGBA8)
	var bytes_a: PackedByteArray = rgba_a.get_data()
	var bytes_b: PackedByteArray = rgba_b.get_data()
	var pixel_count := first.get_width() * first.get_height()
	for pixel_index in range(pixel_count):
		var offset := pixel_index * 4
		if bytes_a[offset] != bytes_b[offset] or bytes_a[offset + 1] != bytes_b[offset + 1] or bytes_a[offset + 2] != bytes_b[offset + 2] or bytes_a[offset + 3] != bytes_b[offset + 3]:
			changed_pixels += 1
	_check(changed_pixels > 0, "two source frames differ at the pixel level")
	print("[MEASURED] front frame_001 vs frame_002: %d/%d pixels differ" % [changed_pixels, pixel_count])

func _test_sprite_frames(frames: SpriteFrames) -> void:
	for direction in SEQUENCES:
		_check(frames.has_animation(direction), "SpriteFrames contains %s" % direction)
		if not frames.has_animation(direction):
			continue
		_check(frames.get_frame_count(direction) == 12, "%s has 12 frames" % direction)
		_check(frames.get_animation_loop(direction), "%s loops" % direction)
		_check(is_equal_approx(frames.get_animation_speed(direction), 1.0), "%s base speed is 1 FPS" % direction)
		var measured_cycle := 0.0
		for index in range(12):
			var duration := frames.get_frame_duration(direction, index)
			measured_cycle += duration
			_check(is_equal_approx(duration, EXPECTED_DURATIONS[index]), "%s frame %02d duration matches configured timing" % [direction, index + 1])
			_check(frames.get_frame_texture(direction, index) != null, "%s frame %02d has a texture" % [direction, index + 1])
		_check(is_equal_approx(measured_cycle, 3.19), "%s cycle duration totals 3.19 seconds" % direction)
		print("[MEASURED] %s SpriteFrames: %d frames, %.2f s cycle" % [direction, frames.get_frame_count(direction), measured_cycle])

func _test_animated_sprite_playback(sprite: AnimatedSprite2D) -> void:
	for direction in SEQUENCES:
		sprite.play(direction)
		sprite.frame = 0
		sprite.frame_progress = 0.0
		await create_timer(0.36).timeout
		_check(sprite.frame != 0, "AnimatedSprite2D advances %s after its first-frame duration" % direction)
		sprite.stop()
	print("[CONFIRMED] AnimatedSprite2D processed one timed frame in each direction")

func _test_resource_save(frames: SpriteFrames) -> void:
	var resource_path := "user://godot_smoke_spriteframes.tres"
	var save_error := ResourceSaver.save(frames, resource_path)
	_check(save_error == OK, "SpriteFrames resource serializes to TRES")
	if save_error == OK:
		var loaded := ResourceLoader.load(resource_path) as SpriteFrames
		_check(loaded != null and loaded.has_animation("FRONT") and loaded.get_frame_count("FRONT") == 12, "saved SpriteFrames TRES reloads")
		print("[MEASURED] SpriteFrames resource saved to %s" % ProjectSettings.globalize_path(resource_path))

func _test_headless_capture() -> void:
	if DisplayServer.get_name() == "headless":
		print("[UNKNOWN] Headless display driver has no readable rendered viewport in this build")
		return
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_width() <= 0 or image.get_height() <= 0:
		print("[UNKNOWN] Headless viewport did not provide a readable image")
		return
	var capture_path := OS.get_environment("GODOT_SMOKE_CAPTURE")
	if capture_path.is_empty():
		capture_path = ProjectSettings.globalize_path("user://godot_headless_smoke.png")
	var save_error := image.save_png(capture_path)
	if save_error == OK:
		print("[MEASURED] Headless viewport capture: %s (%dx%d)" % [capture_path, image.get_width(), image.get_height()])
	else:
		print("[UNKNOWN] Headless viewport image read, but save_png returned %s" % error_string(save_error))

func _test_main_scene_load() -> void:
	var main_packed := load(MAIN_SCENE) as PackedScene
	_check(main_packed != null, "main.tscn loads as PackedScene")
	if main_packed == null:
		return
	var main_instance := main_packed.instantiate()
	root.add_child(main_instance)
	await process_frame
	_check(main_instance.get_script() != null, "main scene instantiates with its GDScript")
	var main_animation := main_instance.get("player_animation") as AnimatedSprite2D
	_check(main_animation != null, "main.gd creates its AnimatedSprite2D")
	if main_animation != null and main_animation.sprite_frames != null:
		for direction in SEQUENCES:
			_check(main_animation.sprite_frames.has_animation(direction), "main.gd integrates %s SpriteFrames" % direction)
			_check(main_animation.sprite_frames.get_frame_count(direction) == 12, "main.gd integrates 12 %s frames" % direction)
	main_instance.queue_free()
	print("[CONFIRMED] Main gameplay scene instantiated headlessly with its SpriteFrames")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] ", message)
	else:
		failure_count += 1
		push_error("[FAIL] " + message)

func _finish() -> void:
	if failure_count == 0:
		print("GODOT_HEADLESS_SMOKE: PASS")
		quit(0)
	else:
		printerr("GODOT_HEADLESS_SMOKE: FAIL (%d checks)" % failure_count)
		quit(1)
