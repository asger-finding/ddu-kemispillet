extends Node

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const MULTIPLAYER_PLAYER_SCENE := preload("res://Scenes/MultiplayerPlayer.tscn")

var player: CharacterBody2D = null
var player_exists := false

# [player_id: int]: Player
var other_players = {}

func spawn_player(parent: Node):
	player = PLAYER_SCENE.instantiate()
	player_exists = true
	parent.add_child(player)

func spawn_other_player(parent: Node, data: Dictionary) -> Player:
	var player_id = data.player_id
	var new_player = MULTIPLAYER_PLAYER_SCENE.instantiate()
	parent.add_child(new_player)
	
	other_players[player_id] = new_player
	return new_player
