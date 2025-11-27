extends Node2D

const _SHOP_SCREEN:PackedScene = preload("res://Assets/Scene/shop_screen.tscn")
const _PAUSE_MENU:PackedScene = preload("res://Assets/Scene/pause_menu.tscn")

# Os desafios usam class_name então são acessíveis globalmente:
# DesafioElefante, DesafioLeao, DesafioMacaco, DesafioGirafa, DesafioZebra

@export_category("Objects")
@export var _hud: CanvasLayer = null
@export var _shop_button: Button = null
@export var _player: CharacterBody2D = null
@export var _moedas_label: Label = null
@export var _placa_label: Label = null

# Sistema de interação com placas
var _prompt_interacao: PanelContainer = null
var _placa_atual: PlacaInteracao = null
var _desafio_ativo: bool = false

# Sistema de renderização de animais nas jaulas
var jaulas_visuais: Dictionary = {}  # {Cage: Node2D} - Container para cada jaula
var animais_sprites: Dictionary = {}  # {Cage: Array[Node2D]} - Sprites dos animais por jaula (AnimatedSprite2D ou Sprite2D)
var spots_jaulas: Dictionary = {}  # {Cage: Array[Vector2]} - 20 spots aleatórios por jaula

# Mapeamento de posições das jaulas no mapa
# 5 jaulas lado a lado: Elefante, Leão, Macaco, Zebra, Girafa
var posicoes_jaulas_por_tipo: Dictionary = {
	"Jaula do Elefante": Vector2(500, 521),
	"Jaula do Leão": Vector2(1200, 521),
	"Jaula do Macaco": Vector2(1900, 521),
	"Jaula da Zebra": Vector2(2600, 521),
	"Jaula da Girafa": Vector2(3300, 521)
}

func _ready() -> void:
	# Adicionar ao grupo "game" para ser encontrado facilmente
	add_to_group("game")
	
	_initialize_shop_button()
	_initialize_player()
	_initialize_moedas_display()
	_initialize_placa_label()
	_initialize_prompt_interacao()
	# Salvar que o jogo foi iniciado quando entrar na cena
	SaveManager.save_game_started()
	# Garantir que o input está sendo processado
	set_process_input(true)
	set_process_unhandled_input(true)
	print("Game.gd inicializado - Input habilitado")
	if not _hud:
		push_error("HUD não encontrado no game.gd!")
	else:
		print("HUD encontrado: ", _hud.name)
	
	# Inicializar sistema de renderização de jaulas
	call_deferred("_initialize_jaulas_visuais")
	
	# Criar áreas de interação para as placas
	call_deferred("_criar_areas_interacao")

func _initialize_shop_button() -> void:
	if _shop_button:
		if not _shop_button.pressed.is_connected(_open_shop):
			_shop_button.pressed.connect(_open_shop)
			print("Botão Loja conectado com sucesso!")
		else:
			print("Botão Loja já estava conectado.")
	else:
		push_warning("Botão Loja não encontrado! A loja pode ser aberta apenas com a tecla L.")

func _initialize_player() -> void:
	# Encontrar o player se não foi atribuído
	if not _player:
		_player = get_node_or_null("CharacterBody2D2") as CharacterBody2D
		if not _player:
			# Tentar encontrar o player de outras formas
			_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
			if not _player:
				# Procurar qualquer CharacterBody2D que tenha o script do player
				for child in get_children():
					if child is CharacterBody2D and child.has_method("comprar_jaula"):
						_player = child
						break
	
	if not _player:
		push_warning("Player não encontrado! A loja pode não funcionar corretamente.")
	else:
		print("Player encontrado: ", _player.name)

func _initialize_moedas_display() -> void:
	if _player and _moedas_label:
		if not _player.moedas_atualizadas.is_connected(_on_moedas_updated):
			_player.moedas_atualizadas.connect(_on_moedas_updated)
		_update_moedas_display()

