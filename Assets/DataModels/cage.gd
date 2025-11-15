extends Resource
class_name Cage

## O "molde" (blueprint) que esta jaula usou
@export var cage_type: CageType

# --- Dados da Instância (criados no código) ---
var purchase_price: int
var purchase_date: String

## A lista de animais REAIS (instâncias) que estão dentro desta jaula
@export var animals: Array[Animal] = []

## A lista de problemas de matemática associados (ainda não usamos)
@export var math_problems: Array = [] 

## Construtor - Chamado quando você escreve 'Cage.new()'
func _init(p_cage_type: CageType = null):
	if p_cage_type:
		self.cage_type = p_cage_type
		self.purchase_price = p_cage_type.base_price
		self.purchase_date = Time.get_datetime_string_from_system()
		# Inicializa os arrays vazios
		self.animals = []
		self.math_problems = []

# --- Funções de Lógica (Traduzidas do seu Java) ---

## Retorna o multiplicador de pontuação baseado no nº de animais
func get_animal_multiplier() -> float:
	if animals.is_empty():
		return 1.0
	# Lógica: 1 animal = 1.0, 2 animais = 1.25, 3 animais = 1.50 ...
	return 1.0 + ((animals.size() - 1) * 0.25)

## Verifica se a jaula tem espaço
func can_add_more_animals() -> bool:
	return animals.size() < 10 # Limite de 10 animais

# --- Funções de "Serviço" (Lógica de Compra) ---

## Tenta adicionar um animal. Retorna o NOVO total de moedas do jogador.
## Se a compra falhar, retorna o valor original.
func comprar_animal(player_moedas: int, animal_template: AnimalTemplate) -> int:
	
	# 1. Verifica se a jaula está cheia
	if not can_add_more_animals():
		print("Erro: Jaula cheia!")
		return player_moedas # Compra falhou

	# 2. Verifica se a jaula aceita este tipo de animal (COMPATIBILIDADE)
	if not animal_template in cage_type.animal_templates_aceitos:
		print("Erro: Esta jaula não aceita este tipo de animal!")
		return player_moedas # Compra falhou
	
	# 3. Verifica se o jogador tem dinheiro (apenas se o preço for positivo)
	var preco = animal_template.base_price
	if preco > 0:  # Apenas verifica se o preço é positivo
		if player_moedas < preco:
			print("Erro: Dinheiro insuficiente!")
			return player_moedas # Compra falhou

	# 4. OK, pode comprar!
	# Cria a "instância" do animal
	var novo_animal = Animal.new(animal_template)
	animals.append(novo_animal)
	
	print("Animal '%s' comprado por %d moedas" % [novo_animal.nome, preco])
	
	# Retorna o novo total de moedas do jogador
	# Se o preço for negativo ou zero, não desconta (animais grátis)
	if preco > 0:
		return player_moedas - preco
	else:
		return player_moedas  # Animal grátis, não desconta moedas
