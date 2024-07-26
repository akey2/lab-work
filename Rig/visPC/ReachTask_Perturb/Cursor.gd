extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

func _draw():
	#print(self.global_position)
	draw_circle(Vector2(0,0),20, Color.WHITE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#self.queue_redraw()
	pass
