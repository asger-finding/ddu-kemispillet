extends Node

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MULTIPLAYER_PLAYER_SCENE := preload("res://Scenes/MultiplayerPlayer.tscn")

var player: CharacterBody2D = null
var player_exists := false
var player_skin: String
var in_game := false
var game_playing := false

var countdown_timer: Timer = null
var game_start_time: float = 0.0

# {
#    "player_id": String,
#    "username": String,
#    "questions_answered": int,
#    "questions_correct": int,
#    "runs": int,
#    "victories": int,
#  }
var player_details := {}

# [player_id: String]: MultiplayerPlayer
var other_players = {}

func _ready() -> void:
	MpClient._handshake.connect(_on_handshaked)
	MpClient._player_list_changed.connect(_player_list_changed)
	MpClient._player_changed.connect(_on_player_changed)
	MpClient._game_starting.connect(_on_game_starting)
	
	countdown_timer = Timer.new()
	countdown_timer.one_shot = true
	countdown_timer.timeout.connect(_on_game_started)
	add_child(countdown_timer)

func spawn_player(parent: Node, position: Vector2):
	player = PLAYER_SCENE.instantiate()
	player.player_skin = player_skin
	player_exists = true
	parent.add_child(player)
	player.position = position
	
	player.set_process(game_playing)

func spawn_other_player_sprite(player_id: String, parent: Node2D, position: Vector2) -> void:
	var other_player = other_players[player_id]
	if other_player != null and not other_player.is_inside_tree():
		parent.add_child(other_player)
		other_player.global_position = position
	
	other_player.set_process(game_playing)

func join_game():
	if in_game:
		return
	
	in_game = true
	SceneManager.load_scene("Game")
	MpClient.join_game()
	
	# If we are server, broadcast game start
	# FIXME: better way to check
	if MpServer.active:
		MpServer.broadcast(MpMessage.create_message(MpMessage.TypeId.GAME_STARTING, {
			"start_time": Time.get_ticks_msec() + Constants.COUNTDOWN_TIME * 1000
		}))

func emit_player_state(state):
	MpClient.send_to_server(MpMessage.create_message(MpMessage.TypeId.STATE_UPDATED_MESSAGE, state))

func get_countdown_remaining() -> float:
	if countdown_timer and countdown_timer.time_left > 0:
		return countdown_timer.time_left
	return 0.0

# Check if countdown is active
func is_countdown_active() -> bool:
	return countdown_timer != null and not countdown_timer.is_stopped()

func _on_handshaked(success: bool, incoming_player_details: Dictionary) -> void:
	player_details = incoming_player_details
	if success: SceneManager.load_scene("Menu/LoggedInMenu")
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
		if player_id == MpClient.player_id:
			GameManager.player_details = entry
			continue
		
		if not other_players.has(player_id):
			var other_player = MULTIPLAYER_PLAYER_SCENE.instantiate()
			other_player.set_player_id(player_id)
			other_player.set_username(entry.username)
			other_player.set_player_skin(entry.player_skin)
			other_players[player_id] = other_player
			if in_game:
				spawn_other_player_sprite(player_id, SceneManager.scene_instance, Constants.SPAWN_POSITION)

func _on_player_changed(state: Dictionary) -> void:
	var player_id = state.player_id
	if not player_id: return
	if not other_players.has(player_id): return
	
	var other_player = other_players[player_id]
	other_player.update_state(state)

func _on_game_starting(start_time: float) -> void:
	if not in_game:
		SceneManager.load_scene("Game")
		in_game = true
	
	game_start_time = start_time
	
	var countdown_ms = start_time - Time.get_ticks_msec()
	if countdown_ms > 0:
		countdown_timer.wait_time = countdown_ms / 1000.0
		countdown_timer.start()
	else:
		_on_game_started()
	
func _on_game_started() -> void:
	print("Game started!")
	game_playing = true
	
	if player:
		player.set_process(game_playing)
	for player_id in other_players:
		var other_player = other_players[player_id]
		other_player.set_process(game_playing)
	
