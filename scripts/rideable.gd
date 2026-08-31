extends RigidBody3D
class_name Rideable

enum Kind { SLED, FRIDGE, TUBE, MATTRESS }

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
			mass = 10.0
			steer_force = 95.0
			hop_impulse = 6.5
			seat_offset = Vector3(0, 0.42, 0.1)
			linear_damp = 0.04
			angular_damp = 1.4
			physics_material_override = _mat(0.10, 0.12)
			_build_sled()
		Kind.FRIDGE:
			display_name = "the Fridge"
			mass = 48.0
			steer_force = 42.0
			hop_impulse = 3.2
			seat_offset = Vector3(0, 1.05, 0)
			linear_damp = 0.08
			angular_damp = 0.25
			physics_material_override = _mat(0.38, 0.06)
			_build_fridge()
		Kind.TUBE:
			display_name = "the Inner Tube"
			mass = 5.5
			steer_force = 70.0
			hop_impulse = 8.5
			seat_offset = Vector3(0, 0.55, 0)
			linear_damp = 0.02
			angular_damp = 0.12
			physics_material_override = _mat(0.06, 0.78)
			_build_tube()
		Kind.MATTRESS:
			display_name = "the Mattress"
			mass = 16.0
			steer_force = 78.0
			hop_impulse = 5.0
			seat_offset = Vector3(0, 0.32, 0)
			linear_damp = 0.06
			angular_damp = 0.9
			physics_material_override = _mat(0.22, 0.38)
			_build_mattress()
	_add_label()


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
	if dir.length_squared() < 0.01:
		return
	var force := Vector3(dir.x, 0.0, dir.z) * steer_force
	apply_central_force(force)
	apply_torque(Vector3(0.0, -dir.x * steer_force * 0.12, 0.0))


func hop() -> void:
	apply_central_impulse(Vector3.UP * hop_impulse * maxf(mass * 0.25, 4.0))
	apply_torque_impulse(Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.0, 1.0)))


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


static func make(p_kind: Kind) -> Rideable:
	var packed := load("res://scenes/rideable.tscn") as PackedScene
	var r: Rideable = packed.instantiate()
	r.setup(p_kind)
	return r
