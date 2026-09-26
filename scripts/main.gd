extends Node2D

const PLAYER_START := Vector2i(1, 1)
const ENEMY_START := Vector2i(9, 1)
const MAX_SHIELDS := 2
const TILE_LIGHT := Color("35434a")
const TILE_DARK := Color("2b3940")
const TILE_EDGE := Color("64747a")
const WALL_TOP := Color("87918b")
const WALL_LEFT := Color("4b5a60")
const WALL_RIGHT := Color("637178")
const TEAL := Color("78d8c4")
const GOLD := Color("f2c66d")
const RED := Color("f07178")

var world: GridWorld
var player: ActorState
var enemy: EnemyState
var shields := MAX_SHIELDS
var turn_count := 0
var coins_collected := 0
var last_direction := Vector2i.RIGHT
var game_state := "playing" # playing, won, game_over
var status_message := "The signal is faint. Find the way out."
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	start_run()
	get_viewport().size_changed.connect(queue_redraw)

func start_run() -> void:
	world = GridWorld.new()
	player = ActorState.new(PLAYER_START)
	enemy = EnemyState.new(ENEMY_START)
	shields = MAX_SHIELDS
	turn_count = 0
	coins_collected = 0
	last_direction = Vector2i.RIGHT
	game_state = "playing"
	status_message = "The signal is faint. Find the way out."
	enemy.plan_step(player.cell, world)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var action := InputRouter.decode(event)
	if action.is_empty():
		return
	if action.type == "restart":
		start_run()
		return
	if game_state != "playing":
		return
	match action.type:
		"move":
			last_direction = action.direction
			perform_player_action(action.direction, false)
		"jump":
			perform_player_action(last_direction, true)
		"wait":
			status_message = "You hold still and listen."
			complete_turn()

func perform_player_action(direction: Vector2i, jumping: bool) -> void:
	var distance := 2 if jumping else 1
	var destination := player.cell + direction * distance
	if not world.is_walkable(destination):
		status_message = "That path is blocked. The world does not advance."
		queue_redraw()
		return
	if jumping:
		status_message = "You clear the space between cells."
	else:
		status_message = "You move into the dark."
	player.cell = destination
	if enemy.cell == player.cell:
		handle_player_collision()
		if game_state != "playing":
			queue_redraw()
			return
	collect_coin()
	if player.cell == world.portal:
		game_state = "won"
		status_message = "You reached the signal. For now, it is quiet."
		queue_redraw()
		return
	complete_turn()

func complete_turn() -> void:
	turn_count += 1
	# Resolve the already-visible plan. Moving away from its target can bait
	# pursuit into the cell the player just vacated.
	var planned_cell := enemy.intent
	var previous_cell := enemy.cell
	if world.is_walkable(planned_cell):
		enemy.cell = planned_cell
		if enemy.cell == player.cell:
			enemy.cell = previous_cell
			handle_enemy_collision()
			if game_state != "playing":
				queue_redraw()
				return
	enemy.plan_step(player.cell, world)
	queue_redraw()

func handle_player_collision() -> void:
	if shields > 0:
		shields -= 1
		enemy.cell = enemy.spawn_cell
		status_message = "Shield discharged. The pursuer recoils."
	else:
		game_state = "game_over"
		status_message = "The pursuer caught you. The signal continues without you."

func handle_enemy_collision() -> void:
	if shields > 0:
		shields -= 1
		status_message = "Shield discharged. You slip past the pursuer."
	else:
		game_state = "game_over"
		status_message = "The pursuer caught you. The signal continues without you."

func collect_coin() -> void:
	if world.coins.has(player.cell):
		world.coins.erase(player.cell)
		coins_collected += 1
		status_message = "Signal fragment recovered."

func _draw() -> void:
	if world == null:
		return
	var origin := world.screen_origin(get_viewport_rect().size)
	draw_interface()
	var cells: Array[Vector2i] = []
	for y in range(GridWorld.HEIGHT):
		for x in range(GridWorld.WIDTH):
			cells.append(Vector2i(x, y))
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x + a.y < b.x + b.y
	)
	for cell in cells:
		draw_floor_tile(origin + world.to_screen(cell), cell)
		if world.walls.has(cell):
			draw_wall(origin + world.to_screen(cell))
		elif world.coins.has(cell):
			draw_coin(origin + world.to_screen(cell))
	if player != null and enemy != null:
		draw_portal(origin + world.to_screen(world.portal))
		draw_enemy_intent(origin + world.to_screen(enemy.cell), origin + world.to_screen(enemy.intent))
		draw_enemy(origin + world.to_screen(enemy.cell))
		draw_player(origin + world.to_screen(player.cell))
	draw_footer()
	if game_state != "playing":
		draw_end_overlay()

