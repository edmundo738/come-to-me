class_name ProceduralGridWorld
extends GridWorld

const DEFAULT_SEED := 20260927
const PLAYER_START := Vector2i(1, 1)

var seed_value := DEFAULT_SEED
var player_spawn := PLAYER_START
var enemy_spawn := Vector2i(9, 1)
var pillar_cells: Array[Vector2i] = []
var moss_cells: Array[Vector2i] = []
var resin_cells: Array[Vector2i] = []

func _init(generation_seed: int = DEFAULT_SEED) -> void:
	super()
	seed_value = generation_seed
	walls.clear()
	coins.clear()
	pillar_cells.clear()
	moss_cells.clear()
	resin_cells.clear()
	_generate(seed_value)

func _generate(generation_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = generation_seed
	player_spawn = PLAYER_START
	portal = Vector2i(WIDTH - 2, HEIGHT - 2)

	# Begin with solid cells, preserving a permanent one-cell perimeter.
	for y in range(HEIGHT):
		for x in range(WIDTH):
			walls[Vector2i(x, y)] = true

	# Randomized depth-first carving makes a connected maze on odd grid cells.
	# Every corridor is two cells wide at first, with the middle cell carved too.
	var start := PLAYER_START
	var visited: Dictionary = {start: true}
	var stack: Array[Vector2i] = [start]
	walls.erase(start)
	var directions: Array[Vector2i] = [
		Vector2i.RIGHT * 2,
		Vector2i.DOWN * 2,
		Vector2i.LEFT * 2,
		Vector2i.UP * 2,
	]
	while not stack.is_empty():
		var current: Vector2i = stack[-1]
		var options: Array[Vector2i] = []
		for direction in directions:
			var candidate := current + direction
			if candidate.x < 1 or candidate.x >= WIDTH - 1 or candidate.y < 1 or candidate.y >= HEIGHT - 1:
				continue
			if not visited.has(candidate):
				options.append(candidate)
		if options.is_empty():
			stack.pop_back()
			continue
		_shuffle(options, rng)
		var next_cell := options[0]
		var middle_cell := Vector2i(
			int((current.x + next_cell.x) / 2),
			int((current.y + next_cell.y) / 2)
		)
		walls.erase(middle_cell)
		walls.erase(next_cell)
		visited[next_cell] = true
		stack.append(next_cell)

	# Open extra interior walls to create loops, wider pockets, and optional routes.
	# Carving extra cells cannot disconnect the spanning-tree path to the exit.
	var extra_walls: Array[Vector2i] = []
	for cell in walls.keys():
		var wall_cell: Vector2i = cell
		if wall_cell.x > 0 and wall_cell.x < WIDTH - 1 and wall_cell.y > 0 and wall_cell.y < HEIGHT - 1:
			extra_walls.append(wall_cell)
	_shuffle(extra_walls, rng)
	var extra_openings := mini(extra_walls.size(), rng.randi_range(7, 11))
	for index in range(extra_openings):
		walls.erase(extra_walls[index])

	var distances := _distances_from(player_spawn)
	enemy_spawn = _choose_enemy_spawn(distances, rng)
	_add_route_fragments(_path_to(portal), rng)
	_place_decorations(rng)
	_place_pillars(rng)

func _choose_enemy_spawn(distances: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var farthest_distance := -1
	var candidates: Array[Vector2i] = []
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			var cell := Vector2i(x, y)
			if cell == player_spawn or cell == portal or not distances.has(cell):
				continue
			var distance: int = distances[cell]
			if distance > farthest_distance:
				farthest_distance = distance
				candidates.clear()
				candidates.append(cell)
			elif distance == farthest_distance:
				candidates.append(cell)
	_shuffle(candidates, rng)
	return candidates[0] if not candidates.is_empty() else player_spawn

func _add_route_fragments(route: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	var safe_route: Array[Vector2i] = []
	for cell in route:
		if cell != player_spawn and cell != enemy_spawn and cell != portal:
			safe_route.append(cell)
	if safe_route.size() >= 2:
		coins[safe_route[int(safe_route.size() / 3.0)]] = true
		coins[safe_route[int((safe_route.size() * 2) / 3.0)]] = true

	var route_set: Dictionary = {}
	for cell in route:
		route_set[cell] = true
	var optional_cells: Array[Vector2i] = []
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			var cell := Vector2i(x, y)
			if is_walkable(cell) and not route_set.has(cell) and cell != enemy_spawn and cell != portal:
				optional_cells.append(cell)
	_shuffle(optional_cells, rng)
	if not optional_cells.is_empty():
		coins[optional_cells[0]] = true

func _place_decorations(rng: RandomNumberGenerator) -> void:
	var route_set: Dictionary = {}
	for cell in _path_to(portal):
		route_set[cell] = true
	var safe_floor: Array[Vector2i] = []
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			var cell := Vector2i(x, y)
			if not is_walkable(cell) or route_set.has(cell) or coins.has(cell):
				continue
			if cell == player_spawn or cell == enemy_spawn or cell == portal:
				continue
			safe_floor.append(cell)
	_shuffle(safe_floor, rng)
	if not safe_floor.is_empty():
		moss_cells.append(safe_floor.pop_back())
	if not safe_floor.is_empty():
		resin_cells.append(safe_floor.pop_back())


func _place_pillars(rng: RandomNumberGenerator) -> void:
	var candidates: Array[Vector2i] = []
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			var cell := Vector2i(x, y)
			if not walls.has(cell):
				continue
			var open_neighbors := 0
			for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
				if is_walkable(cell + direction):
					open_neighbors += 1
			if open_neighbors >= 2:
				candidates.append(cell)
	_shuffle(candidates, rng)
	for index in range(mini(3, candidates.size())):
		pillar_cells.append(candidates[index])

func _distances_from(origin: Vector2i) -> Dictionary:
	var distances: Dictionary = {origin: 0}
	var frontier: Array[Vector2i] = [origin]
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	var head := 0
	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1
		for direction in directions:
			var next_cell := current + direction
			if not is_walkable(next_cell) or distances.has(next_cell):
				continue
			distances[next_cell] = int(distances[current]) + 1
			frontier.append(next_cell)
	return distances

func _path_to(destination: Vector2i) -> Array[Vector2i]:
	var previous: Dictionary = {player_spawn: player_spawn}
	var frontier: Array[Vector2i] = [player_spawn]
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	var head := 0
	while head < frontier.size() and not previous.has(destination):
		var current: Vector2i = frontier[head]
		head += 1
		for direction in directions:
			var next_cell := current + direction
			if not is_walkable(next_cell) or previous.has(next_cell):
				continue
			previous[next_cell] = current
			frontier.append(next_cell)
	var route: Array[Vector2i] = []
	if not previous.has(destination):
		return route
	var cursor := destination
	while cursor != player_spawn:
		route.push_front(cursor)
		cursor = previous[cursor]
	route.push_front(player_spawn)
	return route

func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for index in range(cells.size() - 1, 0, -1):
		var other_index := rng.randi_range(0, index)
		var temporary: Vector2i = cells[index]
		cells[index] = cells[other_index]
		cells[other_index] = temporary
