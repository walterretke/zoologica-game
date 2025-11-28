extends DesafioBase
class_name DesafioElefante

## Desafio da Jaula do Elefante: Adição e Subtração
## Nível: 7º ao 9º ano do Ensino Fundamental

enum TipoOperacao { ADICAO, SUBTRACAO, MISTA }

@export var tipo_operacao: TipoOperacao = TipoOperacao.MISTA
@export var dificuldade: int = 1  # 1 = fácil, 2 = médio, 3 = difícil

var operacao_atual: String = ""

func _ready() -> void:
	titulo = "🐘 DESAFIO DO ELEFANTE"
	descricao = "Resolva as operações de Adição e Subtração!"
	total_perguntas = 5
	moedas_por_acerto = 15
	tempo_por_pergunta = 45.0
	super._ready()

func _obter_conteudo_ajuda(ajuda_label: RichTextLabel) -> void:
	ajuda_label.text = """[center][font_size=32]🐘 ADIÇÃO E SUBTRAÇÃO[/font_size][/center]

[font_size=24]FÓRMULAS:[/font_size]

[font_size=20]• Adição: a + b = c[/font_size]
[font_size=20]• Subtração: a - b = c[/font_size]

[font_size=24]COMO RESOLVER:[/font_size]

[font_size=20]ADIÇÃO (+):[/font_size]
Some os números normalmente.
Exemplo: 15 + 23 = 38

[font_size=20]SUBTRAÇÃO (-):[/font_size]
Subtraia o segundo número do primeiro.
Exemplo: 50 - 23 = 27

[font_size=20]DICA:[/font_size]
• Na adição, você está juntando quantidades
• Na subtração, você está tirando uma quantidade de outra"""

func _gerar_pergunta() -> void:
	var num1: int
	var num2: int
	var operador: String
	
	# Ajustar números baseado na dificuldade
	match dificuldade:
		1:  # Fácil: números de 1 a 50
			num1 = randi_range(10, 50)
			num2 = randi_range(1, 30)
		2:  # Médio: números de 1 a 200
			num1 = randi_range(50, 200)
			num2 = randi_range(10, 100)
		3:  # Difícil: números de 1 a 1000
			num1 = randi_range(100, 1000)
			num2 = randi_range(50, 500)
		_:
			num1 = randi_range(10, 100)
			num2 = randi_range(1, 50)
	
	# Escolher operação
	match tipo_operacao:
		TipoOperacao.ADICAO:
			operador = "+"
		TipoOperacao.SUBTRACAO:
			operador = "-"
			# Garantir resultado positivo
			if num2 > num1:
				var temp = num1
				num1 = num2
				num2 = temp
		TipoOperacao.MISTA:
			if randi() % 2 == 0:
				operador = "+"
			else:
				operador = "-"
				# Garantir resultado positivo
				if num2 > num1:
					var temp = num1
					num1 = num2
					num2 = temp
	
	operacao_atual = operador
	
	# Calcular resposta correta
	if operador == "+":
		resposta_correta = num1 + num2
	else:
		resposta_correta = num1 - num2
	
	# Formatar pergunta com contexto divertido
	var contextos_adicao = [
		"O elefante tinha %d bananas e ganhou mais %d.\nQuantas bananas ele tem agora?",
		"Na savana há %d elefantes. Chegaram mais %d.\nQuantos elefantes há agora?",
		"O zoológico recebeu %d visitantes de manhã e %d à tarde.\nQual o total de visitantes?",
		"Um elefante bebeu %d litros de água hoje e %d ontem.\nQuantos litros ele bebeu no total?",
		"O tratador deu %d amendoins para um elefante e %d para outro.\nQuantos amendoins ele deu ao todo?"
	]
	
	var contextos_subtracao = [
		"O elefante tinha %d bananas e comeu %d.\nQuantas bananas sobraram?",
		"Havia %d elefantes na savana. %d foram para outro lugar.\nQuantos ficaram?",
		"O zoológico tinha %d ingressos. Vendeu %d.\nQuantos ainda restam?",
		"Um tanque tinha %d litros de água. O elefante bebeu %d.\nQuantos litros sobraram?",
		"O tratador tinha %d amendoins. Deu %d para o elefante.\nQuantos ainda tem?"
	]
	
	var contexto: String
	if operador == "+":
		contexto = contextos_adicao[randi() % contextos_adicao.size()]
	else:
		contexto = contextos_subtracao[randi() % contextos_subtracao.size()]
	
	_pergunta_label.text = contexto % [num1, num2]
	
	# Configurar para input de texto
	_configurar_input_texto()
	
	print("Pergunta: %d %s %d = %d" % [num1, operador, num2, resposta_correta])

