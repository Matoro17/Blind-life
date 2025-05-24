extends Node2D

@export var terminal_scene: PackedScene
@export var interaction_distance: float = 100.0

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
		push_error("terminal_scene is not assigned!")
		return

	var terminal = terminal_scene.instantiate()
	
	# Parent to CanvasLayer if your game uses it
	var canvas := get_node("../CanvasLayer")
	canvas.add_child(terminal)

	# Optional: center the terminal
	var camera := get_viewport().get_camera_2d()
	if camera:
		terminal.position = camera.global_position - (terminal.size)
	else:
		push_warning("No active Camera2D found. Defaulting to center screen.")
		terminal.position = (get_viewport().get_visible_rect().size / 3.0) - (terminal.size / 3.0)
	# Signal player to freeze
	player.set_process(false)  # or player.freeze = true if you have that logic
	hide_interact_message()

func show_interact_message():
	print("Press SPACE to interact")  # Replace with UI label if needed

func hide_interact_message():
	# Hide UI label if using one
	pass
