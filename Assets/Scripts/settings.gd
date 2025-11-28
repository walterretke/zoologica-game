extends Control
class_name Settings

@export_category("Objects")
@export var background: TextureRect = null
@export var close_button: Button = null
@export var apply_button: Button = null
@export var volume_label: Label = null
@export var volume_slider: HSlider = null
@export var volume_value_label: Label = null

var _volume_temp: float = 1.0  # Volume temporário antes de aplicar

func _ready() -> void:
	_find_ui_elements()
	_initialize_ui()

func _find_ui_elements() -> void:
	if not background:
		background = get_node_or_null("Background") as TextureRect
	if not close_button:
		close_button = get_node_or_null("ContainerClose/CloseButton") as Button
	if not apply_button:
		apply_button = get_node_or_null("ContainerApply/ApplyButton") as Button
	if not volume_label:
		volume_label = get_node_or_null("ContainerVolume/VolumeLabel") as Label
	if not volume_slider:
		volume_slider = get_node_or_null("ContainerVolume/VBoxVolume/HBoxVolume/VolumeSlider") as HSlider
		if not volume_slider:
			# Tentar caminho alternativo
			volume_slider = get_node_or_null("ContainerVolume/VolumeSlider") as HSlider
	if not volume_value_label:
		volume_value_label = get_node_or_null("ContainerVolume/VBoxVolume/HBoxVolume/VolumeValueLabel") as Label
		if not volume_value_label:
			# Tentar caminho alternativo
			volume_value_label = get_node_or_null("ContainerVolume/VolumeValueLabel") as Label

func _initialize_ui() -> void:
	# Carregar imagem de fundo
	if background:
		var bg_texture = load("res://Assets/Sprites/Assests_Jogo/Jogo/0 .1- Como jogar.png") as Texture2D
		if bg_texture:
			background.texture = bg_texture
			background.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		else:
			push_warning("Não foi possível carregar imagem de fundo das configurações")
	
	# Conectar botões
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	
	# Configurar controles de volume
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		_volume_temp = audio_manager.music_volume
		if volume_slider:
			volume_slider.value = _volume_temp * 100.0
			volume_slider.value_changed.connect(_on_volume_changed)
	else:
		push_warning("AudioManager não encontrado!")
	
	# Atualizar label de volume
	_update_volume_display()
	
	# Permitir fechar com ESC
	set_process_input(true)

func _on_volume_changed(value: float) -> void:
	# Atualizar apenas o volume temporário (não aplicar ainda)
	_volume_temp = value / 100.0
	_update_volume_display()

func _on_apply_pressed() -> void:
	# Aplicar o volume temporário
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.set_volume(_volume_temp)
		print("Volume aplicado: %d%%" % int(_volume_temp * 100.0))

func _update_volume_display() -> void:
	if volume_value_label:
		var volume_percent = int(_volume_temp * 100.0)
		volume_value_label.text = "%d%%" % volume_percent

func _on_close_pressed() -> void:
	print("Fechando configurações...")
	queue_free()

func _input(event: InputEvent) -> void:
	# Fechar com ESC
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

