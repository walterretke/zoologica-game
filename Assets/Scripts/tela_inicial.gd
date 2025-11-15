extends Control

@export_category("Objects")
@export var start_button: Button = null
@export var credits_button: Button = null
@export var quit_button: Button = null

# Cena do jogo principal
const GAME_SCENE = "res://Assets/Scene/game.tscn"

func _ready() -> void:
	_initialize_buttons()
	_setup_input()

func _initialize_buttons() -> void:
	# Conectar botões se não estiverem conectados
	if start_button:
		if not start_button.pressed.is_connected(_on_start_btn_pressed):
			start_button.pressed.connect(_on_start_btn_pressed)
	
	if credits_button:
		if not credits_button.pressed.is_connected(_on_credits_btn_pressed):
			credits_button.pressed.connect(_on_credits_btn_pressed)
	
	if quit_button:
		if not quit_button.pressed.is_connected(_on_quit_btn_pressed):
			quit_button.pressed.connect(_on_quit_btn_pressed)

func _setup_input() -> void:
	# Permitir fechar o jogo com ESC
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE):
		_on_quit_btn_pressed()

func _on_start_btn_pressed() -> void:
	print("Iniciando jogo...")
	var error = get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("Erro ao carregar a cena do jogo: %d" % error)

func _on_credits_btn_pressed() -> void:
	# TODO: Implementar tela de créditos
	print("Créditos (em desenvolvimento)")

func _on_quit_btn_pressed() -> void:
	print("Saindo do jogo...")
	get_tree().quit()
