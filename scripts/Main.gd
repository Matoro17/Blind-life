extends Node

const Enemy = preload("res://scenes/enemy.tscn")
@onready var maze_generator_scene = preload("res://scenes/MazeGenerator.tscn")
@onready var PlayerScene = preload("res://scenes/Player.tscn")

var player: Node2D = null
var viewport_rect
var maze_generator_instance = null

func _ready():
	viewport_rect = get_viewport().get_visible_rect()
	print("🧭 Viewport size: ", viewport_rect.size)

	print("🧱 Instantiating MazeGenerator...")
	maze_generator_instance = maze_generator_scene.instantiate()
	add_child(maze_generator_instance)
	print("✅ MazeGenerator added to scene.")

	maze_generator_instance.connect("maze_generated", _on_maze_generator_maze_generated)
	spawn_enemies()

func _on_maze_generator_maze_generated():
	print("🌀 Maze generation completed.")
	print("📌 Trying to get start room at: ", maze_generator_instance.start_room_pos)

	var start_data = maze_generator_instance.rooms.get(maze_generator_instance.start_room_pos)

	if start_data:
		print("✅ Start room data found.")
		var start_room = start_data["node"]
		print("📦 Start room node: ", start_room)

		if start_room.has_node("SpawnPoint"):
			var spawn_point = start_room.get_node("SpawnPoint")
			print("🎯 SpawnPoint found: ", spawn_point)

			print("🧍 Instantiating Player...")
			player = PlayerScene.instantiate()

			if player:
				spawn_point.add_child(player)
				player.position = Vector2.ZERO
				print("✅ Player instantiated at SpawnPoint.")
				# Camera now handled internally by player
			else:
				printerr("❌ Player instantiation failed!")
		else:
			printerr("⚠️ No SpawnPoint found in the start room!")
	else:
		printerr("❌ Start room not found in room dictionary!")

	spawn_enemies()

func open_braille_terminal():
	var terminal = preload("res://scenes/terminal.tscn").instantiate()
	add_child(terminal)

func spawn_enemies():
	var room_keys = maze_generator_instance.rooms.keys()
	for i in range(2):
		var enemy = Enemy.instantiate()

		var room_pos = room_keys[randi() % room_keys.size()]
		while room_pos == maze_generator_instance.start_room_pos:
			room_pos = room_keys[randi() % room_keys.size()]

		var room_data = maze_generator_instance.rooms[room_pos]
		var room_node = room_data["node"]
		var spawn_position = room_node.global_position + maze_generator_instance.room_size / 2

		enemy.global_position = spawn_position
		add_child(enemy)
		print("👾 Enemy spawned at: ", enemy.global_position)
