extends Panel
class_name ShopCageItem

signal purchase_requested(cage_type: CageType)

var cage_type: CageType = null
var player: CharacterBody2D = null

@export_category("Objects")
@export var _name_label: Label = null
@export var _price_label: Label = null
@export var _description_label: Label = null
@export var _buy_button: Button = null
@export var _difficulty_label: Label = null

func _ready() -> void:
	if _buy_button:
		_buy_button.pressed.connect(_on_buy_pressed)
	
	# Se o setup já foi chamado antes do _ready, atualizar agora
	if cage_type:
		call_deferred("_update_display")

func setup(p_cage_type: CageType, p_player: CharacterBody2D) -> void:
	cage_type = p_cage_type
	player = p_player
	
	# Usar call_deferred para garantir que o nó esteja pronto
	call_deferred("_update_display")

func _update_display() -> void:
	if not cage_type:
		push_error("cage_type é null em _update_display()")
		return
	
	# Atualizar nome
	if _name_label:
		var nome = cage_type.nome_exibicao if cage_type.nome_exibicao else "Jaula"
		_name_label.text = nome
	else:
		push_warning("_name_label é null! Verifique se está atribuído no .tscn")
	
	# Atualizar dificuldade
	if _difficulty_label:
		var difficulty = cage_type.difficulty_level if cage_type.difficulty_level > 0 else 1
		var difficulty_text = _get_difficulty_text(difficulty)
		_difficulty_label.text = difficulty_text
		_difficulty_label.visible = true  # Garantir que está visível
		
		# Mudar cor baseado na dificuldade usando função auxiliar
		var difficulty_color = GameUtils.get_difficulty_color(difficulty)
		
		if _difficulty_label.label_settings:
			_difficulty_label.label_settings.font_color = difficulty_color
		else:
			_difficulty_label.add_theme_color_override("font_color", difficulty_color)
		
		# Garantir que o painel pai também está visível
		var badge_panel = _difficulty_label.get_parent()
		if badge_panel:
			badge_panel.visible = true
	
	# Atualizar preço
	if _price_label:
		var price = cage_type.base_price
		var price_text: String
		if price <= 0:
			price_text = "GRÁTIS"
		else:
			price_text = GameUtils.format_currency(price)
		_price_label.text = price_text
	
	# Atualizar descrição
	if _description_label:
		var desc = cage_type.description if cage_type.description else "Uma jaula para seus animais."
		_description_label.text = desc
	
	# Atualizar botão de compra
	if _buy_button and player:
		var preco = cage_type.base_price
		# Se o preço for negativo ou zero, sempre pode comprar (grátis)
		# Se o preço for positivo, verifica se tem moedas suficientes
		var can_afford = preco <= 0 or player.total_moedas >= preco
		var ja_tem = false
		if player:
			for jaula in player.jaulas_possuidas:
				# Comparar usando resource_path para garantir que funcione corretamente
				if jaula.cage_type and cage_type:
					if jaula.cage_type.resource_path == cage_type.resource_path:
						ja_tem = true
						break
		
		if ja_tem:
			_buy_button.disabled = true
			_buy_button.text = "JÁ POSSUI"
		elif can_afford:
			_buy_button.disabled = false
			_buy_button.text = "COMPRAR"
		else:
			_buy_button.disabled = true
			_buy_button.text = "MOEDAS INSUFICIENTES"

func _get_difficulty_text(difficulty: int) -> String:
	match difficulty:
		1:
			return "INICIANTE"
		2:
			return "FÁCIL"
		3:
			return "MÉDIO"
		4:
			return "DIFÍCIL"
		5:
			return "INTELIGENTE"
		_:
			return "INICIANTE"  # Default

func _on_buy_pressed() -> void:
	if cage_type and player:
		# Verificar novamente se pode comprar antes de emitir
		var preco = cage_type.base_price
		var can_afford = preco <= 0 or player.total_moedas >= preco
		if can_afford:
			purchase_requested.emit(cage_type)
		else:
			print("Moedas insuficientes!")

