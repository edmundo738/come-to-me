class_name FoundationPlayer
extends CharacterBody3D

const FRAME_DURATIONS := [0.27, 0.25, 0.25, 0.25, 0.27, 0.30, 0.30, 0.30, 0.25, 0.25, 0.25, 0.25]
const DIRECTION_PATHS := {
	# This folder shows the protagonist from behind, which is what the trailing camera sees while W is held.
	"AWAY": "res://characters/protagonist/animations/idle_normal/frente/",
	"TOWARD": "res://characters/protagonist/animations/idle_normal/tras/",
	"LEFT": "res://characters/protagonist/review/idle_n_esquerda_skeleton_05/frames/",
	"RIGHT": "res://characters/protagonist/review/idle_n_direita_skeleton_02/frames/",
}

@export_node_path("Node3D") var camera_rig_path: NodePath = ^"../CameraRig"
@export_range(1.0, 8.0, 0.1) var move_speed := 3.2
@export_range(1.0, 24.0, 0.5) var ground_acceleration := 13.0
@export_range(1.0, 24.0, 0.5) var ground_deceleration := 16.0

@onready var camera_rig = get_node(camera_rig_path)
@onready var animated_sprite: AnimatedSprite3D = $VisualRoot/AnimatedSprite3D
@onready var visual_root: Node3D = $VisualRoot

var last_world_direction := Vector3(0.0, 0.0, -1.0)
var _sprite_rest_height := 0.696
var _gait_phase := 0.0

func _ready() -> void:
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)
	_sprite_rest_height = animated_sprite.position.y
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.visible = true
	$VisualRoot/EditorPreview.visible = false
	animated_sprite.play("AWAY")

func _physics_process(delta: float) -> void:
	var axes := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var desired_direction := world_direction_from_camera_basis(axes, camera_rig.get_flat_forward(), camera_rig.get_flat_right())
	if desired_direction.length_squared() > 0.001:
		last_world_direction = desired_direction
		_set_sprite_direction(desired_direction)
		_gait_phase += delta * 11.0
		visual_root.position.y = sin(_gait_phase * TAU) * 0.012
		visual_root.rotation.z = -axes.x * 0.035
	else:
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.08)
		visual_root.rotation.z = move_toward(visual_root.rotation.z, 0.0, delta * 0.18)
		_set_sprite_direction(last_world_direction)

	var acceleration := ground_acceleration if desired_direction.length_squared() > 0.001 else ground_deceleration
	velocity.x = move_toward(velocity.x, desired_direction.x * move_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_direction.z * move_speed, acceleration * delta)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	elif velocity.y < 0.0:
		velocity.y = -0.1
	move_and_slide()

func _set_sprite_direction(world_direction: Vector3) -> void:
	var forward: Vector3 = camera_rig.get_flat_forward()
	var right: Vector3 = camera_rig.get_flat_right()
	var forward_amount := world_direction.dot(forward)
	var right_amount := world_direction.dot(right)
	var animation_name := "AWAY"
	if absf(forward_amount) >= absf(right_amount):
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
