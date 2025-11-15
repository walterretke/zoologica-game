extends Panel
class_name ShopAnimalItem

signal purchase_requested(animal_template: AnimalTemplate, target_cage: Cage)

var animal_template: AnimalTemplate = null
var target_cage: Cage = null
var player: CharacterBody2D = null
var available_cages: Array[Cage] = []

@export_category("Objects")
@export var _name_label: Label = null
@export var _price_label: Label = null
@export var _cage_select: OptionButton = null
@export var _buy_button: Button = null
@export var _space_label: Label = null

func _ready() -> void:
	if _buy_button:
		_buy_button.pressed.connect(_on_buy_pressed)
	if _cage_select:
		_cage_select.item_selected.connect(_on_cage_selected)

func setup(p_animal_template: AnimalTemplate, p_player: CharacterBody2D, p_available_cages: Array[Cage]) -> void:
	animal_template = p_animal_template
	player = p_player
	available_cages = p_available_cages
	
	_update_display()

func _update_display() -> void:
	if not animal_template:
		return
	
	# Atualizar nome
	if _name_label:
		_name_label.text = animal_template.nome_exibicao if animal_template.nome_exibicao else "Animal"
	
	# Atualizar preço
	if _price_label:
		var price = animal_template.base_price
		var price_text: String
		if price == 0:
			price_text = "GRÁTIS"
		else:
			price_text = GameUtils.format_currency(price)
		_price_label.text = price_text
	
	# Atualizar seletor de jaulas
	if _cage_select:
		_cage_select.clear()
		for cage in available_cages:
			# Contar quantos animais deste tipo já existem na jaula
			var count_this_animal = 0
			for animal in cage.animals:
				if animal.template and animal_template:
					# Comparar usando resource_path para garantir que funcione corretamente
					if animal.template.resource_path == animal_template.resource_path:
						count_this_animal += 1
			
			var total_animais = cage.animals.size()
			var cage_name = "%s (%d/%d)" % [cage.cage_type.nome_exibicao, total_animais, 10]
			if count_this_animal > 0:
				cage_name += " - Você tem %d" % count_this_animal
			_cage_select.add_item(cage_name)
		
		# Selecionar primeira jaula por padrão
		if available_cages.size() > 0:
			target_cage = available_cages[0]
			_cage_select.selected = 0
			_update_space_info()
	
	# Atualizar botão de compra
	_update_buy_button()

func _update_space_info() -> void:
	if not target_cage or not _space_label:
		return
	
	var current = target_cage.animals.size()
	var max_animals = 10
	
	if _space_label:
		_space_label.text = "Espaço: %d/%d" % [current, max_animals]
		var space_color = GameUtils.get_space_color(current, max_animals)
		_space_label.add_theme_color_override("font_color", space_color)

func _update_buy_button() -> void:
	if not _buy_button or not player or not animal_template or not target_cage:
		return
	
	var preco = animal_template.base_price
	# Se o preço for negativo ou zero, sempre pode comprar (ganha moedas ou grátis)
	# Se o preço for positivo, verifica se tem moedas suficientes
	var can_afford = preco <= 0 or player.total_moedas >= preco
	var has_space = target_cage.can_add_more_animals()
	var is_compatible = animal_template in target_cage.cage_type.animal_templates_aceitos
	
	if not has_space:
		_buy_button.disabled = true
		_buy_button.text = "JAULA CHEIA"
	elif not is_compatible:
		_buy_button.disabled = true
		_buy_button.text = "INCOMPATÍVEL"
	elif can_afford:
		_buy_button.disabled = false
		_buy_button.text = "COMPRAR"
	else:
		_buy_button.disabled = true
		_buy_button.text = "MOEDAS INSUFICIENTES"

func _on_cage_selected(index: int) -> void:
	if index >= 0 and index < available_cages.size():
		target_cage = available_cages[index]
		_update_space_info()
		_update_buy_button()

func _on_buy_pressed() -> void:
	if animal_template and target_cage and player:
		# Verificar novamente se pode comprar antes de emitir
		var preco = animal_template.base_price
		# Preços negativos sempre podem ser comprados (você ganha moedas)
		# Preços positivos precisam verificar se tem moedas suficientes
		var can_afford = preco <= 0 or player.total_moedas >= preco
		if can_afford and target_cage.can_add_more_animals():
			purchase_requested.emit(animal_template, target_cage)
		else:
			print("Não é possível comprar este animal!")

# Função para atualizar o item após uma compra ou mudança
func refresh() -> void:
	_update_display()

