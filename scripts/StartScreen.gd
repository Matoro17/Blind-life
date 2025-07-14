extends Node2D

@onready var background = $Background
@onready var label = $TextBox/Label

# Background images and story texts
var panels = [
	{
		"image": preload("res://art/transition.png"),
		"text": "Vera estava sozinha em casa.\nA casa permanecia em silêncio.\n Até que a voz do apresentador de notícias rompeu a calmaria.\nAlgo terrível havia acontecido.\nAlgo que mudaria tudo."
	},
	{
		"image": preload("res://art/transition_2.png"),
		"text": "Em meio ao caos, ela encontrou as anotações dispersas de sua mãe.\nPistas, mensagens enigmáticas que apontavam para conhecimento e perigo.\nEla precisava sair, encontrar a verdade e desvendar o código que a faria seguir em frente."
	}
]

var current_panel = 0

func _ready():
	_show_panel(current_panel)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		if current_panel < panels.size() - 1:
			current_panel += 1
			_show_panel(current_panel)
		else:
			# After final panel, start game
			get_tree().change_scene_to_file("res://Main.tscn")

func _show_panel(index):
	var panel = panels[index]
	background.texture = panel["image"]
	label.text = panel["text"]
