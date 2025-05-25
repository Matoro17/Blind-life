extends Camera2D

var player: Node2D = null

func _ready():
	make_current()
	position_smoothing_enabled = true
	position_smoothing_speed = 5
	zoom = Vector2(1.5, 1.5)

func set_player(p):
	player = p
	make_current()
	print("📸 Camera now tracking player: ", p.name, " | ID: ", p.get_instance_id())

func _physics_process(delta):
	if player and is_instance_valid(player):
		global_position = player.global_position
