extends RigidBody3D
class_name Rideable

enum Kind { SLED, FRIDGE, TUBE, MATTRESS, KAYAK, TABLE, POOL, DOOR }

@export var kind: Kind = Kind.SLED

var display_name: String = "Sled"
var seat_offset: Vector3 = Vector3(0, 0.55, 0)
var steer_force: float = 80.0
var hop_impulse: float = 5.0
var riders: Array = []

var _visual: Node3D


func setup(p_kind: Kind) -> void:
	kind = p_kind
	add_to_group("rideables")
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	collision_layer = 2
	collision_mask = 1 | 2 | 4
	can_sleep = false
	match kind:
		Kind.SLED:
			display_name = "the Sled"
			mass = 9.0
			steer_force = 140.0
			hop_impulse = 6.5
			seat_offset = Vector3(0, 0.42, 0.1)
			linear_damp = 0.02
			angular_damp = 0.85
			physics_material_override = _mat(0.04, 0.08)
			_build_sled()
		Kind.FRIDGE:
			display_name = "the Fridge"
			mass = 72.0
			steer_force = 16.0
			hop_impulse = 2.4
			seat_offset = Vector3(0, 1.05, 0)
			linear_damp = 0.14
			angular_damp = 2.6
			physics_material_override = _mat(0.62, 0.02)
			_build_fridge()
		Kind.TUBE:
			display_name = "the Inner Tube"
			mass = 4.5
			steer_force = 95.0
			hop_impulse = 9.0
			seat_offset = Vector3(0, 0.55, 0)
			linear_damp = 0.01
			angular_damp = 0.04
			physics_material_override = _mat(0.04, 0.86)
			_build_tube()
		Kind.MATTRESS:
			display_name = "the Mattress"
			mass = 14.0
			steer_force = 120.0
			hop_impulse = 4.5
			seat_offset = Vector3(0, 0.32, 0)
			linear_damp = 0.04
			angular_damp = 0.12
			physics_material_override = _mat(0.16, 0.44)
			_build_mattress()
		Kind.KAYAK:
			display_name = "the Kayak"
			mass = 11.0
			steer_force = 125.0
			hop_impulse = 5.5
			seat_offset = Vector3(0, 0.38, 0.15)
			linear_damp = 0.03
			angular_damp = 0.55
			physics_material_override = _mat(0.05, 0.12)
			_build_kayak()
		Kind.TABLE:
			display_name = "the Folding Table"
			mass = 7.5
			steer_force = 100.0
			hop_impulse = 5.0
			seat_offset = Vector3(0, 0.55, 0)
			linear_damp = 0.05
			angular_damp = 0.18
			physics_material_override = _mat(0.22, 0.18)
			_build_table()
		Kind.POOL:
			display_name = "the Kiddie Pool"
			mass = 6.0
			steer_force = 70.0
			hop_impulse = 7.5
			seat_offset = Vector3(0, 0.28, 0)
			linear_damp = 0.08
			angular_damp = 0.22
			physics_material_override = _mat(0.12, 0.62)
			_build_pool()
		Kind.DOOR:
			display_name = "the Door"
			mass = 10.0
			steer_force = 110.0
			hop_impulse = 4.8
			seat_offset = Vector3(0, 0.22, 0)
			linear_damp = 0.015
			angular_damp = 0.08
			physics_material_override = _mat(0.06, 0.28)
			_build_door()
	_add_label()


func max_riders() -> int:
	if kind == Kind.FRIDGE:
		return 2
	return 1


func add_rider(player: Player) -> void:
	if not riders.has(player):
		riders.append(player)


func remove_rider(player: Player) -> void:
	riders.erase(player)


func seat_for(player: Player) -> Vector3:
	var idx := riders.find(player)
	if idx < 0:
		idx = riders.size()
	var spread := Vector3.ZERO
	if riders.size() > 1 or idx > 0:
		spread = Vector3((idx % 2) * 0.55 - 0.25, 0.0, floor(float(idx) / 2.0) * -0.45)
	return seat_offset + spread


