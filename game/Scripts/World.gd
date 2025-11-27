extends Node2D


func _ready() -> void:
	GameManager.spawn_player(self, Constants.SPAWN_POSITION)
	
	# Spawn enqueued players
	for player_id in GameManager.other_players:
		GameManager.spawn_other_player_sprite(player_id, self, Constants.SPAWN_POSITION)
