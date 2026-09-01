extends Node
## Listen-server for four players. Local 4-player is unchanged until someone hosts or joins.

const PORT := 24567
const MAX_PLAYERS := 4

var active := false
var join_ip := "127.0.0.1"
var slots: Dictionary = {} # peer_id (int) -> player_index (int)
var status := "local 4-player"

signal status_changed
signal slots_changed


func _ready() -> void:
	set_multiplayer_authority(1)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connect_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func local_ip() -> String:
	for addr in IP.get_local_addresses():
		var s := str(addr)
		if s.begins_with("192.168.") or s.begins_with("10.") or s.begins_with("172.16."):
			return s
	for addr in IP.get_local_addresses():
		var s2 := str(addr)
		if s2.contains(".") and not s2.begins_with("127.") and not s2.begins_with("172.1") and not s2.begins_with("172.2"):
			if not s2.begins_with("169."):
				return s2
	return "127.0.0.1"


func host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS - 1)
	if err != OK:
		status = "host failed (%d)" % err
		status_changed.emit()
		return
	multiplayer.multiplayer_peer = peer
	active = true
	slots.clear()
	slots[1] = 0
	status = "hosting  %s:%d  (you are P1)" % [local_ip(), PORT]
	status_changed.emit()
	slots_changed.emit()
	_bind_players()


func join(ip: String) -> void:
	join_ip = ip.strip_edges()
	if join_ip == "":
		join_ip = "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(join_ip, PORT)
	if err != OK:
		status = "join failed (%d)" % err
		status_changed.emit()
		return
	multiplayer.multiplayer_peer = peer
	active = true
	status = "connecting to %s:%d…" % [join_ip, PORT]
	status_changed.emit()


func peer_for_slot(player_index: int) -> int:
	for pid in slots.keys():
		if int(slots[pid]) == player_index:
			return int(pid)
	return 0


func slot_of_peer(peer_id: int) -> int:
	for pid in slots.keys():
		if int(pid) == peer_id:
			return int(slots[pid])
	return -1


func slot_occupied(player_index: int) -> bool:
	if not active:
		return true
	return peer_for_slot(player_index) != 0


func local_slot() -> int:
	if not active:
		return 0
	var id := multiplayer.get_unique_id()
	if slots.has(id):
		return int(slots[id])
	return 0


func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	var taken: Dictionary = {}
	for pid in slots.keys():
		taken[int(slots[pid])] = true
	var slot := -1
	for i in range(MAX_PLAYERS):
		if not taken.has(i):
			slot = i
			break
	if slot < 0:
		return
	slots[id] = slot
	rpc("_rpc_slots", slots)
	slots_changed.emit()
	status = "hosting  %s:%d  (%d/4)" % [local_ip(), PORT, slots.size()]
	status_changed.emit()
	_bind_players()


func _on_peer_disconnected(id: int) -> void:
	slots.erase(id)
	if multiplayer.is_server():
		rpc("_rpc_slots", slots)
	slots_changed.emit()
	_bind_players()


func _on_connected() -> void:
	active = true
	status = "joined %s" % join_ip
	status_changed.emit()


func _on_connect_failed() -> void:
	active = false
	status = "join failed"
	status_changed.emit()
	multiplayer.multiplayer_peer = null


func _on_server_disconnected() -> void:
	active = false
	slots.clear()
	status = "host left — back to local"
	status_changed.emit()
	slots_changed.emit()
	multiplayer.multiplayer_peer = null
	_bind_players()


@rpc("authority", "call_remote", "reliable")
func _rpc_slots(next: Dictionary) -> void:
	slots = next
	var id := multiplayer.get_unique_id()
	var you := "?"
	if slots.has(id):
		you = "P%d" % (int(slots[id]) + 1)
	status = "online  you are %s  (%d/4)" % [you, slots.size()]
	status_changed.emit()
	slots_changed.emit()
	_bind_players()


func _bind_players() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	var folder := root.get_node_or_null("Players")
	if folder == null:
		return
	for child in folder.get_children():
		if child is Player:
			child.apply_net_occupancy()


func rebind() -> void:
	_bind_players()


func request_restart() -> void:
	if not active:
		get_tree().reload_current_scene()
		return
	if multiplayer.is_server():
		rpc("_rpc_restart")


@rpc("authority", "call_local", "reliable")
func _rpc_restart() -> void:
	get_tree().reload_current_scene()