func _initialize_placa_label() -> void:
	# Buscar o Label da placa se não foi atribuído
	if not _placa_label:
		var placa_node = get_node_or_null("ParallaxBackground/ParallaxLayer/PlacaGrande")
		if placa_node:
			# Procurar Label filho da placa
			for child in placa_node.get_children():
				if child is Label:
					_placa_label = child
					break
			
			# Se não encontrou, criar um novo Label
			if not _placa_label:
				_placa_label = Label.new()
				_placa_label.name = "PlacaLabel"
				_placa_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				_placa_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				# Carregar fonte se disponível
				var font = load("res://Assets/Fonts/Silkscreen/Silkscreen-Regular.ttf")
				if font:
					_placa_label.add_theme_font_override("font", font)
					_placa_label.add_theme_font_size_override("font_size", 24)
				_placa_label.add_theme_color_override("font_color", Color.BLACK)
				_placa_label.add_theme_color_override("font_shadow_color", Color.WHITE)
				_placa_label.add_theme_constant_override("shadow_offset_x", 2)
				_placa_label.add_theme_constant_override("shadow_offset_y", 2)
				placa_node.add_child(_placa_label)
				# Posicionar no centro da placa (ajustar conforme necessário)
				_placa_label.position = Vector2(-100, -20)  # Ajustar posição conforme necessário
				_placa_label.size = Vector2(200, 40)
	
	# Atualizar texto da placa
	_atualizar_placa_jaula()

func _input(event: InputEvent) -> void:
	# Abrir menu de pausa com ESC (apenas se não estiver pausado)
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		print("ESC pressionado no game.gd - pausado: ", get_tree().paused)
		if not get_tree().paused:
			_open_pause_menu()
		get_viewport().set_input_as_handled()
		return
	
	# Interagir com placa usando E ou ESPAÇO
	if event is InputEventKey and event.pressed and not _desafio_ativo:
		if event.keycode == KEY_E and _placa_atual:
			_on_desafio_solicitado(_placa_atual.tipo_desafio, _placa_atual)
			get_viewport().set_input_as_handled()
			return
	
	# Abrir loja com a tecla L (apenas se não estiver pausado)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_L and not get_tree().paused:
			_open_shop()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	# Garantir que ESC funciona mesmo se outros nós não processarem
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		print("ESC pressionado no _unhandled_input - pausado: ", get_tree().paused)
		if not get_tree().paused:
			_open_pause_menu()
		get_viewport().set_input_as_handled()

func _update_moedas_display() -> void:
	if _moedas_label and _player:
		_moedas_label.text = GameUtils.format_moedas_hud(_player.total_moedas)

func _on_moedas_updated(nova_quantidade: int) -> void:
	_update_moedas_display()

func _open_shop() -> void:
	if not _hud:
		push_error("HUD não encontrado! Não é possível abrir a loja.")
		return
	
	if not _player:
		push_error("Player não encontrado! Não é possível abrir a loja.")
		return
	
	# Verificar se a loja já está aberta
	for child in _hud.get_children():
		if child is ShopScreen:
			return  # Loja já está aberta
	
	# Criar e adicionar a tela da loja
	var shop_screen = _SHOP_SCREEN.instantiate() as ShopScreen
	if not shop_screen:
		push_error("Falha ao instanciar a tela da loja!")
		return
	
	shop_screen.set_player(_player)
	_hud.add_child(shop_screen)
	print("Loja aberta com sucesso!")

func _open_pause_menu() -> void:
	if not _hud:
		push_error("HUD não encontrado! Não é possível abrir o menu de pausa.")
		return
	
	# Verificar se o menu de pausa já está aberto
	for child in _hud.get_children():
		if child is PauseMenu:
			return  # Menu de pausa já está aberto
	
	# Verificar se a loja está aberta (não abrir pausa se a loja estiver aberta)
	for child in _hud.get_children():
		if child is ShopScreen:
			return  # Loja está aberta, não abrir pausa
	
	# Criar e adicionar o menu de pausa
	var pause_menu = _PAUSE_MENU.instantiate()
	if not pause_menu:
		push_error("Falha ao instanciar o menu de pausa!")
		return
	
	_hud.add_child(pause_menu)
	print("Menu de pausa aberto!")

# =============================================================
# Sistema de Renderização de Jaulas e Animais
# =============================================================

