extends SceneTree

const ROOM_SCENE := "res://experiments/manual_3d_room/manual_3d_room.tscn"
const BORDER_AND_PILLAR_COUNT := 45

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(ROOM_SCENE) as PackedScene
	_check(packed != null, "manual room scene loads")
	if packed == null:
		_finish()
		return

	var room := packed.instantiate() as ManualRoomController
	_check(room != null, "scene root is the editable room controller")
	if room == null:
		_finish()
		return
	root.add_child(room)
	await process_frame
	await physics_frame

	_test_scene_tree(room)
	_test_evasion_state_and_layout(room)
	await _test_continuous_player_crossings(room)
	room.queue_free()
	await process_frame
	_finish()

func _test_scene_tree(room: ManualRoomController) -> void:
	_check(room.get_node_or_null("Environment/Floor/StoneSlab") is MeshInstance3D, "room has an editable 3D floor mesh")
	_check(room.get_node_or_null("Environment/Floor/CollisionShape3D") is CollisionShape3D, "floor has a physical collision shape")
	_check(room.get_node_or_null("Environment/Walls") is Node3D, "walls are grouped as editable scene instances")
	_check(room.get_node_or_null("Environment/Props") is Node3D, "columns are grouped as editable scene instances")
	var resin_decal := room.get_node_or_null("Environment/Decals/ResinPuddle_Blockout") as MeshInstance3D
	_check(resin_decal != null and resin_decal.mesh is PlaneMesh and is_equal_approx(resin_decal.rotation_degrees.x, -90.0), "experimental resin decal lies flat on the 3D floor and is replaceable")
	_check(room.get_node_or_null("Environment/Doors/ExitGate") is Area3D, "exit is an editable 3D trigger and gate")
	_check(room.get_node_or_null("CameraRig/Camera3D") is Camera3D, "camera is an editable 3D camera node")
	_check(room.get_node_or_null("Environment/KeyLight") is DirectionalLight3D, "room has an editable shadow-casting key light")
	_check(room.get_tree().get_nodes_in_group("grid_blockers").size() == BORDER_AND_PILLAR_COUNT, "all boundary walls and columns are separate collision-backed scene instances")

	var player_sprite := room.get_node_or_null("Gameplay/Player/AnimatedSprite3D") as AnimatedSprite3D
	_check(player_sprite != null and player_sprite.sprite_frames != null, "player is an animated 2D sprite in 3D space")
	if player_sprite != null and player_sprite.sprite_frames != null:
		_check(player_sprite.sprite_frames.has_animation("FRONT") and player_sprite.sprite_frames.get_frame_count("FRONT") == 12, "approved front idle animation is reused as 12 separate frames")
		_check(player_sprite.sprite_frames.has_animation("BACK") and player_sprite.sprite_frames.get_frame_count("BACK") == 12, "approved back idle animation is reused as 12 separate frames")

	var statue_sprite := room.get_node_or_null("Gameplay/Enemy/StatueSprite") as Sprite3D
	_check(statue_sprite != null and statue_sprite.texture != null, "first statue enemy is a 2D Sprite3D, not a code-drawn world shape")

func _test_evasion_state_and_layout(room: ManualRoomController) -> void:
	_check(room.room_grid != null and room.room_grid.walls.size() == BORDER_AND_PILLAR_COUNT, "logical blockers are read from the visible scene instances")
	_check(room.room_grid.is_walkable(Vector2i(2, 4)), "player start is clear")
	_check(room.room_grid.is_walkable(Vector2i(8, 4)), "statue start is clear")
	_check(not room.room_grid.is_walkable(Vector2i(4, 3)), "the center pillar column blocks its real grid cell")
	_check(room.room_grid.portal == Vector2i(9, 8) and room.room_grid.is_walkable(room.room_grid.portal), "the teal gate has an open, reachable threshold in the boundary")
	_check(room.enemy_state is EvasionEnemyState, "room directly reuses the accepted Evasion First state class")
	if room.enemy_state is EvasionEnemyState:
		_check(room.enemy_state.awareness == EvasionEnemyState.Awareness.PURSUING, "statue begins with line of sight and pursuit")
		_check(room.enemy_state.last_seen_cell == room.player_state.cell, "initial visual contact is the remembered player cell")
		_check(_reference_distances(room.player_state.cell, room.room_grid).has(room.room_grid.portal), "objective is reachable through the hand-built room")

func _test_continuous_player_crossings(room: ManualRoomController) -> void:
	var player := room.player_actor
	var start_position := player.global_position
	var start_cell := player.grid_cell
	var starting_turn := room.turn_count
	player.set_key_state(KEY_D, Vector2i.RIGHT, true)
	await create_timer(0.12).timeout
	var moved_inside_cell := player.global_position.distance_to(start_position) > 0.05
	_check(moved_inside_cell, "player position changes continuously between cell centers")
	_check(player.grid_cell == start_cell and room.turn_count == starting_turn, "sub-cell movement does not consume an enemy unit")

	await create_timer(0.22).timeout
	player.set_key_state(KEY_D, Vector2i.RIGHT, false)
	_check(player.grid_cell == start_cell + Vector2i.RIGHT, "crossing into one neighboring cell updates the logical cell")
	_check(room.turn_count == starting_turn + 1, "one crossed cell produces exactly one enemy turn")
	_check(room.enemy_state.cell == Vector2i(7, 4), "the statue animates its already-planned one-cell pursuit")

	player.set_key_state(KEY_W, Vector2i.UP, true)
	await create_timer(0.30).timeout
	player.set_key_state(KEY_W, Vector2i.UP, false)
	_check(player.grid_cell == Vector2i(3, 3), "continuous northward movement crosses one strategic cell")
	_check(room.turn_count == starting_turn + 2, "a second boundary crossing produces one more enemy unit")
	_check(room.enemy_state.awareness == EvasionEnemyState.Awareness.INVESTIGATING, "the center pillar makes the existing AI lose sight and investigate")
	_check(room.enemy_state.last_seen_cell == Vector2i(3, 4), "investigation retains the last cell the statue actually saw")

	var position_before_wall := player.global_position
	player.set_key_state(KEY_D, Vector2i.RIGHT, true)
	await create_timer(0.28).timeout
	player.set_key_state(KEY_D, Vector2i.RIGHT, false)
	_check(player.global_position.x < 3.5 and player.grid_cell == Vector2i(3, 3), "the physical pillar collision stops the player at the blocked cell boundary")
	_check(room.turn_count == starting_turn + 2 and player.global_position.x > position_before_wall.x, "bumping a wall moves up to its collider but does not advance the enemy turn")

func _reference_distances(origin: Vector2i, world: GridWorld) -> Dictionary:
	var distances: Dictionary = {origin: 0}
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
			distances[candidate] = int(distances[current]) + 1
			frontier.append(candidate)
	return distances

func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] ", message)
	else:
		failures += 1
		push_error("[FAIL] " + message)

func _finish() -> void:
	if failures == 0:
		print("GODOT_MANUAL_3D_ROOM: PASS")
		quit(0)
	else:
		printerr("GODOT_MANUAL_3D_ROOM: FAIL (%d checks)" % failures)
		quit(1)
