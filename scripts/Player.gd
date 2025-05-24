# Player.gd
extends CharacterBody2D

@export var speed := 200
@export var health = 2

const SONAR_EMITTER = preload("res://scenes/sonar_emitter.tscn")
@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# Movimento existente...
	if Input.is_action_just_pressed("sonar"):
		emit_sonar()
		
	
	const SPEED = 200.0

	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	update_animation(input_vector)
	
	velocity = input_vector * speed
	move_and_slide()
	
func update_animation(input_vector: Vector2):
	if input_vector != Vector2.ZERO:
		# Prioritize horizontal movement
		if input_vector.x != 0:
			animated_sprite.flip_h = input_vector.x < 0
			animated_sprite.play("walk_right")
		else:
			animated_sprite.play("walk_up" if input_vector.y < 0 else "walk_down")
	else:
		animated_sprite.stop()
	
func _ready():
	# Posiciona o jogador no início do labirinto
	var maze = preload("res://scenes/MazeGenerator.tscn")
	if maze and maze.has_method("get_world_position"):
		global_position = maze.get_world_position(maze.start_position)
	else:
		printerr("MazeGenerator não encontrado ou sem método get_world_position!")

func take_damage():
	health -= 1
	if health <= 0:
		queue_free()
		# Chamar tela de game over
		
func emit_sonar():
	# Instancia o sonar
	var sonar = SONAR_EMITTER.instantiate()
	
	# Posiciona no jogador
	sonar.global_position = global_position
	
	# Adiciona à cena
	get_parent().add_child(sonar)
