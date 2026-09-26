extends SceneTree

const EXPERIMENT_SCENE := "res://experiments/evasion_first_slice/evasion_first_slice.tscn"

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_pathfinding_around_wall()
	_test_pursuit_investigation_and_recovery()
	await _test_experiment_scene()
	if failures == 0:
		print("GODOT_EVASION_EXPERIMENT: PASS")
		quit(0)
	else:
		printerr("GODOT_EVASION_EXPERIMENT: FAIL (%d checks)" % failures)
		quit(1)

func _test_pathfinding_around_wall() -> void:
	var world := GridWorld.new()
	world.walls.clear()
	world.walls[Vector2i(3, 1)] = true
	var pursuer := EvasionEnemyState.new(Vector2i(4, 1))
	var step := pursuer._next_path_step(Vector2i(2, 1), world, false)
	_check(step == Vector2i(4, 2), "BFS chooses a deterministic shortest route around the blocking wall")
	_check(world.is_walkable(step), "BFS never returns a wall cell")

	# Exhaustively check that every reachable pair in the existing room takes
	# one optimal step, including pairs where greedy Manhattan gets stuck.
	var map := GridWorld.new()
	var open_cells: Array[Vector2i] = []
	for y in range(GridWorld.HEIGHT):
		for x in range(GridWorld.WIDTH):
			var candidate := Vector2i(x, y)
			if map.is_walkable(candidate):
				open_cells.append(candidate)
	var checked_pairs := 0
	var invalid_steps := 0
	for destination in open_cells:
		var distances := _reference_distances(destination, map)
		var pathfinder := EvasionEnemyState.new(destination)
		for origin in open_cells:
			if origin == destination or not distances.has(origin):
				continue
			pathfinder.cell = origin
			var next_cell := pathfinder._next_path_step(destination, map, false)
			checked_pairs += 1
			if not map.is_walkable(next_cell) or not distances.has(next_cell) or distances[next_cell] != distances[origin] - 1:
				invalid_steps += 1
	_check(invalid_steps == 0, "BFS takes an optimal valid step for all %d reachable ordered cell pairs" % checked_pairs)
	print("[MEASURED] BFS exhaustive room check: %d reachable pairs, %d invalid first steps" % [checked_pairs, invalid_steps])

func _reference_distances(origin: Vector2i, world: GridWorld) -> Dictionary:
	var distances: Dictionary = {}
	distances[origin] = 0
	var frontier: Array[Vector2i] = [origin]
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	var head := 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		for direction in directions:
			var candidate := current + direction
			if not world.is_walkable(candidate) or distances.has(candidate):
				continue
			distances[candidate] = distances[current] + 1
			frontier.append(candidate)
	return distances

func _test_pursuit_investigation_and_recovery() -> void:
	var world := GridWorld.new()
	world.walls.clear()
	var pursuer := EvasionEnemyState.new(Vector2i(8, 4))
	var player_cell := Vector2i(2, 4)
	pursuer.plan_step(player_cell, world)
	_check(pursuer.awareness == EvasionEnemyState.Awareness.PURSUING, "visible player starts deterministic pursuit")
	_check(pursuer.last_seen_cell == player_cell, "pursuer records the cell it actually sees")

	# Break line of sight after the enemy has committed its previously planned move.
	pursuer.cell = pursuer.intent
	world.walls[Vector2i(4, 3)] = true
	pursuer.plan_step(Vector2i(2, 3), world)
	_check(pursuer.awareness == EvasionEnemyState.Awareness.INVESTIGATING, "wall occlusion changes pursuit into investigation")
	_check(pursuer.last_seen_cell == player_cell, "investigation does not reveal the hidden current player cell")

	world.walls[Vector2i(2, 3)] = true
	pursuer.cell = pursuer.last_seen_cell
	pursuer.plan_step(Vector2i(2, 2), world)
	_check(pursuer.awareness == EvasionEnemyState.Awareness.SEARCHING, "reaching last seen cell begins a bounded search")
	_check(pursuer.search_turns_remaining == EvasionEnemyState.SEARCH_TURNS, "search starts with the full configured duration")
	pursuer.plan_step(Vector2i(2, 2), world)
	_check(pursuer.awareness == EvasionEnemyState.Awareness.SEARCHING, "search remains active during its first turn")
	pursuer.plan_step(Vector2i(2, 2), world)
	_check(pursuer.awareness == EvasionEnemyState.Awareness.SEARCHING, "search remains active during its final turn")
	pursuer.plan_step(Vector2i(2, 2), world)
	_check(pursuer.awareness == EvasionEnemyState.Awareness.RECOVERING, "search ends in a readable recovery state")
	_check(pursuer.intent != pursuer.cell and world.is_walkable(pursuer.intent), "recovery begins by taking a valid path toward the spawn point")

	# Reacquiring sight immediately restores pursuit and updates memory.
	pursuer.cell = Vector2i(8, 4)
	pursuer.plan_step(Vector2i(8, 2), world)
	_check(pursuer.awareness == EvasionEnemyState.Awareness.PURSUING, "clear sight during recovery reacquires the player")
	_check(pursuer.last_seen_cell == Vector2i(8, 2), "reacquisition refreshes last-seen memory")

func _test_experiment_scene() -> void:
	var packed := load(EXPERIMENT_SCENE) as PackedScene
	_check(packed != null, "alternate experiment scene parses and loads")
	if packed == null:
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	var ai := scene.get("enemy") as EvasionEnemyState
	_check(ai != null, "alternate scene selects the isolated evasion AI")
	if ai != null:
		_check(ai.awareness == EvasionEnemyState.Awareness.PURSUING, "alternate scene starts with a visible pursuer")
		var player := scene.get("player") as ActorState
		var world := scene.get("world") as GridWorld
		_check(player != null and player.cell == Vector2i(2, 4), "alternate scene has the designed player start")
		_check(player != null and world != null and _reference_distances(player.cell, world).has(world.portal), "experiment exit is reachable from the player start")
		if player != null:
			scene.call("perform_player_action", Vector2i.UP, false)
			_check(player.cell == Vector2i(2, 3), "player can sidestep to break the initial line of sight")
			_check(ai.awareness == EvasionEnemyState.Awareness.INVESTIGATING, "scene turn resolution enters investigation after the sidestep")
	scene.queue_free()
	await process_frame

func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] ", message)
	else:
		failures += 1
		push_error("[FAIL] " + message)
