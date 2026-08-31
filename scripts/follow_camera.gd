extends Camera3D
class_name FollowCamera

var targets: Array = []

@export var height := 13.0
@export var back := 20.0
@export var look_ahead := 10.0
@export var follow_speed := 3.6


func _ready() -> void:
	fov = 72.0
	near = 0.15
	far = 600.0
	current = true


func _process(delta: float) -> void:
	if targets.is_empty():
		return
	var centroid := Vector3.ZERO
	var n := 0
	var min_x := 999.0
	var max_x := -999.0
	var min_z := 999.0
	var max_z := -999.0
	var lead_z := -999.0
	for t in targets:
		if t == null or not is_instance_valid(t):
			continue
		var p: Vector3 = t.global_position
		centroid += p
		n += 1
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_z = minf(min_z, p.z)
		max_z = maxf(max_z, p.z)
		lead_z = maxf(lead_z, p.z)
	if n == 0:
		return
	centroid /= float(n)
	centroid.z = lerpf(centroid.z, lead_z, 0.35)

	var spread := maxf(max_x - min_x, max_z - min_z)
	var extra_back := clampf(spread * 0.55, 0.0, 18.0)
	var extra_height := clampf(spread * 0.25, 0.0, 10.0)
	var desired := centroid + Vector3(0.0, height + extra_height, -(back + extra_back))
	desired.y = maxf(desired.y, centroid.y + 6.0)

	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
	var look := centroid + Vector3(0.0, 1.2, look_ahead)
	look_at(look, Vector3.UP)
