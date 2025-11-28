extends Control
class_name MainMenu

## Script da Tela Inicial do jogo Zoologica

const INTRO_SCENE = "res://Assets/Scene/intro_story.tscn"
const GAME_SCENE = "res://Assets/Scene/game.tscn"

# Referências aos botões
@onready var btn_novo_jogo: Button = $ContainerIniciar/BtnIniciar
@onready var btn_carregar: Button = $ContainerCarregar/BtnCarregar
@onready var btn_creditos: Button = $ContainerCreditos/BtnCreditos
@onready var btn_configuracoes: Button = $ContainerConfiguracoes/BtnConfiguracoes
@onready var btn_sair: Button = $ContainerSair/BtnSair

# Painel de créditos
@onready var creditos_panel: PanelContainer = $CreditosPanel

func _ready() -> void:
	# Renomear botão se necessário
	if btn_novo_jogo:
		btn_novo_jogo.text = "CRIAR NOVO JOGO"
	
	# Conectar sinais dos botões
	if btn_novo_jogo:
		btn_novo_jogo.pressed.connect(_on_novo_jogo_pressed)
	if btn_carregar:
		btn_carregar.pressed.connect(_on_carregar_pressed)
		# Mostrar botão carregar apenas se houver save
		btn_carregar.visible = SaveManager.has_save()
	if btn_creditos:
		btn_creditos.pressed.connect(_on_creditos_pressed)
	if btn_configuracoes:
		btn_configuracoes.pressed.connect(_on_configuracoes_pressed)
	if btn_sair:
		btn_sair.pressed.connect(_on_sair_pressed)
	
	# Esconder painel de créditos inicialmente
	if creditos_panel:
		creditos_panel.visible = false
	
	# Garantir que não está pausado
	get_tree().paused = false
	
	# Iniciar música do menu
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_menu_music()
	
	print("Tela inicial carregada!")

func _on_novo_jogo_pressed() -> void:
	print("Criando novo jogo...")
	# Limpar save anterior
	SaveManager.clear_save()
	# Parar música do menu
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.stop_menu_music()
	# Carregar cena de introdução
	var error = get_tree().change_scene_to_file(INTRO_SCENE)
	if error != OK:
		push_error("Erro ao carregar cena de introdução: %d" % error)

func _on_carregar_pressed() -> void:
	print("Carregando jogo...")
	# Parar música do menu
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.stop_menu_music()
	# Carregar o jogo diretamente (sem introdução)
	var error = get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("Erro ao carregar cena do jogo: %d" % error)

func _on_creditos_pressed() -> void:
	print("Abrindo créditos...")
	if creditos_panel:
		creditos_panel.visible = true

func _on_configuracoes_pressed() -> void:
	print("Abrindo configurações...")
	var settings_scene = load("res://Assets/Scene/settings.tscn") as PackedScene
	if settings_scene:
		var settings_instance = settings_scene.instantiate()
		add_child(settings_instance)
	else:
		push_error("Não foi possível carregar a cena de configurações!")

func _on_sair_pressed() -> void:
	print("Saindo do jogo...")
	get_tree().quit()

func _fechar_creditos() -> void:
	if creditos_panel:
		creditos_panel.visible = false

func _input(event: InputEvent) -> void:
	# Fechar créditos com ESC ou clique
	if creditos_panel and creditos_panel.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed):
			_fechar_creditos()
			get_viewport().set_input_as_handled()
