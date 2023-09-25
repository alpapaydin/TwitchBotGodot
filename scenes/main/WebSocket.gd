extends Node

var tcpserver
var socket = WebSocketPeer.new()

func _ready():
	tcpserver = TCPServer.new()
	tcpserver.listen(8765, "127.0.0.1")
	
func _process(_delta):
	if tcpserver.is_connection_available():
		var conn = tcpserver.take_connection()
		#print(conn.get_status())
		socket.accept_stream(conn)
		#print(stream)
	var state = socket.get_ready_state()
	#print(state)
	socket.poll()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			#print("Packet: ", packet)
			var message = ""
			for i in packet:
				message += char(i)
			#print(message)
			Twitch.gotMessage(message)
			socket.close()
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		pass
		#var code = socket.get_close_code()
		#var reason = socket.get_close_reason()
		#print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])

		
