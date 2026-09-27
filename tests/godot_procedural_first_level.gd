extends SceneTree

const ProceduralWorld = preload("res://experiments/procedural_first_level/procedural_grid_world.gd")
const ProceduralPursuer = preload("res://experiments/procedural_first_level/procedural_enemy_state.gd")
const EXPERIMENT_SCENE := "res://experiments/procedural_first_level/procedural_first_level.tscn"
const ASSET_PATHS := [
	"res://experiments/procedural_first_level/assets/floor_stone_light.png",
	"res://experiments/procedural_first_level/assets/floor_stone_dark.png",
	"res://experiments/procedural_first_level/assets/wall_panel_face.png",
	"res://experiments/procedural_first_level/assets/moss_patch.png",
	"res://experiments/procedural_first_level/assets/crimson_resin.png",
	"res://experiments/procedural_first_level/assets/cable_bundle.png",
	"res://experiments/procedural_first_level/assets/portal_arch.png",
	"res://experiments/procedural_first_level/assets/pillar.png",
]

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_seeded_world_invariants()
	_test_pursuit_routes()
	await _test_experiment_scene()
	if failures == 0:
		print("GODOT_PROCEDURAL_FIRST_LEVEL: PASS")
		quit(0)
	else:
		printerr("GODOT_PROCEDURAL_FIRST_LEVEL: FAIL (%d checks)" % failures)
		quit(1)

func _test_seeded_world_invariants() -> void:
	var seeds_tested := 0
	for seed in range(20260927, 20260951):
		var world := ProceduralWorld.new(seed) as ProceduralGridWorld
		var reachable := _reference_distances(world.player_spawn, world)
		var walkable_count := 0
		var perimeter_intact := true
		var decorations_safe := true
		var fragments_safe := true
		for y in range(GridWorld.HEIGHT):
			for x in range(GridWorld.WIDTH):
				var cell := Vector2i(x, y)
				if world.is_walkable(cell):
					walkable_count += 1
				if x == 0 or y == 0 or x == GridWorld.WIDTH - 1 or y == GridWorld.HEIGHT - 1:
					perimeter_intact = perimeter_intact and world.walls.has(cell)
		for decoration in world.moss_cells + world.resin_cells:
			decorations_safe = decorations_safe and world.is_walkable(decoration)
		for pillar in world.pillar_cells:
			decorations_safe = decorations_safe and world.walls.has(pillar)
			decorations_safe = decorations_safe and pillar.x > 0 and pillar.x < GridWorld.WIDTH - 1
			decorations_safe = decorations_safe and pillar.y > 0 and pillar.y < GridWorld.HEIGHT - 1
		for fragment in world.coins.keys():
			var cell: Vector2i = fragment
			fragments_safe = fragments_safe and world.is_walkable(cell) and reachable.has(cell)
		_check(reachable.size() == walkable_count, "seed %d has no disconnected floor cells" % seed)
		_check(perimeter_intact, "seed %d preserves the blocking perimeter" % seed)
		_check(world.player_spawn == Vector2i(1, 1) and world.is_walkable(world.player_spawn), "seed %d has a valid player start" % seed)
		_check(world.portal == Vector2i(GridWorld.WIDTH - 2, GridWorld.HEIGHT - 2) and world.is_walkable(world.portal), "seed %d has a reachable exit cell" % seed)
		_check(reachable.has(world.enemy_spawn) and world.enemy_spawn != world.player_spawn, "seed %d places the pursuer on connected floor" % seed)
		_check(decorations_safe, "seed %d keeps props and floor decals out of blocking cells" % seed)
		_check(fragments_safe and world.coins.size() >= 2, "seed %d keeps fragments reachable" % seed)
		seeds_tested += 1

	var first := ProceduralWorld.new(20260927) as ProceduralGridWorld
	var repeat := ProceduralWorld.new(20260927) as ProceduralGridWorld
	_check(_wall_signature(first) == _wall_signature(repeat), "identical seeds reproduce the same wall layout")
	_check(first.enemy_spawn == repeat.enemy_spawn and first.coins == repeat.coins, "identical seeds reproduce enemy and fragment placement")
	print("[MEASURED] Procedural invariants checked across %d deterministic seeds" % seeds_tested)

