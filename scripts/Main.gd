# main.gd
extends Node

const Enemy = preload("res://scenes/enemy.tscn")
@onready var maze_generator_scene = preload("res://scenes/MazeGenerator.tscn")
@onready var PlayerScene = preload("res://scenes/Player.tscn")
@onready var collectibles_ui_scene = preload("res://scenes/collectibles_ui.tscn")
const TERMINAL_SCENE = preload("res://scenes/terminal.tscn")

@onready var main_music = AudioStreamPlayer.new()

var player: Node2D = null
var maze_generator_instance = null
var collectibles_ui_instance: CanvasLayer = null
var current_terminal_instance = null

var screen_fader: ColorRect

# --- NOVAS VARIÁVEIS PARA CONTROLE DE NÍVEL ---
var current_level: int = 1
const MAX_LEVELS: int = 5 # Agora com 5 fases!

func _ready():
	# A música e a UI de coletáveis só precisam ser instanciadas uma vez.
	collectibles_ui_instance = collectibles_ui_scene.instantiate()
	add_child(collectibles_ui_instance)
	
	var music_stream = load("res://audio/full-sound-track.mp3")
	main_music.stream = music_stream
	main_music.autoplay = true
	main_music.volume_db = -20
	add_child(main_music)
	main_music.play()
	
	# Inicia o primeiro nível
	start_level()
	
		# --- CONFIGURAÇÃO DO FADER PARA TRANSIÇÕES ---
	screen_fader = ColorRect.new()
	# Começa totalmente preto e transparente
	screen_fader.color = Color(0, 0, 0, 0) 
	# Garante que o fader cubra a tela inteira e fique por cima de tudo
	screen_fader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) 
	# Adiciona o fader à cena, mas ele está invisível por enquanto
	add_child(screen_fader)

func start_level():
	print("🚀 Iniciando nível ", current_level)

	# Aumenta a complexidade com base no nível
	var new_max_rooms = 3 + (current_level * 2) # Ex: Nível 1=8, Nível 2=11, ..., Nível 5=20
	var new_enemy_count = 1 + current_level   # Ex: Nível 1=2, Nível 2=3, ..., Nível 5=6

	# Cria o novo labirinto
	maze_generator_instance = maze_generator_scene.instantiate()
	maze_generator_instance.max_rooms = new_max_rooms
	# Usamos metadados para passar o número de inimigos de forma segura
	maze_generator_instance.set_meta("enemy_count", new_enemy_count) 
	add_child(maze_generator_instance)

	# Conecta o sinal para quando o novo labirinto for gerado
	maze_generator_instance.connect("maze_generated", _on_maze_generator_maze_generated)
	
	# Primeiro, vamos garantir que o nó esteja pronto na árvore da cena.
	await get_tree().process_frame 
	
	# Agora, chamamos a geração.
	if maze_generator_instance.has_method("generate_dungeon"):
		print("▶️ Comandando MazeGenerator para gerar o novo labirinto...")
		maze_generator_instance.generate_dungeon()
	else:
		printerr("❌ O script MazeGenerator não tem uma função generate_dungeon() para ser chamada!")

func _on_maze_generator_maze_generated():
	print("🌀 Labirinto do nível ", current_level, " gerado.")
	
	# Posiciona o jogador
	place_player_in_start_room()
	
	# Gera os inimigos
	spawn_enemies()
	
	# Conecta o sinal da porta do labirinto recém-criado
	connect_door_signal()

