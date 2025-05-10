extends CSGBox3D
@onready var vision_cast: RayCast3D = $"../../player/nek/head/eyes/Camera3D/vision_cast"
@onready var door: CSGBox3D = $"."
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _process(delta: float) -> void:

	if vision_cast.is_colliding():
		
		if Input.is_action_pressed("interact"):
			animation_player.play("open")
	
	
