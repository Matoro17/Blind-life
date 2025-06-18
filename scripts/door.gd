extends Node2D

@export var terminal_scene: PackedScene
@export var interaction_distance: float = 100.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var collision_shape_interact: CollisionShape2D = $ProximityArea/CollisionShape2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var door_correct_braille_code: Array = [] # New: Store the correct braille code for this door

var player_in_range := false
var player
var is_visible: bool = false
var can_be_revealed: bool = true

func _ready():
	$ProximityArea.body_entered.connect(_on_body_entered)
	$ProximityArea.body_exited.connect(_on_body_exited)
	
	# Para paredes invisíveis (apenas colisão)
	add_to_group("door")
	#sprite.modulate.a = 0.0
	
	# Ou configure uma cor sólida
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 32)  # Tamanho do bloco
	$CollisionShape2D.shape = rect
	
func reveal():
	if not can_be_revealed:
		return
	
	can_be_revealed = false
	is_visible = true
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	# Quick fade-in
	tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
	# Stay visible for 2 seconds
	#tween.tween_callback(func(): await get_tree().create_timer(2.0).timeout)
	# Smooth fade-out
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): 
		is_visible = false
		#await get_tree().create_timer(1.0).timeout  # Cooldown before can be revealed again
		can_be_revealed = true
	)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("ui_accept"):  # usually "space" or "enter"
		print("checked the input")
		open_terminal()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		player = body
		print("Entered:", body.name)
		show_interact_message()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		hide_interact_message()

func is_player_facing() -> bool:
	if not player:
		return false
	return global_position.distance_to(player.global_position) <= interaction_distance


func open_terminal():
	if terminal_scene == null:
		push_error("❌ terminal_scene is not assigned!")
		return

	var terminal = terminal_scene.instantiate()
	terminal.set_correct_code(door_correct_braille_code)

	# Add to CanvasLayer if it exists
	var canvas := get_tree().get_root().find_child("CanvasLayer", true, false)
	if canvas:
		canvas.add_child(terminal)
	else:
		print("⚠️ CanvasLayer not found — fallback to adding directly")
		add_child(terminal)

	# Position terminal at screen center
	if terminal is Control:
		canvas.add_child(terminal)
		await get_tree().process_frame
		var screen_size = get_viewport().get_visible_rect().size
		terminal.position = (screen_size / 2.0) - (terminal.size / 2.0)
	else:
		var camera := get_viewport().get_camera_2d()
		if camera:
			terminal.global_position = camera.global_position
		else:
			terminal.global_position = global_position

	# Freeze player
	player.set_process(false)
	hide_interact_message()

	# Connect signal to handle validation
	terminal.code_validated.connect(_on_terminal_validated)


func _on_terminal_validated():
	print("✅ Código correto, abrindo porta...")
	collision_shape.disabled = true
	collision_shape_interact.disabled = true
	sprite.play("open")
	if player:
		player.set_process(true)  # Desbloqueia o jogador

func show_interact_message():
	print("Press SPACE to interact")  # Replace with UI label if needed

func hide_interact_message():
	# Hide UI label if using one
	pass
	
func set_correct_braille_code(letter: String):
	door_correct_braille_code = get_braille_code_for_letter(letter)
	print("Door's correct code set to braille for letter: ", letter, " (", door_correct_braille_code, ")")
		
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
