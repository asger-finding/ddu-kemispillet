extends Node2D

@onready var _playing_on_label: Label = $PanelContainer/VBoxContainer/PlayingOn
func _ready() -> void:
	_playing_on_label.text = "Playing on %s" % MpClient.socket_address

func _on_login_button_button_up() -> void:
	SceneManager.load_scene("Menu/LoginMenu")

func _on_register_button_button_up() -> void:
	SceneManager.load_scene("Menu/RegisterMenu")
