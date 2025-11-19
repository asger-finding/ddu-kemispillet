extends Node

const SERVER_PORT := 9090

var ws_peer: WebSocketMultiplayerPeer

func create() -> void:
	ws_peer = WebSocketMultiplayerPeer.new()

	var err := ws_peer.create_server(SERVER_PORT, "*")
	if err != OK:
		push_error("MpServer: failed to start WebSocket server on port %d (err=%d)" % [SERVER_PORT, err])
		return

	get_tree().get_multiplayer().multiplayer_peer = ws_peer
	get_tree().get_multiplayer().peer_connected.connect(_on_peer_connected)
	get_tree().get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)

	print("MpServer: WebSocket server listening on localhost:%d" % SERVER_PORT)

func _on_peer_connected(id: int) -> void:
	print("MpServer: peer connected:", id)
	rpc("client_add", id)

func _on_peer_disconnected(id: int) -> void:
	print("MpServer: peer disconnected:", id)
	rpc("client_remove", id)

@rpc func client_update(x: float, y: float) -> void:
	var sender: int = get_tree().get_multiplayer().get_remote_sender_id()
	if sender == 0:
		return
	rpc("server_broadcast_update", sender, x, y)

@rpc func server_broadcast_update(peer_id: int, x: float, y: float) -> void:
	pass

@rpc func client_add(peer_id: int) -> void:
	pass

@rpc func client_remove(peer_id: int) -> void:
	pass
