extends Node

# Singleton para gerenciar salvamento do jogo
const SAVE_FILE_PATH = "user://game_save.cfg"

# Verifica se existe um save
static func has_save() -> bool:
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	return error == OK and config.has_section_key("game", "started")

# Salva o estado completo do jogo
static func save_game(player: CharacterBody2D) -> bool:
	if not player:
		push_error("Player não encontrado para salvar!")
		return false
	
	var config = ConfigFile.new()
	
	# Salvar dados básicos
	config.set_value("game", "started", true)
	config.set_value("player", "total_moedas", player.total_moedas)
	config.set_value("player", "position_x", player.global_position.x)
	config.set_value("player", "position_y", player.global_position.y)
	
	# Salvar jaulas e animais (usando JSON para arrays/dicionários)
	var jaulas_data = []
	for i in range(player.jaulas_possuidas.size()):
		var jaula = player.jaulas_possuidas[i]
		if not jaula or not jaula.cage_type:
			continue
		
		var jaula_data = {
			"cage_type_path": jaula.cage_type.resource_path,
			"animals": []
		}
		
		# Salvar animais da jaula
		for j in range(jaula.animals.size()):
			var animal = jaula.animals[j]
			if not animal or not animal.template:
				continue
			
			var animal_data = {
				"template_path": animal.template.resource_path,
				"nome": animal.nome,
				"purchase_price": animal.purchase_price,
				"purchase_date": animal.purchase_date
			}
			jaula_data.animals.append(animal_data)
		
		jaulas_data.append(jaula_data)
	
	# Converter para JSON string para salvar no ConfigFile
	var json_string = JSON.stringify(jaulas_data)
	if json_string.is_empty():
		push_warning("JSON string está vazio! Nenhuma jaula será salva.")
	else:
		print("JSON string gerado (tamanho: %d caracteres)" % json_string.length())
	config.set_value("player", "jaulas_json", json_string)
	
	var error = config.save(SAVE_FILE_PATH)
	if error == OK:
		print("✓ Jogo salvo com sucesso!")
		print("  - Moedas: %d" % player.total_moedas)
		print("  - Posição: %s" % player.global_position)
		print("  - Jaulas: %d" % player.jaulas_possuidas.size())
		for i in range(player.jaulas_possuidas.size()):
			var jaula = player.jaulas_possuidas[i]
			if jaula and jaula.cage_type:
				print("    - %s: %d animais" % [jaula.cage_type.nome_exibicao, jaula.animals.size()])
		return true
	else:
		push_error("Erro ao salvar jogo: %d" % error)
		return false

# Carrega o estado completo do jogo
static func load_game(player: CharacterBody2D) -> bool:
	if not player:
		push_error("Player não encontrado para carregar!")
		return false
	
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	if error != OK:
		push_error("Erro ao carregar save: %d" % error)
		return false
	
	if not config.has_section_key("game", "started"):
		push_error("Save inválido!")
		return false
	
	# Carregar dados básicos
	if config.has_section_key("player", "total_moedas"):
		player.total_moedas = config.get_value("player", "total_moedas", 99999)
		player.moedas_atualizadas.emit(player.total_moedas)
	
	# Carregar posição
	if config.has_section_key("player", "position_x") and config.has_section_key("player", "position_y"):
		var pos_x = config.get_value("player", "position_x", 0.0)
		var pos_y = config.get_value("player", "position_y", 0.0)
		player.global_position = Vector2(pos_x, pos_y)
	
	# Carregar jaulas e animais (usando JSON)
	if config.has_section_key("player", "jaulas_json"):
		var json_string = config.get_value("player", "jaulas_json", "[]")
		print("JSON string carregado do save (tamanho: %d caracteres)" % json_string.length())
		
		if json_string.is_empty() or json_string == "[]":
			push_warning("JSON de jaulas está vazio! Pode ser um save antigo.")
			player.jaulas_possuidas.clear()
		else:
			var json = JSON.new()
			var parse_error = json.parse(json_string)
			
			if parse_error != OK:
				push_error("Erro ao fazer parse do JSON de jaulas: %d" % parse_error)
				push_error("JSON string (primeiros 500 chars): %s" % json_string.substr(0, 500))
				player.jaulas_possuidas.clear()
			else:
				var jaulas_data = json.data as Array
				if not jaulas_data is Array:
					push_error("Dados de jaulas não são um Array!")
					player.jaulas_possuidas.clear()
				else:
					# Limpar jaulas existentes ANTES de carregar
					player.jaulas_possuidas.clear()
					print("Jaulas limpas. Carregando %d jaulas do save..." % jaulas_data.size())
					
					for jaula_data in jaulas_data:
						if not jaula_data is Dictionary:
							push_warning("Jaula_data não é um Dictionary!")
							continue
						
						if not jaula_data.has("cage_type_path"):
							push_warning("Jaula_data não tem cage_type_path!")
							continue
						
						var cage_type = load(jaula_data.cage_type_path) as CageType
						if not cage_type:
							push_warning("Não foi possível carregar CageType: %s" % jaula_data.cage_type_path)
							continue
						
						var jaula = Cage.new(cage_type)
						
						# Carregar animais
						if jaula_data.has("animals") and jaula_data.animals is Array:
							for animal_data in jaula_data.animals:
								if not animal_data is Dictionary:
									continue
								
								if not animal_data.has("template_path"):
									continue
								
								var template = load(animal_data.template_path) as AnimalTemplate
								if not template:
									push_warning("Não foi possível carregar AnimalTemplate: %s" % animal_data.template_path)
									continue
								
								var animal = Animal.new(template)
								if animal_data.has("nome"):
									animal.nome = animal_data.nome
								if animal_data.has("purchase_price"):
									animal.purchase_price = animal_data.purchase_price
								if animal_data.has("purchase_date"):
									animal.purchase_date = animal_data.purchase_date
								
								jaula.animals.append(animal)
								print("  Animal carregado: %s" % animal.nome)
						
						player.jaulas_possuidas.append(jaula)
						print("  Jaula carregada: %s (%d animais)" % [cage_type.nome_exibicao, jaula.animals.size()])
					
					print("✓ Jogo carregado: %d jaulas, %d moedas" % [player.jaulas_possuidas.size(), player.total_moedas])
	else:
		push_warning("Save não contém 'jaulas_json'! Pode ser um save antigo ou corrompido.")
		player.jaulas_possuidas.clear()
	
	return true

# Salva que o jogo foi iniciado (método antigo mantido para compatibilidade)
# IMPORTANTE: Este método NÃO sobrescreve o save completo, apenas adiciona/atualiza a flag "started"
static func save_game_started() -> void:
	var config = ConfigFile.new()
	# Carregar save existente se houver, para não perder dados
	var error = config.load(SAVE_FILE_PATH)
	if error != OK:
		# Se não existe save, criar novo
		config = ConfigFile.new()
	
	# Apenas atualizar a flag "started", sem perder outros dados
	config.set_value("game", "started", true)
	config.save(SAVE_FILE_PATH)
	print("Jogo salvo: iniciado (sem perder dados existentes)")

# Limpa o save (quando iniciar novo jogo)
static func clear_save() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove(SAVE_FILE_PATH)
		print("Save limpo")

