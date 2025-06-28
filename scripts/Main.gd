extends Node

const Enemy = preload("res://scenes/enemy.tscn")
@onready var maze_generator_scene = preload("res://scenes/MazeGenerator.tscn")
@onready var PlayerScene = preload("res://scenes/Player.tscn")
@onready var collectibles_ui_scene = preload("res://scenes/collectibles_ui.tscn")

@onready var main_music = AudioStreamPlayer.new()

var player: Node2D = null
var viewport_rect
var maze_generator_instance = null
var collectibles_ui_instance: CanvasLayer = null # NEW: Reference to the UI instance
var current_level_key_braille_letter: String = "" # NEW: Stores the letter for the current door
var collected_items_letters: Array[String] = [] # NEW: Stores collected item letters
const TERMINAL_SCENE = preload("res://scenes/terminal.tscn")
var current_terminal_instance = null
var correct_braille_code = null

var current_level: int = 1

func _ready():
	viewport_rect = get_viewport().get_visible_rect()
	print("🧭 Viewport size: ", viewport_rect.size)

	print("🧱 Instantiating MazeGenerator...")
	maze_generator_instance = maze_generator_scene.instantiate()
	add_child(maze_generator_instance)
	print("✅ MazeGenerator added to scene.")

	maze_generator_instance.connect("maze_generated", _on_maze_generator_maze_generated)
	
	collectibles_ui_instance = collectibles_ui_scene.instantiate()
	add_child(collectibles_ui_instance)
	correct_braille_code = maze_generator_instance.getCurrentCode()
	
	var music_stream = load("res://audio/full-sound-track.mp3")
	main_music.stream = music_stream
	main_music.autoplay = true
	main_music.volume_db = -20
	add_child(main_music)
	main_music.play()

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
			if player.has_signal("item_collected"): # Always good to check if signal exists
				player.connect("item_collected", _on_player_item_collected)
			else:
				printerr("❌ Player scene does not have 'item_collected' signal! Check player.gd")

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
	current_level_key_braille_letter = maze_generator_instance.current_item_letter
	print("🔑 Current level key braille letter: ", current_level_key_braille_letter)

	spawn_enemies()
	
	# Connect the door signal directly from the MazeGenerator's door instance
	# MazeGenerator should have a reference to its door or emit a signal with the door.
	# For simplicity, we'll iterate through maze_generator_instance's children
	# as the door is a child of maze_generator_instance.
	var door_found = false
	for child in maze_generator_instance.get_children():
		if child.is_in_group("door"): # Ensure your door is in the "door" group
			var door_node = child as Node
			# Disconnect any previous connections to prevent multiple calls
			if door_node.is_connected("door_opened_correctly", Callable(self, "_on_door_opened")):
				door_node.disconnect("door_opened_correctly", Callable(self, "_on_door_opened"))

			# Connect the signal from the newly created door
			var success := door_node.connect("door_opened_correctly", Callable(self, "_on_door_opened"))
			print("🔗 Conectando porta (de MazeGenerator) ao Main.gd. Sucesso: ", success)
			door_found = true
			break
	if not door_found:
		printerr("❌ Could not find a door in MazeGenerator children to connect.")



func _on_door_opened():
	print("🚪 Porta aberta com sucesso! Avançando para o próximo nível...")
	advance_to_next_level()

func open_braille_terminal():
	if current_terminal_instance: # Don't open multiple terminals
		return

	current_terminal_instance = TERMINAL_SCENE.instantiate()
	get_tree().get_root().add_child(current_terminal_instance)

	# Pass the required braille code to the terminal
	current_terminal_instance.set_required_braille_letter(correct_braille_code)

	# Connect the terminal's signal to know if the code was entered correctly
	if current_terminal_instance.has_signal("braille_code_entered"):
		current_terminal_instance.connect("braille_code_entered", _on_braille_code_entered)
	else:
		printerr("❌ Terminal scene does not have 'braille_code_entered' signal!")

	# Optional: center the terminal or display it correctly
	if current_terminal_instance.has_method("popup_centered"):
		current_terminal_instance.call("popup_centered")
	else:
		current_terminal_instance.show()

