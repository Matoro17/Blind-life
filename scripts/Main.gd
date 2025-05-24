extends Node

# Preload the enemy scene (update the path to your enemy scene)
const Enemy = preload("res://scenes/enemy.tscn")
@onready var maze_generator_scene = preload("res://scenes/MazeGenerator.tscn")
@onready var player = $Player
var viewport_rect
var maze_generator_instance = null

func _ready():
	viewport_rect = get_viewport().get_visible_rect()
	
	# Instance and add the maze generator
	maze_generator_instance = maze_generator_scene.instantiate()
	add_child(maze_generator_instance)
	# Connect to the maze generated signal
	maze_generator_instance.connect("maze_generated", _on_maze_generator_maze_generated)
	spawn_enemies()
	
func _on_maze_generator_maze_generated():
	# Chamado quando o labirinto terminar de gerar
	player.global_position = maze_generator_instance.start_position
	spawn_enemies()
	
func open_braille_terminal():
	var terminal = preload("res://scenes/terminal.tscn").instantiate()
	#terminal.connect(advance_level)
	add_child(terminal)
	
func spawn_enemies():
	for i in range(2):
		var enemy = Enemy.instantiate()
		var random_x = randf_range(0, viewport_rect.size.x)
		var random_y = randf_range(0, viewport_rect.size.y)
		enemy.position = Vector2(random_x, random_y)
		add_child(enemy)
