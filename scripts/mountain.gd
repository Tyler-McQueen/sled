extends Node3D
class_name Mountain
## Summit plateau, icy slope with a bump and a jump, runout, finish basin.

const TRACK_HALF := 12.0
const WALL_H := 9.0
const SLAB_THICK := 5.0

# PackedVector2Array of (z, y) surface samples, summit -> bottom.
var profile: PackedVector2Array = PackedVector2Array([
	Vector2(-42, 58),
	Vector2(-28, 58),
	Vector2(-8, 58),
	Vector2(8, 58),
	Vector2(18, 56.5),
	Vector2(32, 52.0),
	Vector2(48, 46.0),
	Vector2(62, 41.5),
	Vector2(72, 39.5),
	Vector2(80, 42.0),
	Vector2(88, 37.5),
	Vector2(104, 30.0),
	Vector2(118, 24.5),
	Vector2(128, 22.0),
	Vector2(136, 25.5),
	Vector2(144, 16.5),
	Vector2(158, 9.0),
	Vector2(172, 4.5),
	Vector2(188, 2.4),
	Vector2(210, 2.0),
	Vector2(228, 2.0),
	Vector2(242, 7.5),
	Vector2(258, 8.0),
])


func _ready() -> void:
	_build()


func surface_y(z: float) -> float:
	if z <= profile[0].x:
		return profile[0].y
	if z >= profile[profile.size() - 1].x:
		return profile[profile.size() - 1].y
	for i in range(profile.size() - 1):
		var a := profile[i]
		var b := profile[i + 1]
		if z >= a.x and z <= b.x:
			var t := inverse_lerp(a.x, b.x, z)
			return lerp(a.y, b.y, t)
	return 2.0


func _build() -> void:
	var snow := _albedo(Color(0.93, 0.96, 0.99), 0.92)
	var ice := _albedo(Color(0.72, 0.88, 0.96), 0.28)
	ice.metallic = 0.08
	var rock := _albedo(Color(0.45, 0.48, 0.52), 0.85)
	var pine := _albedo(Color(0.12, 0.32, 0.18), 0.9)
	var trunk := _albedo(Color(0.38, 0.24, 0.14), 0.9)
	var flag_red := _albedo(Color(0.85, 0.15, 0.12), 0.6)

	_build_visual_volume(snow, ice)
	_build_collision()
	_build_walls(rock)
	_build_trees(pine, trunk)
	_build_finish_gate(flag_red)
	_build_start_props()


