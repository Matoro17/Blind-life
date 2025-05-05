extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
var is_visible: bool = false
var can_be_revealed: bool = true

func _ready():
	# Para paredes invisíveis (apenas colisão)
	add_to_group("wall")
	sprite.modulate.a = 0.0
	
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
