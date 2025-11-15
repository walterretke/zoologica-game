extends Resource
class_name CageType

## O nome que aparece no jogo, ex: "Jaula do Leão"
@export var nome_exibicao: String = "Jaula"

## O custo para comprar esta jaula (REQ: Preço base)
@export var base_price: int = 1000

## A cena da missão que esta jaula inicia (REQ: Iniciar missão)
## (Aqui você vai arrastar seu arquivo .tscn da missão)
@export_file("*.tscn") var missao_cena: String = ""

## A lista de 'moldes' de animais que esta jaula aceita.
## (REQ: Compatível com o animal)
@export var animal_templates_aceitos: Array[AnimalTemplate] = []

# --- Bônus (do seu modelo Java) ---
## Nível de dificuldade (1-5)
@export var difficulty_level: int = 1
## Descrição da jaula na loja
@export_multiline var description: String = ""
