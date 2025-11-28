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
var areas_assets: Dictionary = {}  # {String: Array[Area2D]} - Áreas dos Assets de cada jaula
var containers_jaulas: Dictionary = {}  # {String: Node2D} - Containers das jaulas por nome

# Mapeamento de posições das jaulas no mapa (mesmas posições do game.tscn)
# 5 jaulas lado a lado: Elefante, Leão, Macaco, Girafa, Zebra
var posicoes_jaulas_por_tipo: Dictionary = {
	"Jaula do Elefante": Vector2(967, 533),
	"Jaula do Leão": Vector2(2887, 533),
	"Jaula do Macaco": Vector2(4804, 533),
	"Jaula da Girafa": Vector2(6724, 533),
	"Jaula da Zebra": Vector2(8644, 533)
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
	
	# Mapear áreas dos Assets das jaulas
	call_deferred("_mapear_areas_assets")

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
	
	var nome_jaula = jaula.cage_type.nome_exibicao
	var container_name = "ContainerJaula_%s" % nome_jaula.replace(" ", "_")
	
	# Tentar encontrar container existente no game.tscn
	var parallax_layer = get_node_or_null("ParallaxBackground/ParallaxLayer")
	if not parallax_layer:
		push_error("ParallaxLayer não encontrado!")
		return
	
	var container = parallax_layer.get_node_or_null(container_name) as Node2D
	
	# Se não existe, criar novo
	if not container:
		container = Node2D.new()
		container.name = container_name
		container.position = posicao
		container.z_index = 10  # Garantir que fique na frente dos assets (z_index menor)
		parallax_layer.add_child(container)
		print("Container da jaula '%s' criado dinamicamente na posição: %s" % [nome_jaula, posicao])
	else:
		print("Container da jaula '%s' encontrado no game.tscn na posição: %s" % [nome_jaula, container.position])
	
	# Guardar referência ao container
	containers_jaulas[nome_jaula] = container
	
	# Registrar container
	jaulas_visuais[jaula] = container
	if not jaula in animais_sprites:
		animais_sprites[jaula] = []
	
	print("Container da jaula '%s' configurado" % nome_jaula)

func _gerar_spots_aleatorios(quantidade: int, nome_jaula: String = "") -> Array[Vector2]:
	# Área da jaula conforme especificado
	var largura_jaula = 1745.0  # x = 1745
	var altura_jaula = 475.0    # y = 475
	
	var spots: Array[Vector2] = []
	
	# Obter áreas bloqueadas para esta jaula
	var areas_bloqueadas: Array[Area2D] = []
	if not nome_jaula.is_empty() and nome_jaula in areas_assets:
		areas_bloqueadas = areas_assets[nome_jaula]
	
	# Grid mais espaçado - máximo 5 colunas e 2 linhas para maior separação
	var colunas = mini(quantidade, 5)  # Máximo 5 por linha
	var linhas = ceili(float(quantidade) / float(colunas))
	if linhas > 2:
		linhas = 2
		colunas = ceili(float(quantidade) / 2.0)
	
	# Margens maiores para mais espaço nas bordas
	var margem_x = 150.0
	var margem_y = 80.0
	
	var area_util_x = largura_jaula - (margem_x * 2)
	var area_util_y = altura_jaula - (margem_y * 2)
	
	var espacamento_x = area_util_x / float(colunas)
	var espacamento_y = area_util_y / float(linhas) if linhas > 1 else area_util_y
	
	# Gerar spots em grid uniforme bem espaçado, evitando áreas bloqueadas
	var tentativas_maximas = quantidade * 30
	var tentativas = 0
	var spots_rejeitados = 0
	
	while spots.size() < quantidade and tentativas < tentativas_maximas:
		tentativas += 1
		
		# Escolher posição do grid ou aleatória
		var base_x: float
		var base_y: float
		
		if spots.size() < colunas * linhas:
			# Usar grid
			var linha = spots.size() / colunas
			var coluna = spots.size() % colunas
			base_x = -largura_jaula/2.0 + margem_x + espacamento_x/2.0 + coluna * espacamento_x
			base_y = -altura_jaula/2.0 + margem_y + espacamento_y/2.0 + linha * espacamento_y
		else:
			# Posição aleatória
			base_x = randf_range(-largura_jaula/2.0 + margem_x, largura_jaula/2.0 - margem_x)
			base_y = randf_range(-altura_jaula/2.0 + margem_y, altura_jaula/2.0 - margem_y)
		
		# Variação aleatória pequena para parecer natural
		var variacao_x = randf_range(-40.0, 40.0)
		var variacao_y = randf_range(-30.0, 30.0)
		
		var novo_spot = Vector2(base_x + variacao_x, base_y + variacao_y)
		
		# Verificar se o spot colide com alguma área bloqueada usando Area2D
		var spot_valido = _verificar_spot_livre(novo_spot, areas_bloqueadas)
		
		if spot_valido:
			spots.append(novo_spot)
		else:
			spots_rejeitados += 1
	
	# Se não conseguiu gerar spots suficientes, adicionar os que conseguiu
	if spots.size() < quantidade:
		print("Aviso: Apenas %d spots válidos gerados (tentou %d)" % [spots.size(), quantidade])
	
	# Embaralhar os spots
	spots.shuffle()
	
	print("Gerados %d spots em área de %.0fx%.0f (evitando %d áreas bloqueadas, %d spots rejeitados)" % [spots.size(), largura_jaula, altura_jaula, areas_bloqueadas.size(), spots_rejeitados])
	return spots

func _verificar_spot_livre(posicao: Vector2, areas_bloqueadas: Array[Area2D]) -> bool:
	if areas_bloqueadas.is_empty():
		return true
	
	# Criar uma Area2D temporária para o animal na posição do spot
	var area_animal_temp = Area2D.new()
	area_animal_temp.name = "AreaAnimalTemp"
	area_animal_temp.position = posicao
	
	# Criar CollisionShape2D circular para o animal
	var collision_animal = CollisionShape2D.new()
	var shape_animal = CircleShape2D.new()
	shape_animal.radius = 35.0  # Raio do animal
	collision_animal.shape = shape_animal
	area_animal_temp.add_child(collision_animal)
	
	# Adicionar temporariamente ao ParallaxLayer para que as colisões funcionem
	var parallax_layer = get_node_or_null("ParallaxBackground/ParallaxLayer")
	if not parallax_layer:
		area_animal_temp.queue_free()
		return true
	
	# Obter o container da jaula para adicionar a área temporária no mesmo espaço
	# Precisamos encontrar qual jaula estamos verificando
	var nome_jaula_atual = ""
	for nome_jaula in areas_assets:
		if areas_bloqueadas == areas_assets[nome_jaula]:
			nome_jaula_atual = nome_jaula
			break
	
	# Se encontrou a jaula, adicionar ao container dela
	var container = containers_jaulas.get(nome_jaula_atual)
	if not container and not nome_jaula_atual.is_empty():
		# Tentar encontrar o container pelo nome no game.tscn
		var container_name = "ContainerJaula_%s" % nome_jaula_atual.replace(" ", "_")
		container = parallax_layer.get_node_or_null(container_name) as Node2D
		if container:
			containers_jaulas[nome_jaula_atual] = container
			print("Container '%s' encontrado no game.tscn" % container_name)
	
	if container:
		container.add_child(area_animal_temp)
	else:
		# Fallback: adicionar ao ParallaxLayer
		parallax_layer.add_child(area_animal_temp)
	
	# Forçar atualização da física
	area_animal_temp.force_update_transform()
	
	# Verificar colisão com cada área bloqueada usando overlaps_area
	var colidiu = false
	for area_asset in areas_bloqueadas:
		if not is_instance_valid(area_asset):
			continue
		
		# Forçar atualização da área do asset também
		area_asset.force_update_transform()
		
		# Usar overlaps_area para verificação precisa
		if area_asset.overlaps_area(area_animal_temp):
			colidiu = true
			break
	
	# Remover área temporária
	if is_instance_valid(area_animal_temp):
		area_animal_temp.queue_free()
	
	# Retornar true se não colidiu (spot é válido)
	return not colidiu

func _atualizar_animais_na_jaula(jaula: Cage) -> void:
	if not jaula in jaulas_visuais:
		push_warning("Tentando atualizar animais em jaula sem container visual!")
		return
	
	var nome_jaula = jaula.cage_type.nome_exibicao
	var quantidade_animais = jaula.animals.size()
	print("Atualizando animais na jaula '%s': %d animais comprados" % [nome_jaula, quantidade_animais])
	
	# Mapear nome da jaula para o node "Posicao dos..."
	var node_posicoes_name = ""
	match nome_jaula:
		"Jaula do Elefante":
			node_posicoes_name = "Posicao dos Elefante"
		"Jaula do Leão":
			node_posicoes_name = "Posicao dos Leao"
		"Jaula do Macaco":
			node_posicoes_name = "Posicao dos Macaco"
		"Jaula da Girafa":
			node_posicoes_name = "Posicao das Girafa"
		"Jaula da Zebra":
			node_posicoes_name = "Posicao das Zebra"
		_:
			push_error("Nome de jaula não mapeado: %s" % nome_jaula)
			return
	
	# Encontrar o node de posições
	var node_posicoes = get_node_or_null(node_posicoes_name) as Node2D
	if not node_posicoes:
		push_error("Node '%s' não encontrado!" % node_posicoes_name)
		return
	
	# Coletar todos os sprites de animais (ordenados: Base, Base2, Base3, etc.)
	var sprites_existentes: Array[Sprite2D] = []
	var children = node_posicoes.get_children()
	
	# Ordenar por nome para garantir ordem correta (Base = 1, Base2 = 2, Base3 = 3, ...)
	children.sort_custom(func(a, b): 
		var name_a = a.name
		var name_b = b.name
		# Extrair número do nome (Base = 1, Base2 = 2, Base3 = 3, etc.)
		var num_a = 1  # Default para "Base" sem número
		var num_b = 1
		
		if "Base" in name_a:
			var parts = name_a.split("Base")
			if parts.size() > 1 and parts[1].length() > 0:
				var num_str = parts[1]
				num_a = int(num_str) if num_str.is_valid_int() else 1
			else:
				num_a = 1  # "Base" sem número = 1
		
		if "Base" in name_b:
			var parts = name_b.split("Base")
			if parts.size() > 1 and parts[1].length() > 0:
				var num_str = parts[1]
				num_b = int(num_str) if num_str.is_valid_int() else 1
			else:
				num_b = 1  # "Base" sem número = 1
		
		return num_a < num_b
	)
	
	for child in children:
		if child is Sprite2D or child is AnimatedSprite2D:
			sprites_existentes.append(child as Sprite2D)
	
	# Limpar lista de sprites
	if not jaula in animais_sprites:
		animais_sprites[jaula] = []
	animais_sprites[jaula].clear()
	
	# Primeiro, tornar todos invisíveis
	for sprite in sprites_existentes:
		sprite.visible = false
	
	# Depois, tornar visíveis apenas os sprites correspondentes aos animais comprados
	var sprites_visiveis = 0
	
	for i in range(mini(quantidade_animais, sprites_existentes.size())):
		var sprite = sprites_existentes[i]
		sprite.visible = true
		animais_sprites[jaula].append(sprite)
		sprites_visiveis += 1
		print("Animal %d tornado visível: %s" % [i + 1, sprite.name])
	
	if quantidade_animais > sprites_existentes.size():
		push_warning("Mais animais comprados (%d) do que slots disponíveis (%d) na jaula '%s'!" % [quantidade_animais, sprites_existentes.size(), nome_jaula])
	
	print("✓ %d animais visíveis na jaula '%s'" % [sprites_visiveis, nome_jaula])

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
	
	# Atualizar placa se o jogador estiver perto de uma placa
	if _placa_atual:
		# Verificar se o animal comprado é da mesma jaula da placa atual
		var tipo_para_nome: Dictionary = {
			"elefante": "Jaula do Elefante",
			"leao": "Jaula do Leão",
			"macaco": "Jaula do Macaco",
			"girafa": "Jaula da Girafa",
			"zebra": "Jaula da Zebra"
		}
		var nome_esperado = tipo_para_nome.get(_placa_atual.tipo_desafio, "")
		if nome_jaula == nome_esperado:
			var jaula_comprada = _verificar_jaula_comprada(_placa_atual.tipo_desafio)
			var jaula_desbloqueada = _verificar_jaula_desbloqueada(_placa_atual.tipo_desafio)
			
			# Se a jaula está comprada mas sem animais, mostrar mensagem diferente
			if jaula_comprada and not jaula_desbloqueada:
				_mostrar_prompt_interacao(_placa_atual.nome_jaula, false, true)  # comprada mas sem animais
			else:
				_mostrar_prompt_interacao(_placa_atual.nome_jaula, jaula_desbloqueada, false)
	else:
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
	# Conectar as áreas de interação das PLACAS (para mostrar o prompt "Pressione E")
	# As áreas estão em PlacasInteracao (áreas menores perto das placas)
	var areas_paths = [
		"PlacasInteracao/PlacaElefante",
		"PlacasInteracao/PlacaLeao",
		"PlacasInteracao/PlacaMacaco",
		"PlacasInteracao/PlacaGirafa",
		"PlacasInteracao/PlacaZebra"
	]
	
	print("=== Conectando áreas de interação existentes nas placas ===")
	
	for path in areas_paths:
		var area = get_node_or_null(path) as PlacaInteracao
		if area:
			# Conectar sinais da área
			if not area.jogador_entrou.is_connected(_on_jogador_entrou_placa):
				area.jogador_entrou.connect(_on_jogador_entrou_placa.bind(area))
			if not area.jogador_saiu.is_connected(_on_jogador_saiu_placa):
				area.jogador_saiu.connect(_on_jogador_saiu_placa.bind(area))
			if not area.desafio_solicitado.is_connected(_on_desafio_solicitado):
				area.desafio_solicitado.connect(_on_desafio_solicitado.bind(area))
			print("✓ Área conectada: %s (tipo: %s) em posição global: %s" % [area.nome_jaula, area.tipo_desafio, area.global_position])
		else:
			push_warning("✗ Área não encontrada: %s" % path)
	
	print("=== Áreas de interação conectadas ===")

func _on_jogador_entrou_placa(placa: PlacaInteracao) -> void:
	if _desafio_ativo:
		return
	
	_placa_atual = placa
	var jaula_comprada = _verificar_jaula_comprada(placa.tipo_desafio)
	var jaula_desbloqueada = _verificar_jaula_desbloqueada(placa.tipo_desafio)
	
	# Se a jaula está comprada mas sem animais, mostrar mensagem diferente
	if jaula_comprada and not jaula_desbloqueada:
		_mostrar_prompt_interacao(placa.nome_jaula, false, true)  # comprada mas sem animais
	else:
		_mostrar_prompt_interacao(placa.nome_jaula, jaula_desbloqueada, false)

func _on_jogador_saiu_placa(placa: PlacaInteracao) -> void:
	if _placa_atual == placa:
		_placa_atual = null
		_esconder_prompt_interacao()

func _mostrar_prompt_interacao(nome_jaula: String, desbloqueada: bool = true, sem_animais: bool = false) -> void:
	if _prompt_interacao:
		_prompt_interacao.visible = true
		var vbox = _prompt_interacao.get_node_or_null("MarginContainer/VBoxContainer")
		if vbox:
			var prompt_label = vbox.get_node_or_null("PromptLabel")
			var nome_label = vbox.get_node_or_null("NomeJaulaLabel")
			
			if prompt_label:
				if desbloqueada:
					prompt_label.text = "🎮 Pressione [E] para entrar no DESAFIO!"
					prompt_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9, 1.0))
				elif sem_animais:
					prompt_label.text = "🐾 JAULA VAZIA - Compre animais na loja"
					prompt_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 1.0))
				else:
					prompt_label.text = "🔒 JAULA BLOQUEADA"
					prompt_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			
			if nome_label:
				if desbloqueada:
					nome_label.text = nome_jaula
					nome_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
				elif sem_animais:
					nome_label.text = "Compre pelo menos 1 animal na loja!"
					nome_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 1.0))
				else:
					nome_label.text = "Compre esta jaula na loja para desbloquear!"
					nome_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2, 1.0))
		
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
	
	# Verificar se a jaula está comprada
	var jaula_comprada = _verificar_jaula_comprada(tipo_desafio)
	if not jaula_comprada:
		print("Jaula bloqueada! Compre a jaula na loja primeiro.")
		# Mostrar feedback visual de bloqueio
		_mostrar_feedback_bloqueio("🔒 JAULA BLOQUEADA!\nCompre na loja (tecla L)")
		return
	
	# Verificar se a jaula tem pelo menos 1 animal
	var jaula = _obter_jaula_por_tipo(tipo_desafio)
	if not jaula or jaula.animals.size() < 1:
		print("Jaula sem animais! Compre pelo menos 1 animal na loja.")
		# Mostrar feedback visual de falta de animais
		_mostrar_feedback_bloqueio("🐾 JAULA VAZIA!\nCompre pelo menos 1 animal na loja")
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

