extends Control
class_name IntroStory

const GAME_SCENE = "res://Assets/Scene/game.tscn"

# Caminhos das imagens dos personagens
const IMG_AVO = "res://Assets/Sprites/imagens_dialogo/0.0.1 - Imagem Tela Dialogo Perosnagem Avó.png"
const IMG_PERSONAGEM = "res://Assets/Sprites/imagens_dialogo/0.0.1 - Imagem Tela Dialogo Perosnagem Principal 2.png"
const IMG_AMELIA = "res://Assets/Sprites/imagens_dialogo/0.0.1 - Imagem Tela Dialogo Perosnagem Amelia.png"

@export_category("Objects")
@export var character_image: TextureRect = null
@export var story_label: RichTextLabel = null
@export var continue_button: Button = null
@export var character_name_label: Label = null

var current_page: int = 0
var is_typing: bool = false
var typing_speed: float = 0.05  # Segundos por caractere

# Som de teclado
const SOUND_KEYBOARD = preload("res://Assets/Musica/Efeitos Sonoros/SomDeTeclado2.mp3")
var _keyboard_sound_player: AudioStreamPlayer = null
var _last_sound_time: float = 0.0
const SOUND_COOLDOWN: float = 0.1  # Intervalo mínimo entre sons (100ms)

# Estrutura: [texto, personagem, nome_personagem]
var story_pages: Array[Dictionary] = [
	{"text": "[center][font_size=48]ZOOLÓGICA[/font_size][/center]\n\n\n", "character": "", "name": ""},
	{"text": "Era uma vez um zoológico próspero, cheio de vida e alegria...\n\n", "character": "", "name": ""},
	{"text": "O dono do parque, seu avô, sempre cuidou com muito carinho de todos os animais.\n\n", "character": IMG_AVO, "name": "Avô"},
	{"text": "Mas um dia, seu avô adoeceu gravemente...\n\n", "character": IMG_AVO, "name": "Avô"},
	{"text": "E você, como neto responsável, precisou assumir a responsabilidade.\n\n", "character": IMG_PERSONAGEM, "name": "Você"},
	{"text": "Agora é você quem deve cuidar do zoológico, alimentar os animais,\ncomprar novas jaulas e expandir o parque.\n\n", "character": IMG_PERSONAGEM, "name": "Você"},
	{"text": "Mas cuidado! Para manter os animais felizes, você precisará resolver\ndesafios matemáticos que aparecerão em cada jaula.\n\n", "character": IMG_AMELIA, "name": "Amelia"},
	{"text": "O futuro do zoológico está em suas mãos!\n\n[center][font_size=32]Boa sorte![/font_size][/center]", "character": IMG_PERSONAGEM, "name": "Você"}
]

func _ready() -> void:
	_find_ui_elements()
	_initialize_ui()
	_create_keyboard_sound_player()
	_show_current_page()

func _create_keyboard_sound_player() -> void:
	# Verificar se o som foi carregado
	if not SOUND_KEYBOARD:
		push_error("Falha ao carregar SomDeTeclado.mp3!")
		return
	
	print("Som de teclado carregado: ", SOUND_KEYBOARD.resource_path)
	
	# Criar um único player
	_keyboard_sound_player = AudioStreamPlayer.new()
	_keyboard_sound_player.name = "KeyboardSoundPlayer"
	_keyboard_sound_player.stream = SOUND_KEYBOARD
	_keyboard_sound_player.volume_db = -10.0  # Volume um pouco mais baixo
	_keyboard_sound_player.bus = "Master"
	_keyboard_sound_player.autoplay = false
	_keyboard_sound_player.stream_paused = false
	add_child(_keyboard_sound_player)
	
	# Pré-tocar o som uma vez para "aquecer" o player (sem som audível)
	# Isso garante que o player esteja pronto quando precisarmos
	_keyboard_sound_player.play()
	_keyboard_sound_player.stop()
	
	print("Player de som de teclado criado e pré-aquecido!")

func _find_ui_elements() -> void:
	if not character_image:
		character_image = get_node_or_null("VBoxContainer/CharacterImageContainer/CharacterImage") as TextureRect
	if not story_label:
		story_label = get_node_or_null("VBoxContainer/StoryLabel") as RichTextLabel
	if not continue_button:
		continue_button = get_node_or_null("VBoxContainer/ContinueButton") as Button
	if not character_name_label:
		character_name_label = get_node_or_null("VBoxContainer/CharacterName") as Label

func _initialize_ui() -> void:
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.disabled = true  # Desabilitar enquanto digita
	
	# Permitir pular com qualquer tecla ou clique
	set_process_input(true)

func _show_current_page() -> void:
	if current_page >= story_pages.size():
		return
	
	var page_data = story_pages[current_page]
	
	# Atualizar imagem do personagem
	if character_image:
		if page_data.character.is_empty():
			character_image.texture = null
			character_image.visible = false
		else:
			var texture = load(page_data.character) as Texture2D
			if texture:
				character_image.texture = texture
				character_image.visible = true
			else:
				push_warning("Não foi possível carregar imagem: %s" % page_data.character)
				character_image.visible = false
	
	# Atualizar nome do personagem
	if character_name_label:
		if page_data.name.is_empty():
			character_name_label.text = ""
			character_name_label.visible = false
		else:
			character_name_label.text = page_data.name
			character_name_label.visible = true
	
	# Iniciar efeito typewriter
	if story_label:
		_start_typewriter(page_data.text)
	
	# Atualizar botão
	if continue_button:
		if current_page >= story_pages.size() - 1:
			continue_button.text = "COMEÇAR JOGO"
		else:
			continue_button.text = "CONTINUAR"

