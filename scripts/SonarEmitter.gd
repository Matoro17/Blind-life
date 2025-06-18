# SonarEmitter.gd
extends Area2D  # Alterado de Node para Area2D!

@export var max_radius: float = 500.0
@export var expansion_speed: float = 800.0
@export var fade_time: float = 1.5

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sonar_sprite: Sprite2D = $Sprite2D
#@onready var particles: GPUParticles2D = $SonarParticles

var current_radius: float = 0.0
var is_active: bool = false

func _ready():
	add_to_group("sonar")
	# Configurações iniciais importantes
	collision_shape.shape = CircleShape2D.new()
	collision_shape.shape.radius = 0
	# Set up sprite properties
	sonar_sprite.scale = Vector2.ZERO
	sonar_sprite.modulate.a = 1.0
	connect("body_entered", _on_body_entered)
		# Set up collision shape and timer for pulse duration
	var pulse_duration = 0.5
	await get_tree().create_timer(pulse_duration).timeout
	queue_free()

func _process(delta):
	if current_radius < max_radius:
		current_radius += expansion_speed * delta
		collision_shape.shape.radius = current_radius
		update_sonar_visuals()
	else:
		queue_free() 
		
func update_sonar_visuals():
	# Update collision shape
	collision_shape.shape.radius = current_radius
	
	# Update visual properties
	var texture_radius = sonar_sprite.texture.get_width() / 2.0
	var scale_factor = current_radius / texture_radius
	sonar_sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Fade out as it expands
	sonar_sprite.modulate.a = 1.0 - (current_radius / max_radius)
	
func emit_sonar():
	if not is_active:
		current_radius = 0.0
		current_radius = 0.0
		is_active = true
		$AudioStreamPlayer2D.play()
		update_sonar_visuals()

func reset_sonar():
	current_radius = 0.0
	is_active = false
#	particles.emitting = false
	collision_shape.shape.radius = 0.0

func _on_body_entered(body):
	#print("Body: " + body.name)
	if body.is_in_group("enemies") or body.is_in_group("wall") or body.is_in_group("door"):
		# Verificação de linha de visão melhorada
		var space_state = get_world_2d().direct_space_state
		var params = PhysicsRayQueryParameters2D.create(
			global_position,
			body.global_position,
			collision_mask,  # Usa a máscara de colisão definida no inspector
			[self, get_parent()]  # Ignora o sonar e seu pai
		)
		
		var result = space_state.intersect_ray(params)
		if result.is_empty():  # Sem obstruções
			body.reveal()
		elif result.collider == body:  # Colisão direta com o inimigo
			body.reveal()
