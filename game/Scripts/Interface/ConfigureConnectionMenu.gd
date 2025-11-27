extends Node2D

@onready var _connect_address_input: LineEdit = %ConnectAddressInput
@onready var _join_options: HBoxContainer = %JoinOptions
@onready var _host_container: MarginContainer = %HostContainer
@onready var _error_message: Label = %ErrorMessage

var http_request := HTTPRequest.new()

func _ready() -> void:
	toggle_host_button()
	
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		_connect_address_input.text = config.get_value("connection", "connect_address", "")
	
	_error_message.visible = false

func toggle_host_button():
	_join_options.hide()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_http_request_completed"))
	http_request.request("http://localhost:8080/api/Health.php")

func _http_request_completed(_result, response_code, _headers, body):
	if response_code == 200 and body.get_string_from_utf8() == "OK": _host_container.show()
	else: _host_container.hide()
	
	_join_options.show()
	http_request.queue_free()

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
