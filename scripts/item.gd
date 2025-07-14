# item.gd
extends Area2D

@export var letter: String = "a" # This defines which letter this item represents

@onready var sprite_node: Sprite2D = Sprite2D.new()
@onready var reveal_sound: AudioStream = preload("res://audio/paper-flutter-5933.mp3")

var is_visible: bool = false
var can_be_revealed: bool = true

func _ready():
	add_child(sprite_node)
	load_letter_sprite()
	
	add_to_group("items") # Add item to the "items" group
	connect("body_entered", Callable(self, "_on_body_entered"))
	sprite_node.modulate.a = 0.0  # Start invisible
	connect("area_entered", Callable(self, "_on_area_entered"))
	# Connect to player's collection area
	# This is an alternative to the player's Area2D, if the item sprite_node.modulate.a = 0.0  # Start invisiblehandles its own collision.
	# For simplicity, we'll assume player has the Area2D.
	# If you want the item to detect the player, use this:
	# body_entered.connect(_on_body_entered)


func load_letter_sprite():
	var path = "res://art/alphabet/%s.png" % letter
	if ResourceLoader.exists(path):
		sprite_node.texture = load(path)
		sprite_node.scale = Vector2(0.02, 0.02) # Adjust scale as needed
	else:
		print("Warning: Sprite for letter '%s' not found at path: %s" % [letter, path])

# This function is not strictly needed if the Player handles collision via its Area2D
# But it's good practice to have for getting item data.
func get_item_data() -> Dictionary:
	return {
		"letter": letter,
		"texture": sprite_node.texture
	}

func _on_body_entered(body):
	if body.name == "Player":
		if body.has_signal("item_collected"):
			body.emit_signal("item_collected", letter, sprite_node.texture)
			body.increase_visibility(0.05)
			reveal()
			await get_tree().create_timer(2.0)
			queue_free()
			
func _on_area_entered(area: Area2D):
	if area.is_in_group("sonar"):
		reveal()
		
func reveal():
	if not can_be_revealed:
		return

	can_be_revealed = false
	is_visible = true

	# Create and configure audio player
	var player = AudioStreamPlayer2D.new()
	player.stream = reveal_sound
	player.global_position = global_position

	var max_offset = reveal_sound.get_length() - 1.0  # Avoid the very end
	player.seek(randf_range(0.0, max_offset))

	get_tree().current_scene.add_child(player)
	player.play()

	# Automatically stop audio after the reveal duration
	var audio_timer = Timer.new()
	audio_timer.wait_time = 2  # Total time of the tween sequence
	audio_timer.one_shot = true
	audio_timer.connect("timeout", Callable(player, "stop"))
	player.add_child(audio_timer)
	audio_timer.start()

	# Fade in sprite
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite_node, "modulate:a", 1.0, 0.2)
	tween.tween_interval(4.0)  # Stay visible

	# Fade out and reset visibility
	tween.tween_property(sprite_node, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		is_visible = false
		can_be_revealed = true
		player.queue_free()
	)
