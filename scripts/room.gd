extends Node2D

@export var background_texture: Texture2D
const WALL_BLOCK_SCENE := preload("res://scenes/Wall.tscn")
const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const EXIT_SCENE := preload("res://scenes/exit.tscn")

var room_size := Vector2(640, 640)
var exits: Array = []
var room_type := "normal"
var walls_generated := false

func _ready():
	add_background()
	# DO NOT call generate_walls() here — wait for exits

func configure_exits(exit_dirs: Array):
	exits = exit_dirs
	if not walls_generated:
		generate_walls()
		walls_generated = true
	setup_contents()

func setup_contents():
	match room_type:
		"start":
			print("johson")
			#var player = PLAYER_SCENE.instantiate()
			#$SpawnPoint.add_child(player)
		"enemy":
			spawn_enemies()
		"end":
			spawn_exit_portal()

func spawn_enemies():
	if not $EnemySpawnPoints:
		return
	var spawner = $EnemySpawnPoints.get_child(randi() % $EnemySpawnPoints.get_child_count())
	var enemy = ENEMY_SCENE.instantiate()
	spawner.add_child(enemy)

func spawn_exit_portal():
	var portal = EXIT_SCENE.instantiate()
	$ExitSpawnPoint.add_child(portal)

func add_background():
	if not background_texture:
		return
	var bg = Sprite2D.new()
	bg.texture = background_texture
	bg.centered = false
	bg.position = Vector2.ZERO
	bg.z_index = -1
	bg.scale = room_size / background_texture.get_size()
	add_child(bg)

func generate_walls():
	var block_size := 25
	var gap_half := 2

	var cols := int(room_size.x / block_size)
	var rows := int(room_size.y / block_size)
	var mid_col := cols / 2
	var mid_row := rows / 2

	# Only build BOTTOM and RIGHT walls (shared borders)
	for x in range(cols):
		var in_bottom_gap = exits.has(Vector2i.DOWN) and abs(x - mid_col) <= gap_half
		if not in_bottom_gap:
			_spawn_wall_block(Vector2(x * block_size, room_size.y - block_size))

	for y in range(rows):
		var in_right_gap = exits.has(Vector2i.RIGHT) and abs(y - mid_row) <= gap_half
		if not in_right_gap:
			_spawn_wall_block(Vector2(room_size.x - block_size, y * block_size))

	# Edge case: If this room is at the left/top border of the map, we must build LEFT/TOP walls
	if not exits.has(Vector2i.UP):
		for x in range(cols):
			var in_top_gap = false  # force top closed
			if not in_top_gap:
				_spawn_wall_block(Vector2(x * block_size, 0))

	if not exits.has(Vector2i.LEFT):
		for y in range(rows):
			var in_left_gap = false  # force left closed
			if not in_left_gap:
				_spawn_wall_block(Vector2(0, y * block_size))



func _spawn_wall_block(pos: Vector2):
	var wall = WALL_BLOCK_SCENE.instantiate()
	wall.position = pos.snapped(Vector2(25, 25))
	add_child(wall)
	wall.is_visible = false
