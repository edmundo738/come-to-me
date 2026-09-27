class_name FoundationPlayer
extends CharacterBody3D

const FRAME_DURATIONS := [0.27, 0.25, 0.25, 0.25, 0.27, 0.30, 0.30, 0.30, 0.25, 0.25, 0.25, 0.25]
const DIRECTION_PATHS := {
	# AWAY moves from the trailing camera: use the back view. TOWARD moves into it: use the front view.
	"AWAY": "res://characters/protagonist/animations/idle_normal/tras/",
	"TOWARD": "res://characters/protagonist/animations/idle_normal/frente/",
	"LEFT": "res://characters/protagonist/review/idle_n_esquerda_skeleton_05/frames/",
	"RIGHT": "res://characters/protagonist/review/idle_n_direita_skeleton_02/frames/",
}

@export_node_path("Node3D") var camera_rig_path: NodePath = ^"../CameraRig"
@export_range(1.0, 8.0, 0.1) var move_speed := 3.2
@export_range(1.0, 24.0, 0.5) var ground_acceleration := 8.0
@export_range(1.0, 24.0, 0.5) var ground_deceleration := 10.0
@export_range(1.0, 18.0, 0.5) var turn_response := 7.5

@onready var camera_rig = get_node(camera_rig_path)
@onready var animated_sprite: AnimatedSprite3D = $VisualRoot/AnimatedSprite3D
@onready var visual_root: Node3D = $VisualRoot

var last_world_direction := Vector3(0.0, 0.0, -1.0)
var _gait_phase := 0.0
var _forward_view_axis := true

func _ready() -> void:
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.visible = true
	$VisualRoot/EditorPreview.visible = false
	animated_sprite.play("AWAY")

func _physics_process(delta: float) -> void:
	var axes := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var desired_direction := world_direction_from_camera_basis(axes, camera_rig.get_flat_forward(), camera_rig.get_flat_right())
	var has_move_input := desired_direction.length_squared() > 0.001
	var target_velocity := desired_direction * move_speed if has_move_input else Vector3.ZERO
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var response := ground_acceleration if has_move_input else ground_deceleration
	horizontal_velocity = horizontal_velocity.move_toward(target_velocity, response * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1
	move_and_slide()

	# Rotate toward the requested heading with damping instead of snapping the
	# character's facing when the input crosses an animation view boundary.
	if has_move_input:
		var target_yaw := atan2(-desired_direction.x, -desired_direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-delta * turn_response))
	last_world_direction = Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	_set_sprite_direction(last_world_direction)

	# The source sequences are idle poses, not a walk cycle. Use only a restrained
	# velocity-driven body bob and lean to soften starts and stops without faking one.
	var speed_ratio := clampf(Vector2(velocity.x, velocity.z).length() / move_speed, 0.0, 1.0)
	if speed_ratio > 0.04:
		_gait_phase += delta * lerpf(7.0, 10.0, speed_ratio)
	var target_bob := sin(_gait_phase) * 0.009 * speed_ratio
	var target_lean := -axes.x * 0.022 * speed_ratio
	var visual_response := 1.0 - exp(-delta * 8.0)
	visual_root.position.y = lerpf(visual_root.position.y, target_bob, visual_response)
	visual_root.rotation.z = lerpf(visual_root.rotation.z, target_lean, visual_response)

func _set_sprite_direction(world_direction: Vector3) -> void:
	var forward: Vector3 = camera_rig.get_flat_forward()
	var right: Vector3 = camera_rig.get_flat_right()
	var forward_amount := world_direction.dot(forward)
	var right_amount := world_direction.dot(right)
	# Hysteresis keeps the four source views from flickering when a diagonal
	# crosses the forward/side boundary by only a few pixels of mouse motion.
	if _forward_view_axis:
		if absf(right_amount) > absf(forward_amount) + 0.16:
			_forward_view_axis = false
	elif absf(forward_amount) > absf(right_amount) + 0.16:
		_forward_view_axis = true
	var animation_name := "AWAY"
	if _forward_view_axis:
		animation_name = "AWAY" if forward_amount >= 0.0 else "TOWARD"
	else:
		animation_name = "RIGHT" if right_amount >= 0.0 else "LEFT"
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

static func world_direction_from_axes(axes: Vector2, camera_yaw: float) -> Vector3:
	var forward := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	return world_direction_from_camera_basis(axes, forward, right)

static func world_direction_from_camera_basis(axes: Vector2, forward: Vector3, right: Vector3) -> Vector3:
	var direction := right * axes.x + forward * -axes.y
	return direction.normalized() if direction.length_squared() > 1.0 else direction

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	for direction in DIRECTION_PATHS:
		frames.add_animation(direction)
		frames.set_animation_loop(direction, true)
		frames.set_animation_speed(direction, 1.0)
		var directory: String = DIRECTION_PATHS[direction]
		for index in range(FRAME_DURATIONS.size()):
			var frame_path := "%sframe_%03d.png" % [directory, index + 1]
			var texture := load(frame_path) as Texture2D
			if texture == null:
				push_error("Visual foundation is missing character frame: %s" % frame_path)
				continue
			frames.add_frame(direction, texture, FRAME_DURATIONS[index])
	return frames
