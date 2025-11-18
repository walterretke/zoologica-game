extends Control

@export_category("Objects")
@export var start_button: Button = null
@export var continue_button: Button = null
@export var quit_button: Button = null

# Cena do jogo principal
const GAME_SCENE = "res://Assets/Scene/game.tscn"
const MENU_SCENE = "res://Tela_inicial.tscn"

func _ready() -> void:
	_find_buttons()
	_initialize_buttons()
	_setup_input()
	_update_menu_visibility()

func _find_buttons() -> void:
	# Buscar botões automaticamente se não estiverem atribuídos
	if not start_button:
		start_button = get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/start_btn") as Button
		if start_button:
			print("Botão Iniciar Jogo encontrado")
		else:
			push_error("Botão Iniciar Jogo não encontrado!")
	
	if not continue_button:
		continue_button = get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/continue_btn") as Button
		if continue_button:
			print("Botão Continuar encontrado")
		else:
			push_warning("Botão Continuar não encontrado!")
	
	if not quit_button:
		quit_button = get_node_or_null("MarginContainer/HBoxContainer/VBoxContainer/quit_btn") as Button
		if quit_button:
			print("Botão Sair encontrado")
		else:
			push_error("Botão Sair não encontrado!")

func _initialize_buttons() -> void:
	# Conectar botões se não estiverem conectados
	if start_button:
		# Desconectar primeiro para evitar duplicatas
		if start_button.pressed.is_connected(_on_start_btn_pressed):
			start_button.pressed.disconnect(_on_start_btn_pressed)
		start_button.pressed.connect(_on_start_btn_pressed)
		print("Botão Iniciar Jogo conectado")
	
	if continue_button:
		# Desconectar primeiro para evitar duplicatas
		if continue_button.pressed.is_connected(_on_continue_btn_pressed):
			continue_button.pressed.disconnect(_on_continue_btn_pressed)
		continue_button.pressed.connect(_on_continue_btn_pressed)
		print("Botão Continuar conectado")
	
	if quit_button:
		# Desconectar primeiro para evitar duplicatas
		if quit_button.pressed.is_connected(_on_quit_btn_pressed):
			quit_button.pressed.disconnect(_on_quit_btn_pressed)
		quit_button.pressed.connect(_on_quit_btn_pressed)
		print("Botão Sair conectado")

func _setup_input() -> void:
	# Permitir fechar o jogo com ESC
	set_process_input(true)

func _update_menu_visibility() -> void:
	# Mostra o botão Continuar apenas se houver save
	if continue_button:
		continue_button.visible = SaveManager.has_save()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE):
		_on_quit_btn_pressed()

func _on_start_btn_pressed() -> void:
	print("Iniciando novo jogo...")
	# Limpa o save anterior ao iniciar novo jogo
	SaveManager.clear_save()
	SaveManager.save_game_started()
	var error = get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("Erro ao carregar a cena do jogo: %d" % error)

func _on_continue_btn_pressed() -> void:
	print("Continuando jogo...")
	var error = get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("Erro ao carregar a cena do jogo: %d" % error)

func _on_quit_btn_pressed() -> void:
	print("Saindo do jogo...")
	get_tree().quit()
