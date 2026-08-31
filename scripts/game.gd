extends Node3D

const PLAYER_COLORS := [
	Color(0.90, 0.22, 0.20),
	Color(0.18, 0.42, 0.95),
	Color(0.95, 0.78, 0.12),
	Color(0.18, 0.72, 0.32),
]

var _finished: Dictionary = {}
var _place := 0
var _clock := 0.0
var _mountain: Mountain

@onready var _camera: FollowCamera = $Camera3D
@onready var _hud: SledHUD = $HUD


func _enter_tree() -> void:
	InputSetup.ensure()


func _ready() -> void:
	_setup_world()
	_mountain = Mountain.new()
	_mountain.name = "Mountain"
	add_child(_mountain)
	_spawn_rideables()
	_spawn_players()
	_spawn_finish()


func _process(delta: float) -> void:
	_clock += delta
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func record_finish(player: Player, vehicle: Rideable) -> void:
	if _finished.has(player):
		return
	_place += 1
	_finished[player] = _place
	var vehicle_name := "foot"
	if vehicle != null and is_instance_valid(vehicle):
		vehicle_name = vehicle.display_name
	elif player.rideable != null:
		vehicle_name = player.rideable.display_name
	_hud.announce_place(_place, player.display_name, vehicle_name, _clock)


func _setup_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.30, 0.55, 0.88)
	sky_mat.sky_horizon_color = Color(0.78, 0.88, 0.96)
	sky_mat.ground_bottom_color = Color(0.82, 0.88, 0.92)
	sky_mat.ground_horizon_color = Color(0.86, 0.91, 0.96)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color(0.80, 0.88, 0.95)
	env.fog_density = 0.0018
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 280.0
	add_child(sun)


func _spawn_players() -> void:
	var root := Node3D.new()
	root.name = "Players"
	add_child(root)
	var packed := load("res://scenes/player.tscn") as PackedScene
	var xs: Array[float] = [-6.0, -2.0, 2.0, 6.0]
	var cam_targets: Array = []
	for i in 4:
		var p: Player = packed.instantiate()
		p.player_index = i
		p.body_color = PLAYER_COLORS[i]
		p.name = "Player%d" % (i + 1)
		root.add_child(p)
		p.global_position = Vector3(xs[i], 58.05, -16.0)
		cam_targets.append(p)
	_camera.targets = cam_targets


func _spawn_rideables() -> void:
	var root := Node3D.new()
	root.name = "Rideables"
	add_child(root)
	var kinds: Array[int] = [
		Rideable.Kind.SLED,
		Rideable.Kind.FRIDGE,
		Rideable.Kind.TUBE,
		Rideable.Kind.MATTRESS,
	]
	var xs: Array[float] = [-7.5, -2.5, 2.5, 7.5]
	for i in kinds.size():
		var r := Rideable.make(kinds[i])
		r.name = ["Sled", "Fridge", "InnerTube", "Mattress"][i]
		root.add_child(r)
		var y := 58.4
		if kinds[i] == Rideable.Kind.FRIDGE:
			y = 58.2
		elif kinds[i] == Rideable.Kind.TUBE:
			y = 58.85
		r.global_position = Vector3(xs[i], y, -4.0)
		r.rotation_degrees = Vector3(0, 180, 0)


func _spawn_finish() -> void:
	var area := Area3D.new()
	area.name = "Finish"
	area.collision_layer = 8
	area.collision_mask = 2 | 4
	area.monitoring = true
	area.monitorable = false
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(24.0, 16.0, 8.0)
	cs.shape = box
	area.add_child(cs)
	area.position = Vector3(0, 8.0, 214.0)
	area.body_entered.connect(_on_finish_body)
	add_child(area)

	var bumper := StaticBody3D.new()
	bumper.name = "Catcher"
	bumper.collision_layer = 1
	var bcs := CollisionShape3D.new()
	var bbox := BoxShape3D.new()
	bbox.size = Vector3(26, 10, 3)
	bcs.shape = bbox
	bcs.position = Vector3(0, 5, 252)
	bumper.add_child(bcs)
	add_child(bumper)


func _on_finish_body(body: Node) -> void:
	if body is Rideable:
		var r: Rideable = body
		var snapshot: Array = r.riders.duplicate()
		if snapshot.is_empty():
			return
		for rider in snapshot:
			if rider is Player:
				record_finish(rider, r)
	elif body is Player:
		record_finish(body, body.rideable)
