extends Node2D

const _SHOP_SCREEN:PackedScene = preload("res://Assets/Scene/shop_screen.tscn")
const _PAUSE_MENU:PackedScene = preload("res://Assets/Scene/pause_menu.tscn")

@export_category("Objects")
@export var _hud: CanvasLayer = null
@export var _shop_button: Button = null
@export var _player: CharacterBody2D = null
@export var _moedas_label: Label = null

func _ready() -> void:
	_initialize_shop_button()
	_initialize_player()
	_initialize_moedas_display()
	# Salvar que o jogo foi iniciado quando entrar na cena
	SaveManager.save_game_started()
	# Garantir que o input está sendo processado
	set_process_input(true)
	set_process_unhandled_input(true)
	print("Game.gd inicializado - Input habilitado")
	if not _hud:
		push_error("HUD não encontrado no game.gd!")
	else:
		print("HUD encontrado: ", _hud.name)

func _initialize_shop_button() -> void:
	if _shop_button:
		if not _shop_button.pressed.is_connected(_open_shop):
			_shop_button.pressed.connect(_open_shop)
			print("Botão Loja conectado com sucesso!")
		else:
			print("Botão Loja já estava conectado.")
	else:
		push_warning("Botão Loja não encontrado! A loja pode ser aberta apenas com a tecla L.")

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

func _initialize_moedas_display() -> void:
	if _player and _moedas_label:
		if not _player.moedas_atualizadas.is_connected(_on_moedas_updated):
			_player.moedas_atualizadas.connect(_on_moedas_updated)
		_update_moedas_display()

func _input(event: InputEvent) -> void:
	# Abrir menu de pausa com ESC (apenas se não estiver pausado)
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		print("ESC pressionado no game.gd - pausado: ", get_tree().paused)
		if not get_tree().paused:
			_open_pause_menu()
		get_viewport().set_input_as_handled()
		return
	
	# Abrir loja com a tecla L (apenas se não estiver pausado)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_L and not get_tree().paused:
			_open_shop()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	# Garantir que ESC funciona mesmo se outros nós não processarem
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		print("ESC pressionado no _unhandled_input - pausado: ", get_tree().paused)
		if not get_tree().paused:
			_open_pause_menu()
		get_viewport().set_input_as_handled()

func _update_moedas_display() -> void:
	if _moedas_label and _player:
		_moedas_label.text = GameUtils.format_moedas_hud(_player.total_moedas)

func _on_moedas_updated(nova_quantidade: int) -> void:
	_update_moedas_display()

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
	
	# Criar e adicionar a tela da loja
	var shop_screen = _SHOP_SCREEN.instantiate() as ShopScreen
	if not shop_screen:
		push_error("Falha ao instanciar a tela da loja!")
		return
	
	shop_screen.set_player(_player)
	_hud.add_child(shop_screen)
	print("Loja aberta com sucesso!")

func _open_pause_menu() -> void:
	if not _hud:
		push_error("HUD não encontrado! Não é possível abrir o menu de pausa.")
		return
	
	# Verificar se o menu de pausa já está aberto
	for child in _hud.get_children():
		if child is PauseMenu:
			return  # Menu de pausa já está aberto
	
	# Verificar se a loja está aberta (não abrir pausa se a loja estiver aberta)
	for child in _hud.get_children():
		if child is ShopScreen:
			return  # Loja está aberta, não abrir pausa
	
	# Criar e adicionar o menu de pausa
	var pause_menu = _PAUSE_MENU.instantiate()
	if not pause_menu:
		push_error("Falha ao instanciar o menu de pausa!")
		return
	
	_hud.add_child(pause_menu)
	print("Menu de pausa aberto!")

