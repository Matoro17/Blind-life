# VisibilityController.gd
extends Node2D

var base_alpha = 0.1
var reveal_duration = 2.0

func _on_SonarEmitter_body_entered(body):
	if body.has_method("reveal"):
		body.reveal()

# Aplicar em todos os objetos do ambiente
func reveal():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	tween.tween_property(self, "modulate:a", base_alpha, reveal_duration)
