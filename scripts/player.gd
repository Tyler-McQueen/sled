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
var _net_axis := Vector2.ZERO
var _net_grab := false
var _net_jump := false
var _sync_acc := 0
var yell_from: Dictionary = {}

@onready var _hat: MeshInstance3D = $Hat
@onready var _body: MeshInstance3D = $Body
@onready var _name_tag: Label3D = $NameTag
@onready var _grab_area: Area3D = $GrabArea


func _ready() -> void:
	InputSetup.ensure()
	add_to_group("players")
	_bind_actions()
	display_name = "P%d" % (player_index + 1)
	_name_tag.text = display_name
	_apply_colors()
	set_multiplayer_authority(1)


func _bind_actions() -> void:
	var idx := 0 if Net.active else player_index
	_action_left = "p%d_left" % idx
	_action_right = "p%d_right" % idx
	_action_up = "p%d_up" % idx
	_action_down = "p%d_down" % idx
	_action_grab = "p%d_grab" % idx
	_action_jump = "p%d_jump" % idx


func apply_net_occupancy() -> void:
	_bind_actions()
	var occ := Net.slot_occupied(player_index)
	visible = occ
	_name_tag.visible = occ
	if not occ:
		rideable = null
		collision_layer = 0
		collision_mask = 0


func _owns() -> bool:
	if not Net.active:
		return true
	return Net.peer_for_slot(player_index) == multiplayer.get_unique_id()


func _simulate() -> bool:
	if not Net.active:
		return true
	return multiplayer.is_server()


func is_hearing_yell(from_idx: int) -> bool:
	return yell_from.has(from_idx) and float(yell_from[from_idx]) > 0.0


func hear_yell(from_idx: int) -> void:
	yell_from[from_idx] = 2.5
	if Net.active and multiplayer.is_server():
		rpc("_cl_yell", from_idx, 2.5)


@rpc("authority", "call_remote", "reliable")
func _cl_yell(from_idx: int, t: float) -> void:
	yell_from[from_idx] = t


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
	var yell_keys: Array = yell_from.keys()
	for k in yell_keys:
		yell_from[k] = float(yell_from[k]) - delta
		if float(yell_from[k]) <= 0.0:
			yell_from.erase(k)

	if Net.active and not Net.slot_occupied(player_index):
		visible = false
		return
	visible = true

	if Net.active and _owns() and not multiplayer.is_server():
		rpc_id(1, "sv_input", _read_axis())
		if Input.is_action_just_pressed(_action_grab):
			rpc_id(1, "sv_grab")
		if Input.is_action_just_pressed(_action_jump):
			rpc_id(1, "sv_jump")

	if not _simulate():
		if rideable != null and is_instance_valid(rideable):
			global_position = rideable.to_global(rideable.seat_for(self))
			global_rotation = Vector3.ZERO
		return

	if rideable != null:
		_process_riding(delta)
	else:
		_process_walking(delta)

	if Net.active and multiplayer.is_server():
		_sync_acc += 1
		if _sync_acc >= 2:
			_sync_acc = 0
			var ride_name := ""
			if rideable != null and is_instance_valid(rideable):
				ride_name = rideable.name
			rpc("cl_state", global_position, velocity, global_rotation, ride_name)


