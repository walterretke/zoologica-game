extends Resource
class_name Animal

## O "molde" (blueprint) que este animal usou
@export var template: AnimalTemplate 

# --- Dados da Instância (criados no código) ---
var nome: String
var purchase_price: int
var purchase_date: String # Data da compra

## Esta é a função "Construtor"
## É chamada quando você escreve 'Animal.new()'
func _init(p_template: AnimalTemplate = null):
	if p_template:
		self.template = p_template
		self.nome = p_template.nome_exibicao
		self.purchase_price = p_template.base_price
		# Pega a data e hora atual do sistema
		self.purchase_date = Time.get_datetime_string_from_system()
