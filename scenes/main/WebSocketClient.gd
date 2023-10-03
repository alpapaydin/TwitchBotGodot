extends Node

var socket = WebSocketPeer.new()
var reconnect_delay = 1.0
var max_reconnect_delay = 16.0

func _ready():
	connect_to_server()

func connect_to_server():
	print("Attempting to connect to server...")
	socket.connect_to_url("wss://opentun.nl/ws")
	set_process(true)  # Enable processing.

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	# Data received from server
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			print("Packet received: ", packet)
	
	# Closing state; continue polling to close cleanly
	elif state == WebSocketPeer.STATE_CLOSING:
		print("Socket is closing...")
	
	# Closed; handle reconnect
	elif state == WebSocketPeer.STATE_CLOSED:
		handle_socket_closed()
		reconnect()

func reconnect():
	# Attempt to reconnect with exponential backoff
	reconnect_delay = min(max_reconnect_delay, reconnect_delay * 2)
	print("Reconnecting in ", reconnect_delay, " seconds...")
	await get_tree().create_timer(reconnect_delay).timeout
	connect_to_server()

func handle_socket_closed():
	var code = socket.get_close_code()
	var reason = socket.get_close_reason()
	print("WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1])
	set_process(false)  # Stop processing.
