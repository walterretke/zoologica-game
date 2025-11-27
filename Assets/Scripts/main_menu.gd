extends Control
class_name MainMenu

## Script da Tela Inicial do jogo Zoologica

# Referências aos botões
@onready var btn_iniciar: Button = $ContainerIniciar/BtnIniciar
@onready var btn_creditos: Button = $ContainerCreditos/BtnCreditos
@onready var btn_sair: Button = $ContainerSair/BtnSair

# Painel de créditos
@onready var creditos_panel: PanelContainer = $CreditosPanel

func _ready() -> void:
	# Conectar sinais dos botões
	btn_iniciar.pressed.connect(_on_iniciar_pressed)
	btn_creditos.pressed.connect(_on_creditos_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)
	
	# Esconder painel de créditos inicialmente
	if creditos_panel:
		creditos_panel.visible = false
	
	# Garantir que não está pausado
	get_tree().paused = false
	
	print("Tela inicial carregada!")

func _on_iniciar_pressed() -> void:
	print("Iniciando jogo...")
	# Carregar a cena do jogo
	get_tree().change_scene_to_file("res://Assets/Scene/game.tscn")

func _on_creditos_pressed() -> void:
	print("Abrindo créditos...")
	if creditos_panel:
		creditos_panel.visible = true

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
