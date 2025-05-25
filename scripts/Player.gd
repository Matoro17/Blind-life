extends CharacterBody2D

@export var speed := 200
@export var health = 2

const SONAR_EMITTER = preload("res://scenes/sonar_emitter.tscn")
const CAMERA_SCENE = preload("res://scenes/camera_2d.tscn")

@onready var animated_sprite = $AnimatedSprite2D
var player_camera: Camera2D = null

func _ready() -> void:
	print("🚶‍♂️ Player READY at: ", global_position, " | ID: ", self.get_instance_id())

	# Instantiate and attach the camera
	player_camera = CAMERA_SCENE.instantiate()
	player_camera.set_player(self)
	add_child(player_camera)
	print("📸 Camera instantiated and following player.")

func _physics_process(delta):
	if Input.is_action_just_pressed("sonar"):
		emit_sonar()
	
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	update_animation(input_vector)
	
	velocity = input_vector * speed
	move_and_slide()

func update_animation(input_vector: Vector2):
	if input_vector != Vector2.ZERO:
		if input_vector.x != 0:
			animated_sprite.flip_h = input_vector.x < 0
			animated_sprite.play("walk_right")
		else:
			animated_sprite.play("walk_up" if input_vector.y < 0 else "walk_down")
	else:
		animated_sprite.stop()

func take_damage():
	health -= 1
	if health <= 0:
		queue_free()

func emit_sonar():
	var sonar = SONAR_EMITTER.instantiate()
	sonar.global_position = global_position
	get_tree().get_root().get_node("Main").add_child(sonar)
