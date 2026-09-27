extends SceneTree

const FOUNDATION_SCENE := "res://experiments/visual_foundation/foundation_room.tscn"

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_project_configuration()
	_test_camera_relative_vectors()
	var packed := load(FOUNDATION_SCENE) as PackedScene
	_check(packed != null, "visual-foundation scene loads")
	if packed == null:
		_finish()
		return

	var room := packed.instantiate()
	root.add_child(room)
	await process_frame
	await physics_frame
	await physics_frame

	var player := room.get_node_or_null("Player") as FoundationPlayer
	var camera_rig := room.get_node_or_null("CameraRig") as FoundationCameraRig
	var camera := room.get_node_or_null("CameraRig/Camera3D") as Camera3D
	_check(room.get_node_or_null("Environment/Floor/PixelStoneFloor") is MeshInstance3D, "the world is built from editable 3D mesh resources")
	_check(room.get_node_or_null("Environment/Floor/CollisionShape3D") is CollisionShape3D, "the walkable floor has a real physics collider")
	_check(room.get_tree().get_nodes_in_group("visual_occluders").size() >= 20, "the room contains distinct collision-backed depth and occlusion geometry")
	_check(room.get_node_or_null("Environment/WorldEnvironment") is WorldEnvironment, "environment lighting/fog is a real WorldEnvironment")
	_check(room.get_node_or_null("Environment/KeyLight") is DirectionalLight3D, "the primary light is a real shadow-casting 3D light")
	_check(not _contains_canvas_hud(room), "the visual foundation contains no HUD")
	_check(player != null and player is CharacterBody3D, "player has a physical 3D character controller")
	_check(camera_rig != null and camera is Camera3D and camera.current, "third-person camera is an active editable Camera3D")

	if player == null or camera_rig == null or camera == null:
		room.queue_free()
		await process_frame
		_finish()
		return

	var sprite := room.get_node_or_null("Player/VisualRoot/AnimatedSprite3D") as AnimatedSprite3D
	_check(sprite != null and sprite.sprite_frames != null, "2D pixel-art frames are presented by an editable 3D sprite node")
	if sprite != null and sprite.sprite_frames != null:
		for view in ["AWAY", "TOWARD", "LEFT", "RIGHT"]:
			_check(sprite.sprite_frames.has_animation(view) and sprite.sprite_frames.get_frame_count(view) == 12, "%s view preserves 12 individual source frames" % view)

	_check(player.is_on_floor(), "player settles onto the physical floor")
	var start_position := player.global_position
	Input.action_press("move_right")
	for _frame in range(150):
		await physics_frame
	Input.action_release("move_right")
	_check(player.global_position.x > start_position.x + 4.0 and player.global_position.x < 6.9, "a real obstacle collider stops free movement at the expected side of the room")
	player.global_position = start_position
	player.velocity = Vector3.ZERO
	await physics_frame
	var forward_start := player.global_position
	Input.action_press("move_forward")
	for _frame in range(36):
		await physics_frame
	Input.action_release("move_forward")
	var moved_position := player.global_position
	_check(moved_position.z < forward_start.z - 0.45, "W moves freely forward through the 3D floor plane")
	_check(absf(moved_position.y - forward_start.y) < 0.1, "forward movement remains grounded without vertical/jump mechanics")

	var yaw_before := camera_rig.get_orbit_yaw()
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var mouse_motion := InputEventMouseMotion.new()
		mouse_motion.relative = Vector2(120.0, -30.0)
		camera_rig._unhandled_input(mouse_motion)
		_check(not is_equal_approx(camera_rig.get_orbit_yaw(), yaw_before), "mouse motion changes third-person camera orbit")
	else:
		print("[UNKNOWN] native mouse capture/orbit requires a display-backed playtest")
	var zoom_before := camera_rig.orbit_distance
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	camera_rig._unhandled_input(wheel)
	_check(camera_rig.orbit_distance < zoom_before, "mouse wheel permits reversible camera-distance adjustment")
	_check(camera.global_position.distance_to(player.global_position) > 2.0, "camera remains behind the moving player at gameplay distance")
	player.global_position = Vector3(9.5, 0.0, 0.0)
	player.velocity = Vector3.ZERO
	camera_rig.orbit_yaw = PI * 0.5
	camera_rig.orbit_distance = 5.2
	for _frame in range(36):
		await physics_frame
	_check(camera_rig._current_distance < camera_rig.orbit_distance - 0.5, "camera shortens smoothly when real room geometry blocks its orbit path")

	room.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_finish()

func _test_project_configuration() -> void:
	_check(ProjectSettings.get_setting("application/run/main_scene") == FOUNDATION_SCENE, "F5 launches the visual-foundation room")
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus", "the desktop uses Forward+ rendering")
	_check(ProjectSettings.get_setting("rendering/rendering_device/driver.windows") == "d3d12", "Windows prefers the D3D12 RenderingDevice driver")

func _test_camera_relative_vectors() -> void:
	_check(FoundationPlayer.world_direction_from_axes(Vector2(0, -1), 0.0).is_equal_approx(Vector3(0, 0, -1)), "W follows camera-forward on the ground plane")
	_check(FoundationPlayer.world_direction_from_axes(Vector2(0, 1), 0.0).is_equal_approx(Vector3(0, 0, 1)), "S moves backward relative to the camera")
	_check(FoundationPlayer.world_direction_from_axes(Vector2(-1, 0), 0.0).is_equal_approx(Vector3(-1, 0, 0)), "A strafes left relative to the camera")
	_check(FoundationPlayer.world_direction_from_axes(Vector2(1, 0), 0.0).is_equal_approx(Vector3(1, 0, 0)), "D strafes right relative to the camera")
	var diagonal := FoundationPlayer.world_direction_from_axes(Vector2(1, -1), 0.0)
	_check(is_equal_approx(diagonal.length(), 1.0) and diagonal.x > 0.0 and diagonal.z < 0.0, "diagonal movement is normalized and not faster")
	var rotated_forward := FoundationPlayer.world_direction_from_axes(Vector2(0, -1), PI * 0.5)
	_check(rotated_forward.x < -0.99 and absf(rotated_forward.z) < 0.01, "W follows camera-forward after a 90-degree orbit")
	var rotated_right := FoundationPlayer.world_direction_from_axes(Vector2(1, 0), PI * 0.5)
	_check(rotated_right.z < -0.99 and absf(rotated_right.x) < 0.01, "D follows camera-right after a 90-degree orbit")

func _contains_canvas_hud(node: Node) -> bool:
	for child in node.get_children():
		if child is CanvasLayer or child is Control:
			return true
		if _contains_canvas_hud(child):
			return true
	return false

func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] ", message)
	else:
		failures += 1
		push_error("[FAIL] " + message)

func _finish() -> void:
	if failures == 0:
		print("GODOT_VISUAL_FOUNDATION: PASS")
		quit(0)
	else:
		printerr("GODOT_VISUAL_FOUNDATION: FAIL (%d checks)" % failures)
		quit(1)