# =============================================================
# Sistema de Bloqueio de Jaulas
# =============================================================

# Verifica se a jaula está comprada (sem verificar animais)
func _verificar_jaula_comprada(tipo_desafio: String) -> bool:
	if not _player:
		return false
	
	# Mapeamento de tipo_desafio para nome_exibicao da jaula
	var tipo_para_nome: Dictionary = {
		"elefante": "Jaula do Elefante",
		"leao": "Jaula do Leão",
		"macaco": "Jaula do Macaco",
		"girafa": "Jaula da Girafa",
		"zebra": "Jaula da Zebra"
	}
	
	var nome_jaula = tipo_para_nome.get(tipo_desafio, "")
	if nome_jaula.is_empty():
		return false
	
	# Verificar se o jogador possui esta jaula
	for jaula in _player.jaulas_possuidas:
		if jaula.cage_type and jaula.cage_type.nome_exibicao == nome_jaula:
			return true
	
	return false

# Obtém a jaula pelo tipo de desafio
func _obter_jaula_por_tipo(tipo_desafio: String) -> Cage:
	if not _player:
		return null
	
	# Mapeamento de tipo_desafio para nome_exibicao da jaula
	var tipo_para_nome: Dictionary = {
		"elefante": "Jaula do Elefante",
		"leao": "Jaula do Leão",
		"macaco": "Jaula do Macaco",
		"girafa": "Jaula da Girafa",
		"zebra": "Jaula da Zebra"
	}
	
	var nome_jaula = tipo_para_nome.get(tipo_desafio, "")
	if nome_jaula.is_empty():
		return null
	
	# Encontrar a jaula
	for jaula in _player.jaulas_possuidas:
		if jaula.cage_type and jaula.cage_type.nome_exibicao == nome_jaula:
			return jaula
	
	return null

