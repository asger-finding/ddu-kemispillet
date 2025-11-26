extends Node

enum TypeId {
	# --- PEER TO SERVER ---
	# payload: {
	#    player_id: string,
	#    auth_token: string
	#  }
	HANDSHAKE_MESSAGE = 1,
	
	# payload: {}
	JOIN_MESSAGE = 2,
	
	# payload: {}
	LEAVE_MESSAGE = 3,
	
	# payload: {
	#    position: [x: float, y: float],
	#    velocity: [x: float, y: float],
	#    action_type: int,
	#    health: int
	#  }
	STATE_UPDATED_MESSAGE = 4,
	
	# --- SERVER TO PEER ---
	# payload: {} # TODO: Something here
	WORLD_UPDATED_MESSAGE = 50,
	
	# payload: {
	#    player_details: <player_id: int, username: string>[]
	# }
	PLAYER_LIST_CHANGED_MESSAGE = 51,
	
	# payload: {
	#    player_id: int,
	#    position: [x: float, y: float],
	#    velocity: [x: float, y: float],
	#    action_type: int,
	#    health: int
	#  }
	PLAYER_CHANGED_MESSAGE = 52,
	
	# --- SERVER RESPONSE TO PEER ---
	# payload: {
	#    result: bool
	#  }
	HANDSHAKE_RESULT_MESSAGE = 80
}

func create_message(type_id: int, payload: Dictionary) -> String:
	return serialize({
		"type_id": type_id,
		"payload": payload
	})

func serialize(message: Dictionary) -> String:
	return JSON.stringify(message)

func deserialize(json_str: String) -> Dictionary:
	var json = JSON.new()
	var error = json.parse(json_str)
	if error == OK:
		var msg = json.data
		if typeof(msg) == TYPE_DICTIONARY and msg.has("type_id") and msg.has("payload"):
			return msg
	else:
		print("JSON Parse Error while deserializing WebSocket mesasge: ", json.get_error_message())
	return {}