func apply_steer(dir: Vector3, _player_index: int) -> void:
	var planar := Vector3(dir.x, 0.0, dir.z)
	if planar.length_squared() < 0.01:
		return
	planar = planar.normalized()
	match kind:
		Kind.SLED:
			# Actually steers: yaw the runners, push along them.
			apply_torque(Vector3(0.0, -planar.x * steer_force * 0.55, 0.0))
			var forward := -global_transform.basis.z
			forward.y = 0.0
			if forward.length_squared() > 0.001:
				forward = forward.normalized()
			apply_central_force(forward * steer_force + planar * (steer_force * 0.12))
		Kind.FRIDGE:
			# Heavy and straight. Almost no yaw, just a stubborn shove.
			apply_central_force(planar * steer_force)
			apply_torque(Vector3(planar.z * 6.0, 0.0, -planar.x * 6.0))
		Kind.TUBE:
			# Input becomes spin.
			apply_torque(Vector3(planar.z * steer_force, -planar.x * steer_force * 1.6, -planar.x * steer_force * 0.55))
			apply_central_force(planar * (steer_force * 0.22))
		Kind.MATTRESS:
			# Flops. Pitch and roll, not a vehicle.
			apply_torque(Vector3(planar.z * steer_force, -planar.x * steer_force * 0.12, -planar.x * steer_force))
			apply_central_force(planar * (steer_force * 0.32))
		Kind.KAYAK:
			# Tracks like a hull, tips if you lean.
			apply_torque(Vector3(0.0, -planar.x * steer_force * 0.48, -planar.x * steer_force * 0.55))
			var kfwd := -global_transform.basis.z
			kfwd.y = 0.0
			if kfwd.length_squared() > 0.001:
				kfwd = kfwd.normalized()
			apply_central_force(kfwd * steer_force * 0.9 + planar * (steer_force * 0.1))
		Kind.TABLE:
			# Legs catch. Flat and stupid.
			apply_torque(Vector3(planar.z * steer_force * 0.7, -planar.x * steer_force * 0.2, -planar.x * steer_force * 0.85))
			apply_central_force(planar * (steer_force * 0.4))
		Kind.POOL:
			# Sloshy saucer. Turns into a spin if you push it.
			apply_torque(Vector3(planar.z * steer_force * 0.45, -planar.x * steer_force, -planar.x * steer_force * 0.3))
			apply_central_force(planar * (steer_force * 0.55))
		Kind.DOOR:
			# Wants to go on edge and slice.
			apply_torque(Vector3(planar.z * steer_force * 0.25, -planar.x * steer_force * 0.9, -planar.x * steer_force * 0.7))
			apply_central_force(planar * (steer_force * 0.7))


func hop() -> void:
	match kind:
		Kind.FRIDGE:
			apply_central_impulse(Vector3.UP * hop_impulse * 8.0)
		Kind.TUBE:
			apply_central_impulse(Vector3.UP * hop_impulse * maxf(mass * 0.25, 4.0))
			apply_torque_impulse(Vector3(randf_range(-4.0, 4.0), randf_range(-6.0, 6.0), randf_range(-4.0, 4.0)))
		Kind.MATTRESS:
			apply_central_impulse(Vector3.UP * hop_impulse * maxf(mass * 0.2, 3.0))
			apply_torque_impulse(Vector3(randf_range(-3.5, 3.5), 0.0, randf_range(-5.0, 5.0)))
		Kind.TABLE:
			apply_central_impulse(Vector3.UP * hop_impulse * maxf(mass * 0.22, 3.0))
			apply_torque_impulse(Vector3(randf_range(-5.0, 5.0), randf_range(-2.0, 2.0), randf_range(-6.0, 6.0)))
		Kind.POOL:
			apply_central_impulse(Vector3.UP * hop_impulse * maxf(mass * 0.3, 4.0))
			apply_torque_impulse(Vector3(randf_range(-2.0, 2.0), randf_range(-8.0, 8.0), randf_range(-2.0, 2.0)))
		Kind.DOOR:
			apply_central_impulse(Vector3.UP * hop_impulse * maxf(mass * 0.22, 3.2))
			apply_torque_impulse(Vector3(randf_range(-1.5, 1.5), randf_range(-4.0, 4.0), randf_range(-8.0, 8.0)))
		_:
			apply_central_impulse(Vector3.UP * hop_impulse * maxf(mass * 0.25, 4.0))
			apply_torque_impulse(Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.6, 0.6)))


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	match kind:
		Kind.FRIDGE:
			var av := state.angular_velocity
			av.y *= 0.12
			state.angular_velocity = av
		Kind.SLED:
			var up := global_transform.basis.y
			var straighten := up.cross(Vector3.UP) * 22.0
			state.angular_velocity += straighten * state.step
		Kind.TUBE:
			var speed := state.linear_velocity.length()
			if speed > 2.0:
				state.angular_velocity.y += speed * 0.35 * state.step
		Kind.MATTRESS:
			pass
		Kind.KAYAK:
			var kup := global_transform.basis.y
			state.angular_velocity += kup.cross(Vector3.UP) * 14.0 * state.step
		Kind.TABLE:
			pass
		Kind.POOL:
			var pspeed := state.linear_velocity.length()
			if pspeed > 1.5:
				state.angular_velocity.y += pspeed * 0.18 * state.step
		Kind.DOOR:
			# Prefer lying flat, but keep the edge-carve if already tipped.
			var dup := global_transform.basis.y
			if dup.dot(Vector3.UP) > 0.35:
				state.angular_velocity += dup.cross(Vector3.UP) * 10.0 * state.step


