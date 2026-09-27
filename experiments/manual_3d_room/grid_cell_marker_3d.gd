@tool
class_name GridCellMarker3D
extends Node3D

@export var grid_cell := Vector2i.ZERO:
	set(value):
		grid_cell = value
		_sync_transform_from_cell()

var _synchronizing := false

func _enter_tree() -> void:
	set_notify_transform(true)

func _ready() -> void:
	_sync_cell_from_transform()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint() and not _synchronizing:
		_sync_cell_from_transform()

func _sync_cell_from_transform() -> void:
	if _synchronizing:
		return
	_synchronizing = true
	grid_cell = Vector2i(roundi(position.x), roundi(position.z))
	position.x = grid_cell.x
	position.z = grid_cell.y
	_synchronizing = false

func _sync_transform_from_cell() -> void:
	if _synchronizing or not is_inside_tree():
		return
	_synchronizing = true
	position.x = grid_cell.x
	position.z = grid_cell.y
	_synchronizing = false
