class_name InputSetup
extends RefCounted
## Keyboard + gamepad actions for four local players. Idempotent.


static var _done := false


static func ensure() -> void:
	if _done:
		return
	_done = true

	# P1 WASD + gamepad 0, P2 arrows + gamepad 1, P3/P4 gamepads 2/3.
	_keys("p0_left", [KEY_A])
	_keys("p0_right", [KEY_D])
	_keys("p0_up", [KEY_W])
	_keys("p0_down", [KEY_S])
	_keys("p0_grab", [KEY_E])
	_keys("p0_jump", [KEY_SPACE])

	_keys("p1_left", [KEY_LEFT])
	_keys("p1_right", [KEY_RIGHT])
	_keys("p1_up", [KEY_UP])
	_keys("p1_down", [KEY_DOWN])
	_keys("p1_grab", [KEY_ENTER, KEY_KP_ENTER])
	_keys("p1_jump", [KEY_SHIFT])

	for i in 4:
		var grab := "p%d_grab" % i
		var jump := "p%d_jump" % i
		_joy_axis("p%d_left" % i, i, JOY_AXIS_LEFT_X, -1.0)
		_joy_axis("p%d_right" % i, i, JOY_AXIS_LEFT_X, 1.0)
		_joy_axis("p%d_up" % i, i, JOY_AXIS_LEFT_Y, -1.0)
		_joy_axis("p%d_down" % i, i, JOY_AXIS_LEFT_Y, 1.0)
		_joy_button(grab, i, JOY_BUTTON_A)
		_joy_button(jump, i, JOY_BUTTON_B)
		_joy_button(jump, i, JOY_BUTTON_LEFT_SHOULDER)

	_keys("restart", [KEY_R])
	for i in 4:
		_joy_button("restart", i, JOY_BUTTON_START)


static func _ensure_action(name: String) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.5)


static func _keys(name: String, keycodes: Array) -> void:
	_ensure_action(name)
	for keycode in keycodes:
		var e := InputEventKey.new()
		e.physical_keycode = keycode
		InputMap.action_add_event(name, e)


static func _joy_button(name: String, device: int, button: int) -> void:
	_ensure_action(name)
	var e := InputEventJoypadButton.new()
	e.device = device
	e.button_index = button
	InputMap.action_add_event(name, e)


static func _joy_axis(name: String, device: int, axis: int, value: float) -> void:
	_ensure_action(name)
	var e := InputEventJoypadMotion.new()
	e.device = device
	e.axis = axis
	e.axis_value = value
	InputMap.action_add_event(name, e)
