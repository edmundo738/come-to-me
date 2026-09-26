extends Node2D

const PLAYER_START := Vector2i(1, 1)
const ENEMY_START := Vector2i(9, 1)
const MAX_SHIELDS := 2
const INK := Color("101923")
const TILE_LIGHT := Color("293944")
const TILE_DARK := Color("23323c")
const WALL_TOP := Color("53636a")
const WALL_LEFT := Color("34444d")
const WALL_RIGHT := Color("40525b")
const TEAL := Color("72e0cc")
const GOLD := Color("f5c56b")
const RED := Color("ef6d72")

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
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.43, 0.57, 0.6, 0.24), 1.0, true)

func draw_wall(center: Vector2) -> void:
	var top := center + Vector2(0, -20)
	var top_points := diamond(top, GridWorld.TILE_WIDTH * 0.5, GridWorld.TILE_HEIGHT * 0.5)
	draw_colored_polygon(PackedVector2Array([top_points[3], top_points[2], center + Vector2(36, 0), center + Vector2(0, 17), center + Vector2(-36, 0)]), WALL_LEFT)
	draw_colored_polygon(PackedVector2Array([top_points[1], top_points[2], center + Vector2(36, 0), center + Vector2(0, 17)]), WALL_RIGHT)
	draw_colored_polygon(top_points, WALL_TOP)
	draw_line(top_points[0], top_points[1], Color(0.72, 0.8, 0.78, 0.32), 1.2)

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
	draw_line(from + Vector2(0, -7), to + Vector2(0, -7), Color(RED, 0.72), 2.5, true)
	var direction := (to - from).normalized()
	var tip := to + Vector2(0, -7)
	draw_line(tip, tip - direction.rotated(0.55) * 10, RED, 2.5, true)
	draw_line(tip, tip - direction.rotated(-0.55) * 10, RED, 2.5, true)
	draw_colored_polygon(diamond(to + Vector2(0, -1), 12, 6), Color(RED, 0.24))

func draw_player(center: Vector2) -> void:
	draw_ellipse(center + Vector2(0, 1), Vector2(16, 8), Color(0.02, 0.04, 0.06, 0.45))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-10, -13), center + Vector2(0, -19), center + Vector2(10, -13), center + Vector2(0, -7)]), Color("b8a27e"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-10, -13), center + Vector2(0, -7), center + Vector2(0, 14), center + Vector2(-8, 7)]), Color("3f9d98"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -7), center + Vector2(10, -13), center + Vector2(8, 7), center + Vector2(0, 14)]), Color("286b70"))
	draw_circle(center + Vector2(0, -14), 3, Color("1b252b"))
	draw_line(center + Vector2(-4, 14), center + Vector2(-5, 20), Color("b8a27e"), 3)
	draw_line(center + Vector2(4, 14), center + Vector2(5, 20), Color("b8a27e"), 3)
	draw_circle(center + Vector2(0, -24), 2.5, TEAL)

func draw_enemy(center: Vector2) -> void:
	draw_ellipse(center + Vector2(0, 1), Vector2(17, 8), Color(0.02, 0.03, 0.05, 0.5))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -13), center + Vector2(0, -20), center + Vector2(12, -13), center + Vector2(0, 8)]), Color("5c343e"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -13), center + Vector2(0, 8), center + Vector2(-4, 16), center + Vector2(-14, 4)]), Color("382630"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(12, -13), center + Vector2(0, 8), center + Vector2(4, 16), center + Vector2(14, 4)]), Color("472b35"))
	draw_circle(center + Vector2(0, -12), 3, RED)
	draw_circle(center + Vector2(-1, -13), 1, Color(1.0, 0.82, 0.71))

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