func _initialize_jaulas_visuais() -> void:
	if not _player:
		push_error("Player não encontrado para inicializar jaulas visuais!")
		return
	
	print("=== Inicializando jaulas visuais ===")
	print("Total de jaulas do jogador: %d" % _player.jaulas_possuidas.size())
	
	# Para cada jaula do jogador, criar container visual
	for i in range(_player.jaulas_possuidas.size()):
		var jaula = _player.jaulas_possuidas[i]
		if not jaula:
			push_warning("Jaula %d é nula!" % i)
			continue
		
		if not jaula.cage_type:
			push_warning("Jaula %d não tem cage_type!" % i)
			continue
		
		var nome_jaula = jaula.cage_type.nome_exibicao
		print("Processando jaula %d: %s (animais: %d)" % [i, nome_jaula, jaula.animals.size()])
		
		# Verificar se temos uma posição definida para este tipo de jaula
		if nome_jaula in posicoes_jaulas_por_tipo:
			var posicao = posicoes_jaulas_por_tipo[nome_jaula]
			_criar_container_jaula(jaula, posicao)
			_atualizar_animais_na_jaula(jaula)
			print("✓ Jaula '%s' inicializada na posição: %s" % [nome_jaula, posicao])
		else:
			push_warning("✗ Posição não definida para jaula: %s" % nome_jaula)
	
	# Atualizar placa
	_atualizar_placa_jaula()
	print("=== Fim da inicialização de jaulas ===")

func _criar_container_jaula(jaula: Cage, posicao: Vector2) -> void:
	# Verificar se já existe container para esta jaula
	if jaula in jaulas_visuais:
		return
	
	# Criar container para os animais da jaula
	var container = Node2D.new()
	container.name = "ContainerJaula_%s" % jaula.cage_type.nome_exibicao.replace(" ", "_")
	container.position = posicao
	container.z_index = 1  # Garantir que fique na frente da jaula (z_index 0)
	
	# Gerar 20 spots aleatórios dentro da área da jaula
	var spots = _gerar_spots_aleatorios(20)
	spots_jaulas[jaula] = spots
	
	# Adicionar ao ParallaxLayer para ficar na mesma camada da jaula
	var parallax_layer = get_node_or_null("ParallaxBackground/ParallaxLayer")
	if parallax_layer:
		parallax_layer.add_child(container)
		jaulas_visuais[jaula] = container
		animais_sprites[jaula] = []
		print("Container da jaula '%s' criado na posição: %s com %d spots" % [jaula.cage_type.nome_exibicao, posicao, spots.size()])
	else:
		push_error("ParallaxLayer não encontrado!")

func _gerar_spots_aleatorios(quantidade: int) -> Array[Vector2]:
	# Área da jaula - aumentada para cobrir toda a área do layout_jaula.png
	# O layout_jaula.png parece ter aproximadamente 300x250 pixels (ajustado para mais espalhado)
	var largura_jaula = 350  # Aumentado de 200 para 350
	var altura_jaula = 280  # Aumentado de 200 para 280
	
	var spots: Array[Vector2] = []
	var min_distancia = 30.0  # Distância mínima entre spots para evitar aglomeração
	
	# Tentar gerar spots bem distribuídos
	var tentativas_maximas = quantidade * 10
	var tentativas = 0
	
	while spots.size() < quantidade and tentativas < tentativas_maximas:
		tentativas += 1
		
		# Gerar posição aleatória dentro da área da jaula
		var x = randf_range(-largura_jaula/2, largura_jaula/2)
		var y = randf_range(-altura_jaula/2, altura_jaula/2)
		var novo_spot = Vector2(x, y)
		
		# Verificar se está longe o suficiente dos outros spots
		var muito_proximo = false
		for spot_existente in spots:
			if novo_spot.distance_to(spot_existente) < min_distancia:
				muito_proximo = true
				break
		
		# Se não está muito próximo, adicionar
		if not muito_proximo:
			spots.append(novo_spot)
	
	# Se não conseguiu gerar spots suficientes com distância mínima, preencher com spots aleatórios
	while spots.size() < quantidade:
		var x = randf_range(-largura_jaula/2, largura_jaula/2)
		var y = randf_range(-altura_jaula/2, altura_jaula/2)
		spots.append(Vector2(x, y))
	
	print("Gerados %d spots em área de %dx%d" % [spots.size(), largura_jaula, altura_jaula])
	return spots

