extends CanvasLayer
class_name SledHUD

var _title: Label
var _hint: Label
var _results: Label
var _toast: Label
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
		"Walk to a rideable  ·  Grab on  ·  Steer down  ·  R restarts",
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


func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)
		if _toast_time <= 0.0:
			_toast.text = ""


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
