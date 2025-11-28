extends DesafioBase
class_name DesafioLeao

## Desafio da Jaula do Leão: Multiplicação
## Nível: 7º ao 9º ano do Ensino Fundamental

@export var dificuldade: int = 1  # 1 = fácil, 2 = médio, 3 = difícil

func _ready() -> void:
	titulo = "🦁 DESAFIO DO LEÃO"
	descricao = "Resolva as operações de Multiplicação!"
	total_perguntas = 5
	moedas_por_acerto = 20
	tempo_por_pergunta = 40.0
	super._ready()

func _obter_conteudo_ajuda(ajuda_label: RichTextLabel) -> void:
	ajuda_label.text = """[center][font_size=32]🦁 MULTIPLICAÇÃO[/font_size][/center]

[font_size=24]FÓRMULA:[/font_size]

[font_size=20]• Multiplicação: a × b = c[/font_size]

[font_size=24]COMO RESOLVER:[/font_size]

[font_size=20]MULTIPLICAÇÃO (×):[/font_size]
Multiplique o primeiro número pelo segundo.
Exemplo: 7 × 8 = 56

[font_size=20]DICAS:[/font_size]
• Multiplicar é somar várias vezes
• 5 × 3 = 5 + 5 + 5 = 15
• Use a tabuada para números menores
• Para números maiores, multiplique normalmente

[font_size=20]EXEMPLO:[/font_size]
12 × 4 = 48
(12 + 12 + 12 + 12 = 48)"""

func _gerar_pergunta() -> void:
	var num1: int
	var num2: int
	
	# Ajustar números baseado na dificuldade
	match dificuldade:
		1:  # Fácil: tabuada básica (1 a 10)
			num1 = randi_range(2, 10)
			num2 = randi_range(2, 10)
		2:  # Médio: números maiores
			num1 = randi_range(5, 15)
			num2 = randi_range(5, 12)
		3:  # Difícil: números de dois dígitos
			num1 = randi_range(10, 25)
			num2 = randi_range(10, 20)
		_:
			num1 = randi_range(2, 10)
			num2 = randi_range(2, 10)
	
	# Calcular resposta correta
	resposta_correta = num1 * num2
	
	# Contextos divertidos
	var contextos = [
		"O leão ruge %d vezes por dia durante %d dias.\nQuantas vezes ele rugiu no total?",
		"Cada leão come %d kg de carne por dia.\nSe temos %d leões, quantos kg são consumidos?",
		"O tratador traz %d baldes de água, %d vezes por dia.\nQuantos baldes ele traz ao todo?",
		"Na savana, há %d grupos de leões.\nCada grupo tem %d leões. Quantos leões há no total?",
		"O leão dorme %d horas por dia.\nEm %d dias, quantas horas ele dormiu?",
		"Cada filhote de leão precisa de %d mamadeiras.\nPara %d filhotes, quantas mamadeiras são necessárias?",
		"O zoológico vende %d ingressos por hora.\nEm %d horas, quantos ingressos foram vendidos?"
	]
	
	var contexto = contextos[randi() % contextos.size()]
	_pergunta_label.text = contexto % [num1, num2]
	
	# Configurar para input de texto
	_configurar_input_texto()
	
	print("Pergunta: %d × %d = %d" % [num1, num2, resposta_correta])

