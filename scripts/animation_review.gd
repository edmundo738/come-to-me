extends Node2D

const FRAME_DURATIONS := [0.27, 0.25, 0.25, 0.25, 0.27, 0.30, 0.30, 0.30, 0.25, 0.25, 0.25, 0.25]
const FRAME_COUNT := 12
const CYCLE_SECONDS := 3.19
const DIRECTION_CONFIG := {
	"FRONT": {
		"label": "IDLE_N_FRENTE",
		"path": "res://characters/protagonist/animations/idle_normal/frente/",
	},
	"BACK": {
		"label": "IDLE_N_TRAS",
		"path": "res://characters/protagonist/animations/idle_normal/tras/",
	},
	"LEFT": {
		"label": "IDLE_N_ESQUERDA · candidato 05",
		"path": "res://characters/protagonist/review/idle_n_esquerda_skeleton_05/frames/",
	},
	"RIGHT": {
		"label": "IDLE_N_DIREITA · candidato 02",
		"path": "res://characters/protagonist/review/idle_n_direita_skeleton_02/frames/",
	},
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_direction := "FRONT"
var paused := false
var playback_scale := 1.0
var font: Font
var viewport_size := Vector2.ZERO

func _ready() -> void:
	font = ThemeDB.fallback_font
	viewport_size = get_viewport_rect().size
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = _build_sprite_frames()
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation = current_direction
	sprite.play(current_direction)
	sprite.speed_scale = playback_scale
	get_viewport().size_changed.connect(_on_viewport_resized)
	queue_redraw()

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	for direction in DIRECTION_CONFIG:
		frames.add_animation(direction)
		frames.set_animation_loop(direction, true)
		# At 1 FPS the per-frame duration multiplier is the duration in seconds.
		frames.set_animation_speed(direction, 1.0)
		var base_path: String = DIRECTION_CONFIG[direction]["path"]
		for frame_index in range(FRAME_COUNT):
			var filename := "frame_%03d.png" % (frame_index + 1)
			var texture := load(base_path + filename) as Texture2D
			if texture == null:
				push_error("Animation review could not load: %s%s" % [base_path, filename])
				continue
			frames.add_frame(direction, texture, FRAME_DURATIONS[frame_index])
	return frames

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			_select_direction("FRONT")
		KEY_2:
			_select_direction("BACK")
		KEY_3:
			_select_direction("LEFT")
		KEY_4:
			_select_direction("RIGHT")
		KEY_SPACE:
			_toggle_pause()
		KEY_LEFT:
			_step_frame(-1)
		KEY_RIGHT:
			_step_frame(1)
		KEY_UP:
			playback_scale = minf(2.0, playback_scale + 0.25)
			sprite.speed_scale = playback_scale
			queue_redraw()
		KEY_DOWN:
			playback_scale = maxf(0.25, playback_scale - 0.25)
			sprite.speed_scale = playback_scale
			queue_redraw()
		KEY_R:
			_reset_cycle()
		_:
			return
	get_viewport().set_input_as_handled()

func _select_direction(direction: String) -> void:
	current_direction = direction
	sprite.play(direction)
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.speed_scale = playback_scale
	if paused:
		sprite.pause()
	queue_redraw()

func _toggle_pause() -> void:
	paused = not paused
	if paused:
		sprite.pause()
	else:
		sprite.play(current_direction)
		sprite.speed_scale = playback_scale
	queue_redraw()

func _step_frame(step: int) -> void:
	paused = true
	sprite.pause()
	sprite.frame = posmod(sprite.frame + step, FRAME_COUNT)
	sprite.frame_progress = 0.0
	queue_redraw()

func _reset_cycle() -> void:
	sprite.play(current_direction)
	sprite.frame = 0
	sprite.frame_progress = 0.0
	sprite.speed_scale = playback_scale
	if paused:
		sprite.pause()
	queue_redraw()

func _on_frame_changed() -> void:
	queue_redraw()

func _on_viewport_resized() -> void:
	viewport_size = get_viewport_rect().size
	sprite.position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5 + 18.0)
	queue_redraw()

func _draw() -> void:
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("171e24"), true)
	draw_line(Vector2(0, 91), Vector2(viewport_size.x, 91), Color("668078"), 1.0)
	draw_string(font, Vector2(28, 36), "IDLE REVIEW  /  %s" % current_direction, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("e2e7df"))
	var playback_state := "PAUSED" if paused else "LOOPING"
	draw_string(font, Vector2(29, 64), "12 frames   |   %.2f s   |   %s   |   %.2fx" % [CYCLE_SECONDS, playback_state, playback_scale], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("aab8b4"))
	draw_line(Vector2(0, viewport_size.y - 82), Vector2(viewport_size.x, viewport_size.y - 82), Color("668078"), 1.0)
	draw_rect(Rect2(0, viewport_size.y - 82, viewport_size.x, 82), Color("171e24"), true)
	draw_string(font, Vector2(28, viewport_size.y - 56), "1 FRONT   2 BACK   3 LEFT   4 RIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e2e7df"))
	draw_string(font, Vector2(29, viewport_size.y - 30), "SPACE play/pause    LEFT/RIGHT step    UP/DOWN speed    R reset    |    Frame %02d / %02d" % [sprite.frame + 1, FRAME_COUNT], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("aab8b4"))