func place_player_in_start_room():
	var start_data = maze_generator_instance.rooms.get(maze_generator_instance.start_room_pos)
	if not start_data:
		printerr("❌ Sala inicial não encontrada no dicionário de salas!")
		return
		
	var start_room = start_data["node"]
	if not start_room.has_node("SpawnPoint"):
		printerr("⚠️ Sem SpawnPoint na sala inicial!")
		return
		
	var spawn_point = start_room.get_node("SpawnPoint")

	if player and is_instance_valid(player):
		# Se o jogador já existe (veio de um nível anterior), movemos ele
		if player.get_parent():
			player.get_parent().remove_child(player)
		spawn_point.add_child(player)
		player.global_position = spawn_point.global_position
		print("✅ Jogador movido para o novo spawn point.")
	else:
		# Se o jogador não existe (primeiro nível), instanciamos ele
		print("🧍 Instanciando jogador pela primeira vez...")
		player = PlayerScene.instantiate()
		player.connect("item_collected", _on_player_item_collected)
		spawn_point.add_child(player)
		print("✅ Jogador instanciado no SpawnPoint.")

	# --- CORREÇÃO CRÍTICA ---
	# Garante que o jogador esteja sempre "descongelado" ao iniciar um nível.
	# Isso resolve o problema do jogador ficar parado após a transição.
	if player and is_instance_valid(player):
		player.set_process(true)
		player.set_physics_process(true)
		# Se você tiver uma função de unfreeze, chame-a também.
		if player.has_method("unfreeze"):
			player.unfreeze()
		print("🏃‍♂️ Processos do jogador reativados para o novo nível.")

func connect_door_signal():
	var door_found = false
	# VERIFICAÇÃO: Garante que a instância do labirinto existe antes de procurar.
	if not is_instance_valid(maze_generator_instance):
		printerr("❌ Tentativa de conectar sinal da porta, mas o MazeGenerator não é válido.")
		return

	# CORREÇÃO: Procuramos a porta nos filhos do 'maze_generator_instance', não do 'Main'.
	for child in maze_generator_instance.get_children():
		# Usamos 'is_in_group' que é mais robusto que checar o nome.
		if child.has_node("Door"): 
			child = child.get_node("Door")
			# Desconectar primeiro para evitar conexões duplicadas ao recarregar a cena
			if child.is_connected("door_opened_correctly", Callable(self, "_on_door_opened")):
				child.disconnect("door_opened_correctly", Callable(self, "_on_door_opened"))
			
			# Conecta o sinal da porta (de door.gd) à função _on_door_opened (em main.gd)
			var error_code = child.connect("door_opened_correctly", Callable(self, "_on_door_opened"))
			
			if error_code == OK:
				print("✅🔗 Sinal 'door_opened_correctly' da porta conectado com sucesso ao Main!")
				door_found = true
				break # Encontramos a porta, não precisa continuar o loop
			else:
				printerr("❌ Falha ao conectar o sinal da porta. Código de erro: %s" % error_code)

	if not door_found:
		# Este erro não deve mais aparecer após a correção.
		printerr("❌ Nenhuma porta encontrada nos filhos do MazeGenerator para conectar.")

func _on_door_opened():
	print("🚪 Porta aberta com sucesso! Avançando para o próximo nível...")
	advance_to_next_level()

func advance_to_next_level():
	if current_level >= MAX_LEVELS:
		show_victory_screen()
		return
	# 1. ESCURECER A TELA (FADE OUT)
	# Cria uma animação (Tween) que não pausa quando o jogo pausa.
	var tween_out = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Anima a propriedade 'color' do nosso fader para preto sólido em 0.5 segundos.
	tween_out.tween_property(screen_fader, "color", Color.BLACK, 0.5)
	
	# 2. ESPERAR A ANIMAÇÃO TERMINAR
	# 'await' pausa a execução DESTA FUNÇÃO aqui até que o tween_out seja concluído.
	# O resto do jogo continua rodando normalmente.
	await tween_out.finished
	current_level += 1
	
	# Limpa todos os elementos do nível anterior
	_cleanup_level()
	
	# Inicia o próximo nível
	start_level()
	# 4. ESPERAR O NOVO NÍVEL ESTAR PRONTO
	# O sinal 'maze_generated' nos diz que o novo labirinto está pronto.
	# Esperamos por este sinal antes de revelar a tela.
	await maze_generator_instance.maze_generated
	
	# 5. REVELAR A TELA (FADE IN)
	var tween_in = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Anima a cor de volta para transparente, revelando o novo nível.
	tween_in.tween_property(screen_fader, "color", Color(0, 0, 0, 0), 3)