func _start_typewriter(text: String) -> void:
	# Se já está digitando, não iniciar novamente
	if is_typing:
		return
	
	print("Iniciando typewriter na StoryLabel...")
	
	is_typing = true
	if continue_button:
		continue_button.disabled = true
	
	# Tocar o som ANTES de começar a digitar (para garantir resposta imediata)
	# Encontrar o primeiro caractere visível no texto
	var first_visible_char_found = false
	for i in range(text.length()):
		var char = text[i]
		# Ignorar tags BBCode
		if char == "[":
			var tag_end = text.find("]", i)
			if tag_end != -1:
				i = tag_end
				continue
		# Se encontrar um caractere visível, tocar som imediatamente
		if char != " " and char != "\n" and not first_visible_char_found:
			_play_keyboard_sound(true)
			first_visible_char_found = true
			break
	
	story_label.text = ""
	var current_char = 0
	var first_visible_char = false  # Já tocamos o som, então não precisamos mais da flag
	
	# Resetar cooldown
	_last_sound_time = Time.get_ticks_msec() / 1000.0
	
	while current_char < text.length() and is_typing:
		var char = text[current_char]
		
		# Se encontrar tag BBCode, processar de uma vez
		if char == "[":
			var tag_end = text.find("]", current_char)
			if tag_end != -1:
				var tag = text.substr(current_char, tag_end - current_char + 1)
				story_label.text += tag
				current_char = tag_end + 1
				continue
		
			# Tocar som ANTES de adicionar o caractere (para ser imediato)
		if char != " " and char != "\n":
			# Para os demais, usar cooldown para evitar muitas reproduções
			_play_keyboard_sound()
		
		# Adicionar próximo caractere
		story_label.text += char
		current_char += 1
		
		# Aguardar antes do próximo caractere (mais rápido para espaços)
		if char != " " and char != "\n":
			await get_tree().create_timer(typing_speed).timeout
		else:
			await get_tree().create_timer(typing_speed * 0.2).timeout
	
	# Mostrar texto completo se foi pulado
	if not is_typing or current_char < text.length():
		story_label.text = text
	
	is_typing = false
	_stop_keyboard_sound()
	print("Typewriter finalizado")
	if continue_button:
		continue_button.disabled = false

func _play_keyboard_sound(force: bool = false) -> void:
	if not _keyboard_sound_player:
		return
	
	if not _keyboard_sound_player.is_inside_tree():
		return
	
	# Garantir que não está pausado
	_keyboard_sound_player.stream_paused = false
	
	# Se for forçado (primeiro caractere), tocar imediatamente sem cooldown
	if force:
		# Parar se já está tocando para reiniciar imediatamente
		if _keyboard_sound_player.playing:
			_keyboard_sound_player.stop()
		# Pular qualquer silêncio inicial do arquivo (se houver)
		_keyboard_sound_player.play()
		# Tentar pular silêncio inicial (ajustar o valor se necessário)
		if _keyboard_sound_player.get_playback_position() == 0.0:
			# Se o arquivo tem silêncio no início, pular para onde o som realmente começa
			# Ajuste este valor baseado no seu arquivo de áudio
			_keyboard_sound_player.seek(0.0)  # Começar do início
		_last_sound_time = Time.get_ticks_msec() / 1000.0
		return
	
	# Cooldown para evitar muitas reproduções simultâneas
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_sound_time < SOUND_COOLDOWN:
		return
	
	_last_sound_time = current_time
	
	# Se não está tocando, tocar o som do início
	if not _keyboard_sound_player.playing:
		_keyboard_sound_player.play()
		_keyboard_sound_player.seek(0.0)  # Garantir que começa do início

func _stop_keyboard_sound() -> void:
	if _keyboard_sound_player and _keyboard_sound_player.playing:
		_keyboard_sound_player.stop()

func _on_continue_pressed() -> void:
	# Se ainda está digitando, pular para o final
	if is_typing:
		is_typing = false
		_stop_keyboard_sound()  # Parar som imediatamente
		if current_page < story_pages.size():
			var page_data = story_pages[current_page]
			if story_label:
				story_label.text = page_data.text
		if continue_button:
			continue_button.disabled = false
		return
	
	# Avançar para próxima página
	if current_page < story_pages.size() - 1:
		current_page += 1
		_show_current_page()
	else:
		_start_game()

func _start_game() -> void:
	print("Iniciando jogo após introdução...")
	var error = get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("Erro ao carregar cena do jogo: %d" % error)

func _input(event: InputEvent) -> void:
	# Permitir avançar com qualquer tecla ou clique
	var viewport = get_viewport()
	if not viewport:
		return
	
	if event is InputEventKey and event.pressed:
		_on_continue_pressed()
		viewport.set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		_on_continue_pressed()
		viewport.set_input_as_handled()
