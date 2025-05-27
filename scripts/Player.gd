extends CharacterBody2D

@export var speed := 200
@export var health = 2

const SONAR_EMITTER = preload("res://scenes/sonar_emitter.tscn")
const CAMERA_SCENE = preload("res://scenes/camera_2d.tscn")
const GAME_OVER_DIALOG_SCENE = preload("res://scenes/gameOverDialog.tscn")

@onready var animated_sprite = $AnimatedSprite2D2
@onready var damage_area = $CollisionShape2D
var player_camera: Camera2D = null
var game_over_dialog: Node = null
@export var invulnerability_time := 5.0
var is_invulnerable := false

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
		# 💡 Collision debug
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("enemies"):
			print("⚔️ Collided with an enemy group member!")
			take_damage()
			break

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
	if is_invulnerable:
		return

	health -= 1
	print("💥 Player took damage! Health: ", health)

	is_invulnerable = true
	start_blinking()

	await get_tree().create_timer(invulnerability_time).timeout
	is_invulnerable = false
	animated_sprite.visible = true

	if health <= 0:
		show_game_over_dialog()

func start_blinking():
	var blink_timer := 0.0
	var blink_interval := 0.1

	while blink_timer < invulnerability_time:
		animated_sprite.visible = !animated_sprite.visible
		await get_tree().create_timer(blink_interval).timeout
		blink_timer += blink_interval

	# Ensure sprite is visible after blinking
	animated_sprite.visible = true


func show_game_over_dialog():
	if game_over_dialog: return # Avoid creating multiple dialogs

	game_over_dialog = GAME_OVER_DIALOG_SCENE.instantiate()
	get_tree().get_root().add_child(game_over_dialog)

	# Optional: Position it centered
	if game_over_dialog.has_method("popup_centered"):
		game_over_dialog.call("popup_centered")
	else:
		game_over_dialog.show()

	# ✅ Fix the paths
	var restart_button = game_over_dialog.get_node("Panel/RestartButton")
	var surrender_button = game_over_dialog.get_node("Panel/SurrenderButton")

	restart_button.connect("pressed", Callable(self, "_on_restart_game"))
	surrender_button.connect("pressed", Callable(self, "_on_surrender"))


func _on_restart_game():
	get_tree().reload_current_scene()

func _on_surrender():
	get_tree().quit()

func emit_sonar():
	var sonar = SONAR_EMITTER.instantiate()
	sonar.global_position = global_position
	get_tree().get_root().get_node("Main").add_child(sonar)

# Optional: call this from enemy collision
func _on_enemy_body_entered(body):
	if body.is_in_group("enemies"):
		take_damage()
