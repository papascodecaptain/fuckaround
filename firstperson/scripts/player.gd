extends CharacterBody3D

#player nodes
@onready var nek: Node3D = $nek
@onready var head: Node3D = $nek/head
@onready var eyes: Node3D = $nek/head/eyes

@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var crouching_collision_shape: CollisionShape3D = $crouching_collision_shape
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var camera_3d: Camera3D = $nek/head/eyes/Camera3D
@onready var animation_player: AnimationPlayer = $nek/head/eyes/AnimationPlayer
@onready var vision_cast: RayCast3D = $nek/head/eyes/Camera3D/vision_cast
@onready var actionable_finder: Area3D = $actionable_finder


#speed vars
var interact_cast_result
var current_speed = 5.0
var lerp_speed = 10.0
var air_lerp_speed = 3.0

const walking_speed = 5.0
const sprinting_speed = 8.0
const crouching_speed = 3.0
#states

var walking = false
var sprinting = false
var crouching = false 
var free_looking = false

#head bob

const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.3

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0

#movement vars

const jump_velocity = 4.5

var crouching_depth = -0.5

var free_look_tilt_amount = 5.0

var last_velocity = Vector3.ZERO

#input vars

var direction = Vector3.ZERO
const mouse_sens = 0.10

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent):
	if Input.is_action_pressed("ui_cancel"):
	
	if Input.is_action_just_pressed("talk"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		var actionable = actionable_finder.get_overlapping_areas()
		if actionable.size() > 0:
			actionable[0].action()
			return
			
		
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
func _input(event):
	
	#mouse looking logic
	
	if event is InputEventMouseMotion:
		if free_looking:
			nek.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			nek.rotation.y = clamp(nek.rotation.y,deg_to_rad(-100),deg_to_rad(100))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-65),deg_to_rad(89))
		
		
func _physics_process(delta):
	
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	#handle movement state
	
	#crouching
	
	if Input.is_action_pressed("crouch"):
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y,crouching_depth,delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		walking = false
		sprinting = false
		crouching = true 

	elif !ray_cast_3d.is_colliding():
		
		#standing
		
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		
		head.position.y = lerp(head.position.y,0.0,delta*lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			#sprinting
			current_speed = sprinting_speed
			
			walking = false
			sprinting = true
			crouching = false 
		else:
			
	#walking
	
			current_speed = walking_speed
			
			walking = true
			sprinting = false
			crouching = false
			
	
	#handle free looking
	
	if Input.is_action_pressed("free_looking"):
		free_looking = true
		camera_3d.rotation.z = -deg_to_rad(nek.rotation.y*free_look_tilt_amount)
	else:
		free_looking = false
		nek.rotation.y = lerp(nek.rotation.y,0.0,delta*lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.z,0.0,delta*lerp_speed)
		
		#head bob
		
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed*delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed*delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed*delta
		
	if is_on_floor() && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5
	

		eyes.position.y = lerp(eyes.position.y,head_bobbing_vector.y*(head_bobbing_current_intensity/2.0),delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,head_bobbing_vector.x*head_bobbing_current_intensity,delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y,0.0,delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,0.0,delta*lerp_speed)
		
	# Add the gravity.
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	
	if Input.is_action_just_pressed("jumpup") and is_on_floor():
		velocity.y = jump_velocity
		animation_player.play("jump")
		
		if is_on_floor():
			if last_velocity.y < 0.0:
				animation_player.play("landing")
		
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*air_lerp_speed)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
		
	
		last_velocity = velocity
	
	move_and_slide()
	
	
	
	
	
	
