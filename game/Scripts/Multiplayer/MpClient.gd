extends Node

var socket = WebSocketPeer.new()

func connect_to_host(host_ip: String):
	var err = socket.connect_to_url(host_ip)
	if err == OK:
		print("Connecting to %s..." % host_ip)
		
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout
		
		# Try send test data
		print("> Sending test packet.")
		socket.send_text("Test packet")
	else:
		push_error("Unable to connect.")
		set_process(false)
