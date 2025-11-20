extends Node

const SERVER_PORT := 9090

var _tcp_server := TCPServer.new()
var _peers: Dictionary[int, Dictionary] = {}
var _last_peer_id := 0

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
# signal peer_message_received(peer_id: int, message: String)

func _ready() -> void:
	set_process(false)

func create() -> void:
	var err := _tcp_server.listen(SERVER_PORT, "*")
	if err == OK:
		print("MpServer: WebSocket server listening on port %d" % SERVER_PORT)
		set_process(true)
	else:
		push_error("MpServer: Failed to start server on port %d (error %d)" % [SERVER_PORT, err])
		set_process(false)

func _process(_delta: float) -> void:
	# Accept new connections
	while _tcp_server.is_connection_available():
		_last_peer_id += 1
		var peer_id = _last_peer_id
		
		var ws = WebSocketPeer.new()
		ws.accept_stream(_tcp_server.take_connection())
		_peers[peer_id] = {
			"ws": ws,
			"player_id": null
		}
		
		print("MpServer: Peer %d connected" % peer_id)
		peer_connected.emit(peer_id)
	
	# Poll all connected peers
	for peer_id in _peers.keys():
		var peer = _peers[peer_id].ws
		peer.poll()
		
		var state = peer.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			# Process incoming packets
			while peer.get_available_packet_count() > 0:
				var packet = peer.get_packet()
				if peer.was_string_packet():
					var packed = packet.get_string_from_utf8()
					var message = MpMessage.deserialize(packed)
					handle_message(peer_id, message)
				else:
					push_warning("MpServer: Received binary packet from peer %d (ignoring)" % peer_id)
		
		elif state == WebSocketPeer.STATE_CLOSED:
			# Handle disconnect
			var code = peer.get_close_code()
			var reason = peer.get_close_reason()
			print("MpServer: Peer %d disconnected (code: %d, reason: %s)" % [peer_id, code, reason])
			
			_peers.erase(peer_id)
			peer_disconnected.emit(peer_id)

func handle_message(peer_id: int, message: Dictionary) -> void:
	var type_id = int(message.get("type_id", -1))
	var payload = message.get("payload", {})
	
	print(message)
	
	match type_id:
		MpMessage.TypeId.HANDSHAKE_MESSAGE:
			# check token and authenticate
			var player_id = int(payload["player_id"]) # FIXME validate types
			var token = payload["auth_token"]
			var result = await Backend.post("make_handshake", { "player_id": player_id, "auth_token": token })
			var handshaked = !result["error"] && result["response"]["ok"]
			
			print("Server is returning if peer %s gets handshake: " % peer_id, handshaked)
			
			send_to_peer(peer_id, MpMessage.create_message(MpMessage.TypeId.HANDSHAKE_RESULT_MESSAGE, {
				"result": handshaked
			}))
			
			if not handshaked: disconnect_peer(peer_id, 1008, "Player failed handshake")
			return
		
		MpMessage.TypeId.LEAVE_MESSAGE:
			disconnect_peer(peer_id, 1000, "Player left the game")
			
			var player_id = _peers[peer_id].player_id
			if player_id:
				send_to_peer(peer_id, MpMessage.create_message(MpMessage.TypeId.PLAYER_REMOVED_MESSAGE, {
					"player_id": player_id
				}))
		
		MpMessage.TypeId.STATE_UPDATED_MESSAGE:
			var player_data = validate_state_update(peer_id, payload)
			broadcast_from(peer_id, player_data)
		_:
			push_warning("Unhandled network message type_id: %d" % type_id)

# Send message to specific peer
func send_to_peer(peer_id: int, message: String) -> void:
	if not _peers.has(peer_id):
		push_warning("MpServer: Cannot send to peer %d (not connected)" % peer_id)
		return
	
	var peer = _peers[peer_id].ws
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		peer.send_text(message)

# Broadcast message to all peers
func broadcast(message: String, exclude_peer: int = -1) -> void:
	for peer_id in _peers.keys():
		if peer_id != exclude_peer:
			send_to_peer(peer_id, message)

# Broadcast message to all peers except sender
func broadcast_from(sender_id: int, message: String) -> void:
	broadcast(message, sender_id)

# Get list of connected peer IDs
func get_peers() -> Array[int]:
	var result: Array[int] = []
	result.assign(_peers.keys())
	return result

# Get number of connected peers
func get_peer_count() -> int:
	return _peers.size()

# Check if peer is connected
func has_peer(peer_id: int) -> bool:
	return _peers.has(peer_id)

# Disconnect a peer
func disconnect_peer(peer_id: int, code: int = 1000, reason: String = "") -> void:
	if not _peers.has(peer_id):
		return
	
	var peer = _peers[peer_id].ws
	peer.close(code, reason)
	_peers.erase(peer_id)
	peer_disconnected.emit(peer_id)

# Shutdown server
func shutdown() -> void:
	print("MpServer: Shutting down...")
	for peer_id in _peers.keys():
		disconnect_peer(peer_id, 1001, "Server shutting down")
	_tcp_server.stop()

func validate_state_update(peer_id: int, data: Dictionary) -> Dictionary:
	var player_instance = PlayerManager.other_players[_peers[peer_id].player_id]
	var sanitized := {
		"type": MpMessage.TypeId.STATE_UPDATED_MESSAGE,
		"position": {"x": player_instance.position.x, "y": player_instance.position.y},
		"velocity": {"x": player_instance.velocity.x, "y": player_instance.velocity.y},
		"action_type": player_instance.action_type,
		"health": player_instance.velocity
	}
	
	# Validate position
	if data.has("position") and data.position is Dictionary:
		var pos = data.position
		if pos.has("x") and (pos.x is float or pos.x is int):
			sanitized.position.x = float(pos.x)
		if pos.has("y") and (pos.y is float or pos.y is int):
			sanitized.position.y = float(pos.y)
	
	# Validate velocity
	if data.has("velocity") and data.velocity is Dictionary:
		var vel = data.velocity
		if vel.has("x") and (vel.x is float or vel.x is int):
			sanitized.velocity.x = float(vel.x)
		if vel.has("y") and (vel.y is float or vel.y is int):
			sanitized.velocity.y = float(vel.y)
	
	# Validate action_type
	if data.has("action_type") and (data.action_type is int or data.action_type is float):
		sanitized.action_type = int(data.action_type)
	
	# Validate health
	if data.has("health") and (data.health is int or data.health is float):
		sanitized.health = int(data.health)
	
	return sanitized
