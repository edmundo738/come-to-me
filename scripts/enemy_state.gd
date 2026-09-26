class_name EnemyState
extends ActorState

var intent := Vector2i.ZERO
var alert := true

func _init(start_cell: Vector2i = Vector2i.ZERO) -> void:
	super(start_cell)
	intent = start_cell

func plan_step(target: Vector2i, world: GridWorld) -> Vector2i:
	# Greedy Manhattan pursuit with stable tie-breaking: the player can learn it.
	var options: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	var best := cell
	var best_distance := absi(target.x - cell.x) + absi(target.y - cell.y)
	for direction in options:
		var candidate := cell + direction
		if not world.is_walkable(candidate):
			continue
		var distance := absi(target.x - candidate.x) + absi(target.y - candidate.y)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	intent = best
	return intent
