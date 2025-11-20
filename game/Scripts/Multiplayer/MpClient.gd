extends Node

var socket := WebSocketPeer.new()
var state = Constants.OFFLINE
var player_id: int
var auth_token: String

signal handshaked

func connect_to_host(url: String) -> void:
	print(url)
	socket.connect_to_url(url)
	set_process(true)

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
			set_process(false)
			return

func _read_messages() -> void:
	while socket.get_available_packet_count() > 0:
		var raw := socket.get_packet().get_string_from_utf8()
		var msg := MpMessage.deserialize(raw)
		
		if msg.type_id == MpMessage.TypeId.HANDSHAKE_RESULT_MESSAGE:
			var ok: bool = msg.payload.result
			if ok:
				state = Constants.HANDSHAKED
			handshaked.emit(ok)

func send_to_server(text: String) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		push_error("Client tried to send WebSocket message before connection was established")
		return
	socket.send_text(text)

func handshake() -> bool:
	assert(player_id, "Client tried to handshake before playerId was set")

	var promise = Promise.new()
	handshaked.connect(func(ok): promise.set_result(ok))
	
	send_to_server(MpMessage.create_message(
		MpMessage.TypeId.HANDSHAKE_MESSAGE,
		{
			"player_id": player_id,
			"auth_token": auth_token
		}
	))
	
	return await promise.async()
