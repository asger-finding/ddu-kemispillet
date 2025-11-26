extends Node

var socket := WebSocketPeer.new()
var state = Constants.OFFLINE
var socket_address: String = ""
var player_id: int
var auth_token: String

signal _handshake
signal _player_list_changed
signal _player_changed

func connect_to_host() -> Error:
	if not socket_address: return Error.FAILED
	socket.connect_to_url(socket_address)
	set_process(true)
	
	return OK

func set_socket_address(address: String) -> String:
	socket_address = address
	return socket_address

func _process(_delta: float) -> void:
	socket.poll()
	
	match socket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			return
		
		WebSocketPeer.STATE_OPEN:
			_read_messages()
			return
		
		WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CLOSED:
			state = Constants.OFFLINE
			socket_address = ""
			set_process(false)
			return

func _read_messages() -> void:
	while socket.get_available_packet_count() > 0:
		var packed := socket.get_packet().get_string_from_utf8()
		var message := MpMessage.deserialize(packed)
		handle_message(message)

func handle_message(message: Dictionary) -> void:
	var type_id = int(message.get("type_id", -1))
	var payload = message.get("payload", {})
	
	match type_id:
		MpMessage.TypeId.HANDSHAKE_RESULT_MESSAGE:
			var ok: bool = payload.result
			
			if ok:
				state = Constants.HANDSHAKED
			else:
				socket.close()
				Backend.server_address = ""
			_handshake.emit(ok)
		
		MpMessage.TypeId.PLAYER_LIST_CHANGED_MESSAGE:
			for player_detail in payload.player_details:
				if player_detail.player_id and player_detail.player_id is float:
					player_detail.player_id = int(player_detail.player_id)
			_player_list_changed.emit(payload.player_details)
		
		MpMessage.TypeId.PLAYER_CHANGED_MESSAGE:
			if payload.player_id && payload.player_id is float:
				payload.player_id = int(payload.player_id)
			if payload.health && payload.health is float:
				payload.health = int(payload.health)
			_player_changed.emit(payload)
		
		_:
			return

func send_to_server(text: String) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		push_error("Client tried to send WebSocket message before connection was established")
		return
	socket.send_text(text)

func handshake() -> bool:
	assert(player_id, "Client tried to handshake before player_id was set")

	var promise = Promise.new()
	_handshake.connect(func(ok): promise.set_result(ok))
	
	send_to_server(MpMessage.create_message(
		MpMessage.TypeId.HANDSHAKE_MESSAGE,
		{
			"player_id": player_id,
			"auth_token": auth_token
		}
	))
	
	return await promise.async()

func join_game() -> void:
	if state != Constants.HANDSHAKED:
		push_error("Player tried to join game before being handshaked")
		return
		
	if not GameManager.player_skin:
		push_error("Player tried to join game without setting a skin first")
		return
	
	send_to_server(MpMessage.create_message(
		MpMessage.TypeId.JOIN_MESSAGE,
		{
			"player_skin": GameManager.player_skin
		}
	))
