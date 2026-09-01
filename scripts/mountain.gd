extends Node3D
class_name Mountain
## Summit, barn jump, ice vs powder split, parking-lot finish.

const TRACK_HALF := 12.0
const WALL_H := 9.0
const SLAB_THICK := 5.0
const SPLIT_Z := 158.0
const LOT_Z := 208.0

# PackedVector2Array of (z, y) surface samples, summit -> lot.
var profile: PackedVector2Array = PackedVector2Array([
	Vector2(-42, 58),
	Vector2(-28, 58),
	Vector2(-8, 58),
	Vector2(8, 58),
	Vector2(18, 56.5),
	Vector2(36, 50.5),
	Vector2(54, 44.5),
	Vector2(72, 38.5),
	Vector2(90, 33.0),
	Vector2(106, 28.5),
	Vector2(116, 31.5),
	Vector2(124, 34.5),
	Vector2(132, 33.0),
	Vector2(140, 24.0),
	Vector2(152, 14.5),
	Vector2(164, 9.0),
	Vector2(180, 5.2),
	Vector2(196, 3.2),
	Vector2(208, 2.2),
	Vector2(228, 2.0),
	Vector2(252, 2.0),
	Vector2(272, 2.0),
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
	var ice := _albedo(Color(0.62, 0.84, 0.96), 0.18)
	var powder := _albedo(Color(0.97, 0.98, 1.0), 0.98)
	var rock := _albedo(Color(0.45, 0.48, 0.52), 0.85)
	var pine := _albedo(Color(0.12, 0.32, 0.18), 0.9)
	var trunk := _albedo(Color(0.38, 0.24, 0.14), 0.9)
	var barn_red := _albedo(Color(0.62, 0.16, 0.12), 0.78)
	var barn_wood := _albedo(Color(0.42, 0.28, 0.16), 0.88)
	var asphalt := _albedo(Color(0.18, 0.19, 0.21), 0.95)
	var paint := _albedo(Color(0.92, 0.9, 0.78), 0.7)
	var flag_red := _albedo(Color(0.85, 0.15, 0.12), 0.6)

	_build_visual_volume(snow)
	_build_split_paint(ice, powder)
	_build_collision()
	_build_walls(rock)
	_build_barn(barn_red, barn_wood)
	_build_trees(pine, trunk)
	_build_parking_lot(asphalt, paint)
	_build_finish_gate(flag_red)
	_build_start_props()


func _albedo(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


func _build_visual_volume(snow: Material) -> void:
	var poly := CSGPolygon3D.new()
	poly.name = "SnowVolume"
	var pts := PackedVector2Array()
	pts.append(Vector2(profile[0].x - 2.0, 0.0))
	for p in profile:
		pts.append(Vector2(p.x, p.y))
	pts.append(Vector2(profile[profile.size() - 1].x + 2.0, 0.0))
	poly.polygon = pts
	poly.mode = CSGPolygon3D.MODE_DEPTH
	poly.depth = TRACK_HALF * 2.0 + 8.0
	poly.rotation_degrees = Vector3(0, -90, 0)
	poly.position = Vector3(TRACK_HALF + 4.0, 0, 0)
	poly.smooth_faces = true
	poly.material = snow
	poly.use_collision = false
	add_child(poly)


func _build_split_paint(ice: Material, powder: Material) -> void:
	var ice_tag := Label3D.new()
	ice_tag.text = "ICE"
	ice_tag.font_size = 72
	ice_tag.outline_size = 12
	ice_tag.position = Vector3(-6.5, surface_y(170.0) + 0.4, 170.0)
	ice_tag.rotation_degrees = Vector3(-90, 0, 0)
	add_child(ice_tag)
	var powder_tag := Label3D.new()
	powder_tag.text = "POWDER"
	powder_tag.font_size = 64
	powder_tag.outline_size = 12
	powder_tag.position = Vector3(6.5, surface_y(170.0) + 0.4, 170.0)
	powder_tag.rotation_degrees = Vector3(-90, 0, 0)
	add_child(powder_tag)
	_drape_lane_paint(ice, -TRACK_HALF * 0.5 - 0.25, 0.08)
	_drape_lane_paint(powder, TRACK_HALF * 0.5 + 0.25, 0.14)


func _drape_lane_paint(mat: Material, x_center: float, thick: float) -> void:
	for i in range(profile.size() - 1):
		var a := profile[i]
		var b := profile[i + 1]
		var zmid: float = (a.x + b.x) * 0.5
		if zmid < SPLIT_Z or zmid > LOT_Z:
			continue
		var run := b.x - a.x
		var drop := a.y - b.y
		var length := sqrt(run * run + drop * drop)
		if length < 0.2:
			continue
		var angle := atan2(drop, run)
		var box := CSGBox3D.new()
		box.size = Vector3(TRACK_HALF - 0.5, thick, length + 0.1)
		var mid_y := (a.y + b.y) * 0.5 + thick * 0.5 + 0.02
		var mid_z := (a.x + b.x) * 0.5
		box.position = Vector3(x_center, mid_y, mid_z)
		box.rotation.x = angle
		box.material = mat
		box.use_collision = false
		add_child(box)


func _build_collision() -> void:
	var snow_body := StaticBody3D.new()
	snow_body.name = "TrackCollision"
	snow_body.collision_layer = 1
	snow_body.collision_mask = 0
	var snow_mat := PhysicsMaterial.new()
	snow_mat.friction = 0.12
	snow_mat.bounce = 0.04
	snow_body.physics_material_override = snow_mat
	add_child(snow_body)

	var ice_body := StaticBody3D.new()
	ice_body.name = "IceCollision"
	ice_body.collision_layer = 1
	ice_body.collision_mask = 0
	var ice_mat := PhysicsMaterial.new()
	ice_mat.friction = 0.02
	ice_mat.bounce = 0.08
	ice_body.physics_material_override = ice_mat
	add_child(ice_body)

	var powder_body := StaticBody3D.new()
	powder_body.name = "PowderCollision"
	powder_body.collision_layer = 1
	powder_body.collision_mask = 0
	var powder_mat := PhysicsMaterial.new()
	powder_mat.friction = 0.42
	powder_mat.bounce = 0.0
	powder_body.physics_material_override = powder_mat
	add_child(powder_body)

	for i in range(profile.size() - 1):
		var a := profile[i]
		var b := profile[i + 1]
		var zmid: float = (a.x + b.x) * 0.5
		if zmid >= SPLIT_Z and zmid < LOT_Z:
			_add_slab(ice_body, a, b, TRACK_HALF - 0.2, SLAB_THICK, -TRACK_HALF * 0.5 - 0.25)
			_add_slab(powder_body, a, b, TRACK_HALF - 0.2, SLAB_THICK, TRACK_HALF * 0.5 + 0.25)
		else:
			var w := TRACK_HALF * 2.0 + 0.6
			if zmid >= LOT_Z:
				w = TRACK_HALF * 2.0 + 10.0
			_add_slab(snow_body, a, b, w, SLAB_THICK, 0.0)

	var pad := StaticBody3D.new()
	pad.name = "SummitPad"
	pad.collision_layer = 1
	pad.collision_mask = 0
	var grip := PhysicsMaterial.new()
	grip.friction = 0.7
	grip.bounce = 0.0
	pad.physics_material_override = grip
	add_child(pad)
	_add_slab(pad, Vector2(-40, 58), Vector2(8, 58), TRACK_HALF * 2.0 + 4.0, 4.0, 0.0)

	var ground := StaticBody3D.new()
	ground.name = "WorldFloor"
	ground.collision_layer = 1
	ground.collision_mask = 0
	add_child(ground)
	var gshape := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(400, 4, 500)
	gshape.shape = gbox
	gshape.position = Vector3(0, -2, 100)
	ground.add_child(gshape)


func _add_slab(body: StaticBody3D, a: Vector2, b: Vector2, width: float, thick: float, x_center: float) -> void:
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
	var mid := Vector3(x_center, (a.y + b.y) * 0.5, (a.x + b.x) * 0.5)
	var local_up := Vector3(0.0, cos(angle), sin(angle))
	cs.position = mid - local_up * (thick * 0.5)
	cs.rotation.x = angle
	body.add_child(cs)


func _build_walls(rock: Material) -> void:
	for side_i in range(2):
		var side := -1.0 if side_i == 0 else 1.0
		for i in range(profile.size() - 1):
			var a := profile[i]
			var b := profile[i + 1]
			var zmid: float = (a.x + b.x) * 0.5
			var half := TRACK_HALF
			if zmid >= LOT_Z:
				half = TRACK_HALF + 6.0
			var x := side * (half + 0.7)
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
	back.size = Vector3(TRACK_HALF * 2.0 + 8.0, 14.0, 2.0)
	back.position = Vector3(0, 58 + 5.0, -43)
	back.material = rock
	back.use_collision = true
	back.collision_layer = 1
	add_child(back)


func _build_barn(red: Material, wood: Material) -> void:
	# Sits on the bump so a ride can hit the roof and launch.
	var z := 124.0
	var y := surface_y(z)
	var w := 9.0
	var d := 8.0
	var wall_h := 4.6

	var floor_b := CSGBox3D.new()
	floor_b.size = Vector3(w, 0.35, d)
	floor_b.position = Vector3(0, y + 0.1, z)
	floor_b.material = wood
	floor_b.use_collision = true
	floor_b.collision_layer = 1
	add_child(floor_b)

	for side_i in range(2):
		var side := -1.0 if side_i == 0 else 1.0
		var wall := CSGBox3D.new()
		wall.size = Vector3(0.35, wall_h, d)
		wall.position = Vector3(side * (w * 0.5), y + wall_h * 0.5, z)
		wall.material = red
		wall.use_collision = true
		wall.collision_layer = 1
		add_child(wall)

	# Uphill back wall. Downhill face stays open.
	var back := CSGBox3D.new()
	back.size = Vector3(w, wall_h, 0.35)
	back.position = Vector3(0, y + wall_h * 0.5, z - d * 0.5)
	back.material = red
	back.use_collision = true
	back.collision_layer = 1
	add_child(back)

	# Peaked roof: two slabs that dump you downhill.
	var roof_l := CSGBox3D.new()
	roof_l.size = Vector3(w * 0.58, 0.28, d + 1.4)
	roof_l.position = Vector3(-w * 0.22, y + wall_h + 1.1, z + 0.4)
	roof_l.rotation_degrees = Vector3(-28, 0, 18)
	roof_l.material = wood
	roof_l.use_collision = true
	roof_l.collision_layer = 1
	add_child(roof_l)
	var roof_r := CSGBox3D.new()
	roof_r.size = Vector3(w * 0.58, 0.28, d + 1.4)
	roof_r.position = Vector3(w * 0.22, y + wall_h + 1.1, z + 0.4)
	roof_r.rotation_degrees = Vector3(-28, 0, -18)
	roof_r.material = wood
	roof_r.use_collision = true
	roof_r.collision_layer = 1
	add_child(roof_r)

	var tag := Label3D.new()
	tag.text = "BARN"
	tag.font_size = 56
	tag.outline_size = 10
	tag.position = Vector3(0, y + wall_h + 3.4, z)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(tag)


func _build_trees(pine: Material, trunk: Material) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(28):
		var z := rng.randf_range(-18.0, 250.0)
		var side := -1.0 if (i % 2 == 0) else 1.0
		var x := side * rng.randf_range(TRACK_HALF + 3.5, TRACK_HALF + 16.0)
		var y := surface_y(z)
		_pine(Vector3(x, y, z), rng.randf_range(4.5, 9.0), pine, trunk)

	# On-course trees you can actually hit.
	var course: Array[Vector3] = [
		Vector3(-8.2, 0, 68),
		Vector3(9.0, 0, 86),
		Vector3(-7.4, 0, 102),
		Vector3(8.6, 0, 148),
		Vector3(-8.0, 0, 176),
		Vector3(8.2, 0, 188),
	]
	for pos in course:
		var p := pos
		p.y = surface_y(p.z)
		_pine(p, 6.2, pine, trunk)


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
	for i in range(3):
		var cone := CSGCylinder3D.new()
		cone.cone = true
		cone.radius = 1.8 - float(i) * 0.35
		cone.height = height * 0.42
		cone.sides = 8
		cone.position = pos + Vector3(0, height * 0.28 + float(i) * height * 0.22, 0)
		cone.material = pine
		cone.use_collision = true
		cone.collision_layer = 1
		add_child(cone)


func _build_parking_lot(asphalt: Material, paint: Material) -> void:
	var y := 2.08
	var z := 236.0
	var lot := CSGBox3D.new()
	lot.name = "ParkingLot"
	lot.size = Vector3(28.0, 0.16, 48.0)
	lot.position = Vector3(0, y, z)
	lot.material = asphalt
	lot.use_collision = false
	add_child(lot)

	for i in range(8):
		var line := CSGBox3D.new()
		line.size = Vector3(0.12, 0.04, 7.5)
		line.position = Vector3(-10.0 + float(i) * 2.8, y + 0.1, z + 10.0)
		line.material = paint
		line.use_collision = false
		add_child(line)

	var cars: Array = [
		[Vector3(-8.5, y + 0.7, z + 16.0), Color(0.15, 0.18, 0.55)],
		[Vector3(-2.5, y + 0.7, z + 16.5), Color(0.72, 0.18, 0.14)],
		[Vector3(6.0, y + 0.7, z + 15.5), Color(0.85, 0.82, 0.2)],
		[Vector3(10.5, y + 0.7, z - 8.0), Color(0.12, 0.12, 0.14)],
	]
	for c in cars:
		var body := CSGBox3D.new()
		body.size = Vector3(1.8, 1.2, 4.2)
		body.position = c[0]
		body.material = _albedo(c[1], 0.55)
		body.use_collision = true
		body.collision_layer = 1
		add_child(body)
		var cab := CSGBox3D.new()
		cab.size = Vector3(1.6, 0.7, 1.8)
		cab.position = c[0] + Vector3(0, 0.85, -0.4)
		cab.material = _albedo(Color(0.35, 0.5, 0.62), 0.3)
		cab.use_collision = false
		add_child(cab)

	var lot_tag := Label3D.new()
	lot_tag.text = "PARKING"
	lot_tag.font_size = 80
	lot_tag.outline_size = 14
	lot_tag.position = Vector3(0, y + 0.2, z - 16.0)
	lot_tag.rotation_degrees = Vector3(-90, 0, 0)
	add_child(lot_tag)


func _build_finish_gate(flag: Material) -> void:
	var z := 218.0
	var y := 2.0
	for side_i in range(2):
		var side := -1.0 if side_i == 0 else 1.0
		var pole := CSGCylinder3D.new()
		pole.radius = 0.18
		pole.height = 8.0
		pole.position = Vector3(side * 10.0, y + 4.0, z)
		pole.material = flag
		pole.use_collision = false
		add_child(pole)
	var bar := CSGBox3D.new()
	bar.size = Vector3(20.4, 0.35, 0.35)
	bar.position = Vector3(0, y + 8.0, z)
	bar.material = flag
	add_child(bar)
	var banner := Label3D.new()
	banner.text = "PARKING LOT"
	banner.font_size = 88
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
