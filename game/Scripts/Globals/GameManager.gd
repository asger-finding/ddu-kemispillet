extends Node

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MULTIPLAYER_PLAYER_SCENE := preload("res://Scenes/MultiplayerPlayer.tscn")

var player: CharacterBody2D = null
var player_exists := false
var player_skin: String
var in_game := false
var game_playing := false

var countdown_timer: Timer = null

# Server only
var question_timer: Timer = null

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

signal _new_question
signal _question_answered_correct
signal _question_answered_wrong
signal _question_answered_none
signal _question_quit

func _ready() -> void:
	MpClient._handshake.connect(_on_handshaked)
	MpClient._player_list_changed.connect(_player_list_changed)
	MpClient._player_changed.connect(_on_player_changed)
	MpClient._game_starting.connect(_on_game_starting)
	MpClient._new_question.connect(_on_new_question)
	
	_question_answered_correct.connect(_on_question_answered_correct)
	_question_answered_wrong.connect(_on_question_answered_wrong)
	_question_answered_none.connect(_on_question_answered_none)
	_question_quit.connect(_on_question_quit)
	
	countdown_timer = Timer.new()
	countdown_timer.one_shot = true
	countdown_timer.timeout.connect(_on_game_started)
	add_child(countdown_timer)
	
	question_timer = Timer.new()
	question_timer.one_shot = false
	question_timer.wait_time = Constants.TIME_BETWEEN_QUESTIONS
	question_timer.timeout.connect(_on_broadcast_new_question)
	add_child(question_timer)

func spawn_player(parent: Node, position: Vector2):
	player = PLAYER_SCENE.instantiate()
	player.player_skin = player_skin
	player_exists = true
	parent.add_child(player)
	player.position = position
	player._handle_animation()
	
	if not game_playing: player.freeze_player()

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
			"start_time": Time.get_ticks_msec() + Constants.COUNTDOWN_TIME * 1000,
			"time_sent": Time.get_ticks_msec()
		}))

func emit_player_state(state):
	MpClient.send_to_server(MpMessage.create_message(MpMessage.TypeId.STATE_UPDATED_MESSAGE, state))

func get_countdown_remaining() -> float:
	if countdown_timer and countdown_timer.time_left > 0:
		return countdown_timer.time_left
	return 0.0

func is_countdown_active() -> bool:
	return countdown_timer != null and not countdown_timer.is_stopped()

func get_question_countdown_remaining() -> float:
	if question_timer and question_timer.time_left > 0:
		return question_timer.time_left
	return 0.0

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

func _on_game_starting(start_time: float, time_sent: float) -> void:
	join_game()
	
	# FIXME: investigate if this even works
	var delta_ping = Time.get_ticks_msec() - time_sent
	start_time += delta_ping
	
	var countdown_ms = start_time - Time.get_ticks_msec()
	if countdown_ms > 0:
		countdown_timer.wait_time = countdown_ms / 1000.0
		countdown_timer.start()
	else:
		_on_game_started()
	
func _on_game_started() -> void:
	print("Game started!")
	game_playing = true
	
	if player and game_playing: player.unfreeze_player()
	for player_id in other_players:
		var other_player = other_players[player_id]
		other_player.set_process(game_playing)
	
	question_timer.start()

func _on_broadcast_new_question() -> void:
	if not MpServer.active:
		return
	
	# Get random question key from Constants.QUESTIONS
	var random_question = Constants.QUESTIONS[randi() % Constants.QUESTIONS.size()]
	var key = random_question.KEY
	
	# Broadcast the new question
	MpServer.broadcast(MpMessage.create_message(MpMessage.TypeId.NEW_QUESTION, {
		"key": key
	}))
	
	print("Server broadcasting new question: ", key)

func punish_player(duration: float) -> void:
	player.freeze_player()
	await get_tree().create_timer(duration).timeout
	player.unfreeze_player()

func _on_new_question(question_key: int) -> void:	
	var question := {}
	for _question in Constants.QUESTIONS:
		if _question.KEY == question_key:
			question = _question
			break;
	assert(not question.is_empty(), "Question key passed to user did not have data")
	
	player.freeze_player()
	_new_question.emit(question)

func _on_question_answered_correct(question_popup: Control) -> void:
	player.unfreeze_player()
	question_popup.queue_free()
	punish_player(0.1)

func _on_question_answered_wrong(question_popup: Control) -> void:
	question_popup.queue_free()
	punish_player(Constants.WRONG_ANSWER_LOCK_TIME)

func _on_question_answered_none(question_popup: Control) -> void:
	question_popup.queue_free()
	punish_player(Constants.WRONG_ANSWER_LOCK_TIME)

func _on_question_quit(question_popup: Control) -> void:
	question_popup.queue_free()
	player.deal_damage(1)
	punish_player(Constants.WRONG_ANSWER_LOCK_TIME)