func _cleanup_level():
	print("🧹 Limpando nível anterior...")
	# Remove todos os inimigos
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	
	# Remove itens coletáveis que possam ter sobrado
	for item in get_tree().get_nodes_in_group("items"):
		item.queue_free()
		
	# Remove o labirinto antigo
	if maze_generator_instance and is_instance_valid(maze_generator_instance):
		maze_generator_instance.queue_free()
		maze_generator_instance = null
		
	# Resgata o jogador para que ele não seja deletado com o labirinto
	if player and is_instance_valid(player):
		if player.get_parent():
			player.get_parent().remove_child(player)
		# Adiciona o jogador como filho temporário de Main para não ser perdido
		add_child(player)

func show_victory_screen():
	print("🏆 PARABÉNS! Você venceu o jogo!")
	get_tree().paused = true
	var victory_label = Label.new()
	victory_label.text = "VOCÊ VENCEU!"
	victory_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Recomendo criar uma cena dedicada para a tela de vitória e instanciá-la aqui.
	add_child(victory_label)

func spawn_enemies():
	var room_keys = maze_generator_instance.rooms.keys()
	# Pega o número de inimigos dos metadados definidos em start_level()
	var enemy_count = maze_generator_instance.get_meta("enemy_count", 1) 
	print("👾 Gerando ", enemy_count, " inimigos.")
	
	for i in range(enemy_count):
		var enemy = Enemy.instantiate()
		var room_pos = room_keys.pick_random()
		# Garante que o inimigo não nasça na sala inicial
		while room_pos == maze_generator_instance.start_room_pos:
			room_pos = room_keys.pick_random()

		var room_data = maze_generator_instance.rooms[room_pos]
		var room_node = room_data["node"]
		
		# Posição aleatória dentro da sala
		var spawn_position = room_node.global_position + Vector2(randf_range(100, 540), randf_range(100, 540))
		enemy.global_position = spawn_position
		add_child(enemy)

# --- LÓGICA DO TERMINAL E ITENS (PRATICAMENTE INALTERADA, MAS REORGANIZADA) ---

func _on_player_item_collected(item_letter: String, item_texture: Texture2D):
	print("🔔 Item coletado em Main: ", item_letter)
	if collectibles_ui_instance:
		collectibles_ui_instance.add_item_texture(item_texture)
	
	# A lógica de abrir a porta agora é tratada pelo script da porta,
	# que já sabe qual é a letra correta através do MazeGenerator.
	# Esta função agora só precisa atualizar a UI.

# A função para abrir o terminal deve ser chamada pela porta, não pelo Main.
# O código abaixo pode ser movido para o script da sua porta.
# Se a porta já faz isso, pode remover esta função de 'main.gd'.
func open_braille_terminal(door_node):
	if current_terminal_instance and is_instance_valid(current_terminal_instance):
		return

	current_terminal_instance = TERMINAL_SCENE.instantiate()
	# O terminal precisa saber o código correto. O MazeGenerator define isso na porta.
	var correct_code_array = get_braille_code_for_letter(door_node.correct_braille_letter)
	current_terminal_instance.set_correct_code(correct_code_array)
	
	# Conecta o sinal do terminal para saber se o código foi validado
	current_terminal_instance.connect("code_validated", func(): door_node._on_terminal_code_validated())
	
	get_tree().get_root().add_child(current_terminal_instance)

# Função auxiliar para converter letra em código Braille
func get_braille_code_for_letter(letter: String) -> Array:
	match letter.to_lower():
		"a": return [true, false, false, false, false, false]
		"b": return [true, false, true, false, false, false]
		"c": return [true, true, false, false, false, false]
		"d": return [true, true, false, true, false, false]
		"e": return [true, false, false, true, false, false]
		_:
			printerr("Código Braille para a letra '%s' não definido!" % letter)
			return []
