extends Node

@onready var ws_server := $WebSocketServer

# Track remote players: peer_id -> MultiplayerPlayer node
var remote_players: Dictionary[int, MultiplayerPlayer] = {}

# Scene references
var remote_player_scene := preload("res://Scenes/MultiplayerPlayer.tscn")

func _ready() -> void:
	# Connect server signals
	ws_server.peer_connected.connect(_on_peer_connected)
	ws_server.peer_disconnected.connect(_on_peer_disconnected)
	ws_server.peer_message_received.connect(_on_peer_message_received)

func _on_peer_connected(peer_id: int) -> void:
	print("GameManager: New player connected (ID: %d)" % peer_id)
	
	# Create remote player
	var player = remote_player_scene.instantiate()
	add_child(player)
	remote_players[peer_id] = player
	
	# Send welcome message
	var welcome = {
		"type": "welcome",
		"peer_id": peer_id,
		"message": "Connected to server"
	}
	ws_server.send_to_peer(peer_id, JSON.stringify(welcome))
	
	# Notify all other players about new player
	var join_message = {
		"type": "player_joined",
		"peer_id": peer_id
	}
	ws_server.broadcast_from(peer_id, JSON.stringify(join_message))

func _on_peer_disconnected(peer_id: int) -> void:
	print("GameManager: Player disconnected (ID: %d)" % peer_id)
	
	# Remove remote player
	if remote_players.has(peer_id):
		var player = remote_players[peer_id]
		player.queue_free()
		remote_players.erase(peer_id)
	
	# Notify all other players
	var leave_message = {
		"type": "player_left",
		"peer_id": peer_id
	}
	ws_server.broadcast(JSON.stringify(leave_message))

func _on_peer_message_received(peer_id: int, message: String) -> void:
	# Parse JSON message
	var json = JSON.new()
	var parse_result = json.parse(message)
	
	if parse_result != OK:
		push_warning("GameManager: Invalid JSON from peer %d: %s" % [peer_id, message])
		return
	
	var data = json.data
	
	if not data is Dictionary:
		push_warning("GameManager: Expected dictionary from peer %d" % peer_id)
		return
	
	# Handle different message types
	if not data.has("type"):
		push_warning("GameManager: Message missing 'type' field from peer %d" % peer_id)
		return
	
	match data.type:
		"player_update":
			_handle_player_update(peer_id, data)
		"chat":
			_handle_chat(peer_id, data)
		_:
			push_warning("GameManager: Unknown message type '%s' from peer %d" % [data.type, peer_id])

func _handle_player_update(peer_id: int, data: Dictionary) -> void:
	# Update the remote player on server
	if remote_players.has(peer_id):
		var player = remote_players[peer_id]
		player.update_from_network(data)
	
	# Broadcast to all other players
	ws_server.broadcast_from(peer_id, JSON.stringify(data))

func _handle_chat(peer_id: int, data: Dictionary) -> void:
	if not data.has("message"):
		return
	
	print("GameManager: Chat from peer %d: %s" % [peer_id, data.message])
	
	# Broadcast chat to all players
	var chat_data = {
		"type": "chat",
		"peer_id": peer_id,
		"message": data.message
	}
	ws_server.broadcast(JSON.stringify(chat_data))

# Example: Send game state to specific player
func send_game_state(peer_id: int) -> void:
	var state = {
		"type": "game_state",
		"players": []
	}
	
	# Add all player states
	for pid in remote_players.keys():
		var player = remote_players[pid]
		state.players.append({
			"peer_id": pid,
			"position": {"x": player.position.x, "y": player.position.y},
			"health": player.get_health()
		})
	
	ws_server.send_to_peer(peer_id, JSON.stringify(state))
