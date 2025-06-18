# terminal.gd
extends Control

signal code_validated

# Removed 'const CORRECT_CODE' - now it's dynamic
var CORRECT_CODE: Array = [] # New: Now a variable to be set dynamically

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
			
	if CORRECT_CODE.is_empty():
		printerr("⚠️ Terminal was opened without a correct braille code set!")
		# You might want a default or error handling here

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

# New: Method to set the correct braille code from outside
func set_correct_code(code_array: Array):
	CORRECT_CODE = code_array
	print("Terminal correct code set to: ", CORRECT_CODE)
	
	
func get_braille_code_for_letter(letter: String) -> Array:
	# This mapping must align with your Terminal's BrailleGrid structure
	# true = dot pressed, false = dot not pressed
	match letter.to_lower():
		"a": return [true, false, false, false, false, false] #
		"b": return [true, false, true, false, false, false]  #
		"c": return [true, true, false, false, false, false]  # 
		"d": return [true, true, false, true, false, false]   # 
		"e": return [true, false, false, true, false, false]  # 
		# ADD MORE LETTERS HERE AS NEEDED FOR YOUR GAME
		_:
			printerr("Braille code for letter '%s' not defined!" % letter)
			return [] # Default empty or error
