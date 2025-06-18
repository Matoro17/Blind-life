# collectibles_ui.gd
extends CanvasLayer

@onready var collected_items_hbox = $UIPanel/CollectedItemsHBox # <--- Verify this path!

func _ready():
	# Always check if the node was successfully assigned by @onready
	if collected_items_hbox:
		# Ensure the HBoxContainer has correct layout to be visible
		collected_items_hbox.add_theme_constant_override("separation", 5) # Adjust spacing between items
		print("CollectedItemsHBox initialized successfully.")
	else:
		printerr("ERROR: collected_items_hbox is null! Check node path in CollectiblesUI.tscn.")

func add_item_texture(texture: Texture2D):
	if not collected_items_hbox:
		printerr("Cannot add item texture: collected_items_hbox is null!")
		return

	var item_display = TextureRect.new()
	item_display.texture = texture
	item_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Adjust size as needed for the UI bar
	item_display.custom_minimum_size = Vector2(32, 32) # Smaller size for UI bar
	collected_items_hbox.add_child(item_display)
