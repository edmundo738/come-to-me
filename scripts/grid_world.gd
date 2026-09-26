class_name GridWorld
extends RefCounted

const WIDTH := 11
const HEIGHT := 9
const TILE_WIDTH := 72.0
const TILE_HEIGHT := 36.0

var walls: Dictionary = {}
var coins: Dictionary = {}
var portal := Vector2i(9, 7)

func _init() -> void:
	# A hand-authored first room: readable lanes, cover, and a few optional detours.
	for cell in [
		Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3),
		Vector2i(5, 1), Vector2i(5, 2), Vector2i(5, 3),
		Vector2i(7, 4), Vector2i(8, 4), Vector2i(3, 6),
		Vector2i(4, 6), Vector2i(6, 7), Vector2i(6, 8)
	]:
		walls[cell] = true
	for cell in [Vector2i(1, 3), Vector2i(4, 3), Vector2i(7, 2), Vector2i(8, 6), Vector2i(3, 7)]:
		coins[cell] = true

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT

func is_walkable(cell: Vector2i) -> bool:
	return is_inside(cell) and not walls.has(cell)

func to_screen(cell: Vector2i) -> Vector2:
	return Vector2((cell.x - cell.y) * TILE_WIDTH * 0.5, (cell.x + cell.y) * TILE_HEIGHT * 0.5)

func screen_origin(viewport_size: Vector2) -> Vector2:
	var left := to_screen(Vector2i(0, HEIGHT - 1)).x
	var right := to_screen(Vector2i(WIDTH - 1, 0)).x
	var top := to_screen(Vector2i(0, 0)).y
	var bottom := to_screen(Vector2i(WIDTH - 1, HEIGHT - 1)).y
	var bounds_center := Vector2((left + right) * 0.5, (top + bottom) * 0.5)
	return Vector2(viewport_size.x * 0.5, viewport_size.y * 0.55) - bounds_center