func _atualizar_animais_na_jaula(jaula: Cage) -> void:
	if not jaula in jaulas_visuais:
		push_warning("Tentando atualizar animais em jaula sem container visual!")
		return
	
	var container = jaulas_visuais[jaula]
	if not is_instance_valid(container):
		push_error("Container da jaula é inválido!")
		return
	
	# Remover sprites antigos
	if jaula in animais_sprites:
		for sprite in animais_sprites[jaula]:
			if is_instance_valid(sprite):
				sprite.queue_free()
		animais_sprites[jaula].clear()
	
	# Criar sprites para cada animal na jaula
	print("Criando sprites para %d animais na jaula" % jaula.animals.size())
	
	# Obter spots para esta jaula
	var spots = spots_jaulas.get(jaula, [])
	if spots.is_empty():
		# Se não tem spots, gerar agora
		spots = _gerar_spots_aleatorios(20)
		spots_jaulas[jaula] = spots
	
	for i in range(jaula.animals.size()):
		var animal = jaula.animals[i]
		var sprite = _criar_sprite_animal(animal)
		
		if sprite:
			# Escolher um spot aleatório para o animal
			var spot_index = i % spots.size()
			var posicao_inicial = spots[spot_index]
			
			sprite.position = posicao_inicial
			sprite.z_index = 1  # Garantir z_index
			container.add_child(sprite)
			
			# Adicionar script de movimento ao animal
			_adicionar_movimento_animal(sprite, spots, jaula)
			
			animais_sprites[jaula].append(sprite)
			print("Animal %d criado no spot %d: %s" % [i, spot_index, posicao_inicial])
		else:
			push_warning("Falha ao criar sprite para animal %d" % i)

func _criar_sprite_animal(animal: Animal) -> Node2D:
	if not animal or not animal.template:
		return null
	
	var template = animal.template as AnimalTemplate
	if not template:
		return null
	
	# Se tem animação configurada, usar AnimatedSprite2D
	if template.animacao_sprite:
		var sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = template.animacao_sprite
		sprite.z_index = 1  # Garantir que fique na frente da jaula (z_index 0)
		
		# Tentar reproduzir a animação "default" ou a primeira disponível
		var animacoes = template.animacao_sprite.get_animation_names()
		if animacoes.size() > 0:
			var animacao = "default" if "default" in animacoes else animacoes[0]
			sprite.play(animacao)
			sprite.autoplay = animacao
			print("Sprite do animal '%s' criado com animação '%s'" % [template.nome_exibicao, animacao])
		else:
			push_warning("Nenhuma animação encontrada para o animal '%s'!" % template.nome_exibicao)
		
		return sprite
	else:
		# Fallback: usar sprite estático se não tiver animação
		print("Animal '%s' não tem animação configurada! Tentando carregar sprite estático..." % template.nome_exibicao)
		
		# Mapear nomes de animais para caminhos de imagens
		var caminhos_por_animal = {
			"Elefante": [
				"res://Assets/Sprites/Animais/Elefante/elefante_base.png",
				"res://Assets/Sprites/Animais/Elefante/elefante_base-2.png.png"
			],
			"Leão": [
				"res://Assets/Sprites/Animais/Leao/leao_base.png"
			],
			"Macaco": [
				"res://Assets/Sprites/Animais/Macaco/macaco_base.png"
			],
			"Zebra": [
				"res://Assets/Sprites/Animais/Zebra/zebra_base.png"
			],
			"Girafa": [
				"res://Assets/Sprites/Animais/Girafa/girafa_base.png"
			]
		}
		
		var sprite = Sprite2D.new()
		sprite.z_index = 1
		
		# Tentar carregar imagem específica do animal
		if template.nome_exibicao in caminhos_por_animal:
			var caminhos = caminhos_por_animal[template.nome_exibicao]
			for path in caminhos:
				if ResourceLoader.exists(path):
					var texture = load(path) as Texture2D
					if texture:
						sprite.texture = texture
						print("✓ Sprite estático do animal '%s' carregado de: %s" % [template.nome_exibicao, path])
						return sprite
					else:
						print("✗ Falha ao carregar textura de: %s" % path)
				else:
					print("✗ Arquivo não existe: %s" % path)
		
		# Se não encontrou nenhuma imagem, criar um placeholder colorido
		print("Nenhuma imagem encontrada para '%s'! Criando placeholder colorido." % template.nome_exibicao)
		sprite = _criar_placeholder_animal(template.nome_exibicao)
		return sprite

func _criar_placeholder_animal(nome: String) -> Sprite2D:
	# Criar um placeholder simples (retângulo colorido)
	var sprite = Sprite2D.new()
	sprite.z_index = 1
	
	# Criar uma textura simples programaticamente
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var cor = Color.BLUE  # Cor padrão para placeholder
	
	match nome.to_lower():
		"elefante":
			cor = Color.GRAY
		"leão", "leao":
			cor = Color.ORANGE
		"macaco":
			cor = Color.BROWN
		"zebra":
			cor = Color.WHITE
		"girafa":
			cor = Color.YELLOW
	
	image.fill(cor)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	print("Placeholder criado para: %s" % nome)
	return sprite