func spawn_enemies():
	var room_keys = maze_generator_instance.rooms.keys()
	var enemy_count = maze_generator_instance.get_meta("enemy_count") if maze_generator_instance.has_meta("enemy_count") else 0

	for i in range(enemy_count):
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
		
func _on_player_item_collected(item_letter: String, item_texture: Texture2D):
	print("Item collected in Main: ", item_letter)
	if not collected_items_letters.has(item_letter): # Avoid adding duplicates if the player somehow collects the same item type twice
		collected_items_letters.append(item_letter)
		if collectibles_ui_instance:
			collectibles_ui_instance.add_item_texture(item_texture)
		
		# Check if the collected item is the key for the current level's door
		if item_letter == current_level_key_braille_letter:
			print("🎉 Collected the correct item for this level! Door code updated.")
			
			# Find the instantiated door and set its correct braille code
			# It's crucial that the door exists in the scene tree when this is called.
			var found_door = false
			for child in get_children():
				if child is Node2D and child.is_in_group("door"): # Ensure your door is in the "door" group
					var door_node = child as Node
					if door_node.has_method("set_correct_braille_code"):
						child.connect("door_opened_correctly", Callable(self, "_on_door_opened"))
						print("🔗 Tentando conectar sinal da porta: ", child.name)
						var success := child.connect("door_opened_correctly", Callable(self, "_on_door_opened"))
						print("✅ Conexão feita? ", success)
						door_node.set_correct_braille_code(item_letter)
						found_door = true
						break # Assuming only one door per level for now
			if not found_door:
				printerr("❌ Could not find an instantiated door in the 'door' group to set its code.")
				
func _on_braille_code_entered(is_correct: bool):
	print("Terminal signal received! Code entered correctly: ", is_correct)

	if is_correct:
		print("🎉 Código Braille correto! Iniciando próximo nível...")
		advance_to_next_level()
	else:
		print("❌ Código Braille incorreto. Tente novamente!")

	if current_terminal_instance:
		current_terminal_instance.queue_free()
		current_terminal_instance = null

		
func advance_to_next_level():
	current_level += 1
	
	# Aumentar complexidade com base no nível
	var new_max_rooms = clamp(3 + current_level * 2, 3, 20)
	var new_enemy_count = clamp(current_level - 1, 0, 10)

	# Remover o labirinto antigo
	if maze_generator_instance and is_instance_valid(maze_generator_instance):
		maze_generator_instance.queue_free()

	# Criar novo labirinto com novo tamanho e número de inimigos
	maze_generator_instance = maze_generator_scene.instantiate()
	add_child(maze_generator_instance)

	maze_generator_instance.max_rooms = new_max_rooms
	maze_generator_instance.room_size = Vector2(640, 640) # Se quiser manter fixo

	# Reconectar o sinal
	maze_generator_instance.connect("maze_generated", _on_maze_generator_maze_generated)

	# Salvar código correto (será sobrescrito ao gerar)
	correct_braille_code = maze_generator_instance.getCurrentCode()

	# Atualize o contador de inimigos a spawnar
	maze_generator_instance.set_meta("enemy_count", new_enemy_count)

	print("🚀 Avançando para o nível ", current_level)

# NEW: Helper function to get braille code for a letter
func get_braille_code_for_letter(letter: String) -> Array:
	# This mapping must align with your Terminal's BrailleGrid structure
	# true = dot pressed, false = dot not pressed
	match letter.to_lower():
		"a": return [true, false, false, false, false, false] #
		"b": return [true, false, true, false, false, false]  #
		"c": return [true, true, false, false, false, false]  # 
		"d": return [true, true, false, true, false, false]   # 
		"e": return [true, false, false, true, false, false]  # 
		# ADD MORE LETTERS HERE AS NEEDED FOR YOUR GAME
		_:
			printerr("Braille code for letter '%s' not defined!" % letter)
			return [] # Default empty or error
