extends CharacterBody3D
class_name Player

const WALK_SPEED := 8.5
const AIR_SPEED := 5.0
const JUMP_VELOCITY := 9.0
const PUSH_STRENGTH := 4.0
const GRAVITY := 16.0

@export var player_index: int = 0

var rideable: Rideable = null
var display_name: String = "P1"
var body_color: Color = Color(0.9, 0.2, 0.2)

var _grab_cooldown := 0.0
var _hop_cooldown := 0.0
var _action_left: String
var _action_right: String
var _action_up: String
var _action_down: String
var _action_grab: String
var _action_jump: String

@onready var _hat: MeshInstance3D = $Hat
@onready var _body: MeshInstance3D = $Body
@onready var _name_tag: Label3D = $NameTag
@onready var _grab_area: Area3D = $GrabArea


func _ready() -> void:
	InputSetup.ensure()
	add_to_group("players")
	_action_left = "p%d_left" % player_index
	_action_right = "p%d_right" % player_index
	_action_up = "p%d_up" % player_index
	_action_down = "p%d_down" % player_index
	_action_grab = "p%d_grab" % player_index
	_action_jump = "p%d_jump" % player_index
	display_name = "P%d" % (player_index + 1)
	_name_tag.text = display_name
	_apply_colors()


func _apply_colors() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = body_color.darkened(0.15)
	body_mat.roughness = 0.7
	_body.material_override = body_mat
	var hat_mat := StandardMaterial3D.new()
	hat_mat.albedo_color = body_color
	hat_mat.roughness = 0.55
	_hat.material_override = hat_mat
	_name_tag.modulate = body_color


func _physics_process(delta: float) -> void:
	_grab_cooldown = maxf(0.0, _grab_cooldown - delta)
	_hop_cooldown = maxf(0.0, _hop_cooldown - delta)

	if rideable != null:
		_process_riding(delta)
		return

	_process_walking(delta)


func _process_walking(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var move := _move_axis()
	var dir := _camera_dir(move)
	var speed := WALK_SPEED if is_on_floor() else AIR_SPEED
	if dir.length_squared() > 0.01:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		var look_dir := Vector3(dir.x, 0.0, dir.z)
		if look_dir.length_squared() > 0.01:
			var target_basis := Basis.looking_at(look_dir, Vector3.UP)
			global_transform.basis = global_transform.basis.slerp(target_basis, clampf(delta * 12.0, 0.0, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 4.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 4.0)

	if Input.is_action_just_pressed(_action_jump) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed(_action_grab) and _grab_cooldown <= 0.0:
		_try_mount()

	move_and_slide()
	_push_rideables()


func _process_riding(_delta: float) -> void:
	if not is_instance_valid(rideable):
		_force_dismount()
		return

	# Stay glued to the seat; the rigidbody does the physics.
	position = rideable.seat_for(self)
	rotation = Vector3.ZERO

	var move := _move_axis()
	var dir := _camera_dir(move)
	rideable.apply_steer(dir, player_index)

	if Input.is_action_just_pressed(_action_jump) and _hop_cooldown <= 0.0:
		rideable.hop()
		_hop_cooldown = 0.45

	if Input.is_action_just_pressed(_action_grab) and _grab_cooldown <= 0.0:
		dismount()


func _try_mount() -> void:
	var best: Rideable = null
	var best_d := 999.0
	for body in _grab_area.get_overlapping_bodies():
		if body is Rideable:
			var d: float = global_position.distance_to(body.global_position)
			if d < best_d:
				best_d = d
				best = body
	if best != null:
		mount(best)


func mount(r: Rideable) -> void:
	if rideable != null:
		return
	rideable = r
	r.add_rider(self)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	reparent(r)
	position = r.seat_for(self)
	rotation = Vector3.ZERO
	_grab_cooldown = 0.35


func dismount() -> void:
	if rideable == null:
		return
	var r := rideable
	var launch := r.linear_velocity + r.global_transform.basis.x * 2.2 + Vector3.UP * 3.5
	var drop_pos := r.global_position + r.global_transform.basis.x * 1.6 + Vector3.UP * 1.2
	r.remove_rider(self)
	rideable = null
	var world := get_tree().current_scene.get_node_or_null("Players")
	if world == null:
		world = get_tree().current_scene
	reparent(world)
	global_position = drop_pos
	global_rotation = Vector3.ZERO
	collision_layer = 4
	collision_mask = 3
	velocity = launch
	_grab_cooldown = 0.4


func _force_dismount() -> void:
	rideable = null
	var world := get_tree().current_scene.get_node_or_null("Players")
	if world == null:
		world = get_tree().current_scene
	reparent(world)
	collision_layer = 4
	collision_mask = 3
	_grab_cooldown = 0.4


func _push_rideables() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is Rideable:
			var rb: Rideable = collider
			rb.apply_central_impulse(-col.get_normal() * PUSH_STRENGTH)


func _move_axis() -> Vector2:
	return Vector2(
		Input.get_axis(_action_left, _action_right),
		Input.get_axis(_action_up, _action_down)
	)


func _camera_dir(move: Vector2) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	var look := Vector3(0, 0, 1)
	var right := Vector3(1, 0, 0)
	if cam != null:
		look = -cam.global_transform.basis.z
		look.y = 0.0
		if look.length_squared() < 0.001:
			look = Vector3(0, 0, 1)
		else:
			look = look.normalized()
		right = cam.global_transform.basis.x
		right.y = 0.0
		if right.length_squared() < 0.001:
			right = Vector3(1, 0, 0)
		else:
			right = right.normalized()
	var dir := right * move.x - look * move.y
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	return dir


func is_riding() -> bool:
	return rideable != null
