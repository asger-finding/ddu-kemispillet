extends Node2D

func _ready() -> void:
	GameManager.spawn_player(self)
	GameManager.player.global_position = Vector2(7953.0, -961.0)