# Verifica se a jaula está desbloqueada (comprada E com pelo menos 1 animal)
func _verificar_jaula_desbloqueada(tipo_desafio: String) -> bool:
	if not _player:
		return false
	
	var jaula = _obter_jaula_por_tipo(tipo_desafio)
	if not jaula:
		return false
	
	# Verificar se a jaula tem pelo menos 1 animal
	return jaula.animals.size() >= 1

func _mostrar_feedback_bloqueio(mensagem: String = "🔒 JAULA BLOQUEADA!\nCompre na loja (tecla L)") -> void:
	# Criar um feedback visual temporário
	if not _hud:
		return
	
	# Verificar se já existe um feedback
	var feedback_existente = _hud.get_node_or_null("FeedbackBloqueio")
	if feedback_existente:
		feedback_existente.queue_free()
	
	var feedback = PanelContainer.new()
	feedback.name = "FeedbackBloqueio"
	feedback.set_anchors_preset(Control.PRESET_CENTER_TOP)
	feedback.position = Vector2(-200, 50)
	feedback.custom_minimum_size = Vector2(400, 80)
	
	# Estilizar
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.2, 0.1, 0.1, 0.95)
	estilo.border_color = Color(1.0, 0.3, 0.3, 1.0)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(15)
	feedback.add_theme_stylebox_override("panel", estilo)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	feedback.add_child(margin)
	
	var label = Label.new()
	label.text = mensagem
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font = load("res://Assets/Fonts/Silkscreen/Silkscreen-Regular.ttf")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	margin.add_child(label)
	
	_hud.add_child(feedback)
	
	# Remover após 3 segundos
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(feedback):
		feedback.queue_free()

