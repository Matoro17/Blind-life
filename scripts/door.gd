extends Node2D

@export var terminal_scene: PackedScene
@export var interaction_distance: float = 100.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_in_range := false
var player

func _ready():
	$ProximityArea.body_entered.connect(_on_body_entered)
	$ProximityArea.body_exited.connect(_on_body_exited)

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

	# Procura CanvasLayer globalmente
	var canvas := get_tree().get_root().find_child("CanvasLayer", true, false)
	if canvas:
		canvas.add_child(terminal)
	else:
		print("⚠️ CanvasLayer not found — fallback to adding directly")
		add_child(terminal)

	# Centraliza baseado na câmera
	var camera := get_viewport().get_camera_2d()
	if camera:
		terminal.position = camera.global_position - terminal.size / 2
	else:
		terminal.position = (get_viewport().get_visible_rect().size / 2.0) - (terminal.size / 2.0)

	# Bloqueia o jogador
	player.set_process(false)
	hide_interact_message()

	# CONECTA o sinal do terminal para só abrir depois do código correto
	terminal.code_validated.connect(_on_terminal_validated)


func _on_terminal_validated():
	print("✅ Código correto, abrindo porta...")
	collision_shape.disabled = true
	sprite.play("open")
	if player:
		player.set_process(true)  # Desbloqueia o jogador

func show_interact_message():
	print("Press SPACE to interact")  # Replace with UI label if needed

func hide_interact_message():
	# Hide UI label if using one
	pass
