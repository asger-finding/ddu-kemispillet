extends Node2D

@onready var _connect_address_input: LineEdit = $"PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/ConnectAddressInput"
@onready var _error_message: Label = $"ErrorMessage"

func _ready() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		_connect_address_input.text = config.get_value("connection", "connect_address", "")
	
	_error_message.visible = false

func _on_host_button_button_up() -> void:
	MpServer.create()
	
	Backend.set_server_address("localhost")
	MpClient.set_socket_address("127.0.0.1:9090")
	connect_and_enter()

func _on_join_button_button_up() -> void:
	var connect_address = _connect_address_input.get_text()
	save_connect_address(connect_address)
	
	Backend.set_server_address(connect_address)
	MpClient.set_socket_address(connect_address + "/sync")
	connect_and_enter()

func connect_and_enter() -> void:
	var connect_error = MpClient.connect_to_host()
	if connect_error == OK:
		SceneManager.load_scene("Menu/MainMenu")
	else:
		handle_error("failed_to_connect")

func save_connect_address(connection_address: String) -> void:
	var config = ConfigFile.new()
	config.set_value("connection", "connect_address", connection_address)
	config.save("user://settings.cfg")

func handle_error(code: String) -> void:
	_error_message.text = 'Error: ' + code # TODO: human readable errors
	_error_message.visible = true
	await get_tree().create_timer(5).timeout
	_error_message.text = ''
	_error_message.visible = false
