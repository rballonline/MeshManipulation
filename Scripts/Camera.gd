extends Camera


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var cube = get_node("/root/Main/Meshes/Cube")
	look_at(cube.global_transform.origin, Vector3(0,1,0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