func _adicionar_movimento_animal(sprite: Node2D, spots: Array[Vector2], jaula: Cage) -> void:
	# Criar um script inline para o movimento do animal
	var script = GDScript.new()
	script.source_code = """
extends Node2D

var spots: Array[Vector2] = []
var spot_atual_index: int = 0
var proximo_spot: Vector2
var velocidade: float = 20.0
var pausa_tempo: float = 0.0
var pausa_maxima: float = 3.0
var em_movimento: bool = false

func _ready():
	# Escolher um spot inicial aleatório
	if spots.size() > 0:
		spot_atual_index = randi() % spots.size()
		position = spots[spot_atual_index]
		# Aguardar um pouco antes de começar a se mover
		await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
		_escolher_proximo_spot()

func _process(delta):
	if spots.is_empty():
		return
	
	# Se está em pausa, aguardar
	if pausa_tempo > 0:
		pausa_tempo -= delta
		return
	
	# Se não está em movimento, escolher próximo spot
	if not em_movimento:
		_escolher_proximo_spot()
	
	# Mover em direção ao próximo spot
	if em_movimento:
		var direcao = (proximo_spot - position).normalized()
		var distancia = position.distance_to(proximo_spot)
		
		if distancia < 5.0:
			# Chegou no spot, fazer pausa
			position = proximo_spot
			em_movimento = false
			pausa_tempo = randf_range(1.0, pausa_maxima)
			spot_atual_index = (spot_atual_index + 1) % spots.size()
		else:
			# Continuar se movendo
			position += direcao * velocidade * delta

func _escolher_proximo_spot():
	if spots.size() == 0:
		return
	
	# Escolher um spot diferente do atual
	var novo_index = spot_atual_index
	while novo_index == spot_atual_index and spots.size() > 1:
		novo_index = randi() % spots.size()
	
	proximo_spot = spots[novo_index]
	em_movimento = true
	velocidade = randf_range(15.0, 30.0)  # Velocidade variável
"""
	
	# Compilar e anexar o script
	script.reload()
	sprite.set_script(script)
	
	# Passar os spots para o script
	sprite.set("spots", spots)
	
	print("Movimento adicionado ao animal com %d spots disponíveis" % spots.size())

func _atualizar_placa_jaula() -> void:
	if not _placa_label:
		return
	
	if not _player or _player.jaulas_possuidas.is_empty():
		_placa_label.text = ""
		return
	
	# Procurar jaula de elefante (primeira jaula inicial)
	for jaula in _player.jaulas_possuidas:
		if jaula.cage_type and jaula.cage_type.nome_exibicao == "Jaula do Elefante":
			_placa_label.text = "JAULA DO ELEFANTE"
			return
	
	# Se não encontrar jaula de elefante, mostrar a primeira jaula disponível
	if _player.jaulas_possuidas.size() > 0:
		var primeira_jaula = _player.jaulas_possuidas[0]
		if primeira_jaula.cage_type:
			_placa_label.text = primeira_jaula.cage_type.nome_exibicao.to_upper()
		else:
			_placa_label.text = ""
	else:
		_placa_label.text = ""

# Função para ser chamada quando um animal é comprado
func _on_animal_comprado(jaula: Cage) -> void:
	if not jaula or not jaula.cage_type:
		return
	
	var nome_jaula = jaula.cage_type.nome_exibicao
	print("Animal comprado! Atualizando jaula: ", nome_jaula)
	
	# Se a jaula visual não existe ainda, criar
	if not jaula in jaulas_visuais:
		if nome_jaula in posicoes_jaulas_por_tipo:
			var posicao = posicoes_jaulas_por_tipo[nome_jaula]
			_criar_container_jaula(jaula, posicao)
		else:
			push_warning("Posição não definida para jaula: %s" % nome_jaula)
			return
	
	# Atualizar os animais na jaula (garante que quantidade visível = quantidade comprada)
	if jaula in jaulas_visuais:
		print("Atualizando animais na jaula. Total de animais: ", jaula.animals.size())
		_atualizar_animais_na_jaula(jaula)
	else:
		push_warning("Jaula visual não encontrada para atualizar!")
	
	# Atualizar placa
	_atualizar_placa_jaula()

