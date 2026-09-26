class_name EvasionEnemyState
extends EnemyState

# Reversible prototype AI: vision drives pursuit; lost contact leads to an
# investigation, a brief visible scan, and a return to the spawn/guard point.
enum Awareness {
	UNAWARE,
	PURSUING,
	INVESTIGATING,
	SEARCHING,
	RECOVERING,
}

const SIGHT_RANGE := 6
const SEARCH_TURNS := 2
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

var awareness := Awareness.UNAWARE
var last_seen_cell := Vector2i(-1, -1)
var tracked_player_cell := Vector2i(-1, -1)
var search_turns_remaining := 0
var scan_direction_index := 0
var facing := Vector2i.LEFT

func plan_step(target: Vector2i, world: GridWorld) -> Vector2i:
	tracked_player_cell = target
	if _can_see(target, world):
		awareness = Awareness.PURSUING
		last_seen_cell = target
		search_turns_remaining = SEARCH_TURNS
		intent = _next_path_step(target, world, false)
		_update_facing(intent)
		return intent

	match awareness:
		Awareness.UNAWARE:
			intent = cell
		Awareness.PURSUING:
			# The target moved after the previously planned step. Remember only
			# the last cell actually visible, never the hidden current position.
			awareness = Awareness.INVESTIGATING
			intent = _next_path_step(last_seen_cell, world, true)
			_update_facing(intent)
		Awareness.INVESTIGATING:
			if cell == last_seen_cell:
				awareness = Awareness.SEARCHING
				search_turns_remaining = SEARCH_TURNS
				scan_direction_index = 0
				intent = cell
			else:
				intent = _next_path_step(last_seen_cell, world, true)
				_update_facing(intent)
		Awareness.SEARCHING:
			_plan_search(world)
		Awareness.RECOVERING:
			if cell == spawn_cell:
				awareness = Awareness.UNAWARE
				intent = cell
			else:
				intent = _next_path_step(spawn_cell, world, true)
				_update_facing(intent)
	return intent

func _plan_search(world: GridWorld) -> void:
	if search_turns_remaining <= 0:
		awareness = Awareness.RECOVERING
		intent = _next_path_step(spawn_cell, world, true)
		_update_facing(intent)
		return
	facing = DIRECTIONS[scan_direction_index % DIRECTIONS.size()]
	scan_direction_index += 1
	search_turns_remaining -= 1
	intent = cell

func _can_see(target: Vector2i, world: GridWorld) -> bool:
	if maxi(absi(target.x - cell.x), absi(target.y - cell.y)) > SIGHT_RANGE:
		return false
	return _has_clear_line_of_sight(target, world)

func _has_clear_line_of_sight(target: Vector2i, world: GridWorld) -> bool:
	var x := cell.x
	var y := cell.y
	var dx := absi(target.x - x)
	var dy := absi(target.y - y)
	var step_x := 1 if x < target.x else -1
	var step_y := 1 if y < target.y else -1
	var error := dx - dy

	while true:
		var current := Vector2i(x, y)
		if current != cell and current != target and not world.is_walkable(current):
			return false
		if current == target:
			return true
		var doubled_error := error * 2
		if doubled_error > -dy:
			error -= dy
			x += step_x
		if doubled_error < dx:
			error += dx
			y += step_y
	return false

func _next_path_step(destination: Vector2i, world: GridWorld, avoid_player: bool) -> Vector2i:
	if destination == cell or not world.is_walkable(destination):
		return cell

	var frontier: Array[Vector2i] = [cell]
	var came_from: Dictionary = {}
	came_from[cell] = cell
	var head := 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		if current == destination:
			break
		for direction in DIRECTIONS:
			var candidate := current + direction
			if not world.is_walkable(candidate) or came_from.has(candidate):
				continue
			if avoid_player and candidate == tracked_player_cell and candidate != destination:
				continue
			came_from[candidate] = current
			frontier.append(candidate)

	if not came_from.has(destination):
		return cell
	var step := destination
	while came_from[step] != cell:
		step = came_from[step]
	return step

func _update_facing(next_cell: Vector2i) -> void:
	var difference := next_cell - cell
	if difference != Vector2i.ZERO:
		facing = difference
