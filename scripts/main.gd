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
	# Back-to-front by screen row. Actors can pass behind foreground objects.
	for y in range(GridWorld.HEIGHT):
		for x in range(GridWorld.WIDTH):
			var cell := Vector2i(x, y)
			var center := origin + world.to_screen(cell)
			draw_floor_tile(center, cell)
			if cell == world.portal:
				draw_portal(center)
			if world.walls.has(cell):
				draw_wall(center)
			elif world.coins.has(cell):
				draw_coin(center)
			if enemy != null and enemy.cell == cell:
				draw_enemy(center)
			if player != null and player.cell == cell:
				draw_player(center)
	draw_footer()
	if game_state != "playing":
		draw_end_overlay()

func draw_floor_tile(center: Vector2, cell: Vector2i) -> void:
	var size := Vector2(GridWorld.TILE_WIDTH, GridWorld.TILE_HEIGHT * 0.92)
	var rect := Rect2(center - size * 0.5, size)
	var color := TILE_LIGHT if (cell.x + cell.y) % 2 == 0 else TILE_DARK
	draw_rect(rect, color)
	# Straight grid edges preserve immediate screen-direction readability.
	draw_rect(rect, TILE_EDGE, false, 1.2)

func draw_wall(center: Vector2) -> void:
	# Raised rectangular wall block, seen from a shallow top-down angle.
	var half_w := GridWorld.TILE_WIDTH * 0.5
	var half_h := GridWorld.TILE_HEIGHT * 0.92 * 0.5
	var lift := 28.0
	var base := PackedVector2Array([
		center + Vector2(-half_w, -half_h),
		center + Vector2(half_w, -half_h),
		center + Vector2(half_w, half_h),
		center + Vector2(-half_w, half_h)
	])
	var top := PackedVector2Array([
		base[0] + Vector2(0, -lift),
		base[1] + Vector2(0, -lift),
		base[2] + Vector2(0, -lift),
		base[3] + Vector2(0, -lift)
	])
	# Only faces on the near/right sides are shaded; the flat top remains clear.
	draw_colored_polygon(PackedVector2Array([top[3], top[2], base[2], base[3]]), WALL_LEFT)
	draw_colored_polygon(PackedVector2Array([top[1], top[2], base[2], base[1]]), WALL_RIGHT)
	draw_colored_polygon(top, WALL_TOP)
	var outline := Color("d1d3c9")
	draw_polyline(PackedVector2Array([top[0], top[1], top[2], top[3], top[0]]), outline, 1.5, true)
	draw_line(top[3], base[3], outline, 1.2, true)
	draw_line(top[2], base[2], outline, 1.2, true)
	draw_line(top[1], base[1], Color(outline, 0.65), 1.0, true)

func draw_coin(center: Vector2) -> void:
	draw_circle(center + Vector2(0, -7), 8, Color(0.10, 0.12, 0.13, 0.5))
	draw_circle(center + Vector2(0, -13), 6, GOLD)
	draw_circle(center + Vector2(-1, -14), 2, Color(1.0, 0.91, 0.67))

func draw_portal(center: Vector2) -> void:
	var footprint := Rect2(center + Vector2(-22, -8), Vector2(44, 16))
	draw_rect(footprint, Color(TEAL, 0.13))
	draw_rect(footprint, Color(TEAL, 0.65), false, 1.5)
	# A simple upright doorway, grounded on the same screen-aligned grid.
	draw_line(center + Vector2(-15, -3), center + Vector2(-15, -25), TEAL, 3.0, true)
	draw_line(center + Vector2(15, -3), center + Vector2(15, -25), TEAL, 3.0, true)
	draw_arc(center + Vector2(0, -25), 15, PI, TAU, 20, TEAL, 3.0, true)
	draw_line(center + Vector2(-10, -3), center + Vector2(10, -3), Color(TEAL, 0.7), 1.0, true)
	draw_string(font, center + Vector2(-13, 14), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("b8f1e6"))

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
	draw_string(font, Vector2(700, 37), "WATCH. LEARN. MOVE.", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEAL)
	draw_string(font, Vector2(700, 62), "Read the pursuer's behavior", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("9eadae"))
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

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
