extends Control

signal code_validated

const CORRECT_CODE = [true, true, 
					  true, false, 
					  true, false] # Example code

var dots := []
func _ready():
	dots = [
	$Panel/BrailleGrid/Dot0,
	$Panel/BrailleGrid/Dot1,
	$Panel/BrailleGrid/Dot2,
	$Panel/BrailleGrid/Dot3,
	$Panel/BrailleGrid/Dot4,
	$Panel/BrailleGrid/Dot5]
	for dot in dots:
		dot.pressed.connect(func(): _on_dot_pressed(dot))
	$Panel/BtnEnter.pressed.connect(_on_enter_pressed)
	$Panel/BtnClose.pressed.connect(_on_close_pressed)
			

func _on_dot_pressed(dot: TextureButton):
	dot.modulate = Color.GREEN if dot.button_pressed else Color.WHITE

func _on_close_pressed():
	queue_free()

func _on_enter_pressed():
	var current_code := []
	print("Current array")
	print(current_code)
	for dot in dots:
		current_code.append(dot.button_pressed)
	print(current_code)
	if current_code == CORRECT_CODE:
		
		code_validated.emit()
		queue_free()
