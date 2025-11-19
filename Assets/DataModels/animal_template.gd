extends Resource
class_name AnimalTemplate

## O ID único do template, ex: "LEAO_ADULTO"
@export var id_nome: String = ""
## O nome que aparece no jogo, ex: "Leão"
@export var nome_exibicao: String = "Leão"
## O custo para comprar este animal
@export var base_price: int = 100
## O ícone que aparece na loja
@export_file("*.png", "*.jpg") var icone: String = ""
## A animação do animal que aparece na jaula (SpriteFrames)
## Arraste aqui o arquivo .tres do SpriteFrames criado a partir do GIF
## Exemplo: res://Assets/Sprites/Animais/leao.tres
@export var animacao_sprite: SpriteFrames = null
