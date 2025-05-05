extends Camera2D

var zoom_speed = 0.1
var player: Node2D

func _ready():
	# Get reference to the player node (adjust the path accordingly)
	player = get_node("../Player")
	
	# Set this camera as the active one
	make_current()
	
	# Enable position smoothing for smooth following
	position_smoothing_enabled = true
	position_smoothing_speed = 5  # Adjust speed as needed
	
	# Set closer zoom (increase values to zoom in more)
	zoom = Vector2(1.5, 1.5)

func _process(delta):
	if player:
		# Update camera position to follow player
		global_position = player.global_position
