extends Node

const SERVER_HEADERS = ["Content-Type: application/x-www-form-urlencoded", "Cache-Control: max-age=0"]

var server_address: String = ""
var http_request : HTTPRequest = HTTPRequest.new()
var request_queue : Array = []
var is_requesting : bool = false
var current_request : Dictionary = {}

func _ready():
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_http_request_completed"))

func _process(_delta):
	if is_requesting: return
	if request_queue.is_empty(): return
	
	is_requesting = true
	current_request = request_queue.pop_front()
	_send_request(current_request)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		MpClient.send_to_server(MpMessage.create_message(MpMessage.TypeId.LEAVE_MESSAGE, {}))
		# var result = await post("update_player", {
		# 	"player_id": MpClient.player_id
		# })
		get_tree().quit()

func _http_request_completed(result, _response_code, _headers, body):
	is_requesting = false
	var request = current_request
	current_request = {}
	
	if result != HTTPRequest.RESULT_SUCCESS:
		printerr("Error with connection: " + str(result))
		if request and request.has("promise"):
			request["promise"].set_result({"error": "connection_failed", "response": null, "datasize": 0})
		return
	
	var response_body = body.get_string_from_utf8()
	var response_parser = JSON.new()
	var parse_error = response_parser.parse(response_body)
	
	if parse_error != OK:
		printerr("JSON parse error: " + response_parser.get_error_message())
		if request and request.has("promise"):
			request["promise"].set_result({"error": "json_parse_error", "response": null, "datasize": 0})
		return
	
	var response = response_parser.get_data()
	if response['error'] != "":
		printerr("Backend returned error: " + response['error'])
		if request and request.has("promise"):
			request["promise"].set_result({"error": response['error'], "response": null, "datasize": 0})
		return
	
	var response_data = response['response']
	var data_size = int(response['datasize'])
	
	if request and request.has("promise"):
		request["promise"].set_result({"error": "", "response": response_data, "datasize": data_size})
	else:
		print(response_data, data_size)

func _send_request(request: Dictionary):
	if not server_address:
		handle_error("Attempted to POST with method %s but server address is unset" % request['command'])
		return {"error": "server_address_unset", "response": null, "datasize": 0}
	
	var client = HTTPClient.new()
	var data = client.query_string_from_dict({
		"data": JSON.stringify(request['data'])
	})
	var body = "command=" + request['command'] + "&" + data
	var err = http_request.request(server_address, SERVER_HEADERS, HTTPClient.METHOD_POST, body)
	
	if err != OK:
		printerr("HTTPRequest error: " + str(err))
		if request.has("promise"):
			request["promise"].set_result({"error": "request_error", "response": null, "datasize": 0})
		return
	
	print("Requesting...\n\tCommand: " + request['command'] + "\n\tBody: " + body)

func post(method: String, data: Dictionary) -> Dictionary:	
	var promise = Promise.new()
	request_queue.append({"command": method, "data": data, "promise": promise})
	return await promise.async()

func handle_error(error_message: String) -> void:
	push_error(error_message)

func set_server_address(address: String) -> void:
	server_address = "http://%s:8080/api/Session.php" % address