# =============================================================
# Sistema de Interação com Placas e Desafios
# =============================================================

func _initialize_prompt_interacao() -> void:
	if not _hud:
		return
	
	# Criar o prompt de interação
	_prompt_interacao = PanelContainer.new()
	_prompt_interacao.name = "PromptInteracao"
	_prompt_interacao.visible = false
	
	# Posicionar no centro inferior da tela
	_prompt_interacao.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_interacao.position = Vector2(-200, -150)
	_prompt_interacao.custom_minimum_size = Vector2(400, 80)
	
	# Estilizar o painel
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.1, 0.15, 0.1, 0.95)
	estilo.border_color = Color(0.3, 0.8, 0.3, 1.0)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(15)
	_prompt_interacao.add_theme_stylebox_override("panel", estilo)
	
	# Criar container interno
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	_prompt_interacao.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Carregar fonte
	var font = load("res://Assets/Fonts/Silkscreen/Silkscreen-Regular.ttf")
	
	# Label com instrução
	var label = Label.new()
	label.name = "PromptLabel"
	label.text = "🎮 Pressione [E] para entrar no DESAFIO!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9, 1.0))
	vbox.add_child(label)
	
	# Label com nome da jaula
	var nome_label = Label.new()
	nome_label.name = "NomeJaulaLabel"
	nome_label.text = ""
	nome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		nome_label.add_theme_font_override("font", font)
	nome_label.add_theme_font_size_override("font_size", 18)
	nome_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	vbox.add_child(nome_label)
	
	_hud.add_child(_prompt_interacao)
	print("Prompt de interação criado!")

func _criar_areas_interacao() -> void:
	# Mapeamento direto dos caminhos das placas no game.tscn para os tipos de desafio
	# Baseado na estrutura: ParallaxBackground/ParallaxLayer/Jaula X/PlacaX
	var placas_config = [
		{
			"jaula_path": "ParallaxBackground/ParallaxLayer/Jaula Elefante",
			"placa_nome": "PlacaElefante",
			"tipo_desafio": "elefante",
			"nome": "Jaula do Elefante - Adição e Subtração"
		},
		{
			"jaula_path": "ParallaxBackground/ParallaxLayer/Jaula Leao",
			"placa_nome": "PlacaLeao",
			"tipo_desafio": "leao",
			"nome": "Jaula do Leão - Multiplicação"
		},
		{
			"jaula_path": "ParallaxBackground/ParallaxLayer/Jaula Macaco",
			"placa_nome": "PlacaMacaco",
			"tipo_desafio": "macaco",
			"nome": "Jaula do Macaco - Divisão"
		},
		{
			"jaula_path": "ParallaxBackground/ParallaxLayer/Jaula Girafa",
			"placa_nome": "PlacaGirafa",
			"tipo_desafio": "girafa",
			"nome": "Jaula da Girafa - Regra de Três Simples"
		},
		{
			"jaula_path": "ParallaxBackground/ParallaxLayer/Jaula Zebra",
			"placa_nome": "PlacaZebra",
			"tipo_desafio": "zebra",
			"nome": "Jaula da Zebra - Regra de Três Composta"
		}
	]
	
	# Obter o ParallaxLayer para adicionar as áreas
	var parallax_layer = get_node_or_null("ParallaxBackground/ParallaxLayer")
	if not parallax_layer:
		push_error("ParallaxLayer não encontrado!")
		return
	
	print("=== Criando áreas de interação para placas ===")
	
	for config in placas_config:
		# Buscar a jaula
		var jaula_node = get_node_or_null(config.jaula_path)
		if not jaula_node:
			push_warning("✗ Jaula não encontrada: %s" % config.jaula_path)
			continue
		
		# Buscar a placa dentro da jaula
		var placa_node = jaula_node.get_node_or_null(config.placa_nome)
		if not placa_node:
			push_warning("✗ Placa '%s' não encontrada na jaula!" % config.placa_nome)
			continue
		
		# Calcular posição real da placa no mundo
		# Posição = Jaula.position + (Placa.position * Jaula.scale)
		var jaula_pos = jaula_node.position
		var jaula_scale = jaula_node.scale
		var placa_pos_local = placa_node.position
		
		var pos_mundo = jaula_pos + Vector2(placa_pos_local.x * jaula_scale.x, placa_pos_local.y * jaula_scale.y)
		
		# Criar área e adicionar ao ParallaxLayer
		var area = _criar_area_interacao(config.placa_nome, config, pos_mundo)
		parallax_layer.add_child(area)
		print("✓ Área criada para %s em posição: %s (jaula: %s, placa local: %s)" % [config.placa_nome, pos_mundo, jaula_pos, placa_pos_local])
	
	print("=== Áreas de interação criadas ===")

