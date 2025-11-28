extends CharacterBody2D

# =============================================================
# 1. SINAIS (Seus "avisos" para a UI)
# =============================================================
# (Copie e cole esta parte no topo do arquivo)
signal vida_atualizada(nova_vida)
signal moedas_atualizadas(total_moedas)
signal conquista_desbloqueada(id_conquista)
signal jogador_morreu

# =============================================================
# 2. VARIÁVEIS DE "BACKEND" (Seu "Model")
# =============================================================
# (Copie e cole esta parte logo abaixo dos sinais)

# --- Variáveis do seu Model Spring ---
@export var nome: String = "Jogador"
@export var total_moedas: int = 99999

# Arrays para guardar IDs ou dados
@export var conquistas_obtidas: Array[String] = []
@export var jaulas_possuvidas: Array = []
@export var historico_problemas: Array[Dictionary] = []

# Dicionário para o outfit
@export var outfit: Dictionary = {"chapeu": "padrao", "roupa": "padrao"}

# --- Variáveis de Estado do Jogo ---
@export var vida_maxima: int = 100
var vida_atual: int = 100


# =============================================================
# 3. VARIÁVEIS DE MOVIMENTO (QUE SEUS COLEGAS JÁ USAVAM)
# =============================================================
# (Esta parte provavelmente já existe. Você vai ADICIONAR 
#  @export nelas para poderem ser editadas no Inspetor)

@export var velocidade: float = 1000.0   # Velocidade aumentada para movimento mais rápido
@export var forca_pulo: float = -600.0  # Força do pulo estilo Mario (mais forte e rápido)
@export var gravidade: float = 2800.0    # Gravidade alta estilo Mario (pulo rápido e responsivo)
@export var gravidade_caindo: float = 3500.0  # Gravidade ainda maior quando caindo (estilo Mario)
# Esta é a lista das "instâncias" de jaulas que o jogador possui.
@export var jaulas_possuidas: Array[Cage] = []

# Referência ao sprite para poder virá-lo
var sprite: AnimatedSprite2D

# Limites do mapa (ajustar conforme necessário)
@export var limite_esquerda: float = 0.0
@export var limite_direita: float = 9500.0  # Ajustado para acessar todas as jaulas até a Barreira Direita

# =============================================================
# 4. FUNÇÕES "BUILT-IN" (Onde a lógica acontece)
# =============================================================

# (Esta função _ready provavelmente já existe,
#  apenas adicione a linha da vida_atual)
func _ready():
	vida_atual = vida_maxima
	# Inicializa moedas se ainda não foram definidas
	if total_moedas == 0:
		total_moedas = 99999
	moedas_atualizadas.emit(total_moedas)
	
	# Adicionar ao grupo "player" para ser encontrado facilmente
	add_to_group("player")
	
	# Garantir que o player está na collision layer 1 para ser detectado pelas áreas
	collision_layer = 1
	collision_mask = 1
	
	# Busca o AnimatedSprite2D para poder virá-lo
	sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite:
		# Tenta encontrar em qualquer filho
		for child in get_children():
			if child is AnimatedSprite2D:
				sprite = child
				break
	
	# Inicializa o jogador com uma jaula de elefante se ainda não tiver nenhuma
	if jaulas_possuidas.is_empty():
		var elephant_cage_type = load("res://Assets/DataModels/elephant_cage.tres") as CageType
		if elephant_cage_type:
			var jaula_elefante = Cage.new(elephant_cage_type)
			# Adiciona automaticamente o primeiro animal compatível (toda jaula vem com um animal)
			if not elephant_cage_type.animal_templates_aceitos.is_empty():
				var primeiro_animal_template = elephant_cage_type.animal_templates_aceitos[0]
				var animal_inicial = Animal.new(primeiro_animal_template)
				jaula_elefante.animals.append(animal_inicial)
				print("Jogador iniciado com jaula de elefante! Animal '%s' incluído." % animal_inicial.nome)
			else:
				print("Jogador iniciado com jaula de elefante!")
			jaulas_possuidas.append(jaula_elefante)
	# ... (pode ter outros códigos dos seus colegas aqui)


