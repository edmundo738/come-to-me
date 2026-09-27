class_name ProceduralEnemyState
extends EnemyState

func plan_step(target: Vector2i, world: GridWorld) -> Vector2i:
	# The default prototype enemy is greedy and can stall at maze corners.
	# This experiment uses deterministic breadth-first pursuit so every generated
	# connected corridor remains traversable by the existing turn-based rules.
	if target == cell or not world.is_walkable(target):
		intent = cell
		return intent

	var previous: Dictionary = {cell: cell}
	var frontier: Array[Vector2i] = [cell]
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	var head := 0
	while head < frontier.size() and not previous.has(target):
		var current: Vector2i = frontier[head]
		head += 1
		for direction in directions:
			var next_cell := current + direction
			if not world.is_walkable(next_cell) or previous.has(next_cell):
				continue
			previous[next_cell] = current
			frontier.append(next_cell)

	if not previous.has(target):
		intent = cell
		return intent

	var next_step := target
	while previous[next_step] != cell:
		next_step = previous[next_step]
	intent = next_step
	return intent
