extends Node2D

@onready var _ip_address_input: LineEdit = $"PanelContainer/VBoxContainer/IpAddressInput"
@onready var _error_message: Label = $"ErrorMessage"

func _ready() -> void:
	_error_message.visible = false

func _on_host_button_button_up() -> void:
	Backend.set_server_address("localhost")
	SceneManager.load_scene("Menu/MainMenu")

func _on_join_button_button_up() -> void:
	var ip_address = _ip_address_input.get_text()
	Backend.set_server_address(ip_address)
	SceneManager.load_scene("Menu/MainMenu")

func handle_error(code: String) -> void:
	_error_message.text = 'Error: ' + code # TODO: human readable errors
	_error_message.visible = true
	await get_tree().create_timer(5).timeout
	_error_message.text = ''
	_error_message.visible = false
