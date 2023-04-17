extends Node

var socket
var udpthread
var vistree

# Called when the node enters the scene tree for the first time.
func _ready():
	
	vistree = get_node("VisScene").get_children()
	
	# Set up UDP socket:
	socket = PacketPeerUDP.new()
	var err = socket.bind(11114, "127.0.0.1", 65536)
	if (err):
		print("Could not bind UDP socket")
	
	# Set up UDPListener thread:
	udpthread = Thread.new()
	err = udpthread.start(Callable(self, "_udp_recv_thread").bind(null), Thread.PRIORITY_NORMAL)
	if (err):
		print("Could not start thread")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

	
func _udp_recv_thread(userdata):
	while true:
		if (socket.wait() != OK):
			print("udp error")
		_parse_packet(socket.get_packet())
	pass
	
func _parse_packet(packet:PackedByteArray):
	var idx = 0
	while (idx < packet.size()):
		var id = packet[idx]		 # id of resource to update
		var property = packet[idx+1] # property to update
		match (property):
			1:                          # position (2 uint16s)
				vistree[id].position = Vector2(packet.decode_u16(idx+2), packet.decode_u16(idx+4))
				idx += 6
			2:                          # visibility (1 uint8)
				vistree[id].visible = packet[idx+2] as bool;
				idx += 3
			3:                          # color (3 uint8s)
				vistree[id].set_color(packet[idx+2], packet[idx+3], packet[idx+4])
				idx += 5
			_:
				print("Could not match requested property")
	
	pass
