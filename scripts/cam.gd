extends CharacterBody3D

var prev_x = 0
var prev_y = 0
var now
var rotation_velocity_x = 0
var rotation_velocity_y = 0
var damping = 0.9  # Damping factor for deceleration
var camera_distance: float = 10.0  # Initial distance from the subject (the `Node3D`)
var target_camera_distance: float = 10.0  # Target zoom distance
var vertical_angle = 0.0
var horizontal_angle = 0.0
var subject_position  # Position of the subject (the `Node3D`)
var zoom_speed = 0.1  # Speed of zoom
var min_zoom = 1.0  # Minimum zoom distance
var max_zoom = 5.0  # Maximum zoom distance

var camera  # Reference to the Camera3D node
var subject  # Reference to the subject (Node3D)

var current_character
var character_scenes = [
	"res://female1.tscn",
	"res://male1.tscn"
]
var current_index = 0

# Function to switch character
func switch_character():
	# Remove the current character
	if current_character:
		current_character.queue_free()
	
	# Load the new character scene
	var new_character_scene = load(character_scenes[current_index]) # Ensure it's a PackedScene
	var packed_scene = new_character_scene as PackedScene
	
	if packed_scene:
		current_character = packed_scene.instantiate() # Create an instance of the character
	
		# Add the new character to the scene
		add_child(current_character)
	
	# Update index for the next switch
	current_index = (current_index + 1) % character_scenes.size()


func _ready():
	# Assign references to the camera and subject (Node3D)
	camera = $Node3D/Camera3D
	subject = $Node3D
	subject_position = subject.global_position  # Assuming the subject is the target
	# $"Model/AnimationPlayer".play("Imported/idle2")
	# switch_character()

func _input(event):
	# Detect mouse wheel scroll event for zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_camera_distance -= zoom_speed  # Zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_camera_distance += zoom_speed  # Zoom out

	# Clamp target zoom distance to avoid going too close or too far
	target_camera_distance = clamp(target_camera_distance, min_zoom, max_zoom)

func _physics_process(delta):
	now = Input.get_last_mouse_velocity()

	# Update rotation velocity when the mouse is pressed
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		rotation_velocity_x = now[0]  # Horizontal rotation
		rotation_velocity_y = now[1]  # Vertical rotation

	# Decelerate the rotation velocities
	rotation_velocity_x *= damping
	rotation_velocity_y *= damping

	# Update angles based on velocity and delta
	horizontal_angle += -rotation_velocity_x * delta * 0.01  # Horizontal rotation
	vertical_angle += rotation_velocity_y * delta * 0.01  # Vertical rotation

	# Clamp vertical angle to avoid flipping the camera (e.g., between -10 to 85 degrees)
	vertical_angle = clamp(vertical_angle, deg_to_rad(-15), deg_to_rad(85))

	# Smoothly interpolate the camera distance towards the target distance
	camera_distance = lerp(camera_distance, target_camera_distance, 0.1)

	# Calculate new camera position based on the angles and distance from the subject
	var camera_offset = Vector3(
		camera_distance * cos(vertical_angle) * sin(horizontal_angle),
		camera_distance * sin(vertical_angle),
		camera_distance * cos(vertical_angle) * cos(horizontal_angle)
	)

	# Set the camera's position and make it look at the subject
	camera.global_position = subject_position + camera_offset
	camera.look_at(subject_position, Vector3(0, 1, 0))  # Up vector set to Y-axis