func draw_floor_tile(center: Vector2, cell: Vector2i) -> void:
	var points := diamond(center, GridWorld.TILE_WIDTH * 0.5, GridWorld.TILE_HEIGHT * 0.5)
	var color := TILE_LIGHT if (cell.x + cell.y) % 2 == 0 else TILE_DARK
	draw_colored_polygon(points, color)
	# A full, consistent cell outline makes the movement grid easy to read.
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), TILE_EDGE, 1.35, true)

func draw_wall(center: Vector2) -> void:
	# A single extruded isometric block: two side faces, then one top diamond.
	# Keeping the base vertices aligned with the floor cell avoids the old
	# skewed/overlapping wall shape.
	var base := diamond(center, GridWorld.TILE_WIDTH * 0.5, GridWorld.TILE_HEIGHT * 0.5)
	var top_center := center + Vector2(0, -38)
	var top := diamond(top_center, GridWorld.TILE_WIDTH * 0.5, GridWorld.TILE_HEIGHT * 0.5)
	var left_face := PackedVector2Array([top[3], top[2], base[2], base[3]])
	var right_face := PackedVector2Array([top[2], top[1], base[1], base[2]])
	draw_colored_polygon(left_face, WALL_LEFT)
	draw_colored_polygon(right_face, WALL_RIGHT)
	draw_colored_polygon(top, WALL_TOP)
	var outline := Color("c1c7bd")
	draw_polyline(PackedVector2Array([top[3], top[2], top[1], base[1], base[2], base[3], top[3]]), outline, 1.7, true)
	# Simple material seam: reads as a solid block, not a strange floor marking.
	draw_line(top[3] + Vector2(9, 5), top[2] + Vector2(-9, 5), Color("aeb8b0", 0.65), 1.0, true)

func draw_coin(center: Vector2) -> void:
	draw_circle(center + Vector2(0, -7), 8, Color(0.10, 0.12, 0.13, 0.5))
	draw_circle(center + Vector2(0, -13), 6, GOLD)
	draw_circle(center + Vector2(-1, -14), 2, Color(1.0, 0.91, 0.67))

func draw_portal(center: Vector2) -> void:
	draw_colored_polygon(diamond(center + Vector2(0, -4), 21, 10), Color(0.25, 0.8, 0.77, 0.18))
	draw_arc(center + Vector2(0, -8), 13, PI, TAU, 24, TEAL, 3.0, true)
	draw_line(center + Vector2(-13, -8), center + Vector2(-13, 3), TEAL, 3.0)
	draw_line(center + Vector2(13, -8), center + Vector2(13, 3), TEAL, 3.0)
	draw_line(center + Vector2(-13, 3), center + Vector2(13, 3), TEAL, 3.0)
	draw_string(font, center + Vector2(-18, 26), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.65, 0.9, 0.86, 0.8))

func draw_enemy_intent(from: Vector2, to: Vector2) -> void:
	if from.distance_to(to) < 2:
		return
	# Mark only the destination cell; a long arrow crossing the board made the
	# tactical picture noisy and obscured the grid.
	var marker := to + Vector2(0, -1)
	var points := diamond(marker, GridWorld.TILE_WIDTH * 0.5 - 5, GridWorld.TILE_HEIGHT * 0.5 - 3)
	draw_colored_polygon(points, Color(RED, 0.24))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), RED, 2.2, true)
	draw_circle(to + Vector2(0, -9), 9, Color("311f27"))
	draw_string(font, to + Vector2(-4, -5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("ffe4d8"))

func draw_player(center: Vector2) -> void:
	draw_ellipse(center + Vector2(0, 2), Vector2(17, 8), Color(0.02, 0.04, 0.06, 0.5))
	# Boots and legs sit below the coat so the character has a clear upright read.
	draw_line(center + Vector2(-4, 9), center + Vector2(-6, 19), Color("263239"), 5.0, true)
	draw_line(center + Vector2(4, 9), center + Vector2(6, 19), Color("263239"), 5.0, true)
	draw_line(center + Vector2(-6, 19), center + Vector2(-2, 20), Color("d0bd9a"), 3.0, true)
	draw_line(center + Vector2(6, 19), center + Vector2(10, 20), Color("d0bd9a"), 3.0, true)
	# Backpack, coat and arms give the player a recognizable explorer silhouette.
	draw_colored_polygon(PackedVector2Array([center + Vector2(-11, -12), center + Vector2(-5, -16), center + Vector2(-4, 4), center + Vector2(-11, 2)]), Color("bd985b"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-7, -14), center + Vector2(0, -18), center + Vector2(8, -13), center + Vector2(7, 7), center + Vector2(0, 13), center + Vector2(-7, 7)]), Color("428e88"))
	draw_line(center + Vector2(-8, -8), center + Vector2(-13, 3), Color("d4ad79"), 4.0, true)
	draw_line(center + Vector2(8, -8), center + Vector2(12, 2), Color("d4ad79"), 4.0, true)
	draw_circle(center + Vector2(0, -22), 7, Color("c69f79"))
	draw_arc(center + Vector2(0, -22), 7, PI, TAU, 16, Color("263239"), 4.0, true)
	draw_circle(center + Vector2(2, -22), 1.2, Color("20262a"))
	draw_circle(center + Vector2(0, -31), 2.5, TEAL)

