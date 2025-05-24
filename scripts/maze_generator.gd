extends Node2D

@export var max_rooms := 2
@export var room_size := Vector2(640, 640)  # 32 * 200, 500)
@export var start_room_scene: PackedScene = preload("res://scenes/room.tscn")
@export var enemy_room_scene: PackedScene = preload("res://scenes/room.tscn")
@export var end_room_scene: PackedScene = preload("res://scenes/room.tscn")

var rooms = {}  # Dictionary with key: Vector2i (grid position), value: room data
var start_room_pos = Vector2i(0, 0)
var end_room_pos: Vector2i
var start_position: Vector2 = Vector2.ZERO
signal maze_generated 

func _ready():
	randomize()
	generate_dungeon()

func generate_dungeon():
	# Clear previous dungeon
	for child in get_children():
		child.queue_free()
	rooms.clear()
	
	# Add start room
	add_room(start_room_pos, "start")
	
	var rooms_to_process = [start_room_pos]
	var rooms_created = 1
	
	while rooms_created < max_rooms and not rooms_to_process.is_empty():
		var current_pos = rooms_to_process.pop_front()
		var directions = get_random_directions()

		for dir in directions:
			var new_pos = current_pos + dir

			if rooms.has(new_pos):
				continue  # Already placed

			if rooms_created >= max_rooms:
				break

			# Add the new room
			add_room(new_pos, "enemy")
			connect_rooms(current_pos, new_pos)
			# Update exit config in both rooms
			rooms[current_pos]["node"].configure_exits(rooms[current_pos]["exits"])
			rooms[new_pos]["node"].configure_exits(rooms[new_pos]["exits"])
			rooms_to_process.append(new_pos)
			rooms_created += 1
	
	find_and_mark_end_room()
	emit_signal("maze_generated") 

func add_room(grid_pos: Vector2i, room_type: String):
	var new_room = instantiate_room_scene(room_type)
	var room_world_position = (Vector2(grid_pos) * room_size).snapped(Vector2(32, 32))
	new_room.position = (Vector2(grid_pos) * room_size).snapped(Vector2(32, 32))
	add_child(new_room)

	var exits = rooms.get(grid_pos, {}).get("exits", [])

	rooms[grid_pos] = {
		"position": grid_pos,
		"type": room_type,
		"exits": [],
		"node": new_room
	}
	
	if room_type == "start":
		start_position = room_world_position + room_size / 2

func connect_rooms(pos_a: Vector2i, pos_b: Vector2i):
	var direction = pos_b - pos_a
	rooms[pos_a]["exits"].append(direction)
	rooms[pos_b]["exits"].append(-direction)

func instantiate_room_scene(room_type: String) -> Node2D:
	var scene: PackedScene
	
	match room_type:
		"start":
			if !start_room_scene:
				printerr("Start Room Scene not assigned!")
				return Node2D.new()
			scene = start_room_scene
		
		"end":
			if !end_room_scene:
				printerr("End Room Scene not assigned!")
				return Node2D.new()
			scene = end_room_scene
		
		_:
			if !enemy_room_scene:
				printerr("Enemy Room Scene not assigned!")
				return Node2D.new()
			scene = enemy_room_scene
	
	return scene.instantiate()

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
	rooms[end_room_pos]["type"] = "end"
	
	# Remove existing room node at that position
	for child in get_children():
		if child.position == Vector2(end_room_pos.x, end_room_pos.y) * room_size:
			child.queue_free()
			break
	
	# Add end room
	var end_room = end_room_scene.instantiate()
	end_room.position = Vector2(end_room_pos.x, end_room_pos.y) * room_size
	end_room.call_deferred("configure_exits", rooms[end_room_pos]["exits"])
	add_child(end_room)