func _mat(friction: float, bounce: float) -> PhysicsMaterial:
	var m := PhysicsMaterial.new()
	m.friction = friction
	m.bounce = bounce
	return m


func _mesh(parent: Node3D, size: Vector3, offset: Vector3, color: Color, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = offset
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func _add_collision_box(size: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = offset
	add_child(cs)


func _add_collision_sphere(radius: float) -> void:
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	cs.shape = sphere
	add_child(cs)


func _visual_root() -> Node3D:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	return _visual


func _add_label() -> void:
	var tag := Label3D.new()
	tag.text = display_name.trim_prefix("the ")
	tag.font_size = 42
	tag.outline_size = 10
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = seat_offset + Vector3(0, 0.55, 0)
	tag.modulate = Color(1, 1, 1, 0.9)
	add_child(tag)


func _build_sled() -> void:
	var v := _visual_root()
	_mesh(v, Vector3(1.5, 0.12, 2.3), Vector3(0, 0.12, 0), Color(0.72, 0.22, 0.14))
	_mesh(v, Vector3(0.12, 0.10, 2.45), Vector3(-0.58, 0.02, 0.05), Color(0.28, 0.16, 0.08))
	_mesh(v, Vector3(0.12, 0.10, 2.45), Vector3(0.58, 0.02, 0.05), Color(0.28, 0.16, 0.08))
	_mesh(v, Vector3(1.2, 0.08, 0.35), Vector3(0, 0.22, -1.05), Color(0.65, 0.18, 0.12), Vector3(18, 0, 0))
	_mesh(v, Vector3(1.35, 0.18, 0.08), Vector3(0, 0.28, 0.55), Color(0.55, 0.15, 0.1))
	_add_collision_box(Vector3(1.55, 0.28, 2.4), Vector3(0, 0.14, 0))
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.05, 0.15)


func _build_fridge() -> void:
	var v := _visual_root()
	_mesh(v, Vector3(0.85, 1.7, 0.72), Vector3(0, 0.85, 0), Color(0.93, 0.94, 0.96))
	_mesh(v, Vector3(0.04, 1.55, 0.74), Vector3(0.44, 0.85, 0), Color(0.55, 0.58, 0.62))
	_mesh(v, Vector3(0.06, 0.28, 0.06), Vector3(0.48, 0.95, 0.12), Color(0.75, 0.78, 0.2))
	_mesh(v, Vector3(0.70, 0.04, 0.68), Vector3(0, 0.85, 0), Color(0.7, 0.72, 0.75))
	_mesh(v, Vector3(0.5, 0.08, 0.08), Vector3(0, 1.72, 0.2), Color(0.2, 0.45, 0.85))
	_add_collision_box(Vector3(0.9, 1.75, 0.78), Vector3(0, 0.875, 0))
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.95, 0)


func _build_tube() -> void:
	var v := _visual_root()
	var mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.28
	torus.outer_radius = 0.78
	torus.rings = 24
	torus.ring_segments = 16
	mi.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.38, 0.12)
	mat.roughness = 0.45
	mi.material_override = mat
	v.add_child(mi)
	var cap := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.32
	cyl.bottom_radius = 0.32
	cyl.height = 0.08
	cap.mesh = cyl
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.98, 0.55, 0.18)
	cap.material_override = cap_mat
	cap.position = Vector3(0, 0.02, 0)
	v.add_child(cap)
	_add_collision_sphere(0.72)
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0, 0)


