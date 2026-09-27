class_name RoomEnemyVisual
extends Node3D

@export var grid_cell := Vector2i(8, 4)
@export_range(0.1, 1.0, 0.05) var step_seconds := 0.28

var _movement_tween: Tween
@onready var sprite: Sprite3D = $StatueSprite

func _ready() -> void:
	grid_cell = Vector2i(roundi(position.x), roundi(position.z))

func move_to_cell(target: Vector2i, duration: float = -1.0) -> void:
	var seconds := step_seconds if duration < 0.0 else duration
	_start_tween()
	_movement_tween.tween_property(
		self,
		"global_position",
		Vector3(target.x, 0.0, target.y),
		seconds
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	grid_cell = target

func move_along_cells(path: Array[Vector2i], seconds_per_cell: float = 0.08) -> void:
	_start_tween()
	var last_position := global_position
	for cell in path:
		var destination := Vector3(cell.x, 0.0, cell.y)
		if last_position.distance_to(destination) < 0.01:
			continue
		_movement_tween.tween_property(
			self,
			"global_position",
			destination,
			seconds_per_cell
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		last_position = destination
	if not path.is_empty():
		grid_cell = path[-1]

func snap_to_cell(cell: Vector2i) -> void:
	if _movement_tween != null and _movement_tween.is_running():
		_movement_tween.kill()
	grid_cell = cell
	global_position = Vector3(cell.x, 0.0, cell.y)

func set_awareness(state: int) -> void:
	match state:
		EvasionEnemyState.Awareness.PURSUING:
			sprite.modulate = Color(1.0, 0.77, 0.64, 1.0)
		EvasionEnemyState.Awareness.INVESTIGATING:
			sprite.modulate = Color(1.0, 0.80, 0.44, 1.0)
		EvasionEnemyState.Awareness.SEARCHING:
			sprite.modulate = Color(1.0, 0.95, 0.72, 1.0)
		EvasionEnemyState.Awareness.RECOVERING:
			sprite.modulate = Color(0.70, 0.78, 0.72, 1.0)
		_:
			sprite.modulate = Color(0.62, 0.68, 0.63, 1.0)

func _start_tween() -> void:
	if _movement_tween != null and _movement_tween.is_running():
		_movement_tween.kill()
	_movement_tween = create_tween()