func _on_jaula_comprada(cage_type: CageType) -> void:
	# Encontrar a jaula recém-comprada no jogador
	var jaula_comprada: Cage = null
	for jaula in _player.jaulas_possuidas:
		if jaula.cage_type and jaula.cage_type.resource_path == cage_type.resource_path:
			jaula_comprada = jaula
			break
	
	if not jaula_comprada:
		push_warning("Jaula comprada não encontrada no jogador!")
		return
	
	var nome_jaula = cage_type.nome_exibicao
	print("Jaula '%s' comprada! Inicializando visualização (animais: %d)" % [nome_jaula, jaula_comprada.animals.size()])
	
	# Criar container visual se não existir
	if not jaula_comprada in jaulas_visuais:
		if nome_jaula in posicoes_jaulas_por_tipo:
			var posicao = posicoes_jaulas_por_tipo[nome_jaula]
			_criar_container_jaula(jaula_comprada, posicao)
		else:
			push_warning("Posição não definida para jaula: %s" % nome_jaula)
			return
	
	# Atualizar os animais visuais (apenas a jaula do elefante vem com 1 animal, as demais começam vazias)
	_atualizar_animais_na_jaula(jaula_comprada)
	
	# Quando uma jaula é comprada, atualizar o prompt se o jogador estiver perto de uma placa
	if _placa_atual:
		# Verificar se a jaula comprada corresponde à placa atual
		var tipo_para_nome: Dictionary = {
			"elefante": "Jaula do Elefante",
			"leao": "Jaula do Leão",
			"macaco": "Jaula do Macaco",
			"girafa": "Jaula da Girafa",
			"zebra": "Jaula da Zebra"
		}
		
		var nome_esperado = tipo_para_nome.get(_placa_atual.tipo_desafio, "")
		if cage_type.nome_exibicao == nome_esperado:
			# Atualizar o prompt para mostrar que está desbloqueada
			var jaula_esta_comprada = _verificar_jaula_comprada(_placa_atual.tipo_desafio)
			var jaula_desbloqueada = _verificar_jaula_desbloqueada(_placa_atual.tipo_desafio)
			
			# Se a jaula está comprada mas sem animais, mostrar mensagem diferente
			if jaula_esta_comprada and not jaula_desbloqueada:
				_mostrar_prompt_interacao(_placa_atual.nome_jaula, false, true)  # comprada mas sem animais
			else:
				_mostrar_prompt_interacao(_placa_atual.nome_jaula, jaula_desbloqueada, false)

