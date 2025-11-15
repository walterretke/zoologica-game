extends Control
class_name ShopScreen

# Referência ao jogador
var player: CharacterBody2D = null

# Lista de jaulas disponíveis na loja
var available_cages: Array[CageType] = []
# Lista de animais disponíveis na loja
var available_animals: Array[AnimalTemplate] = []

@export_category("Objects")
@export var _moedas_label: Label = null
@export var _cages_container: VBoxContainer = null
@export var _animals_container: VBoxContainer = null
@export var _close_button: Button = null
@export var _tab_container: TabContainer = null

# Cena do item de jaula (será criado dinamicamente)
const CAGE_ITEM_SCENE = preload("res://Assets/Scene/shop_cage_item.tscn")
# Cena do item de animal (será criado dinamicamente)
const ANIMAL_ITEM_SCENE = preload("res://Assets/Scene/shop_animal_item.tscn")

func _ready() -> void:
	# Carregar todas as jaulas disponíveis
	_load_available_cages()
	
	# Carregar todos os animais disponíveis
	_load_available_animals()
	
	# Atualizar a interface primeiro
	_update_ui()
	
	# Conectar o botão de fechar (depois de atualizar UI para garantir que o botão existe)
	call_deferred("_connect_close_button")
	
	# Conectar mudança de aba
	if _tab_container:
		_tab_container.tab_changed.connect(_on_tab_changed)
	
	# Também permitir fechar com ESC
	set_process_input(true)

func _connect_close_button() -> void:
	if _close_button:
		if not _close_button.pressed.is_connected(_on_close_pressed):
			_close_button.pressed.connect(_on_close_pressed)
			print("Botão fechar conectado!")
		else:
			print("Botão fechar já estava conectado!")
	else:
		print("ERRO: Botão fechar não encontrado!")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE):
		_on_close_pressed()

func _load_available_cages() -> void:
	# Carregar todas as jaulas do diretório DataModels
	var cage_paths = [
		"res://Assets/DataModels/lion_cage.tres",
		"res://Assets/DataModels/elephant_cage.tres",
		"res://Assets/DataModels/monkey_cage.tres",
		"res://Assets/DataModels/zebra_cage.tres",
		"res://Assets/DataModels/giraffe_cage.tres"
	]
	
	for path in cage_paths:
		var cage_type = load(path) as CageType
		if cage_type:
			available_cages.append(cage_type)
	
	# Ordenar por dificuldade (mais fáceis primeiro)
	available_cages.sort_custom(func(a, b): 
		var diff_a = a.difficulty_level if a.difficulty_level > 0 else 1
		var diff_b = b.difficulty_level if b.difficulty_level > 0 else 1
		return diff_a < diff_b
	)

func _load_available_animals() -> void:
	# Carregar todos os animais do diretório DataModels
	var animal_paths = [
		"res://Assets/DataModels/lion.tres",
		"res://Assets/DataModels/elephant.tres",
		"res://Assets/DataModels/monkey.tres",
		"res://Assets/DataModels/zebra.tres",
		"res://Assets/DataModels/giraffe.tres"
	]
	
	for path in animal_paths:
		var animal_template = load(path) as AnimalTemplate
		if animal_template:
			available_animals.append(animal_template)

func _update_ui() -> void:
	# Atualizar moedas com formatação
	if player and _moedas_label:
		_moedas_label.text = GameUtils.format_currency(player.total_moedas)
	
	# Atualizar seção de jaulas
	_update_cages_section()
	
	# Atualizar seção de animais
	_update_animals_section()

func _update_cages_section() -> void:
	# Limpar container de jaulas
	if _cages_container:
		for child in _cages_container.get_children():
			child.queue_free()
		
		# Adicionar cada jaula disponível
		for cage_type in available_cages:
			var cage_item = CAGE_ITEM_SCENE.instantiate()
			cage_item.setup(cage_type, player)
			cage_item.purchase_requested.connect(_on_cage_purchased)
			_cages_container.add_child(cage_item)

