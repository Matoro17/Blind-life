extends CharacterBody2D

@export var speed := 200
@export var health = 2

const SONAR_EMITTER = preload("res://scenes/sonar_emitter.tscn")
const CAMERA_SCENE = preload("res://scenes/camera_2d.tscn")
const GAME_OVER_DIALOG_SCENE = preload("res://scenes/gameOverDialog.tscn")

signal item_collected(letter: String, texture: Texture2D)

@onready var animated_sprite = $AnimatedSprite2D2
@onready var damage_area = $CollisionShape2D
var player_camera: Camera2D = null
var game_over_dialog: Node = null
@export var invulnerability_time := 3.0
var is_invulnerable := false

@onready var item_collection_area = $ItemCollectionArea # This MUST match the name you gave the Area2D in your Player scene!


@onready var vignette_rect: ColorRect = $VignetteLayer/ColorRect
# Raio de visão base do jogador. Aumente isso ao coletar itens.
var base_visibility_radius: float = 0.15 
# Raio de expansão do sonar para a vinheta
var sonar_expansion_radius: float = 0.25 
# Duração da animação de expansão/contração do sonar na vinheta
var sonar_vignette_duration: float = 0.8 

func _ready() -> void:
	print("🚶‍♂️ Player READY at: ", global_position, " | ID: ", self.get_instance_id())
	
	## FIX 1: Verify the node exists and make its material unique.
	if not vignette_rect:
		printerr("Vignette Rect node not found! Check the path in the script.")
		return

	if vignette_rect.material:
		# This is the most critical fix. It creates a unique copy of the material
		# for this specific player instance, so changing its parameters won't affect
		# other instances and works reliably.
		vignette_rect.material = vignette_rect.material.duplicate()

		# Now, send the viewport size to our unique material.
		var viewport_size = get_viewport_rect().size
		vignette_rect.material.set_shader_parameter("viewport_size", viewport_size)
		# Set the initial radius
		vignette_rect.material.set_shader_parameter("radius", base_visibility_radius)
	else:
		printerr("Vignette Rect does not have a ShaderMaterial assigned in the editor!")


	# Instantiate and attach the camera
	player_camera = CAMERA_SCENE.instantiate()
	player_camera.set_player(self)
	add_child(player_camera)
	print("📸 Camera instantiated and following player.")
	emit_sonar()
	
	if item_collection_area: # Ensure this node exists in your Player scene
		item_collection_area.area_entered.connect(_on_item_collection_area_area_entered)
		print("✅ Player's ItemCollectionArea signal connected.")
	else:
		printerr("❌ ItemCollectionArea node not found! Check the path in the Player script and Player.tscn.")




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
	animate_vignette_sonar()

func animate_vignette_sonar():
	if not vignette_rect or not vignette_rect.material:
		return

	# Cria uma animação (Tween) para expandir e contrair o raio da vinheta
	var tween = create_tween()
	
	# Para garantir que a animação não se sobreponha a outra em andamento
	tween.stop() 

	# 1. Expansão rápida
	var final_radius = base_visibility_radius + sonar_expansion_radius
	tween.tween_property(
		vignette_rect.material, "shader_parameter/radius", final_radius, sonar_vignette_duration * 0.4
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# 2. Contração suave de volta ao raio base
	tween.tween_property(
		vignette_rect.material, "shader_parameter/radius", base_visibility_radius, sonar_vignette_duration * 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func increase_visibility(amount: float = 0.05):
	# Aumenta o raio de visão base
	base_visibility_radius += amount
	# Garante que não passe de um limite (ex: 0.8, para nunca revelar a tela inteira)
	base_visibility_radius = min(base_visibility_radius, 0.8)

	print("Visibilidade aumentada para: ", base_visibility_radius)

	# Anima suavemente a mudança para o novo raio base
	if vignette_rect and vignette_rect.material:
		var tween = create_tween()
		tween.tween_property(
			vignette_rect.material, "shader_parameter/radius", base_visibility_radius, 0.5
		).set_ease(Tween.EASE_OUT)

# Optional: call this from enemy collision
func _on_enemy_body_entered(body):
	if body.is_in_group("enemies"):
		take_damage()

func _on_item_collection_area_area_entered(area: Area2D):
	print("Item collection area entered by: ", area.name)
	
	if area.is_in_group("items"):
		print("Item group detected!")
		if area.has_method("get_item_data"):
			print("Item data method exists.")
			var item_data = area.get_item_data()
			var item_letter = item_data["letter"]
			var item_texture = item_data["texture"]
			
			# Emit signal to Main
			item_collected.emit(item_letter, item_texture)
			
			increase_visibility(0.05) # Increase vignette
			area.queue_free() # Remove the item from the scene
