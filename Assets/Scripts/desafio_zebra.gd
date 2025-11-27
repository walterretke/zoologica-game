extends DesafioBase
class_name DesafioZebra

## Desafio da Jaula da Zebra: Regra de Três Composta
## Nível: 7º ao 9º ano do Ensino Fundamental

@export var dificuldade: int = 1  # 1 = fácil, 2 = médio, 3 = difícil

func _ready() -> void:
	titulo = "🦓 DESAFIO DA ZEBRA"
	descricao = "Resolva os problemas de Regra de Três Composta!"
	total_perguntas = 5
	moedas_por_acerto = 30
	tempo_por_pergunta = 75.0
	super._ready()

func _gerar_pergunta() -> void:
	# Regra de três composta com 2 grandezas
	# Diretamente proporcional: quanto mais, mais
	# Inversamente proporcional: quanto mais, menos
	
	var problema: Dictionary = _gerar_problema_composto()
	
	_pergunta_label.text = problema.texto
	resposta_correta = problema.resposta
	
	# Configurar múltipla escolha com 4 opções
	var opcoes = _gerar_opcoes(int(resposta_correta))
	_configurar_multipla_escolha(opcoes)
	
	print("Regra de Três Composta - Resposta: %d" % resposta_correta)

func _gerar_problema_composto() -> Dictionary:
	var tipo = randi() % 5
	var resultado: Dictionary = {}
	
	match tipo:
		0:  # Trabalhadores, dias, trabalho (2 grandezas inversamente proporcionais)
			# Se 4 tratadores alimentam 20 zebras em 3 horas,
			# quantas horas 6 tratadores levarão para alimentar 30 zebras?
			var tratadores1 = randi_range(2, 5)
			var zebras1 = tratadores1 * randi_range(4, 8)
			var horas1 = randi_range(2, 5)
			
			var tratadores2 = randi_range(2, 6)
			var zebras2 = tratadores2 * randi_range(3, 7)
			
			# Mais tratadores = menos tempo (inversa), mais zebras = mais tempo (direta)
			# horas2 = horas1 * (tratadores1/tratadores2) * (zebras2/zebras1)
			var resposta_float = float(horas1 * tratadores1 * zebras2) / float(tratadores2 * zebras1)
			
			# Ajustar para resultado inteiro
			var resposta_inteira = roundi(resposta_float)
			if resposta_inteira < 1:
				resposta_inteira = 1
			
			resultado.texto = "Se %d tratadores alimentam %d zebras em %d horas,\nem quantas horas %d tratadores alimentarão %d zebras?" % [
				tratadores1, zebras1, horas1, tratadores2, zebras2
			]
			resultado.resposta = resposta_inteira
			
		1:  # Máquinas, dias, produção
			var maquinas1 = randi_range(2, 4)
			var dias1 = randi_range(3, 6)
			var producao1 = maquinas1 * dias1 * randi_range(5, 10)
			
			var maquinas2 = randi_range(3, 6)
			var producao2 = maquinas2 * randi_range(6, 12)
			
			# dias2 = (producao2 * dias1 * maquinas1) / (producao1 * maquinas2)
			var resposta_float = float(producao2 * dias1 * maquinas1) / float(producao1 * maquinas2)
			var resposta_inteira = roundi(resposta_float)
			if resposta_inteira < 1:
				resposta_inteira = 1
			
			resultado.texto = "Se %d máquinas produzem %d rações em %d dias,\nem quantos dias %d máquinas produzirão %d rações?" % [
				maquinas1, producao1, dias1, maquinas2, producao2
			]
			resultado.resposta = resposta_inteira
			
		2:  # Funcionários, horas, tarefas (mais simples)
			var func1 = randi_range(2, 4)
			var horas1 = randi_range(2, 4)
			var tarefas1 = func1 * horas1 * 2
			
			var func2 = randi_range(3, 6)
			var tarefas2 = func2 * randi_range(2, 4) * 2
			
			# horas2 = (tarefas2 * horas1 * func1) / (tarefas1 * func2)
			var resposta_float = float(tarefas2 * horas1 * func1) / float(tarefas1 * func2)
			var resposta_inteira = roundi(resposta_float)
			if resposta_inteira < 1:
				resposta_inteira = 1
			
			resultado.texto = "Se %d funcionários completam %d tarefas em %d horas,\nem quantas horas %d funcionários completarão %d tarefas?" % [
				func1, tarefas1, horas1, func2, tarefas2
			]
			resultado.resposta = resposta_inteira
			
		3:  # Zebras, comida, dias
			var zebras1 = randi_range(3, 6)
			var comida1 = zebras1 * randi_range(4, 8)
			var dias1 = randi_range(2, 5)
			
			var zebras2 = randi_range(4, 8)
			var dias2 = randi_range(3, 6)
			
			# comida2 = (comida1 * zebras2 * dias2) / (zebras1 * dias1)
			var resposta_float = float(comida1 * zebras2 * dias2) / float(zebras1 * dias1)
			var resposta_inteira = roundi(resposta_float)
			if resposta_inteira < 1:
				resposta_inteira = 1
			
			resultado.texto = "Se %d zebras consomem %d kg de capim em %d dias,\nquantos kg de capim %d zebras consumirão em %d dias?" % [
				zebras1, comida1, dias1, zebras2, dias2
			]
			resultado.resposta = resposta_inteira
			
		4:  # Pedreiros, dias, metros
			var pedreiros1 = randi_range(2, 4)
			var dias1 = randi_range(3, 5)
			var metros1 = pedreiros1 * dias1 * randi_range(3, 6)
			
			var pedreiros2 = randi_range(3, 6)
			var metros2 = pedreiros2 * randi_range(4, 8) * 2
			
			# dias2 = (metros2 * dias1 * pedreiros1) / (metros1 * pedreiros2)
			var resposta_float = float(metros2 * dias1 * pedreiros1) / float(metros1 * pedreiros2)
			var resposta_inteira = roundi(resposta_float)
			if resposta_inteira < 1:
				resposta_inteira = 1
			
			resultado.texto = "Se %d pedreiros constroem %d metros de cerca em %d dias,\nem quantos dias %d pedreiros construirão %d metros?" % [
				pedreiros1, metros1, dias1, pedreiros2, metros2
			]
			resultado.resposta = resposta_inteira
		
		_:
			resultado.texto = "Problema não definido"
			resultado.resposta = 1
	
	return resultado

func _gerar_opcoes(resposta_correta_int: int) -> Array:
	var opcoes: Array = [resposta_correta_int]
	
	# Gerar 3 opções incorretas próximas à resposta correta
	var variacoes = [-3, -2, -1, 1, 2, 3, 4, 5, 6]
	variacoes.shuffle()
	
	var tentativas = 0
	while opcoes.size() < 4 and tentativas < 20:
		var variacao = variacoes[tentativas % variacoes.size()]
		var nova_opcao = resposta_correta_int + variacao
		
		# Garantir que a opção é positiva e única
		if nova_opcao > 0 and not nova_opcao in opcoes:
			opcoes.append(nova_opcao)
		
		tentativas += 1
	
	# Se ainda não tem 4 opções, adicionar valores diferentes
	while opcoes.size() < 4:
		var nova_opcao = randi_range(max(1, resposta_correta_int - 10), resposta_correta_int + 15)
		if nova_opcao > 0 and not nova_opcao in opcoes:
			opcoes.append(nova_opcao)
	
	# Embaralhar opções
	opcoes.shuffle()
	return opcoes