func _update_animals_section() -> void:
	if not player or not _animals_container:
		return
	
	# Limpar container de animais
	for child in _animals_container.get_children():
		child.queue_free()
	
	# Obter todas as jaulas que o jogador possui
	var player_cages = player.jaulas_possuidas
	
	if player_cages.is_empty():
		# Se não tem jaulas, mostrar mensagem
		var empty_label = Label.new()
		empty_label.text = "Você precisa comprar jaulas primeiro!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_animals_container.add_child(empty_label)
		return
	
	# Para cada animal disponível, verificar se é compatível com alguma jaula
	for animal_template in available_animals:
		# Encontrar todas as jaulas compatíveis com este animal
		var compatible_cages: Array[Cage] = []
		for cage in player_cages:
			if animal_template in cage.cage_type.animal_templates_aceitos:
				compatible_cages.append(cage)
		
		# Se encontrou jaulas compatíveis, adicionar o animal à loja
		if not compatible_cages.is_empty():
			var animal_item = ANIMAL_ITEM_SCENE.instantiate()
			animal_item.setup(animal_template, player, compatible_cages)
			animal_item.purchase_requested.connect(_on_animal_purchased)
			_animals_container.add_child(animal_item)

func _on_cage_purchased(cage_type: CageType) -> void:
	if not player:
		push_error("Player não encontrado! Não é possível comprar a jaula.")
		return
	
	# Verificar se já possui a jaula (máximo 1 de cada tipo)
	var ja_tem = false
	for jaula in player.jaulas_possuidas:
		# Comparar usando resource_path para garantir que funcione corretamente
		if jaula.cage_type and cage_type:
			if jaula.cage_type.resource_path == cage_type.resource_path:
				ja_tem = true
				break
	
	if ja_tem:
		print("Você já possui esta jaula! Máximo de 1 de cada tipo.")
		# TODO: Adicionar feedback visual (toast, som, etc.)
		return
	
	# Guardar moedas antes da compra para feedback
	var moedas_antes = player.total_moedas
	
	# Tentar comprar a jaula
	player.comprar_jaula(cage_type)
	
	# Verificar se a compra foi bem-sucedida
	if player.total_moedas < moedas_antes or cage_type.base_price <= 0:
		print("Jaula '%s' comprada com sucesso!" % cage_type.nome_exibicao)
		# TODO: Adicionar feedback visual positivo
	
	# Atualizar a UI
	_update_ui()

func _on_animal_purchased(animal_template: AnimalTemplate, target_cage: Cage) -> void:
	if not player:
		push_error("Player não encontrado! Não é possível comprar o animal.")
		return
	
	# Guardar moedas antes da compra para feedback
	var moedas_antes = player.total_moedas
	
	# Comprar o animal para a jaula selecionada
	player.comprar_animal_para_jaula(target_cage, animal_template)
	
	# Verificar se a compra foi bem-sucedida
	var compra_sucesso = false
	if animal_template.base_price <= 0:
		compra_sucesso = true  # Grátis ou ganho de moedas
	elif player.total_moedas < moedas_antes:
		compra_sucesso = true  # Moedas foram descontadas
	
	if compra_sucesso:
		print("Animal '%s' comprado com sucesso!" % animal_template.nome_exibicao)
		# TODO: Adicionar feedback visual positivo
	
	# Atualizar a UI
	_update_ui()
	
	# Atualizar todos os itens de animal para refletir mudanças nas jaulas
	for child in _animals_container.get_children():
		if child is ShopAnimalItem:
			child.refresh()

func _on_tab_changed(tab: int) -> void:
	# Quando mudar de aba, atualizar a seção de animais para refletir mudanças
	if tab == 1:  # Aba de Animais
		_update_animals_section()

func _on_close_pressed() -> void:
	print("Botão fechar pressionado! Fechando loja...")
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	queue_free()

func set_player(p_player: CharacterBody2D) -> void:
	player = p_player
	if player:
		# Conectar ao sinal de moedas atualizadas
		if not player.moedas_atualizadas.is_connected(_on_moedas_updated):
			player.moedas_atualizadas.connect(_on_moedas_updated)
		_update_ui()

func _on_moedas_updated(nova_quantidade: int) -> void:
	_update_ui()

