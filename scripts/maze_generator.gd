extends Node2D

@export var max_rooms := 5
@export var room_size := Vector2(640, 640)
@export var start_room_scene: PackedScene = preload("res://scenes/room.tscn")
@export var enemy_room_scene: PackedScene = preload("res://scenes/room.tscn")
@export var end_room_scene: PackedScene = preload("res://scenes/room.tscn")
@export var door_scene: PackedScene = preload("res://scenes/door.tscn")
@export var item_scene: PackedScene = preload("res://scenes/item.tscn")
var start_room_image: Texture2D = preload("res://art/arrow_keys.jpg")
const WALL_SCENE := preload("res://scenes/Wall.tscn")

var current_item_letter: String = "" # New: Store the letter of the item for the current level

# List of possible braille letters for items
const BRAILLE_LETTERS = ["a", "b", "c", "d", "e"] # Extend as needed

var enemy_count = 2

var rooms = {}  # Dictionary with key: Vector2i (grid position), value: room data
var start_room_pos = Vector2i(0, 0)
var end_room_pos: Vector2i
var start_position: Vector2 = Vector2.ZERO
signal maze_generated

func _ready():
	randomize()
	generate_dungeon()
	
func getCurrentCode():
	return current_item_letter

func generate_dungeon():
	for child in get_children():
		child.queue_free()
	rooms.clear()
	current_item_letter = BRAILLE_LETTERS.pick_random()
	print("🔑 Maze key for this level is: ", current_item_letter)

	add_room(start_room_pos, "start")

	var rooms_to_process = [start_room_pos]
	var rooms_created = 1

	while rooms_created < max_rooms and not rooms_to_process.is_empty():
		var current_pos = rooms_to_process.pop_front()
		var directions = get_random_directions()

		for dir in directions:
			var new_pos = current_pos + dir

			if rooms.has(new_pos):
				continue

			if rooms_created >= max_rooms:
				break

			add_room(new_pos, "enemy")
			connect_rooms(current_pos, new_pos)
			rooms_to_process.append(new_pos)
			rooms_created += 1

	# ✅ Configure exits AFTER all connections are done
	for room_data in rooms.values():
		room_data["node"].configure_exits(room_data["exits"])

	find_and_mark_end_room()
	call_deferred("emit_signal", "maze_generated")
		# DEBUG
	print("Calling item placement")
	call_deferred("place_item_in_random_room")

func place_item_in_random_room():
	if item_scene == null:
		printerr("❌ No item scene provided!")
		return

	var candidate_rooms := []
	for room_pos in rooms:
		var type = rooms[room_pos]["type"]
		if type == "enemy" and room_pos != start_room_pos and room_pos != end_room_pos:  # or type != "start" and type != "end"
			candidate_rooms.append(room_pos)

	if candidate_rooms.is_empty():
		print("⚠️ No suitable rooms to place item.")
		return

	var selected_pos = candidate_rooms.pick_random()
	var room_node = rooms[selected_pos]["node"]
	var room_center = Vector2(selected_pos) * room_size + room_size / 2

	var item = item_scene.instantiate()
		# New: Randomly select a braille letter for this level's key item
	item.letter = current_item_letter # Assign the chosen letter to the item instance
	
	var margin = 32  # Deixar um espaço de margem para não colar nas bordas
	var random_x = randf_range(margin, room_size.x - margin)
	var random_y = randf_range(margin, room_size.y - margin)
	item.position = Vector2(random_x, random_y)
	room_node.add_child(item)

	print("🎁 Item placed in room at:", selected_pos, " with letter: ", current_item_letter)