# (ESTA É A FUNÇÃO MAIS IMPORTANTE QUE SEUS COLEGAS FIZERAM)
func _physics_process(delta):
	# --- INÍCIO DO CÓDIGO DELES (Exemplo) ---
	
	# Aplica gravidade (estilo Mario: mais forte quando caindo)
	if not is_on_floor():
		# Se está caindo (velocidade positiva), usa gravidade mais forte
		if velocity.y > 0:
			velocity.y += gravidade_caindo * delta
		else:
			velocity.y += gravidade * delta

	# Checa o pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = forca_pulo # <-- MODIFICAÇÃO: Usando sua variável `forca_pulo`

	# Checa movimento Esquerda/Direita
	var direcao = Input.get_axis("ui_left", "ui_right")
	
	# Aplica limites ANTES do movimento para evitar sair do mapa
	if global_position.x <= limite_esquerda and direcao < 0:
		direcao = 0
		velocity.x = 0
	elif global_position.x >= limite_direita and direcao > 0:
		direcao = 0
		velocity.x = 0
	
	if direcao:
		velocity.x = direcao * velocidade # <-- MODIFICAÇÃO: Usando sua variável `velocidade`
		
		# Vira o sprite baseado na direção do movimento
		if sprite:
			if direcao < 0:  # Movendo para esquerda
				sprite.flip_h = true
			elif direcao > 0:  # Movendo para direita
				sprite.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade) # Para suavemente

	# Função mágica que move o personagem
	move_and_slide()
	
	# Limita a posição do jogador dentro dos limites do mapa (garantia extra)
	if global_position.x < limite_esquerda:
		global_position.x = limite_esquerda
		velocity.x = 0
	elif global_position.x > limite_direita:
		global_position.x = limite_direita
		velocity.x = 0
	
	# Previne queda infinita - se cair muito abaixo do chão, reseta a posição
	if global_position.y > 1200:  # Ajuste conforme a altura do seu mapa
		global_position.y = 800  # Posição segura (ajuste conforme necessário)
		velocity.y = 0
	
	# --- ANIMAÇÕES ---
	_atualizar_animacao(direcao)
	
	# --- FIM DO CÓDIGO DELES ---

# Função para atualizar a animação baseada no estado do jogador
func _atualizar_animacao(direcao: float) -> void:
	if not sprite:
		return
	
	# Se não está no chão, usa animação de pulo
	if not is_on_floor():
		if sprite.animation != "jump":
			sprite.play("jump")
		return
	
	# Se está se movendo no chão
	if direcao != 0:
		# Usa "run" se estiver em alta velocidade, senão "walk"
		if abs(velocity.x) > velocidade * 0.7:
			if sprite.animation != "run":
				sprite.play("run")
		else:
			if sprite.animation != "walk":
				sprite.play("walk")
	else:
		# Parado - usa idle
		if sprite.animation != "idle":
			sprite.play("idle")

# --- NOVAS FUNÇÕES DE "BACKEND" (para comprar coisas) ---

## Esta função é chamada por um botão de "Comprar Jaula" na sua loja.
## Você passa para ela o "molde" (ex: jaula_leao.tres) que o jogador quer comprar.
func comprar_jaula(cage_type_blueprint: CageType) -> bool:
	# Validação: verificar se o blueprint é válido
	if not cage_type_blueprint:
		push_error("Tentativa de comprar jaula com blueprint inválido!")
		return false
	
	# Verificar se já possui esta jaula (máximo 1 de cada tipo)
	for jaula in jaulas_possuidas:
		# Comparar usando resource_path para garantir que funcione corretamente
		if jaula.cage_type and cage_type_blueprint:
			if jaula.cage_type.resource_path == cage_type_blueprint.resource_path:
				print("Você já possui esta jaula! Máximo de 1 de cada tipo.")
				return false
	
	# Verificar se tem dinheiro suficiente (apenas se o preço for positivo)
	if cage_type_blueprint.base_price > 0:
		if total_moedas < cage_type_blueprint.base_price:
			print("Dinheiro insuficiente para comprar a jaula '%s'! Necessário: %d, Você tem: %d" % [
				cage_type_blueprint.nome_exibicao,
				cage_type_blueprint.base_price,
				total_moedas
			])
			return false

	# 1. Desconta o dinheiro (apenas se o preço for positivo)
	if cage_type_blueprint.base_price > 0:
		total_moedas -= cage_type_blueprint.base_price
		moedas_atualizadas.emit(total_moedas) # Avisa a UI para atualizar
	
	# 2. Cria a "Instância" da Jaula
	var nova_jaula = Cage.new(cage_type_blueprint)
	
	# 3. Adiciona automaticamente o primeiro animal compatível APENAS para a jaula do elefante
	# As demais jaulas começam vazias e os animais devem ser comprados separadamente
	if cage_type_blueprint.nome_exibicao == "Jaula do Elefante":
		if not cage_type_blueprint.animal_templates_aceitos.is_empty():
			var primeiro_animal_template = cage_type_blueprint.animal_templates_aceitos[0]
			# Adiciona o animal sem descontar moedas (vem grátis com a jaula)
			var animal_inicial = Animal.new(primeiro_animal_template)
			nova_jaula.animals.append(animal_inicial)
			print("Jaula '%s' comprada com sucesso! Animal '%s' incluído." % [nova_jaula.cage_type.nome_exibicao, animal_inicial.nome])
		else:
			print("Jaula '%s' comprada com sucesso!" % nova_jaula.cage_type.nome_exibicao)
	else:
		print("Jaula '%s' comprada com sucesso! (sem animais - compre animais na loja)" % nova_jaula.cage_type.nome_exibicao)
	
	# 4. Adiciona à lista do jogador
	jaulas_possuidas.append(nova_jaula)
	return true

