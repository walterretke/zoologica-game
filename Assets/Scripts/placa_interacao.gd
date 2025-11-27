extends Area2D
class_name PlacaInteracao

## Script para detectar quando o jogador se aproxima da placa e permitir interação

signal jogador_entrou
signal jogador_saiu
signal desafio_solicitado(tipo_desafio: String)

@export var tipo_desafio: String = "elefante"  # elefante, leao, macaco, girafa, zebra
@export var nome_jaula: String = "Jaula do Elefante"

var jogador_proximo: bool = false
var _player: CharacterBody2D = null

func _ready() -> void:
	# Conectar sinais de colisão
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configurar collision layer/mask para detectar apenas o player
	collision_layer = 0
	collision_mask = 1  # Player está na layer 1
	
	# Configurar monitoramento ativo
	monitoring = true
	monitorable = false

func _on_body_entered(body: Node2D) -> void:
	# Verificar se é o jogador (pode ser por grupo ou método)
	if body is CharacterBody2D:
		if body.is_in_group("player") or body.has_method("adicionar_moedas"):
			jogador_proximo = true
			_player = body
			jogador_entrou.emit()
			print("Jogador entrou na área da placa: ", nome_jaula)

func _on_body_exited(body: Node2D) -> void:
	# Verificar se é o jogador
	if body is CharacterBody2D:
		if body.is_in_group("player") or body.has_method("adicionar_moedas"):
			jogador_proximo = false
			_player = null
			jogador_saiu.emit()
			print("Jogador saiu da área da placa: ", nome_jaula)

func get_jogador() -> CharacterBody2D:
	return _player

func solicitar_desafio() -> void:
	if jogador_proximo:
		desafio_solicitado.emit(tipo_desafio)

