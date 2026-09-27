class_name FoundationCameraRig
extends Node3D

@export_node_path("Node3D") var target_path: NodePath = ^"../Player"
@export_range(3.0, 8.0, 0.1) var orbit_distance := 5.2
@export_range(8.0, 55.0, 1.0) var pitch_degrees := 18.0
@export_range(0.0005, 0.01, 0.0005) var mouse_sensitivity := 0.0025
@export_range(0.0, 1.0, 0.05) var follow_look_ahead := 0.16
@export_range(2.0, 18.0, 0.5) var orbit_damping := 8.5
@export_range(2.0, 18.0, 0.5) var follow_damping := 7.0
@export_range(2.0, 18.0, 0.5) var position_damping := 8.0

@onready var camera: Camera3D = $Camera3D

var _target: CharacterBody3D
var _smoothed_pivot := Vector3.ZERO
var _current_distance := 5.2
var _smoothed_yaw := 0.0
var _smoothed_pitch := 18.0
var orbit_yaw := 0.0
var _min_distance := 3.2
var _max_distance := 7.5

func _ready() -> void:
	_target = get_node(target_path) as CharacterBody3D
	if _target == null:
		push_error("Visual foundation camera target must be a CharacterBody3D.")
		return
	_current_distance = orbit_distance
	_smoothed_yaw = orbit_yaw
	_smoothed_pitch = pitch_degrees
	_smoothed_pivot = _target.global_position + Vector3(0.0, 1.45, 0.0)
	camera.current = true
	var initial_pitch := deg_to_rad(_smoothed_pitch)
	var initial_direction := Vector3(sin(_smoothed_yaw) * cos(initial_pitch), sin(initial_pitch), cos(_smoothed_yaw) * cos(initial_pitch)).normalized()
	camera.global_position = _smoothed_pivot + initial_direction * orbit_distance
	camera.look_at(_smoothed_pivot - Vector3(0.0, 0.08, 0.0), Vector3.UP)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		orbit_yaw -= event.relative.x * mouse_sensitivity
		pitch_degrees = clampf(pitch_degrees + event.relative.y * mouse_sensitivity * 180.0 / PI, 8.0, 58.0)
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_distance = maxf(_min_distance, orbit_distance - 0.45)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_distance = minf(_max_distance, orbit_distance + 0.45)
		elif event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if _target == null:
		return
	var player_velocity := _target.velocity
	var desired_pivot := _target.global_position + Vector3(0.0, 1.45, 0.0) + Vector3(player_velocity.x, 0.0, player_velocity.z) * follow_look_ahead
	_smoothed_pivot = _smoothed_pivot.lerp(desired_pivot, 1.0 - exp(-delta * follow_damping))
	_smoothed_yaw = lerp_angle(_smoothed_yaw, orbit_yaw, 1.0 - exp(-delta * orbit_damping))
	_smoothed_pitch = lerpf(_smoothed_pitch, pitch_degrees, 1.0 - exp(-delta * orbit_damping))

	var pitch := deg_to_rad(_smoothed_pitch)
	var camera_offset_direction := Vector3(
		sin(_smoothed_yaw) * cos(pitch),
		sin(pitch),
		cos(_smoothed_yaw) * cos(pitch)
	).normalized()
	var requested_position := _smoothed_pivot + camera_offset_direction * orbit_distance
	var unobstructed_distance := orbit_distance
	var query := PhysicsRayQueryParameters3D.create(_smoothed_pivot, requested_position)
	query.collision_mask = 1
	query.exclude = [_target.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		unobstructed_distance = maxf(0.45, _smoothed_pivot.distance_to(hit.position) - 0.3)

	# The boom uses an eased obstruction response: it yields to geometry without
	# announcing a hard boundary, then returns more gently when space opens up.
	var distance_damping := 5.5 if unobstructed_distance < _current_distance else 2.4
	_current_distance = lerpf(_current_distance, unobstructed_distance, 1.0 - exp(-delta * distance_damping))
	var desired_camera_position := _smoothed_pivot + camera_offset_direction * _current_distance
	camera.global_position = camera.global_position.lerp(desired_camera_position, 1.0 - exp(-delta * position_damping))
	camera.look_at(_smoothed_pivot - Vector3(0.0, 0.08, 0.0), Vector3.UP)

func get_orbit_yaw() -> float:
	return orbit_yaw

func get_flat_forward() -> Vector3:
	var forward := -camera.global_basis.z
	forward.y = 0.0
	return forward.normalized()

func get_flat_right() -> Vector3:
	var right := camera.global_basis.x
	right.y = 0.0
	return right.normalized()
