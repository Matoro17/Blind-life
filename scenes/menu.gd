extends Button


@onready var background_music = $BackgroundMusic

func _ready():
	# Set initial volume (0-1)
	background_music.volume_db = linear_to_db(0.5)
	pressed.connect(_on_pressed)
	
	# Or fade in over 2 seconds
	create_tween().tween_property(background_music, "volume_db", linear_to_db(1.0), 2.0)

	

func _on_pressed():
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")
