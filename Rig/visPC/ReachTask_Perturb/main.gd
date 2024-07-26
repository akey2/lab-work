extends Node

var socket
var udpthread
var vistree
var packetnum

# Called when the node enters the scene tree for the first time.
func _ready():
	
	packetnum = 0
	
	vistree = get_node("VisScene").get_children()
	vistree[0].set_scaling(100)
	# Set up UDP socket:
	socket = PacketPeerUDP.new()
	var err = socket.bind(11114, "192.168.44.2",65536)
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
		#print("# packets: ", socket.get_available_packet_count())
		var data
		while socket.get_available_packet_count() > 0:
			data = socket.get_packet()
		_parse_packet(data)
		#_parse_packet(socket.get_packet())
		
	pass
	
func _parse_packet(packet:PackedByteArray):
	
	var pnumvistree = packet.decode_u32(0)   # 1st uint32 is a packet count
	
	#if (packetnum != null && (packetnum + 1) != pnum):
	#	print("We missed a packet")
	#print("# missed packets: ", pnum - packetnum - 1)
	#packetnum = pnum
	
	var idx = 4
	while (idx < packet.size()):
		var id = packet[idx] - 1	 # id of resource to update
		var property = packet[idx+1] # property to update
		match (property):
			1:                          # position (2 uint16s)
				vistree[id].position = Vector2(packet.decode_u16(idx+2), packet.decode_u16(idx+4))
				#print("Position (id, left, top)", packet.decode_u16(idx+4))
				idx += 6
			2:                          # visibility (1 uint8)
				vistree[id].visible = packet[idx+2]
				idx += 3
			3:                          # color (3 uint8s)
				
				vistree[id].set_color(packet[idx+2], packet[idx+3], packet[idx+4])
				idx += 5
			4:                          # scaling (1 uint8)
				vistree[id].set_scaling(float(packet[idx+2]));
				idx += 3
			5:                          # fill (1 uint8)
				vistree[id].set_filled(packet[idx+2])
				idx += 3
			_:
				print("Could not match requested property")
		vistree[id].queue_redraw()
	pass