func _build_mattress() -> void:
	var v := _visual_root()
	_mesh(v, Vector3(2.35, 0.22, 1.45), Vector3(0, 0.12, 0), Color(0.95, 0.82, 0.2))
	_mesh(v, Vector3(2.38, 0.06, 1.48), Vector3(0, 0.24, 0), Color(0.98, 0.92, 0.55))
	_mesh(v, Vector3(0.12, 0.26, 1.4), Vector3(-0.6, 0.12, 0), Color(0.9, 0.55, 0.15))
	_mesh(v, Vector3(0.12, 0.26, 1.4), Vector3(0.6, 0.12, 0), Color(0.9, 0.55, 0.15))
	_mesh(v, Vector3(0.12, 0.26, 1.4), Vector3(0.0, 0.12, 0), Color(0.92, 0.62, 0.18))
	_add_collision_box(Vector3(2.4, 0.28, 1.5), Vector3(0, 0.14, 0))
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.08, 0)



func _build_kayak() -> void:
	var v := _visual_root()
	_mesh(v, Vector3(0.72, 0.22, 2.7), Vector3(0, 0.16, 0), Color(0.12, 0.42, 0.72))
	_mesh(v, Vector3(0.55, 0.16, 0.7), Vector3(0, 0.28, 0.9), Color(0.18, 0.52, 0.82), Vector3(16, 0, 0))
	_mesh(v, Vector3(0.55, 0.16, 0.7), Vector3(0, 0.28, -0.95), Color(0.18, 0.52, 0.82), Vector3(-16, 0, 0))
	_mesh(v, Vector3(0.08, 0.12, 2.5), Vector3(-0.32, 0.22, 0), Color(1.0, 0.78, 0.12))
	_mesh(v, Vector3(0.08, 0.12, 2.5), Vector3(0.32, 0.22, 0), Color(1.0, 0.78, 0.12))
	_add_collision_box(Vector3(0.78, 0.32, 2.75), Vector3(0, 0.16, 0))
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.08, 0.1)


func _build_table() -> void:
	var v := _visual_root()
	_mesh(v, Vector3(1.7, 0.08, 0.85), Vector3(0, 0.48, 0), Color(0.82, 0.78, 0.68))
	var leg_c := Color(0.55, 0.52, 0.48)
	_mesh(v, Vector3(0.06, 0.46, 0.06), Vector3(-0.72, 0.23, -0.34), leg_c)
	_mesh(v, Vector3(0.06, 0.46, 0.06), Vector3(0.72, 0.23, -0.34), leg_c)
	_mesh(v, Vector3(0.06, 0.46, 0.06), Vector3(-0.72, 0.23, 0.34), leg_c)
	_mesh(v, Vector3(0.06, 0.46, 0.06), Vector3(0.72, 0.23, 0.34), leg_c)
	_add_collision_box(Vector3(1.74, 0.52, 0.9), Vector3(0, 0.26, 0))
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.18, 0)


func _build_pool() -> void:
	var v := _visual_root()
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.12
	torus.outer_radius = 0.95
	torus.rings = 20
	torus.ring_segments = 14
	rim.mesh = torus
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.15, 0.62, 0.92)
	rim_mat.roughness = 0.5
	rim.material_override = rim_mat
	v.add_child(rim)
	var floor_m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.82
	cyl.bottom_radius = 0.82
	cyl.height = 0.06
	floor_m.mesh = cyl
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.55, 0.85, 0.98)
	floor_m.material_override = floor_mat
	floor_m.position = Vector3(0, 0.02, 0)
	v.add_child(floor_m)
	_add_collision_sphere(0.9)
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.02, 0)


func _build_door() -> void:
	var v := _visual_root()
	_mesh(v, Vector3(0.92, 0.08, 2.05), Vector3(0, 0.08, 0), Color(0.42, 0.24, 0.12))
	_mesh(v, Vector3(0.08, 0.1, 1.9), Vector3(-0.38, 0.14, 0), Color(0.32, 0.18, 0.08))
	_mesh(v, Vector3(0.08, 0.1, 1.9), Vector3(0.38, 0.14, 0), Color(0.32, 0.18, 0.08))
	_mesh(v, Vector3(0.1, 0.12, 0.1), Vector3(0.4, 0.16, 0.35), Color(0.72, 0.62, 0.18))
	_add_collision_box(Vector3(0.96, 0.16, 2.1), Vector3(0, 0.08, 0))
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, 0.04, 0)


static func make(p_kind: Kind) -> Rideable:
	var packed := load("res://scenes/rideable.tscn") as PackedScene
	var r: Rideable = packed.instantiate()
	r.setup(p_kind)
	return r
