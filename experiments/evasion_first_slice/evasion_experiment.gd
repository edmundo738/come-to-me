extends "res://scripts/main.gd"

const PLAYER_TEST_START := Vector2i(2, 4)
const ENEMY_TEST_START := Vector2i(8, 4)

func _ready() -> void:
	super._ready()
	# Keep the experiment robust if a future base-scene startup stops dispatching
	# its setup through this override.
	if not (enemy is EvasionEnemyState):
		start_run()

func start_run() -> void:
	world = GridWorld.new()
	world.walls.clear()
	world.coins.clear()
	# Short central pillars leave an exposed lane for the opening chase, then
	# a one-cell sidestep can break sight without requiring a new player verb.
	for wall in [
		Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 5), Vector2i(4, 6),
		Vector2i(6, 2), Vector2i(6, 3), Vector2i(6, 5), Vector2i(6, 6),
		Vector2i(3, 6), Vector2i(7, 6)
	]:
		world.walls[wall] = true
	world.coins[Vector2i(7, 7)] = true
	world.portal = Vector2i(9, 7)

	player = ActorState.new(PLAYER_TEST_START)
	enemy = EvasionEnemyState.new(ENEMY_TEST_START)
	shields = MAX_SHIELDS
	turn_count = 0
	coins_collected = 0
	last_direction = Vector2i.RIGHT
	game_state = "playing"
	status_message = "The signal is faint. Find the way out."
	enemy.plan_step(player.cell, world)
	set_player_facing(last_direction)
	queue_redraw()

func draw_enemy(center: Vector2) -> void:
	var evasion_enemy := enemy as EvasionEnemyState
	if evasion_enemy == null:
		super.draw_enemy(center)
		return

	draw_shadow_ellipse(center + Vector2(0, 2), Vector2(18, 8), Color(0.02, 0.03, 0.05, 0.58))
	draw_line(center + Vector2(-5, 6), center + Vector2(-9, 16), Color("382b35"), 5.0, true)
	draw_line(center + Vector2(5, 6), center + Vector2(9, 15), Color("382b35"), 5.0, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-11, -11), center + Vector2(-6, -19), center + Vector2(0, -23), center + Vector2(7, -19), center + Vector2(12, -9), center + Vector2(9, 8), center + Vector2(2, 15), center + Vector2(-3, 9), center + Vector2(-10, 13), center + Vector2(-13, 2)]), Color("493541"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-8, -11), center + Vector2(-4, -17), center + Vector2(4, -17), center + Vector2(9, -9), center + Vector2(5, -3), center + Vector2(-6, -3)]), Color("211e27"))
	var eye_color := Color("f07178")
	match evasion_enemy.awareness:
		EvasionEnemyState.Awareness.INVESTIGATING:
			eye_color = Color("f2c66d")
		EvasionEnemyState.Awareness.SEARCHING:
			eye_color = Color("fff0b3")
		EvasionEnemyState.Awareness.RECOVERING, EvasionEnemyState.Awareness.UNAWARE:
			eye_color = Color("a88796")
	var gaze := Vector2(evasion_enemy.facing) * 2.0
	draw_circle(center + Vector2(-3, -9) + gaze, 2.2, eye_color)
	draw_circle(center + Vector2(4, -9) + gaze, 2.2, eye_color)
	draw_line(center + Vector2(-2, 1), center + Vector2(5, 6), Color("74515a"), 1.5, true)
