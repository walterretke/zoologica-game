extends Control
class_name PauseMenu

@export_category("Objects")
@export var resume_button: Button = null
@export var quit_button: Button = null

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

func _on_quit_btn_pressed() -> void:
	print("Saindo para o menu principal...")
	# Despausar o jogo antes de mudar de cena
	get_tree().paused = false
	# Salvar que o jogo foi iniciado
	SaveManager.save_game_started()
	# Voltar para o menu principal
	var error = get_tree().change_scene_to_file(MENU_SCENE)
	if error != OK:
		push_error("Erro ao carregar o menu principal: %d" % error)

func _unhandled_input(event: InputEvent) -> void:
	# Permitir fechar o menu de pausa com ESC também
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		_on_resume_btn_pressed()
		get_viewport().set_input_as_handled()

