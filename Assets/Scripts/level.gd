extends Node2D
class_name Level

const _DIALOG_SCREEN:PackedScene = preload("res://Assets/Scene/dialog_screen.tscn")
const _SHOP_SCREEN:PackedScene = preload("res://Assets/Scene/shop_screen.tscn")

# Dados do diálogo inicial
var _dialog_data: Dictionary = {
	0: {
		"faceset": "res://Assets/Sprites/imagens_dialogo/0.0.1 - Imagem Tela Dialogo Perosnagem Principal 2.png",
		"dialog": "Olá, Bem vindos ao ZoOlógica",
		"title": "Joseph" 
	},
	
	1: {
		"faceset": "res://Assets/Sprites/imagens_dialogo/0.0.1 - Imagem Tela Dialogo Perosnagem Amelia.png",
		"dialog": "Aqui voce vai adentrar ao Zoológica e aprender bastante",
		"title": "Amelia" 
	},
	
	2: {
		"faceset": "res://Assets/Sprites/imagens_dialogo/0.0.1 - Imagem Tela Dialogo Perosnagem Avó.png",
		"dialog": "Aqui voce aprendera os principais fundamentos da matemática",
		"title": "Avô" 
	},
	
	3: {
		"faceset": "res://Assets/Sprites/imagens_dialogo/0.0.1 - Imagem Tela Dialogo Perosnagem Marcus.png",
		"dialog": "E eu irei lhe ajudar para tirar todas as suas dúvidas",
		"title": "Marcus" 
	}
} 

@export_category("Objects")
@export var _hud: CanvasLayer = null
@export var _shop_button: Button = null
@export var _player: CharacterBody2D = null
@export var auto_show_dialog: bool = false  # Se deve mostrar o diálogo automaticamente ao iniciar

func _ready() -> void:
	_initialize_shop_button()
	_initialize_player()
	
	# Mostrar diálogo automaticamente se configurado
	if auto_show_dialog:
		call_deferred("_show_initial_dialog")

func _initialize_shop_button() -> void:
	if _shop_button:
		if not _shop_button.pressed.is_connected(_on_shop_button_pressed):
			_shop_button.pressed.connect(_on_shop_button_pressed)
			print("Botão Loja conectado com sucesso!")
		else:
			print("Botão Loja já estava conectado.")
	else:
		push_warning("Botão Loja não encontrado! Verifique o caminho no level.tscn")

func _initialize_player() -> void:
	# Encontrar o player se não foi atribuído
	if not _player:
		_player = get_node_or_null("CharacterBody2D2") as CharacterBody2D
		if not _player:
			# Tentar encontrar o player de outras formas
			_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
			if not _player:
				# Procurar qualquer CharacterBody2D que tenha o script do player
				for child in get_children():
					if child is CharacterBody2D and child.has_method("comprar_jaula"):
						_player = child
						break
	
	if not _player:
		push_warning("Player não encontrado! A loja pode não funcionar corretamente.")
	else:
		print("Player encontrado: ", _player.name)

func _input(event: InputEvent) -> void:
	# Abrir diálogo com a tecla D
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			_show_initial_dialog()
	
	# Abrir loja com a tecla L
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_L:
			_open_shop()

func _show_initial_dialog() -> void:
	if not _hud:
		push_error("HUD não encontrado! Não é possível mostrar o diálogo.")
		return
	
	# Verificar se já existe um diálogo aberto
	for child in _hud.get_children():
		if child is DialogScreen:
			return  # Diálogo já está aberto
	
	var new_dialog = _DIALOG_SCREEN.instantiate() as DialogScreen
	if not new_dialog:
		push_error("Falha ao instanciar a tela de diálogo!")
		return
	
	new_dialog.data = _dialog_data
	_hud.add_child(new_dialog)
	print("Diálogo inicial exibido!")

func _open_shop() -> void:
	if not _hud:
		push_error("HUD não encontrado! Não é possível abrir a loja.")
		return
	
	if not _player:
		push_error("Player não encontrado! Não é possível abrir a loja.")
		return
	
	# Verificar se a loja já está aberta
	for child in _hud.get_children():
		if child is ShopScreen:
			return  # Loja já está aberta
	
	var shop_screen = _SHOP_SCREEN.instantiate() as ShopScreen
	if not shop_screen:
		push_error("Falha ao instanciar a tela da loja!")
		return
	
	shop_screen.set_player(_player)
	_hud.add_child(shop_screen)
	print("Loja aberta com sucesso!")

func _on_shop_button_pressed() -> void:
	_open_shop()
