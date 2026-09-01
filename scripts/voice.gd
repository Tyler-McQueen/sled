extends Node
## Proximity voice. Quiet on the same ride, yelling on a steal, gone in the trees.

const RANGE := 38.0
const TREE_X := 13.0
const RATE := 8000
const STRIDE := 6

var _capture: AudioEffectCapture
var _mic_player: AudioStreamPlayer
var _ready_mic := false
var _streams: Dictionary = {} # peer_id -> AudioStreamPlayer
var _gens: Dictionary = {} # peer_id -> AudioStreamGeneratorPlayback
var _send_acc := 0.0


func _ready() -> void:
	set_multiplayer_authority(1)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not Net.active:
		return
	if not _ready_mic:
		_setup_mic()
	_send_acc += delta
	if _send_acc >= 0.08:
		_send_acc = 0.0
		_send_chunk()
	_mix_volumes()


func _setup_mic() -> void:
	_ready_mic = true
	var bus_name := "MicIn"
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_mute(idx, true)
		_capture = AudioEffectCapture.new()
		AudioServer.add_bus_effect(idx, _capture)
	else:
		_capture = AudioServer.get_bus_effect(idx, 0) as AudioEffectCapture
		if _capture == null:
			_capture = AudioEffectCapture.new()
			AudioServer.add_bus_effect(idx, _capture)
	if _mic_player == null:
		_mic_player = AudioStreamPlayer.new()
		_mic_player.stream = AudioStreamMicrophone.new()
		_mic_player.bus = bus_name
		add_child(_mic_player)
	if not _mic_player.playing:
		_mic_player.play()


func _send_chunk() -> void:
	if _capture == null:
		return
	var avail := _capture.get_frames_available()
	if avail < 64:
		return
	var frames: PackedVector2Array = _capture.get_buffer(avail)
	var packed := PackedByteArray()
	var i := 0
	while i < frames.size():
		var s: float = clampf((frames[i].x + frames[i].y) * 0.5, -1.0, 1.0)
		var v: int = int(s * 32767.0)
		packed.append(v & 255)
		packed.append((v >> 8) & 255)
		i += STRIDE
	if packed.size() < 4:
		return
	rpc("_rpc_voice", packed)


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_voice(packed: PackedByteArray) -> void:
	var from_id := multiplayer.get_remote_sender_id()
	if from_id == 0 or from_id == multiplayer.get_unique_id():
		return
	var pb := _playback_for(from_id)
	if pb == null:
		return
	var frames := PackedVector2Array()
	var i := 0
	while i + 1 < packed.size():
		var lo := packed[i]
		var hi := packed[i + 1]
		var v: int = lo | (hi << 8)
		if v >= 32768:
			v -= 65536
		var s := float(v) / 32767.0
		frames.append(Vector2(s, s))
		i += 2
	if pb.can_push_buffer(frames.size()):
		pb.push_buffer(frames)


func _playback_for(peer_id: int) -> AudioStreamGeneratorPlayback:
	if not _gens.has(peer_id):
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = float(RATE)
		gen.buffer_length = 0.3
		var player := AudioStreamPlayer.new()
		player.stream = gen
		player.volume_db = -80.0
		add_child(player)
		player.play()
		_streams[peer_id] = player
		_gens[peer_id] = player.get_stream_playback()
	return _gens[peer_id]


func _mix_volumes() -> void:
	var listener := _local_player()
	for peer_id in _streams.keys():
		var player: AudioStreamPlayer = _streams[peer_id]
		var slot := Net.slot_of_peer(int(peer_id))
		if slot < 0:
			player.volume_db = -80.0
			continue
		var speaker := _player_at(slot)
		player.volume_db = linear_to_db(maxf(_gain(speaker, listener), 0.0001))


func _gain(speaker: Player, listener: Player) -> float:
	if speaker == null or listener == null or speaker == listener:
		return 0.0
	var d: float = speaker.global_position.distance_to(listener.global_position)
	var in_trees := absf(speaker.global_position.x) > TREE_X
	if in_trees and d > 18.0:
		return 0.0
	if d > RANGE:
		return 0.0
	var g: float = clampf(1.0 - d / RANGE, 0.0, 1.0)
	if speaker.rideable != null and speaker.rideable == listener.rideable:
		g *= 0.28
	if listener.is_hearing_yell(speaker.player_index):
		g = maxf(g, 0.95)
	return g


func _local_player() -> Player:
	return _player_at(Net.local_slot() if Net.active else 0)


func _player_at(slot: int) -> Player:
	var root := get_tree().current_scene
	if root == null:
		return null
	var folder := root.get_node_or_null("Players")
	if folder == null:
		return null
	for child in folder.get_children():
		if child is Player and child.player_index == slot:
			return child
	return null
