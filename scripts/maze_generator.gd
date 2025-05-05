# MazeGenerator.gd
extends Node2D  # Alterado de TileMap para Node2D

var grid_size = Vector2(60, 60)
var wall_probability = 0.1
@export var cell_size = Vector2(32, 32)  # Tamanho de cada célula em pixels

@export var wall_scene: PackedScene  # Arraste o Wall.tscn para aqui no Inspector
@export var start_position := Vector2i(0, 0)
@export var end_position := Vector2i(100, 100)


var walls = []  # Array para armazenar referências das paredes

func _ready():
	generate_maze()
	

func clear_maze():
	for wall in walls:
		wall.queue_free()
	walls.clear()
	
func get_world_position(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * cell_size.x + cell_size.x / 2,
		grid_pos.y * cell_size.y + cell_size.y / 2
	)

func generate_maze():
	var grid = []
	# Inicializa grid com paredes aleatórias
	for x in grid_size.x:
		grid.append([])
		for y in grid_size.y:
			grid[x].append(randf() < wall_probability)
	
	# Garante caminho principal
	carve_path(grid, Vector2(0,0), Vector2(grid_size.x-1, grid_size.y-1))
	
	# Adiciona aberturas extras
	for i in range(3):
		var random_x = randi() % int(grid_size.x)
		var random_y = randi() % int(grid_size.y)
		grid[random_x][random_y] = false
	
	# Instancia paredes baseadas no grid final
	for x in grid_size.x:
		for y in grid_size.y:
			if grid[x][y]:
				var wall = wall_scene.instantiate()
				wall.position = Vector2(x * cell_size.x, y * cell_size.y)
				add_child(wall)
				walls.append(wall)

func carve_path(grid, start: Vector2, end: Vector2):
	var current_pos = start
	var path = []
	
	grid[start.x][start.y] = false  # Abre célula inicial
	
	while current_pos != end:
		var next_pos = current_pos
		var directions = []
		
		# Prioriza direção correta
		if current_pos.x < end.x:
			directions.append(Vector2.RIGHT)
		if current_pos.y < end.y:
			directions.append(Vector2.DOWN)
		
		# Adiciona aleatoriedade
		if randf() < 0.3:
			directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
		
		directions.shuffle()
		
		# Encontra próxima posição válida
		for dir in directions:
			var test_pos = current_pos + dir
			if test_pos.x >= 0 and test_pos.x < grid_size.x and test_pos.y >= 0 and test_pos.y < grid_size.y:
				next_pos = test_pos
				break
		
		# Abre caminho
		grid[next_pos.x][next_pos.y] = false
		path.append(next_pos)
		
		# Conexões laterais
		if randf() < 0.2 && path.size() > 2:
			var connect_pos = path[randi() % path.size()]
			var between = Vector2(
				(current_pos.x + connect_pos.x) / 2,
				(current_pos.y + connect_pos.y) / 2
			).floor()
			grid[between.x][between.y] = false
		
		current_pos = next_pos
