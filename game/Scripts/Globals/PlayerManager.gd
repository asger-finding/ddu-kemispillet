extends Node

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")

var player: CharacterBody2D = null
var player_exists := false

func spawn_player(parent: Node):
	player = PLAYER_SCENE.instantiate()
	player_exists = true
	parent.add_child(player)
