# item.gd
extends Area2D

@export var letter: String = "a" # This defines which letter this item represents

var sprite_node: Sprite2D

func _ready():
	sprite_node = Sprite2D.new()
	add_child(sprite_node)
	load_letter_sprite()
	
	add_to_group("items") # Add item to the "items" group
	connect("body_entered", Callable(self, "_on_body_entered"))
	# Connect to player's collection area
	# This is an alternative to the player's Area2D, if the item handles its own collision.
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
			queue_free()