## Esta função compra um animal PARA UMA JAULA ESPECÍFICA.
## Você passa a "instância" da jaula (ex: jaulas_possuidas[0])
## e o "molde" do animal (ex: lion.tres).
## Retorna true se a compra foi bem-sucedida, false caso contrário.
func comprar_animal_para_jaula(jaula_instancia: Cage, animal_template_blueprint: AnimalTemplate) -> bool:
	# Validações
	if not jaula_instancia:
		push_error("Tentativa de comprar animal para jaula inválida!")
		return false
	
	if not animal_template_blueprint:
		push_error("Tentativa de comprar animal com template inválido!")
		return false
	
	# Verificar se a jaula pode adicionar mais animais
	if not jaula_instancia.can_add_more_animals():
		print("Erro: Jaula cheia! (%d/10 animais)" % jaula_instancia.animals.size())
		return false
	
	# Verificar compatibilidade
	if not animal_template_blueprint in jaula_instancia.cage_type.animal_templates_aceitos:
		print("Erro: Esta jaula não aceita este tipo de animal! Jaula: '%s', Animal: '%s'" % [
			jaula_instancia.cage_type.nome_exibicao,
			animal_template_blueprint.nome_exibicao
		])
		return false
	
	# Verificar se tem dinheiro suficiente (apenas se o preço for positivo)
	var preco = animal_template_blueprint.base_price
	if preco > 0:
		if total_moedas < preco:
			print("Erro: Dinheiro insuficiente! Necessário: %d, Você tem: %d" % [preco, total_moedas])
			return false
	
	# OK, pode comprar! Atualiza as moedas
	# Se preço > 0: desconta (custa moedas)
	# Se preço < 0: adiciona (ganha moedas)
	# Se preço = 0: não muda (grátis)
	total_moedas -= preco  # Subtrai o preço (se negativo, adiciona moedas)
	moedas_atualizadas.emit(total_moedas) # Avisa a UI
	
	# Adiciona o animal à jaula
	var novo_animal = Animal.new(animal_template_blueprint)
	jaula_instancia.animals.append(novo_animal)
	
	var mensagem = "Animal '%s' comprado" % novo_animal.nome
	if preco > 0:
		mensagem += " por %s moedas" % GameUtils.format_currency(preco)
	elif preco < 0:
		mensagem += " - você ganhou %s moedas!" % GameUtils.format_currency(abs(preco))
	else:
		mensagem += " (grátis)"
	mensagem += ". Moedas restantes: %s" % GameUtils.format_currency(total_moedas)
	print(mensagem)
	
	return true

# =============================================================
# 5. FUNÇÕES DE "BACKEND" (Suas novas funções)
# =============================================================
# (Copie e cole esta parte inteira no final do seu arquivo .gd)

func adicionar_moedas(quantidade: int) -> void:
	if quantidade <= 0:
		push_warning("Tentativa de adicionar quantidade inválida de moedas: %d" % quantidade)
		return
	
	total_moedas += quantidade
	print("Moedas adicionadas: %s. Total: %s" % [
		GameUtils.format_currency(quantidade),
		GameUtils.format_currency(total_moedas)
	])
	moedas_atualizadas.emit(total_moedas)

func tomar_dano(quantidade: int) -> void:
	if quantidade <= 0:
		return  # Ignora dano inválido
	
	if vida_atual == 0:
		return  # Não pode tomar dano se já estiver morto

	vida_atual -= quantidade
	if vida_atual < 0:
		vida_atual = 0
	
	print("Dano recebido: %d. Vida atual: %d/%d" % [quantidade, vida_atual, vida_maxima])
	vida_atualizada.emit(vida_atual) # Avisa a UI
	
	if vida_atual == 0:
		morrer()

func morrer() -> void:
	print("Jogador morreu!")
	jogador_morreu.emit()
	# Exemplo simples: recarrega a cena
	# TODO: Implementar tela de game over mais elaborada
	get_tree().reload_current_scene()

func desbloquear_conquista(id_conquista: String) -> bool:
	if id_conquista.is_empty():
		push_warning("Tentativa de desbloquear conquista com ID vazio!")
		return false
	
	if id_conquista in conquistas_obtidas:
		return false  # Já possui esta conquista
	
	conquistas_obtidas.append(id_conquista)
	print("Nova conquista desbloqueada: %s" % id_conquista)
	conquista_desbloqueada.emit(id_conquista)
	return true

# Adicione outras funções do seu "Model" aqui...