func _test_pursuit_routes() -> void:
	var world := ProceduralWorld.new(20260927) as ProceduralGridWorld
	var distance_to_exit := _reference_distances(world.portal, world)
	var pursuer := ProceduralPursuer.new(world.enemy_spawn) as ProceduralEnemyState
	var walkable_count := 0
	var invalid_first_steps := 0
	for y in range(1, GridWorld.HEIGHT - 1):
		for x in range(1, GridWorld.WIDTH - 1):
			var origin := Vector2i(x, y)
			if not world.is_walkable(origin):
				continue
			walkable_count += 1
			pursuer.cell = origin
			var step := pursuer.plan_step(world.portal, world)
			if origin == world.portal:
				if step != origin:
					invalid_first_steps += 1
			elif not world.is_walkable(step) or not distance_to_exit.has(step) or distance_to_exit[step] != distance_to_exit[origin] - 1:
				invalid_first_steps += 1
	_check(invalid_first_steps == 0, "BFS pursuer advances one valid shortest-path step from every open cell")
	print("[MEASURED] Procedural pursuer first-step check: %d reachable cells, %d invalid steps" % [walkable_count, invalid_first_steps])

func _test_experiment_scene() -> void:
	for asset_path in ASSET_PATHS:
		_check(load(asset_path) is Texture2D, "candidate asset loads: %s" % asset_path.get_file())

	var packed := load(EXPERIMENT_SCENE) as PackedScene
	_check(packed != null, "procedural experiment scene parses and loads")
	if packed == null:
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	var world := scene.get("world") as ProceduralGridWorld
	var player := scene.get("player") as ActorState
	var enemy := scene.get("enemy") as ProceduralEnemyState
	_check(world != null, "alternate scene selects the generated grid world")
	_check(player != null and world != null and player.cell == world.player_spawn, "player starts at the generated entrance")
	_check(enemy != null and world != null and enemy.cell == world.enemy_spawn, "pursuer starts at a generated reachable cell")
	if world != null and player != null and enemy != null:
		var move_direction := Vector2i.ZERO
		for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var destination := player.cell + direction
			if world.is_walkable(destination) and destination != enemy.cell:
				move_direction = direction
				break
		var old_cell := player.cell
		if move_direction != Vector2i.ZERO:
			scene.call("perform_player_action", move_direction, false)
		_check(move_direction != Vector2i.ZERO and player.cell == old_cell + move_direction, "player can make a legal first move through the generated maze")
		var blocked_direction := Vector2i.ZERO
		for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			if not world.is_walkable(player.cell + direction):
				blocked_direction = direction
				break
		var cell_before_block := player.cell
		var old_turn := int(scene.get("turn_count"))
		if blocked_direction != Vector2i.ZERO:
			scene.call("perform_player_action", blocked_direction, false)
		_check(blocked_direction != Vector2i.ZERO and player.cell == cell_before_block and int(scene.get("turn_count")) == old_turn, "wall collision blocks movement without advancing a turn")
	scene.queue_free()
	await process_frame

func _reference_distances(origin: Vector2i, world: GridWorld) -> Dictionary:
	var distances: Dictionary = {origin: 0}
	var frontier: Array[Vector2i] = [origin]
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	var head := 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		for direction in directions:
			var next_cell := current + direction
			if not world.is_walkable(next_cell) or distances.has(next_cell):
				continue
			distances[next_cell] = int(distances[current]) + 1
			frontier.append(next_cell)
	return distances

func _wall_signature(world: GridWorld) -> String:
	var signature := ""
	for y in range(GridWorld.HEIGHT):
		for x in range(GridWorld.WIDTH):
			signature += "1" if world.walls.has(Vector2i(x, y)) else "0"
	return signature

func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] ", message)
	else:
		failures += 1
		push_error("[FAIL] " + message)
