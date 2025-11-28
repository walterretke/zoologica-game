extends DesafioBase
class_name DesafioMacaco

## Desafio da Jaula do Macaco: Divisão
## Nível: 7º ao 9º ano do Ensino Fundamental

@export var dificuldade: int = 1  # 1 = fácil, 2 = médio, 3 = difícil
@export var permitir_resto: bool = false  # Se true, pode ter divisões com resto

func _ready() -> void:
	titulo = "🐒 DESAFIO DO MACACO"
	descricao = "Resolva as operações de Divisão!"
	total_perguntas = 5
	moedas_por_acerto = 20
	tempo_por_pergunta = 45.0
	super._ready()

func _obter_conteudo_ajuda(ajuda_label: RichTextLabel) -> void:
	ajuda_label.text = """[center][font_size=32]🐒 DIVISÃO[/font_size][/center]

[font_size=24]FÓRMULA:[/font_size]

[font_size=20]• Divisão: a ÷ b = c[/font_size]

[font_size=24]COMO RESOLVER:[/font_size]

[font_size=20]DIVISÃO (÷):[/font_size]
Divida o primeiro número pelo segundo.
Exemplo: 24 ÷ 6 = 4

[font_size=20]DICAS:[/font_size]
• Divisão é o oposto da multiplicação
• Se 6 × 4 = 24, então 24 ÷ 6 = 4
• Pense: "Quantas vezes b cabe em a?"
• Use a tabuada para verificar

[font_size=20]EXEMPLO:[/font_size]
30 ÷ 5 = 6
(Porque 5 × 6 = 30)"""

func _gerar_pergunta() -> void:
	var dividendo: int
	var divisor: int
	
	# Ajustar números baseado na dificuldade
	match dificuldade:
		1:  # Fácil: divisões exatas simples
			divisor = randi_range(2, 10)
			var multiplicador = randi_range(2, 10)
			dividendo = divisor * multiplicador
		2:  # Médio: divisões maiores
			divisor = randi_range(3, 12)
			var multiplicador = randi_range(5, 15)
			dividendo = divisor * multiplicador
		3:  # Difícil: divisões com números maiores
			divisor = randi_range(5, 20)
			var multiplicador = randi_range(10, 25)
			dividendo = divisor * multiplicador
		_:
			divisor = randi_range(2, 10)
			var multiplicador = randi_range(2, 10)
			dividendo = divisor * multiplicador
	
	# Calcular resposta correta
	resposta_correta = dividendo / divisor
	
	# Contextos divertidos
	var contextos = [
		"O macaco tem %d bananas para dividir igualmente entre %d amigos.\nQuantas bananas cada um recebe?",
		"O tratador trouxe %d amendoins para %d macacos.\nQuantos amendoins cada macaco ganha?",
		"O zoológico arrecadou %d reais em %d dias.\nQual foi a média diária de arrecadação?",
		"Há %d cocos para serem distribuídos em %d cestas.\nQuantos cocos em cada cesta?",
		"Os macacos colheram %d frutas em %d árvores.\nQuantas frutas por árvore, em média?",
		"A família de macacos tem %d galhos para %d membros.\nQuantos galhos para cada um?",
		"O veterinário dará %d vitaminas divididas em %d doses.\nQuantas vitaminas por dose?"
	]
	
	var contexto = contextos[randi() % contextos.size()]
	_pergunta_label.text = contexto % [dividendo, divisor]
	
	# Configurar para input de texto
	_configurar_input_texto()
	
	print("Pergunta: %d ÷ %d = %d" % [dividendo, divisor, resposta_correta])

