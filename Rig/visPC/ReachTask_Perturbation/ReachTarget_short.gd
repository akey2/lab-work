extends Node2D

var color = Color.RED
var filled = true
var size = 50
var size_scaled = 50

func set_color(r, g, b):
	color = Color8(r, g, b)
	self.queue_redraw()
	
func set_filled(fill):
	filled = fill
	self.queue_redraw()
	
func set_scaling(scaleperc):
	size_scaled = (scaleperc/100)*size
	self.queue_redraw()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
	
func _draw():
	draw_rect(Rect2(Vector2(-size/2,-size/2), Vector2(size, size)), color, filled)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
