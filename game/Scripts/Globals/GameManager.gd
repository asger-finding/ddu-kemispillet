extends Node

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MULTIPLAYER_PLAYER_SCENE := preload("res://Scenes/MultiplayerPlayer.tscn")

var player: CharacterBody2D = null
var player_exists := false

# [player_id: int]: Player
var other_players = {}

func _ready() -> void:
	MpClient._handshake.connect(_on_handshaked)
	MpClient._player_list_changed.connect(_player_list_changed)
	MpClient._player_changed.connect(_on_player_changed)

func spawn_player(parent: Node):
	player = PLAYER_SCENE.instantiate()
	player_exists = true
	parent.add_child(player)

func emit_player_state(state):
	MpClient.send_to_server(MpMessage.create_message(MpMessage.TypeId.STATE_UPDATED_MESSAGE, state))

func _on_handshaked(success: bool) -> void:
	if success:
		SceneManager.load_scene("Game")
		MpClient.join_game()
	else: SceneManager.load_scene("Menu/ConfigureConnectionMenu")

func _player_list_changed(list: Array):
	var incoming_ids: = {}
	for entry in list:
		incoming_ids[entry.player_id] = true
	
	# remove missing
	for player_id in other_players.keys():
		if player_id == MpClient.player_id: continue
		if not incoming_ids.has(player_id):
			other_players[player_id].queue_free()
			other_players.erase(player_id)
	
	# add new
	for entry in list:
		var player_id = entry.player_id
		if player_id == MpClient.player_id: continue
		if not other_players.has(player_id):
			var other_player = MULTIPLAYER_PLAYER_SCENE.instantiate()
			SceneManager.scene_instance.add_child(other_player)
			other_player.global_position = Vector2(7953.0, -961.0)
			other_players[player_id] = other_player

func _on_player_changed(state: Dictionary) -> void:
	var player_id = state.player_id
	if not player_id: return
	if not other_players.has(player_id): return
	
	var other_player = other_players[player_id]
	other_player.update_from_network(state)