func _criar_area_interacao(nome: String, config: Dictionary, pos_mundo: Vector2) -> PlacaInteracao:
	var area = PlacaInteracao.new()
	area.name = "AreaInteracao_" + nome
	# Posição baseada na posição calculada da placa + offset para baixo (onde o jogador fica no chão)
	area.position = pos_mundo + Vector2(0, 120)  # Offset para baixo da placa
	area.tipo_desafio = config.tipo_desafio
	area.nome_jaula = config.nome
	
	# Criar collision shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(180, 200)  # Área para detectar o jogador
	collision.shape = shape
	
	area.add_child(collision)
	
	# Conectar sinais
	area.jogador_entrou.connect(_on_jogador_entrou_placa.bind(area))
	area.jogador_saiu.connect(_on_jogador_saiu_placa.bind(area))
	area.desafio_solicitado.connect(_on_desafio_solicitado.bind(area))
	
	return area

func _on_jogador_entrou_placa(placa: PlacaInteracao) -> void:
	if _desafio_ativo:
		return
	
	_placa_atual = placa
	_mostrar_prompt_interacao(placa.nome_jaula)

func _on_jogador_saiu_placa(placa: PlacaInteracao) -> void:
	if _placa_atual == placa:
		_placa_atual = null
		_esconder_prompt_interacao()

func _mostrar_prompt_interacao(nome_jaula: String) -> void:
	if _prompt_interacao:
		_prompt_interacao.visible = true
		var nome_label = _prompt_interacao.get_node_or_null("MarginContainer/VBoxContainer/NomeJaulaLabel")
		if nome_label:
			nome_label.text = nome_jaula
		
		# Iniciar animação de pulso
		_animar_prompt()

func _esconder_prompt_interacao() -> void:
	if _prompt_interacao:
		_prompt_interacao.visible = false
		# Parar animação
		var tween = get_tree().create_tween()
		tween.kill()

func _animar_prompt() -> void:
	if not _prompt_interacao or not _prompt_interacao.visible:
		return
	
	# Criar animação de pulso suave
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(_prompt_interacao, "modulate:a", 0.7, 0.5)
	tween.tween_property(_prompt_interacao, "modulate:a", 1.0, 0.5)

func _on_desafio_solicitado(tipo_desafio: String, placa: PlacaInteracao) -> void:
	if _desafio_ativo:
		return
	
	print("Iniciando desafio: ", tipo_desafio)
	_esconder_prompt_interacao()
	_iniciar_desafio(tipo_desafio)

func _iniciar_desafio(tipo: String) -> void:
	if not _hud or not _player:
		push_error("HUD ou Player não encontrado para iniciar desafio!")
		return
	
	_desafio_ativo = true
	
	# Criar a cena do desafio baseado no tipo
	var desafio: DesafioBase = null
	
	match tipo:
		"elefante":
			desafio = DesafioElefante.new()
		"leao":
			desafio = DesafioLeao.new()
		"macaco":
			desafio = DesafioMacaco.new()
		"girafa":
			desafio = DesafioGirafa.new()
		"zebra":
			desafio = DesafioZebra.new()
		_:
			push_error("Tipo de desafio desconhecido: %s" % tipo)
			_desafio_ativo = false
			return
	
	if desafio:
		desafio.set_player(_player)
		desafio.desafio_concluido.connect(_on_desafio_concluido)
		desafio.desafio_cancelado.connect(_on_desafio_cancelado)
		_hud.add_child(desafio)
		print("Desafio '%s' iniciado!" % tipo)

func _on_desafio_concluido(acertos: int, total: int, moedas_ganhas: int) -> void:
	print("Desafio concluído! Acertos: %d/%d | Moedas: +%d" % [acertos, total, moedas_ganhas])
	_desafio_ativo = false
	_update_moedas_display()

func _on_desafio_cancelado() -> void:
	print("Desafio cancelado!")
	_desafio_ativo = false