# =============================================================
# Sistema de Mapeamento de Áreas dos Assets
# =============================================================

func _mapear_areas_assets() -> void:
	# Mapeamento de nomes dos nodes Assets para nomes das jaulas
	var assets_para_jaula: Dictionary = {
		"Assests Elefante": "Jaula do Elefante",
		"Assets Leao": "Jaula do Leão",
		"Assets Macaco": "Jaula do Macaco",
		"Assets Girafa": "Jaula da Girafa",
		"Assets Zebra": "Jaula da Zebra"
	}
	
	# Mapeamento de posições das jaulas (onde os containers são criados)
	var posicoes_jaulas: Dictionary = {
		"Jaula do Elefante": Vector2(967, 533),
		"Jaula do Leão": Vector2(2887, 533),
		"Jaula do Macaco": Vector2(4804, 533),
		"Jaula da Girafa": Vector2(6724, 533),
		"Jaula da Zebra": Vector2(8644, 533)
	}
	
	print("=== Criando Area2D para Assets das jaulas ===")
	
	for assets_nome in assets_para_jaula:
		var nome_jaula = assets_para_jaula[assets_nome]
		var assets_node = get_node_or_null(assets_nome) as Node2D
		
		if not assets_node:
			push_warning("Node '%s' não encontrado!" % assets_nome)
			continue
		
		var posicao_jaula = posicoes_jaulas.get(nome_jaula, Vector2.ZERO)
		var areas: Array[Area2D] = []
		
		# Processar todos os sprites filhos do node Assets e criar Area2D como filhos dos sprites
		_processar_sprites_assets(assets_node, areas, posicao_jaula, nome_jaula)
		
		# Ajustar z_index dos sprites dos assets para ficarem atrás
		_ajustar_z_index_assets(assets_node, 5)
		
		areas_assets[nome_jaula] = areas
		print("✓ Criadas %d Area2D para '%s' (node: %s)" % [areas.size(), nome_jaula, assets_nome])
		# Debug: verificar se as áreas têm CollisionShape2D
		for area in areas:
			var collision = area.get_node_or_null("CollisionShape2D")
			if collision and collision.shape:
				var shape = collision.shape
				if shape is RectangleShape2D:
					var size = (shape as RectangleShape2D).size
					print("  - Area em %s: tamanho %s" % [area.get_path(), size])
	
	print("=== Criação de áreas concluída ===")

