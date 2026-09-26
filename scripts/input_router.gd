class_name InputRouter
extends RefCounted

# Keyboard bindings are translated once into logical actions. Gameplay never
# needs to know whether an action came from a key, pad, remote, or touch gesture.
static func decode(event: InputEventKey) -> Dictionary:
	var key := event.keycode
	match key:
		KEY_UP, KEY_W:
			return {"type": "move", "direction": Vector2i.UP}
		KEY_DOWN, KEY_S:
			return {"type": "move", "direction": Vector2i.DOWN}
		KEY_LEFT, KEY_A:
			return {"type": "move", "direction": Vector2i.LEFT}
		KEY_RIGHT, KEY_D:
			return {"type": "move", "direction": Vector2i.RIGHT}
		KEY_SPACE:
			return {"type": "jump"}
		KEY_E, KEY_PERIOD:
			return {"type": "wait"}
		KEY_R:
			return {"type": "restart"}
		_:
			return {}
