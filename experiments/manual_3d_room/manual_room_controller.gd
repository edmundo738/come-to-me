class_name ManualRoomController
extends Node3D

const PLAYER_START := Vector2i(2, 4)
const ENEMY_START := Vector2i(8, 4)
const MAX_SHIELDS := 2
const EvasionAI = preload("res://experiments/evasion_first_slice/evasion_enemy_state.gd")

@onready var player_actor: RoomPlayer3D = $Gameplay/Player
@onready var enemy_actor: RoomEnemyVisual = $Gameplay/Enemy
@onready var exit_gate: GridCellMarker3D = $Environment/Doors/ExitGate
@onready var exit_light: OmniLight3D = $Environment/Doors/ExitGate/ArrivalLight

var room_grid: GridWorld
var player_state: ActorState
var enemy_state: EvasionEnemyState
var player_start_cell := PLAYER_START
var enemy_start_cell := ENEMY_START
var shields := MAX_SHIELDS
var turn_count := 0
var game_state := "playing" # playing, won, game_over
var last_feedback := "The gate is quiet. The statue has seen you."

func _ready() -> void:
	_build_grid_from_editable_scene()
	player_start_cell = player_actor.grid_cell
	enemy_start_cell = enemy_actor.grid_cell
	player_state = ActorState.new(player_start_cell)
	enemy_state = EvasionAI.new(enemy_start_cell)
	player_actor.configure(self, player_start_cell)
	player_actor.cell_entered.connect(_on_player_cell_entered)
	enemy_actor.snap_to_cell(enemy_start_cell)
	enemy_state.plan_step(player_state.cell, room_grid)
	enemy_actor.set_awareness(enemy_state.awareness)

func _build_grid_from_editable_scene() -> void:
	room_grid = GridWorld.new()
	room_grid.walls.clear()
	room_grid.coins.clear()
	for blocker_node in get_tree().get_nodes_in_group("grid_blockers"):
		if not is_ancestor_of(blocker_node):
			continue
		var blocker := blocker_node as GridCellMarker3D
		if blocker == null:
			push_error("Grid blocker lacks GridCellMarker3D: %s" % blocker_node.get_path())
			continue
		room_grid.walls[blocker.grid_cell] = true
	room_grid.portal = exit_gate.grid_cell
	if not room_grid.is_walkable(player_actor.grid_cell):
		push_error("The editable room blocks the Player node at %s." % player_actor.grid_cell)
	if not room_grid.is_walkable(enemy_actor.grid_cell):
		push_error("The editable room blocks the Enemy node at %s." % enemy_actor.grid_cell)
	if not room_grid.is_walkable(exit_gate.grid_cell):
		push_error("The editable room blocks the ExitGate node at %s." % exit_gate.grid_cell)

func is_round_active() -> bool:
	return game_state == "playing"

func is_cell_walkable(cell: Vector2i) -> bool:
	return room_grid != null and room_grid.is_walkable(cell)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if key_event.echo:
		return
	var action := InputRouter.decode(key_event)
	if action.is_empty():
		return
	if action.type == "move":
		player_actor.set_key_state(key_event.keycode, action.direction, key_event.pressed)
		if key_event.pressed:
			player_actor.face(action.direction)
	elif not key_event.pressed:
		return
	elif action.type == "wait":
		player_actor.clear_movement_input()
		_advance_enemy_unit()
	elif action.type == "restart":
		_restart_room()

func _on_player_cell_entered(cell: Vector2i) -> void:
	if not is_round_active():
		return
	player_state.cell = cell
	if cell == room_grid.portal:
		turn_count += 1
		game_state = "won"
		last_feedback = "You reached the gate."
		exit_light.light_color = Color(0.58, 1.0, 0.7, 1.0)
		exit_light.light_energy = 2.2
		player_actor.set_terminal_tint(Color(0.72, 1.0, 0.88, 1.0))
		return
	if cell == enemy_state.cell:
		turn_count += 1
		_resolve_player_collision()
		return
	_advance_enemy_unit()

func _advance_enemy_unit() -> void:
	if not is_round_active():
		return
	turn_count += 1
	var previous_enemy_cell := enemy_state.cell
	var planned_cell := enemy_state.intent
	if room_grid.is_walkable(planned_cell):
		if planned_cell == player_state.cell:
			_resolve_enemy_collision()
		else:
			enemy_state.cell = planned_cell
			enemy_actor.move_to_cell(planned_cell)
	enemy_state.plan_step(player_state.cell, room_grid)
	enemy_actor.set_awareness(enemy_state.awareness)
	if enemy_state.cell == previous_enemy_cell and enemy_state.awareness == EvasionEnemyState.Awareness.SEARCHING:
		last_feedback = "The statue searches the room."

func _resolve_player_collision() -> void:
	if shields <= 0:
		game_state = "game_over"
		last_feedback = "The statue caught you."
		player_actor.set_terminal_tint(Color(0.7, 0.36, 0.34, 1.0))
		return
	shields -= 1
	last_feedback = "The ward repels the statue."
	player_actor.pulse_ward()
	var recoil_path := _path_to_spawn()
	enemy_state.cell = enemy_state.spawn_cell
	enemy_actor.move_along_cells(recoil_path, 0.07)
	enemy_state.plan_step(player_state.cell, room_grid)
	enemy_actor.set_awareness(enemy_state.awareness)

func _resolve_enemy_collision() -> void:
	if shields > 0:
		shields -= 1
		last_feedback = "The ward holds for one more crossing."
		player_actor.pulse_ward()
	else:
		game_state = "game_over"
		last_feedback = "The statue caught you."
		player_actor.set_terminal_tint(Color(0.7, 0.36, 0.34, 1.0))

func _path_to_spawn() -> Array[Vector2i]:
	var original_cell := enemy_state.cell
	var cursor := original_cell
	var path: Array[Vector2i] = [cursor]
	for _step in range(GridWorld.WIDTH * GridWorld.HEIGHT):
		if cursor == enemy_state.spawn_cell:
			break
		enemy_state.cell = cursor
		var next_cell := enemy_state._next_path_step(enemy_state.spawn_cell, room_grid, false)
		if next_cell == cursor:
			break
		cursor = next_cell
		path.append(cursor)
	enemy_state.cell = original_cell
	return path

func _restart_room() -> void:
	game_state = "playing"
	shields = MAX_SHIELDS
	turn_count = 0
	last_feedback = "The gate is quiet. The statue has seen you."
	player_state = ActorState.new(player_start_cell)
	enemy_state = EvasionAI.new(enemy_start_cell)
	player_actor.reset_to_cell(player_start_cell)
	enemy_actor.snap_to_cell(enemy_start_cell)
	exit_light.light_color = Color(0.12, 0.92, 0.76, 1.0)
	exit_light.light_energy = 1.4
	enemy_state.plan_step(player_state.cell, room_grid)
	enemy_actor.set_awareness(enemy_state.awareness)
