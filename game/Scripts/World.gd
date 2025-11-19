extends Node2D

func _ready() -> void:
	PlayerManager.spawn_player(self)
	PlayerManager.player.global_position = Vector2(7953.0, -961.0)
