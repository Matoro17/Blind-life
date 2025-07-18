# Enemy.gd
extends CharacterBody2D

var speed = 120.0
var target: Node2D

var is_visible: bool = false
var can_be_revealed: bool = true
var last_known_position: Vector2
var reveal_sound = preload("res://audio/enemy.wav")



@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

func _ready():
	target = get_tree().get_first_node_in_group("Player")
	add_to_group("enemies")
	sprite.modulate.a = 0.0
	detection_area.area_entered.connect(_on_detection_area_entered)
	detection_area.connect("body_entered", Callable(self, "_on_damage_area_body_entered"))

func _physics_process(delta):
	if target and position.distance_to(target.global_position) < 10.0:
		target.call("take_damage")
	if not is_visible:
		return
	# Chase either player or last known position
	var chase_target = target.global_position if target else last_known_position
	var direction = (chase_target - global_position).normalized()
	velocity = direction * speed
	update_animation(direction)
	move_and_slide()
		
		
func _on_detection_area_entered(area: Area2D):
	if area.is_in_group("sonar"):
		reveal()
		
		# Store player position when sonar was emitted
		last_known_position = area.global_position
		
func update_animation(input_vector: Vector2):
	if input_vector != Vector2.ZERO:
		# Prioritize horizontal movement
		if input_vector.x != 0:
			sprite.flip_h = input_vector.x < 0
			sprite.play("walk_right")
		else:
			sprite.play("walk_up" if input_vector.y < 0 else "walk_down")
	else:
		sprite.stop()
func reveal():
	if not can_be_revealed:
		return
	
	can_be_revealed = false
	is_visible = true
	var player = AudioStreamPlayer2D.new()
	player.stream = reveal_sound
	player.global_position = global_position
	get_tree().current_scene.add_child(player)
	player.play()
	
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
		
