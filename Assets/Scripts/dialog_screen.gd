extends Control
class_name DialogScreen

# Velocidade de digitação (segundos por caractere)
@export var typing_speed: float = 0.05
# Velocidade rápida quando segurar o botão
@export var fast_typing_speed: float = 0.01
# Se pode pular o diálogo atual
var can_skip: bool = false

var _id: int = 0
var data: Dictionary = {}
var _is_typing: bool = false

@export_category("Objects")
@export var _name: Label = null
@export var _dialog: RichTextLabel = null
@export var _faceset: TextureRect = null

func _ready() -> void:
	if data.is_empty():
		push_warning("DialogScreen iniciado sem dados! Fechando...")
		queue_free()
		return
	
	_initialize_dialog()

func _input(event: InputEvent) -> void:
	# Pular diálogo com Enter ou Espaço
	if event.is_action_pressed("ui_accept"):
		if _is_typing:
			# Se está digitando, completa o texto imediatamente
			_complete_current_dialog()
		else:
			# Se terminou de digitar, avança para o próximo
			_advance_dialog()

func _initialize_dialog() -> void:
	if _id >= data.size():
		_close_dialog()
		return
	
	if not data.has(_id):
		push_error("Dados de diálogo inválidos para ID: %d" % _id)
		_close_dialog()
		return
	
	var dialog_data = data[_id]
	
	# Atualizar nome do personagem
	if _name and dialog_data.has("title"):
		_name.text = dialog_data["title"]
	
	# Atualizar imagem do personagem
	if _faceset and dialog_data.has("faceset"):
		var texture = load(dialog_data["faceset"]) as Texture2D
		if texture:
			_faceset.texture = texture
		else:
			push_warning("Não foi possível carregar a imagem: %s" % dialog_data["faceset"])
	
	# Atualizar texto do diálogo
	if _dialog and dialog_data.has("dialog"):
		_dialog.text = dialog_data["dialog"]
		_dialog.visible_characters = 0
		_start_typing_animation()
	else:
		_is_typing = false

func _start_typing_animation() -> void:
	_is_typing = true
	can_skip = true
	
	# Animar o texto aparecendo
	while _dialog.visible_ratio < 1.0:
		var current_speed = fast_typing_speed if Input.is_action_pressed("ui_accept") else typing_speed
		await get_tree().create_timer(current_speed).timeout
		_dialog.visible_characters += 1
	
	_is_typing = false
	can_skip = false

func _complete_current_dialog() -> void:
	if _is_typing and _dialog:
		_dialog.visible_characters = -1  # Mostra todo o texto
		_is_typing = false
		can_skip = false

func _advance_dialog() -> void:
	_id += 1
	if _id >= data.size():
		_close_dialog()
		return
	
	_initialize_dialog()

func _close_dialog() -> void:
	print("Fechando diálogo...")
	queue_free()
