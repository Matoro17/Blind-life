extends Node

# Preload the enemy scene (update the path to your enemy scene)
const Enemy = preload("res://scenes/enemy.tscn")
@onready var maze_generator = $MazeGenerator
@onready var player = $Player
var viewport_rect

func _ready():
	# Get the screen/viewport size
	viewport_rect = get_viewport().get_visible_rect()
	#maze_generator.generate_maze()
	player.global_position = maze_generator.get_world_position(maze_generator.start_position)
	#$Camera2D.setup_limits(maze_generator)
	
	#$MazeGenerator.generate_maze()
#	$Player.initialize($MazeGenerator)
	spawn_enemies()
	
func _on_maze_generator_maze_generated():
	# Chamado quando o labirinto terminar de gerar
	spawn_enemies()
	
	
func spawn_enemies():
	# Spawn 10 enemies
	for i in range(10):
		# Create a new enemy instance
		var enemy = Enemy.instantiate()
		
		# Generate random coordinates within the viewport
		var random_x = randf_range(0, viewport_rect.size.x)
		var random_y = randf_range(0, viewport_rect.size.y)
		
		# Set enemy position
		enemy.position = Vector2(random_x, random_y)
		
		# Add enemy to the scene
		add_child(enemy)