func _albedo(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


func _build_visual_volume(snow: Material, ice: Material) -> void:
	var poly := CSGPolygon3D.new()
	poly.name = "SnowVolume"
	var pts := PackedVector2Array()
	pts.append(Vector2(profile[0].x - 2.0, 0.0))
	for p in profile:
		pts.append(Vector2(p.x, p.y))
	pts.append(Vector2(profile[profile.size() - 1].x + 2.0, 0.0))
	poly.polygon = pts
	poly.mode = CSGPolygon3D.MODE_DEPTH
	poly.depth = TRACK_HALF * 2.0 + 1.0
	poly.rotation_degrees = Vector3(0, -90, 0)
	poly.position = Vector3(TRACK_HALF + 0.5, 0, 0)
	poly.smooth_faces = true
	poly.material = snow
	poly.use_collision = false
	add_child(poly)

	# ice material reserved for future racing-line paint


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "TrackCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)

	var icy := PhysicsMaterial.new()
	icy.friction = 0.08
	icy.bounce = 0.05
	body.physics_material_override = icy

	for i in range(profile.size() - 1):
		_add_slab(body, profile[i], profile[i + 1], TRACK_HALF * 2.0 + 0.6, SLAB_THICK)

	var pad := StaticBody3D.new()
	pad.name = "SummitPad"
	pad.collision_layer = 1
	pad.collision_mask = 0
	var grip := PhysicsMaterial.new()
	grip.friction = 0.7
	grip.bounce = 0.0
	pad.physics_material_override = grip
	add_child(pad)
	_add_slab(pad, Vector2(-40, 58), Vector2(8, 58), TRACK_HALF * 2.0, 4.0)

	var ground := StaticBody3D.new()
	ground.name = "WorldFloor"
	ground.collision_layer = 1
	ground.collision_mask = 0
	add_child(ground)
	var gshape := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(400, 4, 400)
	gshape.shape = gbox
	gshape.position = Vector3(0, -2, 80)
	ground.add_child(gshape)


func _add_slab(body: StaticBody3D, a: Vector2, b: Vector2, width: float, thick: float) -> void:
	var run := b.x - a.x
	var drop := a.y - b.y
	var length := sqrt(run * run + drop * drop)
	if length < 0.05:
		return
	var angle := atan2(drop, run)
	var box := BoxShape3D.new()
	box.size = Vector3(width, thick, length + 0.15)
	var cs := CollisionShape3D.new()
	cs.shape = box
	var mid := Vector3(0.0, (a.y + b.y) * 0.5, (a.x + b.x) * 0.5)
	var local_up := Vector3(0.0, cos(angle), sin(angle))
	cs.position = mid - local_up * (thick * 0.5)
	cs.rotation.x = angle
	body.add_child(cs)


func _build_walls(rock: Material) -> void:
	for side in [-1.0, 1.0]:
		var x := side * (TRACK_HALF + 0.7)
		for i in range(profile.size() - 1):
			var a := profile[i]
			var b := profile[i + 1]
			var run := b.x - a.x
			var drop := a.y - b.y
			var length := sqrt(run * run + drop * drop)
			if length < 0.2:
				continue
			var angle := atan2(drop, run)
			var box := CSGBox3D.new()
			box.size = Vector3(1.4, WALL_H, length + 0.2)
			var mid_y := (a.y + b.y) * 0.5 + WALL_H * 0.35
			var mid_z := (a.x + b.x) * 0.5
			box.position = Vector3(x, mid_y, mid_z)
			box.rotation.x = angle
			box.material = rock
			box.use_collision = true
			box.collision_layer = 1
			box.collision_mask = 0
			add_child(box)

	var back := CSGBox3D.new()
	back.size = Vector3(TRACK_HALF * 2.0 + 4.0, 14.0, 2.0)
	back.position = Vector3(0, 58 + 5.0, -43)
	back.material = rock
	back.use_collision = true
	back.collision_layer = 1
	add_child(back)


func _build_trees(pine: Material, trunk: Material) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 18:
		var z := rng.randf_range(-20.0, 230.0)
		var side := -1.0 if (i % 2 == 0) else 1.0
		var x := side * rng.randf_range(TRACK_HALF + 4.0, TRACK_HALF + 14.0)
		var y := surface_y(z)
		_pine(Vector3(x, y, z), rng.randf_range(4.5, 8.5), pine, trunk)


func _pine(pos: Vector3, height: float, pine: Material, trunk: Material) -> void:
	var t := CSGCylinder3D.new()
	t.radius = 0.28
	t.height = height * 0.35
	t.sides = 6
	t.position = pos + Vector3(0, t.height * 0.5, 0)
	t.material = trunk
	t.use_collision = true
	t.collision_layer = 1
	add_child(t)
	for i in 3:
		var cone := CSGCylinder3D.new()
		cone.cone = true
		cone.radius = 1.8 - float(i) * 0.35
		cone.height = height * 0.42
		cone.sides = 8
		cone.position = pos + Vector3(0, height * 0.28 + float(i) * height * 0.22, 0)
		cone.material = pine
		cone.use_collision = false
		add_child(cone)


func _build_finish_gate(flag: Material) -> void:
	var z := 214.0
	var y := 2.0
	for side in [-1.0, 1.0]:
		var pole := CSGCylinder3D.new()
		pole.radius = 0.18
		pole.height = 8.0
		pole.position = Vector3(side * 8.0, y + 4.0, z)
		pole.material = flag
		pole.use_collision = false
		add_child(pole)
	var bar := CSGBox3D.new()
	bar.size = Vector3(16.4, 0.35, 0.35)
	bar.position = Vector3(0, y + 8.0, z)
	bar.material = flag
	add_child(bar)
	var banner := Label3D.new()
	banner.text = "FINISH"
	banner.font_size = 96
	banner.outline_size = 16
	banner.position = Vector3(0, y + 9.2, z)
	banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(banner)


func _build_start_props() -> void:
	var sign := Label3D.new()
	sign.text = "GRAB SOMETHING"
	sign.font_size = 64
	sign.outline_size = 12
	sign.position = Vector3(0, 61.5, 6)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sign)
