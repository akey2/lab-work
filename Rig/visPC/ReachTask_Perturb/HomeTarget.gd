extends Node2D

var color = Color.RED
var filled = true
var size = Vector2(50, 50)
var size_scaled = size

func set_color(r, g, b):
	color = Color8(r, g, b)
	#self.queue_redraw()
	
func set_filled(fill):
	filled = fill
	#self.queue_redraw()
	
func set_scaling(scaleperc):
	size_scaled = (scaleperc/100)*size
	#self.queue_redraw()
	


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.

func _draw():
	#print(self.global_position)
	if (filled):
		draw_rect(Rect2(Vector2(0,0), size_scaled), color)
	else:
		draw_rect(Rect2(Vector2(0,0), size_scaled), color)
		var bgcolor = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
		draw_rect(Rect2(Vector2(2,2), size_scaled-Vector2(4,4)), bgcolor)
	#draw_rect(Rect2(Vector2(0,0), size_scaled), color)
	#draw_rect(Rect2(Vector2(800 - (size[0]/2),900 - size[1]), size), color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(self.position)
	#self.queue_redraw()
	pass
