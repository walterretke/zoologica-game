extends Control
class_name KeymapDisplay

@export_category("Objects")
@export var close_label: Label = null

func _ready() -> void:
	_find_ui_elements()
	_initialize_ui()

func _find_ui_elements() -> void:
	if not close_label:
		close_label = get_node_or_null("VBoxContainer/CloseLabel") as Label

func _initialize_ui() -> void:
	# Atualizar texto de fechar
	if close_label:
		close_label.text = "Pressione H para fechar"
	
	# Permitir fechar com H
	set_process_input(true)

func _input(event: InputEvent) -> void:
	# Fechar com H
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		_on_close()
		get_viewport().set_input_as_handled()

func _on_close() -> void:
	print("Fechando mapa de teclas...")
	queue_free()

