extends Node2D

const FRAME_DIRECTORY := "res://characters/protagonist/review/walk_n_frente_spritedna_01/frames/"
const FRAME_COUNT := 12
const FRAME_RATE := 12.5
const GAME_SPRITE_SCALE := 0.15
const TILE_STEP_Y := 47.84 # GridWorld.TILE_HEIGHT * 0.92
const STEP_SECONDS := 0.48 # Two steps align approximately with one 0.96s gait loop.

var font: Font
var actor_root: Node2D
var walk_sprite: AnimatedSprite2D
var movement_tween: Tween
var step_count := 0
var paused_by_user := false
var status_text := "Press Enter to walk one world-down cell."

func _ready() -> void:
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor_root = Node2D.new()
	actor_root.name = "WalkingRoot"
	add_child(actor_root)
	walk_sprite = AnimatedSprite2D.new()
	walk_sprite.name = "WalkFrontCandidate"
	walk_sprite.position = Vector2(0, -15)
	walk_sprite.scale = Vector2.ONE * GAME_SPRITE_SCALE
	walk_sprite.sprite_frames = build_walk_frames()
	walk_sprite.animation = "WALK_N_FRONT"
	actor_root.add_child(walk_sprite)
	reset_preview()
	walk_sprite.play("WALK_N_FRONT")
	get_viewport().size_changed.connect(on_viewport_size_changed)
	queue_redraw()

func build_walk_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	frames.add_animation("WALK_N_FRONT")
	frames.set_animation_loop("WALK_N_FRONT", true)
	frames.set_animation_speed("WALK_N_FRONT", FRAME_RATE)
	for index in range(FRAME_COUNT):
		var frame_path := FRAME_DIRECTORY + "frame_%03d.png" % (index + 1)
		var texture := load(frame_path) as Texture2D
		if texture == null:
			push_error("Missing experimental walk frame: %s" % frame_path)
			continue
		frames.add_frame("WALK_N_FRONT", texture, 1.0)
	return frames

func reset_preview() -> void:
	if movement_tween != null and movement_tween.is_running():
		movement_tween.kill()
	step_count = 0
	actor_root.position = preview_start_position()
	walk_sprite.frame = 0
	walk_sprite.frame_progress = 0.0
	paused_by_user = false
	status_text = "Press Enter to walk one world-down cell."
	walk_sprite.play("WALK_N_FRONT")
	queue_redraw()

func preview_start_position() -> Vector2:
	var viewport_size := get_viewport_rect().size
	return Vector2(viewport_size.x * 0.5, viewport_size.y * 0.48)

func on_viewport_size_changed() -> void:
	if step_count == 0 and (movement_tween == null or not movement_tween.is_running()):
		actor_root.position = preview_start_position()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_DOWN:
			advance_one_cell()
			get_viewport().set_input_as_handled()
		KEY_SPACE:
			paused_by_user = not paused_by_user
			if paused_by_user:
				walk_sprite.pause()
				status_text = "Paused — Left/Right step frames; Space resumes."
			else:
				walk_sprite.play("WALK_N_FRONT")
				status_text = "Playing at %.1f FPS; Enter advances one cell." % FRAME_RATE
			queue_redraw()
			get_viewport().set_input_as_handled()
		KEY_LEFT, KEY_RIGHT:
			paused_by_user = true
			walk_sprite.pause()
			var step := -1 if event.keycode == KEY_LEFT else 1
			walk_sprite.frame = posmod(walk_sprite.frame + step, FRAME_COUNT)
			status_text = "Paused on frame %02d / %02d." % [walk_sprite.frame + 1, FRAME_COUNT]
			queue_redraw()
			get_viewport().set_input_as_handled()
		KEY_R:
			reset_preview()
			get_viewport().set_input_as_handled()

func advance_one_cell() -> void:
	if movement_tween != null and movement_tween.is_running():
		return
	if paused_by_user:
		paused_by_user = false
		walk_sprite.play("WALK_N_FRONT")
	var destination := actor_root.position + Vector2(0, TILE_STEP_Y)
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	movement_tween.tween_property(actor_root, "position", destination, STEP_SECONDS)
	step_count += 1
	status_text = "Walking cell %d — root movement is separate from the PNG gait." % step_count
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var tile_size := Vector2(72.0, TILE_STEP_Y)
	for row in range(-2, 6):
		var center := Vector2(size.x * 0.5, preview_start_position().y + row * TILE_STEP_Y)
		var rect := Rect2(center - tile_size * 0.5, tile_size)
		var color := Color("35434a") if row % 2 == 0 else Color("2b3940")
		draw_rect(rect, color)
		draw_rect(rect, Color("64747a"), false, 1.0)
	draw_string(font, Vector2(28, 36), "SPRITEDNA / WALK_N_FRENTE — REVIEW ONLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("78d8c4"))
	draw_string(font, Vector2(28, 62), "12-frame two-step cycle · %.1f FPS · 0.96 s loop" % FRAME_RATE, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("bdc9c2"))
	draw_string(font, Vector2(28, size.y - 48), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f2c66d"))
	draw_string(font, Vector2(28, size.y - 25), "Enter/Down: move one cell  ·  Space: pause/play  ·  Left/Right: frame step  ·  R: reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("9eadae"))