func draw_enemy(center: Vector2) -> void:
	draw_ellipse(center + Vector2(0, 2), Vector2(18, 8), Color(0.02, 0.03, 0.05, 0.58))
	# A hunched, hooded silhouette with two readable eyes; kept distinct from
	# the player's warm face and teal coat.
	draw_line(center + Vector2(-5, 6), center + Vector2(-9, 16), Color("382b35"), 5.0, true)
	draw_line(center + Vector2(5, 6), center + Vector2(9, 15), Color("382b35"), 5.0, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-11, -11), center + Vector2(-6, -19), center + Vector2(0, -23), center + Vector2(7, -19), center + Vector2(12, -9), center + Vector2(9, 8), center + Vector2(2, 15), center + Vector2(-3, 9), center + Vector2(-10, 13), center + Vector2(-13, 2)]), Color("493541"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-8, -11), center + Vector2(-4, -17), center + Vector2(4, -17), center + Vector2(9, -9), center + Vector2(5, -3), center + Vector2(-6, -3)]), Color("211e27"))
	draw_circle(center + Vector2(-3, -9), 2.2, RED)
	draw_circle(center + Vector2(4, -9), 2.2, RED)
	draw_line(center + Vector2(-2, 1), center + Vector2(5, 6), Color("74515a"), 1.5, true)

func draw_interface() -> void:
	var width := get_viewport_rect().size.x
	draw_rect(Rect2(0, 0, width, 102), Color(0.035, 0.055, 0.075, 0.97))
	draw_line(Vector2(0, 101), Vector2(width, 101), Color(TEAL, 0.3), 1.0)
	draw_string(font, Vector2(34, 39), "COME TO ME", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("e2e7df"))
	draw_string(font, Vector2(35, 64), "FIELD TEST  /  01", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("83a0a2"))
	draw_string(font, Vector2(320, 37), "TURN  %02d" % turn_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d6ded8"))
	draw_string(font, Vector2(320, 63), "FRAGMENTS  %02d" % coins_collected, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	draw_string(font, Vector2(490, 37), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d6ded8"))
	for index in range(MAX_SHIELDS):
		var pip_color := TEAL if index < shields else Color("42545b")
		draw_circle(Vector2(552 + index * 22, 33), 6, pip_color)
	draw_string(font, Vector2(700, 37), "PURSUER INTENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, RED)
	draw_string(font, Vector2(700, 62), "Arrow marks its next cell", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("9eadae"))
	draw_string(font, Vector2(35, 88), status_message, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("bdc9c2"))

func draw_footer() -> void:
	var height := get_viewport_rect().size.y
	var width := get_viewport_rect().size.x
	draw_rect(Rect2(0, height - 35, width, 35), Color(0.035, 0.055, 0.075, 0.92))
	draw_string(font, Vector2(25, height - 12), "MOVE  WASD / ARROWS     JUMP  SPACE     WAIT  E     RESTART  R", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9eadae"))
	draw_string(font, Vector2(width - 205, height - 12), "FIND THE TEAL GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEAL)

func draw_end_overlay() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.04, 0.76))
	var heading := "SIGNAL REACHED" if game_state == "won" else "CONNECTION LOST"
	var heading_color := TEAL if game_state == "won" else RED
	draw_string(font, Vector2(0, size.y * 0.47), heading, HORIZONTAL_ALIGNMENT_CENTER, size.x, 27, heading_color)
	draw_string(font, Vector2(0, size.y * 0.47 + 34), status_message, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color("d3dbd6"))
	draw_string(font, Vector2(0, size.y * 0.47 + 70), "PRESS R TO BEGIN AGAIN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color("9eadae"))

func diamond(center: Vector2, half_width: float, half_height: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0, -half_height),
		center + Vector2(half_width, 0),
		center + Vector2(0, half_height),
		center + Vector2(-half_width, 0)
	])

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
