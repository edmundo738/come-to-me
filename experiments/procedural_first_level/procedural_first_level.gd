extends "res://scripts/main.gd"

const ProceduralWorld = preload("res://experiments/procedural_first_level/procedural_grid_world.gd")
const ProceduralPursuer = preload("res://experiments/procedural_first_level/procedural_enemy_state.gd")
const FLOOR_LIGHT = preload("res://experiments/procedural_first_level/assets/floor_stone_light.png")
const FLOOR_DARK = preload("res://experiments/procedural_first_level/assets/floor_stone_dark.png")
const WALL_FACE = preload("res://experiments/procedural_first_level/assets/wall_panel_face.png")
const MOSS_DECAL = preload("res://experiments/procedural_first_level/assets/moss_patch.png")
const RESIN_DECAL = preload("res://experiments/procedural_first_level/assets/crimson_resin.png")
const PORTAL_SPRITE = preload("res://experiments/procedural_first_level/assets/portal_arch.png")
const PILLAR_SPRITE = preload("res://experiments/procedural_first_level/assets/pillar.png")
const CELL_SIZE := Vector2(72.0, 47.84)
const WALL_LIFT := 28.0

var next_seed := ProceduralWorld.DEFAULT_SEED

func _ready() -> void:
	super._ready()
	# Keep the experiment robust if base startup ever stops dispatching to the
	# overridden start_run(). This leaves the default main scene untouched.
	if not (world is ProceduralGridWorld):
		start_run()

func start_run() -> void:
	var generation_seed := next_seed
	next_seed += 7919
	var generated_world := ProceduralWorld.new(generation_seed) as ProceduralGridWorld
	world = generated_world
	player = ActorState.new(generated_world.player_spawn)
	enemy = ProceduralPursuer.new(generated_world.enemy_spawn)
	shields = MAX_SHIELDS
	turn_count = 0
	coins_collected = 0
	last_direction = Vector2i.RIGHT
	game_state = "playing"
	status_message = "The signal is faint. Find the way out."
	enemy.plan_step(player.cell, world)
	set_player_facing(last_direction)
	queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var procedural_world := world as ProceduralGridWorld
	if procedural_world == null:
		super._draw()
		return

	var origin := world.screen_origin(get_viewport_rect().size)
	draw_interface()
	# First lay the complete floor. This prevents the draw order of a decal or
	# a long cable from changing the floor cells beneath it.
	for y in range(GridWorld.HEIGHT):
		for x in range(GridWorld.WIDTH):
			var cell := Vector2i(x, y)
			draw_stone_floor(origin + world.to_screen(cell), cell)

	# Structures, decals, pickups and actors are then depth-sorted by grid row.
	for y in range(GridWorld.HEIGHT):
		for x in range(GridWorld.WIDTH):
			var cell := Vector2i(x, y)
			var center := origin + world.to_screen(cell)
			draw_floor_detail(center, cell, procedural_world)
			if cell == world.portal:
				draw_portal_asset(center)
			if world.walls.has(cell):
				draw_textured_wall(center, cell)
				if procedural_world.pillar_cells.has(cell):
					draw_pillar_asset(center)
			elif world.coins.has(cell):
				draw_coin(center)
			if enemy != null and enemy.cell == cell:
				draw_enemy(center)
			if player != null and player.cell == cell:
				draw_player(center)

	draw_footer()
	if game_state != "playing":
		draw_end_overlay()

func draw_stone_floor(center: Vector2, cell: Vector2i) -> void:
	var rect := Rect2(center - CELL_SIZE * 0.5, CELL_SIZE)
	var texture: Texture2D = FLOOR_LIGHT if (cell.x + cell.y) % 2 == 0 else FLOOR_DARK
	draw_texture_rect(texture, rect, false)
	draw_rect(rect, Color("b7ad98", 0.36), false, 1.0)

func draw_floor_detail(center: Vector2, cell: Vector2i, procedural_world: ProceduralGridWorld) -> void:
	if procedural_world.moss_cells.has(cell):
		draw_texture_rect(MOSS_DECAL, Rect2(center + Vector2(-40, -26), Vector2(80, 52)), false)
	if procedural_world.resin_cells.has(cell):
		draw_texture_rect(RESIN_DECAL, Rect2(center + Vector2(-34, -21), Vector2(68, 42)), false)

func draw_textured_wall(center: Vector2, cell: Vector2i) -> void:
	var face := Rect2(center + Vector2(-36, -4), Vector2(72, WALL_LIFT))
	if world.is_walkable(cell + Vector2i.DOWN):
		draw_texture_rect(WALL_FACE, face, false, Color("d0c3a5"))
		draw_rect(face, Color("221c19", 0.8), false, 1.0)

	# The cap is built from the same aligned stone tile family as the floor.
	var cap := Rect2(center + Vector2(-36, -24 - WALL_LIFT), Vector2(72, 48))
	draw_texture_rect(FLOOR_DARK, cap, false, Color("a69a82"))
	draw_rect(cap, Color("ddd1b8", 0.72), false, 1.2)

func draw_pillar_asset(center: Vector2) -> void:
	var destination := Rect2(center + Vector2(-31, -50), Vector2(62, 74))
	draw_texture_rect(PILLAR_SPRITE, destination, false)

func draw_portal_asset(center: Vector2) -> void:
	draw_shadow_ellipse(center + Vector2(0, 15), Vector2(29, 8), Color(0.04, 0.18, 0.19, 0.65))
	var destination := Rect2(center + Vector2(-39, -70), Vector2(78, 94))
	draw_texture_rect(PORTAL_SPRITE, destination, false)
	draw_string(font, center + Vector2(-12, 20), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("c1f6e8"))
