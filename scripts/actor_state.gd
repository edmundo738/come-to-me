class_name ActorState
extends RefCounted

var cell: Vector2i
var spawn_cell: Vector2i

func _init(start_cell: Vector2i = Vector2i.ZERO) -> void:
	cell = start_cell
	spawn_cell = start_cell