func _processar_sprites_assets(node: Node, areas: Array[Area2D], posicao_container: Vector2, nome_jaula: String) -> void:
	# Processar este nó se for Sprite2D
	if node is Sprite2D:
		var sprite = node as Sprite2D
		if sprite.texture:
			# Verificar se já tem Area2D (pode ter nome "AreaAsset" ou mesmo nome do sprite)
			var area_existente = sprite.get_node_or_null("AreaAsset")
			if not area_existente:
				# Tentar encontrar qualquer Area2D filho
				for child in sprite.get_children():
					if child is Area2D:
						area_existente = child
						break
			
			if area_existente:
				areas.append(area_existente as Area2D)
				# Verificar se tem CollisionShape2D, se não tiver, criar
				var collision = area_existente.get_node_or_null("CollisionShape2D")
				var textura = sprite.texture
				var tamanho = textura.get_size() * sprite.scale
				
				if not collision:
					collision = CollisionShape2D.new()
					var shape = RectangleShape2D.new()
					shape.size = tamanho  # Tamanho exato do sprite
					collision.shape = shape
					area_existente.add_child(collision)
				else:
					# Ajustar tamanho do shape existente para corresponder ao sprite
					if collision.shape is RectangleShape2D:
						(collision.shape as RectangleShape2D).size = tamanho
					elif collision.shape:
						# Se for outro tipo de shape, criar novo RectangleShape2D
						var shape = RectangleShape2D.new()
						shape.size = tamanho
						collision.shape = shape
				return
			
			# Obter tamanho do sprite (considerando escala)
			var textura = sprite.texture
			var tamanho = textura.get_size() * sprite.scale
			
			# Criar Area2D como filho do sprite (posição relativa ao sprite = 0,0)
			var area = Area2D.new()
			area.name = "AreaAsset"
			area.position = Vector2.ZERO  # Relativo ao sprite
			
			# Criar CollisionShape2D com tamanho exato do sprite
			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = tamanho  # Tamanho exato do sprite
			collision.shape = shape
			area.add_child(collision)
			
			# Adicionar como filho do sprite
			sprite.add_child(area)
			
			# Guardar referência para verificação de colisão
			areas.append(area)
	
	# Processar filhos recursivamente
	for child in node.get_children():
		_processar_sprites_assets(child, areas, posicao_container, nome_jaula)

func _ajustar_z_index_assets(node: Node, z_index_val: float) -> void:
	# Ajustar z_index de todos os sprites para ficarem atrás dos animais
	if node is Sprite2D:
		(node as Sprite2D).z_index = z_index_val
	
	# Processar filhos recursivamente
	for child in node.get_children():
		_ajustar_z_index_assets(child, z_index_val)

func _criar_area_animal(sprite: Node2D, posicao: Vector2) -> void:
	# Criar Area2D para o animal para detectar colisões futuras
	# A área está na posição (0,0) relativa ao sprite, já que o sprite já está posicionado
	var area = Area2D.new()
	area.name = "AreaAnimal"
	area.position = Vector2.ZERO  # Relativo ao sprite (que já está na posição correta)
	
	# Criar CollisionShape2D circular com o mesmo raio usado na verificação
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 35.0  # Raio do animal (mesmo usado em _verificar_spot_livre)
	collision.shape = shape
	area.add_child(collision)
	
	# Adicionar como filho do sprite
	sprite.add_child(area)