func add_room(grid_pos: Vector2i, room_type: String):
	print("Room added at grid: ", grid_pos)
	if rooms.has(grid_pos):
		return

	var new_room = instantiate_room_scene(room_type)
	new_room.room_type = room_type
	var room_world_position = Vector2(grid_pos) * room_size
	new_room.position = room_world_position
	add_child(new_room)

	rooms[grid_pos] = {
		"position": grid_pos,
		"type": room_type,
		"exits": [],
		"node": new_room
	}

	if room_type == "start":
		start_position = room_world_position + room_size / 2
		var image_node = Sprite2D.new()
		image_node.texture = start_room_image
		image_node.modulate.a = 0.1
		image_node.scale = Vector2(0.2, 0.2)
		image_node.position = room_size / 2  # Coloca no centro da sala
		# ✅ Adicionar 3 paredes acima do sprite
		var base_pos = image_node.position + Vector2(0, -48)  # Um pouco acima (ajuste a distância como quiser)
		var spacing = 32  # Espaçamento horizontal entre as paredes
		for i in range(3):
			var wall_instance = WALL_SCENE.instantiate()
			wall_instance.position = base_pos + Vector2(0 , (i - 1) * spacing)  # Centraliza as 3 paredes
			new_room.add_child(wall_instance)
		new_room.add_child(image_node)
		

func connect_rooms(pos_a: Vector2i, pos_b: Vector2i):
	var direction = pos_b - pos_a
	rooms[pos_a]["exits"].append(direction)
	rooms[pos_b]["exits"].append(-direction)

func instantiate_room_scene(room_type: String) -> Node2D:
	match room_type:
		"start":
			if start_room_scene:
				return start_room_scene.instantiate()
		"end":
			if end_room_scene:
				return end_room_scene.instantiate()
		_:
			if enemy_room_scene:
				return enemy_room_scene.instantiate()

	printerr("Room scene not assigned for type:", room_type)
	return Node2D.new()

func get_random_directions() -> Array:
	var directions = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
	directions.shuffle()
	return directions

func find_and_mark_end_room():
	var farthest_distance = 0
	var farthest_room_pos = start_room_pos

	for room_pos in rooms.keys():
		var distance = (room_pos - start_room_pos).length_squared()
		if distance > farthest_distance:
			farthest_distance = distance
			farthest_room_pos = room_pos

	end_room_pos = farthest_room_pos

	var old_node = rooms[end_room_pos]["node"]
	if is_instance_valid(old_node):
		old_node.queue_free()

	var end_room = instantiate_room_scene("end")
	end_room.position = Vector2(end_room_pos) * room_size
	add_child(end_room)

	rooms[end_room_pos]["node"] = end_room
	rooms[end_room_pos]["type"] = "end"

	var exits = rooms[end_room_pos]["exits"]
	end_room.call_deferred("configure_exits", exits)

	if exits.size() > 0 and door_scene:
		var selected_dir = exits.pick_random()
		var adjacent_pos = end_room_pos + selected_dir
		print("🗝️ Adding door between ", end_room_pos, " and ", adjacent_pos)

		var door = door_scene.instantiate()
		if door.has_node("Door"):
			var door_logic = door.get_node("Door")
			door_logic.set_correct_braille_code(current_item_letter)
		else:
			printerr("❌ Porta instanciada, mas não foi encontrado o nó 'Door' dentro dela.")
		var mid_pos = (Vector2(end_room_pos) + Vector2(adjacent_pos)) * room_size / 2
		door.position = mid_pos

		match selected_dir:
			Vector2i.LEFT:
				door.rotation_degrees = 270
			Vector2i.RIGHT:
				door.rotation_degrees = 90
			Vector2i.UP:
				door.rotation_degrees = 0
			Vector2i.DOWN:
				door.rotation_degrees = 180

		add_child(door)
	else:
		print("⚠️ Could not add door: exits.size() =", exits.size(), ", door_scene =", door_scene)

func get_reachable_rooms_excluding_blocked(blocked_a: Vector2i, blocked_b: Vector2i) -> Array[Vector2i]:
	var visited := {}
	var queue := [start_room_pos]
	visited[start_room_pos] = true

	while not queue.is_empty():
		var current = queue.pop_front()
		for dir in rooms[current]["exits"]:
			var neighbor = current + dir

			# Skip blocked connection (the door)
			if (current == blocked_a and neighbor == blocked_b) or (current == blocked_b and neighbor == blocked_a):
				continue

			if not visited.has(neighbor) and rooms.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)

	return visited.keys()
