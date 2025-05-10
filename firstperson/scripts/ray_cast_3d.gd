extends RayCast3D
@onready var ray_cast_3d: RayCast3D = $vision_cast
@onready var prompt: Label = $prompt

func _physics_process(delta):
	
	prompt.text = ""
	if is_colliding():
		prompt.text = "interact"
	
