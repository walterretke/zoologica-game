extends Control
class_name PauseMenu

@export_category("Objects")
@export var resume_button: Button = null
@export var save_button: Button = null
@export var settings_button: Button = null
@export var quit_button: Button = null

const SETTINGS_SCENE = preload("res://Assets/Scene/settings.tscn")

const MENU_SCENE = "res://Assets/Scene/main_menu.tscn"

func _ready() -> void:
	_find_buttons()
	_initialize_buttons()
	# Pausar o jogo quando o menu de pausa aparece
	get_tree().paused = true
	# Permitir que este nó processe input mesmo quando pausado
	set_process_mode(PROCESS_MODE_ALWAYS)
	set_process_unhandled_input(true)

func _find_buttons() -> void:
	# Buscar botões automaticamente se não estiverem atribuídos
	if not resume_button:
		resume_button = get_node_or_null("CenterContainer/VBoxContainer/resume_btn") as Button
		if resume_button:
			print("Botão Retomar encontrado")
		else:
			push_error("Botão Retomar não encontrado!")
	
	if not save_button:
		save_button = get_node_or_null("CenterContainer/VBoxContainer/save_btn") as Button
		if save_button:
			print("Botão Salvar encontrado")
		else:
			push_warning("Botão Salvar não encontrado!")
	
	if not settings_button:
		settings_button = get_node_or_null("CenterContainer/VBoxContainer/settings_btn") as Button
		if settings_button:
			print("Botão Configurações encontrado")
		else:
			push_warning("Botão Configurações não encontrado!")
	
	if not quit_button:
		quit_button = get_node_or_null("CenterContainer/VBoxContainer/quit_btn") as Button
		if quit_button:
			print("Botão Sair encontrado")
		else:
			push_error("Botão Sair não encontrado!")

func _initialize_buttons() -> void:
	if resume_button:
		# Desconectar primeiro para evitar duplicatas
		if resume_button.pressed.is_connected(_on_resume_btn_pressed):
			resume_button.pressed.disconnect(_on_resume_btn_pressed)
		resume_button.pressed.connect(_on_resume_btn_pressed)
		print("Botão Retomar conectado")
	
	if save_button:
		# Desconectar primeiro para evitar duplicatas
		if save_button.pressed.is_connected(_on_save_btn_pressed):
			save_button.pressed.disconnect(_on_save_btn_pressed)
		save_button.pressed.connect(_on_save_btn_pressed)
		print("Botão Salvar conectado")
	
	if settings_button:
		# Desconectar primeiro para evitar duplicatas
		if settings_button.pressed.is_connected(_on_settings_btn_pressed):
			settings_button.pressed.disconnect(_on_settings_btn_pressed)
		settings_button.pressed.connect(_on_settings_btn_pressed)
		print("Botão Configurações conectado")
	
	if quit_button:
		# Desconectar primeiro para evitar duplicatas
		if quit_button.pressed.is_connected(_on_quit_btn_pressed):
			quit_button.pressed.disconnect(_on_quit_btn_pressed)
		quit_button.pressed.connect(_on_quit_btn_pressed)
		print("Botão Sair conectado")

func _on_resume_btn_pressed() -> void:
	print("Retomando jogo...")
	# Despausar o jogo
	get_tree().paused = false
	# Remover o menu de pausa
	queue_free()

func _on_settings_btn_pressed() -> void:
	print("Abrindo configurações...")
	if SETTINGS_SCENE:
		var settings_instance = SETTINGS_SCENE.instantiate()
		add_child(settings_instance)
	else:
		push_error("Não foi possível carregar a cena de configurações!")

func _on_save_btn_pressed() -> void:
	print("Salvando jogo...")
	# Encontrar o jogador
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var player = player_nodes[0] as CharacterBody2D
		if player:
			var saved = SaveManager.save_game(player)
			if saved:
				_mostrar_feedback_salvamento(true)
			else:
				_mostrar_feedback_salvamento(false)
		else:
			push_error("Player não encontrado para salvar!")
	else:
		push_error("Nenhum player encontrado no grupo 'player'!")

func _mostrar_feedback_salvamento(sucesso: bool) -> void:
	# Criar feedback visual temporário
	var feedback = Label.new()
	feedback.name = "SaveFeedback"
	feedback.text = "JOGO SALVO!" if sucesso else "ERRO AO SALVAR!"
	feedback.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1.0) if sucesso else Color(1.0, 0.2, 0.2, 1.0))
	var font = load("res://Assets/Fonts/Silkscreen/Silkscreen-Regular.ttf")
	if font:
		feedback.add_theme_font_override("font", font)
	feedback.add_theme_font_size_override("font_size", 32)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.set_anchors_preset(Control.PRESET_CENTER_TOP)
	feedback.position = Vector2(-200, 100)
	feedback.custom_minimum_size = Vector2(400, 60)
	add_child(feedback)
	
	# Remover após 2 segundos
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(feedback):
		feedback.queue_free()

func _on_quit_btn_pressed() -> void:
	print("Saindo para o menu principal...")
	# Despausar o jogo antes de mudar de cena
	get_tree().paused = false
	# Salvar o jogo completo antes de sair (não apenas a flag "started")
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var player = player_nodes[0] as CharacterBody2D
		if player:
			SaveManager.save_game(player)
			print("Jogo salvo antes de sair para o menu")
	# Voltar para o menu principal
	var error = get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		push_error("Erro ao carregar o menu principal: %d" % error)

func _unhandled_input(event: InputEvent) -> void:
	# Permitir fechar o menu de pausa com ESC também
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		_on_resume_btn_pressed()
		get_viewport().set_input_as_handled()

