extends CanvasLayer
class_name SledHUD

var _title: Label
var _hint: Label
var _results: Label
var _toast: Label
var _status: Label
var _ip: LineEdit
var _host_btn: Button
var _join_btn: Button
var _places: PackedStringArray = PackedStringArray()
var _toast_time := 0.0


func _ready() -> void:
	layer = 10
	_title = _label(
		"SLED",
		24, Color(1, 1, 1),
		Vector2(0, 18), Vector2(1280, 70),
		HORIZONTAL_ALIGNMENT_CENTER, 42
	)
	_hint = _label(
		"Walk to a rideable  ·  Grab on  ·  Steer down  ·  R restarts  ·  H host  ·  J join",
		18, Color(0.92, 0.95, 1.0, 0.85),
		Vector2(0, 640), Vector2(1280, 40),
		HORIZONTAL_ALIGNMENT_CENTER, 8
	)
	_results = _label(
		"",
		20, Color(1, 0.95, 0.55),
		Vector2(840, 20), Vector2(420, 400),
		HORIZONTAL_ALIGNMENT_RIGHT, 10
	)
	_toast = _label(
		"",
		28, Color(1, 0.92, 0.35),
		Vector2(0, 300), Vector2(1280, 80),
		HORIZONTAL_ALIGNMENT_CENTER, 14
	)
	_status = _label(
		"local 4-player",
		16, Color(0.85, 0.95, 1.0, 0.9),
		Vector2(16, 12), Vector2(520, 36),
		HORIZONTAL_ALIGNMENT_LEFT, 8
	)
	_ip = LineEdit.new()
	_ip.placeholder_text = "join IP"
	_ip.text = "127.0.0.1"
	_ip.position = Vector2(16, 48)
	_ip.size = Vector2(180, 28)
	_ip.add_theme_font_size_override("font_size", 14)
	add_child(_ip)
	_host_btn = _btn("Host", Vector2(204, 48), _on_host)
	_join_btn = _btn("Join", Vector2(278, 48), _on_join)
	Net.status_changed.connect(_on_net_status)
	_on_net_status()


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)
		if _toast_time <= 0.0:
			_toast.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if _ip.has_focus():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_H:
			_on_host()
		elif event.physical_keycode == KEY_J:
			_on_join()


func _on_host() -> void:
	Net.host()


func _on_join() -> void:
	Net.join(_ip.text)


func _on_net_status() -> void:
	_status.text = Net.status
	if Net.active:
		_hint.text = "WASD+E  ·  mic is proximity voice  ·  same fridge is quiet  ·  steal yells  ·  R restarts (host)"
	else:
		_hint.text = "Walk to a rideable  ·  Grab on  ·  Steer down  ·  R restarts  ·  H host  ·  J join"


func announce_place(place: int, player_name: String, vehicle: String, time_s: float) -> void:
	var ordinal := _ordinal(place)
	var line := "%s  %s  on %s  (%.1fs)" % [ordinal, player_name, vehicle, time_s]
	_places.append(line)
	_results.text = "FINISH\n" + "\n".join(_places)
	_toast.text = "%s  %s  on %s" % [ordinal, player_name, vehicle]
	_toast_time = 3.2
	_toast.modulate.a = 1.0


func _ordinal(n: int) -> String:
	match n:
		1:
			return "1st"
		2:
			return "2nd"
		3:
			return "3rd"
		_:
			return "%dth" % n


func _btn(text: String, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(68, 28)
	b.pressed.connect(cb)
	add_child(b)
	return b


func _label(text: String, font_size: int, color: Color, pos: Vector2, size: Vector2, align: int, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.18, 0.9))
	l.add_theme_constant_override("outline_size", outline)
	add_child(l)
	return l
