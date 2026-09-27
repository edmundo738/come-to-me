class_name RoomPlayer3D
extends CharacterBody3D

signal cell_entered(cell: Vector2i)

const FRAME_DURATIONS := [0.27, 0.25, 0.25, 0.25, 0.27, 0.30, 0.30, 0.30, 0.25, 0.25, 0.25, 0.25]
const ANIMATION_PATHS := {
	"FRONT": "res://characters/protagonist/animations/idle_normal/frente/",
	"BACK": "res://characters/protagonist/animations/idle_normal/tras/",
	"LEFT": "res://characters/protagonist/review/idle_n_esquerda_skeleton_05/frames/",
	"RIGHT": "res://characters/protagonist/review/idle_n_direita_skeleton_02/frames/",
}

@export var grid_cell := Vector2i(2, 4)
@export_range(0.5, 5.0, 0.1) var move_speed := 2.0

var controller: ManualRoomController
var requested_direction := Vector2i.ZERO
var _held_keys: Dictionary = {}
var _press_order := 0
var _gait_phase := 0.0
var _sprite_rest_height := 0.696
var _ward_tween: Tween
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	grid_cell = Vector2i(roundi(position.x), roundi(position.z))
	_sprite_rest_height = animated_sprite.position.y
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.visible = true
	$EditorPreview.visible = false
	animated_sprite.play("FRONT")

func configure(room_controller: ManualRoomController, start_cell: Vector2i) -> void:
	controller = room_controller
	grid_cell = start_cell
	position = Vector3(start_cell.x, 0.0, start_cell.y)

func set_key_state(keycode: int, direction: Vector2i, is_pressed: bool) -> void:
	if is_pressed:
		_press_order += 1
		_held_keys[keycode] = {"direction": direction, "order": _press_order}
	else:
		_held_keys.erase(keycode)
	_refresh_requested_direction()

func _refresh_requested_direction() -> void:
	var newest_order := -1
	requested_direction = Vector2i.ZERO
	for keycode in _held_keys:
		var record: Dictionary = _held_keys[keycode]
		if int(record.order) > newest_order:
			newest_order = int(record.order)
			requested_direction = record.direction

func _physics_process(delta: float) -> void:
	if controller == null or not controller.is_round_active():
		velocity = Vector3.ZERO
		return

	var direction := Vector3(requested_direction.x, 0.0, requested_direction.y)
	if requested_direction != Vector2i.ZERO:
		face(requested_direction)
	velocity = direction * move_speed
	move_and_slide()
	_update_body_language(delta, not direction.is_zero_approx() and not is_on_wall())
	_consume_grid_crossings()

func _consume_grid_crossings() -> void:
	if controller == null:
		return
	var reached_cell := Vector2i(
		floori(global_position.x + 0.5),
		floori(global_position.z + 0.5)
	)
	var transitions := 0
	while grid_cell != reached_cell and transitions < 4:
		var difference := reached_cell - grid_cell
		var direction := Vector2i.ZERO
		if difference.x != 0:
			direction.x = signi(difference.x)
		else:
			direction.y = signi(difference.y)
		var next_cell := grid_cell + direction
		if not controller.is_cell_walkable(next_cell):
			break
		grid_cell = next_cell
		transitions += 1
		cell_entered.emit(grid_cell)
		if not controller.is_round_active():
			requested_direction = Vector2i.ZERO
			break

func _update_body_language(delta: float, is_moving: bool) -> void:
	if is_moving:
		_gait_phase += delta * 12.0
		animated_sprite.position.y = _sprite_rest_height + sin(_gait_phase * 2.0) * 0.022
		animated_sprite.rotation_degrees.z = -float(requested_direction.x) * 1.8
	else:
		animated_sprite.position.y = move_toward(animated_sprite.position.y, _sprite_rest_height, delta * 0.12)
		animated_sprite.rotation_degrees.z = move_toward(animated_sprite.rotation_degrees.z, 0.0, delta * 10.0)

func face(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	var animation_name := "RIGHT"
	if direction == Vector2i.UP:
		animation_name = "BACK"
	elif direction == Vector2i.DOWN:
		animation_name = "FRONT"
	elif direction == Vector2i.LEFT:
		animation_name = "LEFT"
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

func clear_movement_input() -> void:
	_held_keys.clear()
	requested_direction = Vector2i.ZERO

func set_terminal_tint(tint: Color) -> void:
	if _ward_tween != null and _ward_tween.is_running():
		_ward_tween.kill()
	animated_sprite.modulate = tint

func pulse_ward() -> void:
	if _ward_tween != null and _ward_tween.is_running():
		_ward_tween.kill()
	animated_sprite.modulate = Color(0.48, 1.0, 0.87, 1.0)
	_ward_tween = create_tween()
	_ward_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.32)

func reset_to_cell(cell: Vector2i) -> void:
	grid_cell = cell
	global_position = Vector3(cell.x, 0.0, cell.y)
	velocity = Vector3.ZERO
	requested_direction = Vector2i.ZERO
	_held_keys.clear()
	animated_sprite.position.y = _sprite_rest_height
	animated_sprite.rotation_degrees.z = 0.0
	animated_sprite.modulate = Color.WHITE

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	for animation_name in ANIMATION_PATHS:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, 1.0)
		var directory: String = ANIMATION_PATHS[animation_name]
		for frame_index in range(FRAME_DURATIONS.size()):
			var frame_path := "%sframe_%03d.png" % [directory, frame_index + 1]
			var texture := load(frame_path) as Texture2D
			if texture == null:
				push_error("Missing 3D-room player frame: %s" % frame_path)
				continue
			frames.add_frame(animation_name, texture, FRAME_DURATIONS[frame_index])
	return frames
