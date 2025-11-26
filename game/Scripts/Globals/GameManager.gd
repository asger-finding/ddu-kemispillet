extends Node

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MULTIPLAYER_PLAYER_SCENE := preload("res://Scenes/MultiplayerPlayer.tscn")

var player: CharacterBody2D = null
var player_exists := false
var player_skin: String
var in_game := false

# [player_id: int]: MultiplayerPlayer
var other_players = {}

func _ready() -> void:
	MpClient._handshake.connect(_on_handshaked)
	MpClient._player_list_changed.connect(_player_list_changed)
	MpClient._player_changed.connect(_on_player_changed)

func spawn_player(parent: Node, position: Vector2):
	player = PLAYER_SCENE.instantiate()
	player.player_skin = player_skin
	player_exists = true
	parent.add_child(player)
	player.position = position

func spawn_other_player(player_id: int, parent: Node2D, position: Vector2) -> void:
	var other_player = other_players[player_id]
	if other_player != null and not other_player.is_inside_tree():
		parent.add_child(other_player)
		other_player.global_position = position

func join_game(skin: String):
	player_skin = skin
	SceneManager.load_scene("Game")
	MpClient.join_game()
	
	in_game = true

func emit_player_state(state):
	MpClient.send_to_server(MpMessage.create_message(MpMessage.TypeId.STATE_UPDATED_MESSAGE, state))

func _on_handshaked(success: bool) -> void:
	if success: SceneManager.load_scene("Menu/LobbyMenu")
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
			other_player.set_player_id(player_id)
			other_player.set_username(entry.username)
			other_player.set_player_skin(entry.player_skin)
			other_players[player_id] = other_player
			if in_game:
				spawn_other_player(player_id, SceneManager.scene_instance, Constants.SPAWN_POSITION)

func _on_player_changed(state: Dictionary) -> void:
	var player_id = state.player_id
	if not player_id: return
	if not other_players.has(player_id): return
	
	var other_player = other_players[player_id]
	other_player.update_state(state)