@rpc("any_peer", "call_remote", "unreliable")
func sv_input(axis: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if Net.peer_for_slot(player_index) != multiplayer.get_remote_sender_id():
		return
	_net_axis = axis


@rpc("any_peer", "call_remote", "reliable")
func sv_grab() -> void:
	if not multiplayer.is_server():
		return
	if Net.peer_for_slot(player_index) != multiplayer.get_remote_sender_id():
		return
	_net_grab = true


@rpc("any_peer", "call_remote", "reliable")
func sv_jump() -> void:
	if not multiplayer.is_server():
		return
	if Net.peer_for_slot(player_index) != multiplayer.get_remote_sender_id():
		return
	_net_jump = true


@rpc("authority", "call_remote", "unreliable")
func cl_state(pos: Vector3, vel: Vector3, rot: Vector3, ride_name: String) -> void:
	if multiplayer.is_server():
		return
	velocity = vel
	global_rotation = rot
	_apply_ride_from_net(ride_name, pos, vel)


func _apply_ride_from_net(ride_name: String, pos: Vector3, vel: Vector3) -> void:
	if ride_name == "":
		if rideable != null:
			rideable.remove_rider(self)
			rideable = null
			collision_layer = 4
			collision_mask = 3
		global_position = pos
		velocity = vel
		return
	var folder := get_tree().current_scene.get_node_or_null("Rideables")
	if folder == null:
		global_position = pos
		return
	var r := folder.get_node_or_null(ride_name)
	if r == null or not (r is Rideable):
		global_position = pos
		return
	var ride: Rideable = r
	if rideable != ride:
		if rideable != null:
			rideable.remove_rider(self)
		rideable = ride
		ride.add_rider(self)
		collision_layer = 0
		collision_mask = 0
	global_position = ride.to_global(ride.seat_for(self))
	global_rotation = Vector3.ZERO


func _want_grab() -> bool:
	if Net.active and multiplayer.is_server() and not _owns():
		if _net_grab:
			_net_grab = false
			return true
		return false
	return Input.is_action_just_pressed(_action_grab)


func _want_jump() -> bool:
	if Net.active and multiplayer.is_server() and not _owns():
		if _net_jump:
			_net_jump = false
			return true
		return false
	return Input.is_action_just_pressed(_action_jump)


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

	if _want_jump() and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if _want_grab() and _grab_cooldown <= 0.0:
		_try_mount()

	move_and_slide()
	_push_rideables()


func _process_riding(_delta: float) -> void:
	if not is_instance_valid(rideable):
		_force_dismount()
		return

	# Stay glued to the seat without reparenting (RPC paths stay under Players/).
	global_position = rideable.to_global(rideable.seat_for(self))
	global_rotation = Vector3.ZERO

	var move := _move_axis()
	var dir := _camera_dir(move)
	rideable.apply_steer(dir, player_index)

	if _want_jump() and _hop_cooldown <= 0.0:
		rideable.hop()
		_hop_cooldown = 0.45

	if _want_grab() and _grab_cooldown <= 0.0:
		var other := _nearest_rideable(rideable)
		if other != null:
			mount(other)
		else:
			dismount()


func _try_mount() -> void:
	var best := _nearest_rideable(null)
	if best != null:
		mount(best)


func _nearest_rideable(exclude: Rideable) -> Rideable:
	var best: Rideable = null
	var best_d := 999.0
	for body in _grab_area.get_overlapping_bodies():
		if body is Rideable and body != exclude:
			var d: float = global_position.distance_to(body.global_position)
			if d < best_d:
				best_d = d
				best = body
	return best


func mount(r: Rideable) -> void:
	if r == null or rideable == r:
		return
	if rideable != null:
		dismount()
	if r.riders.size() >= r.max_riders():
		var victims: Array = r.riders.duplicate()
		for p in victims:
			if p != self and p.has_method("dismount"):
				if p.has_method("hear_yell"):
					p.hear_yell(player_index)
				p.dismount()
	rideable = r
	r.add_rider(self)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	global_position = r.to_global(r.seat_for(self))
	global_rotation = Vector3.ZERO
	_grab_cooldown = 0.35


func dismount() -> void:
	if rideable == null:
		return
	var r := rideable
	var launch := r.linear_velocity + r.global_transform.basis.x * 2.2 + Vector3.UP * 3.5
	var drop_pos := r.global_position + r.global_transform.basis.x * 1.6 + Vector3.UP * 1.2
	r.remove_rider(self)
	rideable = null
	global_position = drop_pos
	global_rotation = Vector3.ZERO
	collision_layer = 4
	collision_mask = 3
	velocity = launch
	_grab_cooldown = 0.4


func _force_dismount() -> void:
	rideable = null
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


func _read_axis() -> Vector2:
	return Vector2(
		Input.get_axis(_action_left, _action_right),
		Input.get_axis(_action_up, _action_down)
	)


func _move_axis() -> Vector2:
	if Net.active and multiplayer.is_server() and not _owns():
		return _net_axis
	return _read_axis()


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
